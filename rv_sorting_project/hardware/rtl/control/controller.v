// first-level controller
module controller(
    input wire [6:0] op,
    input wire [2:0] funct3,
    output reg rf_we,
    output reg [2:0] sel_ext,
    output reg sel_alu_src_b,
    output reg dmem_we,
    output reg [1:0] sel_result,
    output reg [1:0] alu_op,
    output reg branch,
    output reg jump
);

    localparam OPCODE_LW = 7'b0000011;
    localparam OPCODE_SW = 7'b0100011;
    localparam OPCODE_R_TYPE = 7'b0110011;
    localparam OPCODE_I_TYPE = 7'b0010011;
    localparam OPCODE_BEQ = 7'b1100011;
    localparam OPCODE_JAL = 7'b1101111;
    localparam OPCODE_LUI = 7'b0110111;

    localparam EXIT_I = 3'b000;
    localparam EXIT_S = 3'b001;
    localparam EXIT_B = 3'b010;
    localparam EXIT_J = 3'b011;
    localparam EXIT_U = 3'b100;

    localparam RESULT_ALU = 2'b00;
    localparam RESULT_MEM = 2'b01;
    localparam RESULT_PC4 = 2'b10;
    localparam RESULT_IMM = 2'b11;

    localparam ALU_OP_ADD = 2'b00;
    localparam ALU_OP_R = 2'b01;
    localparam ALU_OP_I = 2'b10;
    localparam ALU_OP_BEQ = 2'b11;

    always @(*) begin
        rf_we = 1'b0;
        sel_ext = EXIT_I;
        sel_alu_src_b = 1'b0;
        dmem_we = 1'b0;
        sel_result = RESULT_ALU;
        alu_op = ALU_OP_ADD;
        branch = 1'b0;
        jump = 1'b0;

        case (op)
            OPCODE_LW: begin
                // This core implements LW only.
                if (funct3 == 3'b010) begin
                    rf_we = 1'b1;
                    sel_ext = EXIT_I;
                    sel_alu_src_b = 1'b1;
                    dmem_we = 1'b0;
                    sel_result = RESULT_MEM;
                    alu_op = ALU_OP_ADD;
                end
            end

            OPCODE_SW: begin
                // This core implements SW only.
                if (funct3 == 3'b010) begin
                    rf_we = 1'b0;
                    sel_ext = EXIT_S;
                    sel_alu_src_b = 1'b1;
                    dmem_we = 1'b1;
                    sel_result = RESULT_ALU;
                    alu_op = ALU_OP_ADD;
                end
            end

            OPCODE_R_TYPE: begin
                rf_we = 1'b1;
                sel_ext = EXIT_I;
                sel_alu_src_b = 1'b0;
                dmem_we = 1'b0;
                sel_result = RESULT_ALU;
                alu_op = ALU_OP_R;
            end

            OPCODE_I_TYPE: begin
                rf_we = 1'b1;
                sel_ext = EXIT_I;
                sel_alu_src_b = 1'b1;
                dmem_we = 1'b0;
                sel_result = RESULT_ALU;
                alu_op = ALU_OP_I;
            end

            OPCODE_BEQ: begin
                // This core implements BEQ only.
                if (funct3 == 3'b000) begin
                    rf_we = 1'b0;
                    sel_ext = EXIT_B;
                    sel_alu_src_b = 1'b0;
                    dmem_we = 1'b0;
                    sel_result = RESULT_ALU;
                    alu_op = ALU_OP_BEQ;
                    branch = 1'b1;
                end
            end

            OPCODE_JAL: begin
                rf_we = 1'b1;
                sel_ext = EXIT_J;
                sel_alu_src_b = 1'b0;
                dmem_we = 1'b0;
                sel_result = RESULT_PC4;
                alu_op = ALU_OP_ADD;
                jump = 1'b1;
            end

            OPCODE_LUI: begin
                rf_we = 1'b1;
                sel_ext = EXIT_U;
                sel_alu_src_b = 1'b1;
                dmem_we = 1'b0;
                sel_result = RESULT_IMM;
                alu_op = ALU_OP_ADD;
            end

            default: begin
                rf_we = 1'b0;
                sel_ext = EXIT_I;
                sel_alu_src_b = 1'b0;
                dmem_we = 1'b0;
                sel_result = RESULT_ALU;
                alu_op = ALU_OP_ADD;
                branch = 1'b0;
                jump = 1'b0;
            end
        endcase
    end
endmodule
