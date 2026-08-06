// Pipeline Register 4: MA -> WB
module plr4_ma_wb (
    input wire clk,
    input wire rst,

// Datapath inputs from MA stage
    input wire [31:0] M_alu_o,
    input wire [31:0] M_dm_rd,
    input wire [4:0] M_rf_a3,
    input wire [31:0] M_pc_p4,

// Control inputs from MA stage
    input wire [1:0] M_sel_result,
    input wire M_we_rf,

// Datapath outputs to WB stage
    output reg [31:0] W_alu_o,
    output reg [31:0] W_dm_rd,
    output reg [4:0] W_rf_a3,
    output reg [31:0] W_pc_p4,

// Control outputs to WB stage
    output reg [1:0] W_sel_result,
    output reg W_we_rf,

    //ext
    input wire [31:0] M_ext,
    output reg [31:0] W_ext
);

    always @(posedge clk) begin
        if (rst) begin
            W_alu_o <= 32'b0;
            W_dm_rd <= 32'b0;
            W_rf_a3 <= 5'b0;
            W_pc_p4 <= 32'b0;

            W_sel_result <= 2'b0;
            W_we_rf <= 1'b0;
            W_ext <= 32'b0;
        end else begin
            W_alu_o <= M_alu_o;
            W_dm_rd <= M_dm_rd;
            W_rf_a3 <= M_rf_a3;
            W_pc_p4 <= M_pc_p4;

            W_sel_result <= M_sel_result;
            W_we_rf <= M_we_rf;
            W_ext <= M_ext;
        end
    end
endmodule