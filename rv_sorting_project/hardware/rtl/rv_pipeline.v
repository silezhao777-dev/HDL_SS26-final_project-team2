module rv_pipeline (
    input  wire        clk,
    input  wire        sys_resetn,
    input  wire        run_resetn,

    // Instruction BRAM Port B
    output wire        imem_enb,
    output wire [3:0]  imem_web,
    output wire [31:0] imem_addrb,
    output wire [31:0] imem_dinb,
    input  wire [31:0] imem_doutb,

    // Data BRAM Port B
    output wire        dmem_enb,
    output wire [3:0]  dmem_web,
    output wire [31:0] dmem_addrb,
    output wire [31:0] dmem_dinb,
    input  wire [31:0] dmem_doutb
);

    // Write-back source encoding.  Keep this encoding identical to
    // controller.v and to the pipeline-register control fields.
    localparam [1:0] RESULT_ALU = 2'b00;
    localparam [1:0] RESULT_MEM = 2'b01;
    localparam [1:0] RESULT_PC4 = 2'b10;
    localparam [1:0] RESULT_IMM = 2'b11;

    // Either active-low reset input can hold the core in reset.
    wire rst;
    assign rst = (~sys_resetn) | (~run_resetn);

    // ============================================================
    // Hazard control
    // ============================================================

    wire       F_en_pc;
    wire       D_en_plr1;
    wire       D_clr_plr1_hazard;
    wire       D_clr_plr1;
    wire       E_clr_plr2;

    wire [1:0] E_forward_alu_op1;
    wire [1:0] E_forward_alu_op2;

    wire [31:0] E_forwarded_rd1;
    wire [31:0] E_forwarded_rd2;

    // ============================================================
    // IF stage
    // ============================================================

    wire [31:0] F_pc;
    wire [31:0] F_pc_next;
    wire [31:0] F_pc_p4;
    wire [31:0] F_instr;

    wire        E_take_branch;
    wire        E_control_taken;
    wire [31:0] E_target_pc;

    pc PC (
        .clk     (clk),
        .rst     (rst),
        .en      (F_en_pc),
        .next_pc (F_pc_next),
        .pc      (F_pc)
    );

    adder #(
        .WIDTH(32)
    ) PC_ADD4 (
        .a (F_pc),
        .b (32'd4),
        .y (F_pc_p4)
    );

    assign F_pc_next =
        E_control_taken ? E_target_pc : F_pc_p4;

    // ============================================================
    // External synchronous Instruction BRAM
    // ============================================================

    /*
     * Port B receives a 32-bit byte address.  The BRAM has one-cycle
     * synchronous read latency, so the core presents the address that
     * will correspond to the next visible PC value.
     */
    wire [31:0] F_fetch_addr;
    reg         F_imem_valid;

    assign F_fetch_addr =
        F_en_pc ? F_pc_next : F_pc;

    assign imem_enb   = ~rst;
    assign imem_web   = 4'b0000;
    assign imem_addrb = F_fetch_addr;
    assign imem_dinb  = 32'b0;

    assign F_instr = imem_doutb;

    /*
     * The first BRAM output after reset release is not yet a valid
     * instruction, so clear IF/ID for that first cycle.
     */
    always @(posedge clk) begin
        if (rst)
            F_imem_valid <= 1'b0;
        else
            F_imem_valid <= 1'b1;
    end

    assign D_clr_plr1 =
        D_clr_plr1_hazard | (~F_imem_valid);

    // ============================================================
    // PLR1: IF -> ID
    // ============================================================

    wire [31:0] D_instr;
    wire [31:0] D_pc;
    wire [31:0] D_pc_p4;

    plr1_if_id PLR1 (
        .clk       (clk),
        .rst       (rst),
        .en        (D_en_plr1),
        .clr       (D_clr_plr1),

        .F_instr   (F_instr),
        .F_pc      (F_pc),
        .F_pc_p4   (F_pc_p4),

        .D_instr   (D_instr),
        .D_pc      (D_pc),
        .D_pc_p4   (D_pc_p4)
    );

    // ============================================================
    // ID stage
    // ============================================================

    wire [6:0] D_op;
    wire [2:0] D_funct3;
    wire       D_funct75;

    wire [4:0] D_rf_a1;
    wire [4:0] D_rf_a2;
    wire [4:0] D_rf_a3;

    wire [31:0] D_rf_rd1;
    wire [31:0] D_rf_rd2;
    wire [31:0] D_ext;

    wire       D_we_rf;
    wire [2:0] D_sel_ext;
    wire       D_sel_alu_src_b;
    wire       D_we_dm;
    wire [1:0] D_sel_result;
    wire [1:0] D_alu_op;
    wire       D_branch;
    wire       D_jump;

    wire [3:0] D_alu_control;

    assign D_op      = D_instr[6:0];
    assign D_rf_a3   = D_instr[11:7];
    assign D_funct3  = D_instr[14:12];
    assign D_rf_a1   = D_instr[19:15];
    assign D_rf_a2   = D_instr[24:20];
    assign D_funct75 = D_instr[30];

    controller CONTROLLER (
        .op            (D_op),
        .funct3        (D_funct3),
        .rf_we         (D_we_rf),
        .sel_ext       (D_sel_ext),
        .sel_alu_src_b (D_sel_alu_src_b),
        .dmem_we       (D_we_dm),
        .sel_result    (D_sel_result),
        .alu_op        (D_alu_op),
        .branch        (D_branch),
        .jump          (D_jump)
    );

    alu_controller ALU_CONTROLLER (
        .alu_op      (D_alu_op),
        .funct3      (D_funct3),
        .funct75     (D_funct75),
        .alu_control (D_alu_control)
    );

    wire        W_we_rf;
    wire [4:0]  W_rf_a3;
    wire [31:0] W_result;

    my_reg REGFILE (
        .clk   (clk),
        .rst   (rst),
        .rf_we (W_we_rf),

        .a1    (D_rf_a1),
        .a2    (D_rf_a2),
        .a3    (W_rf_a3),

        .wd    (W_result),

        .rd1   (D_rf_rd1),
        .rd2   (D_rf_rd2)
    );

    sign_ext SIGN_EXT (
        .instr   (D_instr),
        .sel_ext (D_sel_ext),
        .imm_ext (D_ext)
    );

    // ============================================================
    // PLR2: ID -> EX
    // ============================================================

    wire [31:0] E_pc;
    wire [31:0] E_pc_p4;
    wire [31:0] E_ext;
    wire [31:0] E_rf_rd1;
    wire [31:0] E_rf_rd2;

    wire [4:0] E_rf_a1;
    wire [4:0] E_rf_a2;
    wire [4:0] E_rf_a3;

    wire [3:0] E_alu_control;
    wire       E_sel_alu_src_b;
    wire [1:0] E_sel_result;
    wire       E_we_dm;
    wire       E_we_rf;
    wire       E_branch;
    wire       E_jump;

    wire       E_is_load;
    assign E_is_load = (E_sel_result == RESULT_MEM);

    plr2_id_ex PLR2 (
        .clk             (clk),
        .rst             (rst),
        .clr             (E_clr_plr2),

        .D_pc            (D_pc),
        .D_pc_p4         (D_pc_p4),
        .D_ext           (D_ext),
        .D_rf_rd1        (D_rf_rd1),
        .D_rf_rd2        (D_rf_rd2),

        .D_rf_a1         (D_rf_a1),
        .D_rf_a2         (D_rf_a2),
        .D_rf_a3         (D_rf_a3),

        .D_alu_control   (D_alu_control),
        .D_sel_alu_src_b (D_sel_alu_src_b),
        .D_sel_result    (D_sel_result),
        .D_we_dm         (D_we_dm),
        .D_we_rf         (D_we_rf),
        .D_branch        (D_branch),
        .D_jump          (D_jump),

        .E_pc            (E_pc),
        .E_pc_p4         (E_pc_p4),
        .E_ext           (E_ext),
        .E_rf_rd1        (E_rf_rd1),
        .E_rf_rd2        (E_rf_rd2),

        .E_rf_a1         (E_rf_a1),
        .E_rf_a2         (E_rf_a2),
        .E_rf_a3         (E_rf_a3),

        .E_alu_control   (E_alu_control),
        .E_sel_alu_src_b (E_sel_alu_src_b),
        .E_sel_result    (E_sel_result),
        .E_we_dm         (E_we_dm),
        .E_we_rf         (E_we_rf),
        .E_branch        (E_branch),
        .E_jump          (E_jump)
    );

    // ============================================================
    // MA-stage signals declared before the forwarding network
    // ============================================================

    wire [31:0] M_alu_o;
    wire [31:0] M_dm_wd;
    wire [4:0]  M_rf_a3;
    wire [31:0] M_pc_p4;
    wire [31:0] M_ext;

    wire [1:0] M_sel_result;
    wire       M_we_dm;
    wire       M_we_rf;

    /*
     * The value forwarded from MA must match the architectural value
     * that the instruction will eventually write back:
     *
     *   ALU instruction -> M_alu_o
     *   JAL             -> M_pc_p4
     *   LUI             -> M_ext
     *
     * A load is deliberately not forwarded from MA in this design.
     * The load-use interlock inserts one bubble, after which the load
     * result is available through W_result and is forwarded from WB.
     */
    wire        M_forward_valid;
    wire [31:0] M_forward_value;

    assign M_forward_valid =
        M_we_rf &&
        (M_sel_result != RESULT_MEM);

    assign M_forward_value =
        (M_sel_result == RESULT_ALU) ? M_alu_o  :
        (M_sel_result == RESULT_PC4) ? M_pc_p4  :
        (M_sel_result == RESULT_IMM) ? M_ext    :
                                      32'b0;

    // ============================================================
    // EX stage
    // ============================================================

    wire [31:0] E_alu_src_b;
    wire [31:0] E_alu_o;
    wire        E_zero;
    wire [31:0] E_dm_wd;

    mux3to1 #(
        .WIDTH(32)
    ) FORWARD_OP1_MUX (
        .d0  (E_rf_rd1),
        .d1  (W_result),
        .d2  (M_forward_value),
        .sel (E_forward_alu_op1),
        .y   (E_forwarded_rd1)
    );

    mux3to1 #(
        .WIDTH(32)
    ) FORWARD_OP2_MUX (
        .d0  (E_rf_rd2),
        .d1  (W_result),
        .d2  (M_forward_value),
        .sel (E_forward_alu_op2),
        .y   (E_forwarded_rd2)
    );

    assign E_alu_src_b =
        E_sel_alu_src_b ? E_ext : E_forwarded_rd2;

    alu ALU (
        .a           (E_forwarded_rd1),
        .b           (E_alu_src_b),
        .alu_control (E_alu_control),
        .alu_result  (E_alu_o),
        .zero        (E_zero)
    );

    adder #(
        .WIDTH(32)
    ) TARGET_PC_ADD (
        .a (E_pc),
        .b (E_ext),
        .y (E_target_pc)
    );

    assign E_dm_wd = E_forwarded_rd2;

    assign E_take_branch =
        E_branch && E_zero;

    assign E_control_taken =
        E_take_branch || E_jump;

    // ============================================================
    // External synchronous Data BRAM
    // ============================================================

    /*
     * Launch the byte address while the load/store is in EX.
     * One clock later, dmem_doutb is aligned with the same
     * instruction's MA-stage control signals.
     */
    wire E_mem_access;

    assign E_mem_access =
        E_is_load | E_we_dm;

    assign dmem_enb =
        (~rst) && E_mem_access;

    assign dmem_web =
        ((~rst) && E_we_dm) ? 4'b1111 : 4'b0000;

    assign dmem_addrb = E_alu_o;
    assign dmem_dinb  = E_dm_wd;

    // ============================================================
    // PLR3: EX -> MA
    // ============================================================

    plr3_ex_ma PLR3 (
        .clk          (clk),
        .rst          (rst),

        .E_alu_o      (E_alu_o),
        .E_dm_wd      (E_dm_wd),
        .E_rf_a3      (E_rf_a3),
        .E_pc_p4      (E_pc_p4),
        .E_ext        (E_ext),

        .E_sel_result (E_sel_result),
        .E_we_dm      (E_we_dm),
        .E_we_rf      (E_we_rf),

        .M_alu_o      (M_alu_o),
        .M_dm_wd      (M_dm_wd),
        .M_rf_a3      (M_rf_a3),
        .M_pc_p4      (M_pc_p4),
        .M_ext        (M_ext),

        .M_sel_result (M_sel_result),
        .M_we_dm      (M_we_dm),
        .M_we_rf      (M_we_rf)
    );

    // ============================================================
    // MA stage
    // ============================================================

    /*
     * Block Memory Generator updates dmem_doutb after the rising edge
     * that accepts the read address. Capture the returned word on the
     * falling edge so that it is stable before PLR4 samples it on the
     * next rising edge. This preserves the five-stage pipeline and the
     * existing one-cycle load-use interlock.
     */
    reg [31:0] M_dm_rd;

    always @(negedge clk) begin
        if (rst)
            M_dm_rd <= 32'b0;
        else
            M_dm_rd <= dmem_doutb;
    end

    // ============================================================
    // PLR4: MA -> WB
    // ============================================================

    wire [31:0] W_alu_o;
    wire [31:0] W_dm_rd;
    wire [31:0] W_pc_p4;
    wire [31:0] W_ext;
    wire [1:0]  W_sel_result;

    plr4_ma_wb PLR4 (
        .clk          (clk),
        .rst          (rst),

        .M_alu_o      (M_alu_o),
        .M_dm_rd      (M_dm_rd),
        .M_rf_a3      (M_rf_a3),
        .M_pc_p4      (M_pc_p4),
        .M_ext        (M_ext),

        .M_sel_result (M_sel_result),
        .M_we_rf      (M_we_rf),

        .W_alu_o      (W_alu_o),
        .W_dm_rd      (W_dm_rd),
        .W_rf_a3      (W_rf_a3),
        .W_pc_p4      (W_pc_p4),
        .W_ext        (W_ext),

        .W_sel_result (W_sel_result),
        .W_we_rf      (W_we_rf)
    );

    // ============================================================
    // WB stage
    // ============================================================

    assign W_result =
        (W_sel_result == RESULT_ALU) ? W_alu_o  :
        (W_sel_result == RESULT_MEM) ? W_dm_rd  :
        (W_sel_result == RESULT_PC4) ? W_pc_p4  :
                                      W_ext;

    // ============================================================
    // Hazard Unit
    // ============================================================

    hazard_unit HAZARD_UNIT (
        // ID stage
        .D_op              (D_op),
        .D_rf_a1           (D_rf_a1),
        .D_rf_a2           (D_rf_a2),

        // EX stage
        .E_rf_a1           (E_rf_a1),
        .E_rf_a2           (E_rf_a2),
        .E_rf_a3           (E_rf_a3),
        .E_is_load         (E_is_load),
        .E_control_taken   (E_control_taken),

        // MA stage
        .M_rf_a3           (M_rf_a3),
        .M_forward_valid   (M_forward_valid),

        // WB stage
        .W_rf_a3           (W_rf_a3),
        .W_we_rf           (W_we_rf),

        // Forwarding
        .E_forward_alu_op1 (E_forward_alu_op1),
        .E_forward_alu_op2 (E_forward_alu_op2),

        // Stall and flush
        .F_en_pc           (F_en_pc),
        .D_en_plr1         (D_en_plr1),
        .D_clr_plr1        (D_clr_plr1_hazard),
        .E_clr_plr2        (E_clr_plr2)
    );

endmodule
