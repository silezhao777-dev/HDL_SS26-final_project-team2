module hazard_unit (
    // ID-stage instruction information
    input  wire [6:0] D_op,
    input  wire [4:0] D_rf_a1,
    input  wire [4:0] D_rf_a2,

    // EX-stage register information
    input  wire [4:0] E_rf_a1,
    input  wire [4:0] E_rf_a2,
    input  wire [4:0] E_rf_a3,
    input  wire       E_is_load,
    input  wire       E_control_taken,

    // MA-stage forwarding information
    input  wire [4:0] M_rf_a3,
    input  wire       M_forward_valid,

    // WB-stage register information
    input  wire [4:0] W_rf_a3,
    input  wire       W_we_rf,

    // Forwarding control
    // 00: original EX operand
    // 01: WB-stage result
    // 10: MA-stage result
    output reg  [1:0] E_forward_alu_op1,
    output reg  [1:0] E_forward_alu_op2,

    // Stall and flush control
    output reg        F_en_pc,
    output reg        D_en_plr1,
    output reg        D_clr_plr1,
    output reg        E_clr_plr2
);

    // ============================================================
    // Opcodes implemented by this processor
    // ============================================================

    localparam [6:0] OP_R_TYPE = 7'b0110011;
    localparam [6:0] OP_I_TYPE = 7'b0010011;
    localparam [6:0] OP_LW     = 7'b0000011;
    localparam [6:0] OP_SW     = 7'b0100011;
    localparam [6:0] OP_BRANCH = 7'b1100011;
    localparam [6:0] OP_JAL    = 7'b1101111;
    localparam [6:0] OP_LUI    = 7'b0110111;

    reg D_uses_rs1;
    reg D_uses_rs2;
    reg load_use_hazard;

    // ============================================================
    // Determine which source registers the ID instruction uses.
    //
    // This avoids false load-use stalls caused by instruction bits
    // that occupy the rs1/rs2 positions but are not source registers.
    // ============================================================

    always @(*) begin
        D_uses_rs1 = 1'b0;
        D_uses_rs2 = 1'b0;

        case (D_op)
            OP_R_TYPE: begin
                D_uses_rs1 = 1'b1;
                D_uses_rs2 = 1'b1;
            end

            OP_I_TYPE: begin
                D_uses_rs1 = 1'b1;
                D_uses_rs2 = 1'b0;
            end

            OP_LW: begin
                D_uses_rs1 = 1'b1;
                D_uses_rs2 = 1'b0;
            end

            OP_SW: begin
                D_uses_rs1 = 1'b1;
                D_uses_rs2 = 1'b1;
            end

            OP_BRANCH: begin
                D_uses_rs1 = 1'b1;
                D_uses_rs2 = 1'b1;
            end

            OP_JAL: begin
                D_uses_rs1 = 1'b0;
                D_uses_rs2 = 1'b0;
            end

            OP_LUI: begin
                D_uses_rs1 = 1'b0;
                D_uses_rs2 = 1'b0;
            end

            default: begin
                D_uses_rs1 = 1'b0;
                D_uses_rs2 = 1'b0;
            end
        endcase
    end

    // ============================================================
    // Load-use hazard detection
    //
    // The load is in EX and the dependent instruction is in ID.
    // A one-cycle stall lets the load reach WB, from which W_result
    // can be forwarded to the dependent instruction in EX.
    // ============================================================

    always @(*) begin
        load_use_hazard =
            E_is_load &&
            (E_rf_a3 != 5'd0) &&
            (
                (D_uses_rs1 && (E_rf_a3 == D_rf_a1)) ||
                (D_uses_rs2 && (E_rf_a3 == D_rf_a2))
            );
    end

    // ============================================================
    // RAW forwarding
    //
    // MA has priority over WB because MA contains the newer result.
    // M_forward_valid is deliberately false for a load in MA; the
    // load result is forwarded from WB after the load-use stall.
    // ============================================================

    always @(*) begin
        E_forward_alu_op1 = 2'b00;
        E_forward_alu_op2 = 2'b00;

        // Operand 1
        if (
            M_forward_valid &&
            (M_rf_a3 != 5'd0) &&
            (M_rf_a3 == E_rf_a1)
        ) begin
            E_forward_alu_op1 = 2'b10;
        end
        else if (
            W_we_rf &&
            (W_rf_a3 != 5'd0) &&
            (W_rf_a3 == E_rf_a1)
        ) begin
            E_forward_alu_op1 = 2'b01;
        end

        // Operand 2 and store write data
        if (
            M_forward_valid &&
            (M_rf_a3 != 5'd0) &&
            (M_rf_a3 == E_rf_a2)
        ) begin
            E_forward_alu_op2 = 2'b10;
        end
        else if (
            W_we_rf &&
            (W_rf_a3 != 5'd0) &&
            (W_rf_a3 == E_rf_a2)
        ) begin
            E_forward_alu_op2 = 2'b01;
        end
    end

    // ============================================================
    // Stall and control-hazard handling
    //
    // A taken branch/JAL has priority over a load-use stall because
    // the younger instructions are on the wrong path and must be
    // flushed immediately.
    // ============================================================

    always @(*) begin
        F_en_pc    = 1'b1;
        D_en_plr1  = 1'b1;
        D_clr_plr1 = 1'b0;
        E_clr_plr2 = 1'b0;

        if (E_control_taken) begin
            D_clr_plr1 = 1'b1;
            E_clr_plr2 = 1'b1;
        end
        else if (load_use_hazard) begin
            F_en_pc    = 1'b0;
            D_en_plr1  = 1'b0;
            E_clr_plr2 = 1'b1;
        end
    end

endmodule
