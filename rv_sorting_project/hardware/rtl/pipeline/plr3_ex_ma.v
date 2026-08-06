// store write data & destination register address
module plr3_ex_ma(
    input wire clk,
    input wire rst,
//Datapath inputs(EX stage)
    input wire [31:0] E_alu_o,
    input wire [31:0] E_dm_wd,
    input wire [4:0] E_rf_a3,
    input wire [31:0] E_pc_p4,
//Control inputs(EX stage)
    input wire [1:0] E_sel_result,
    input wire E_we_dm,
    input wire E_we_rf,
//Datapath outputs(MA stage)
    output reg [31:0] M_alu_o,
    output reg [31:0] M_dm_wd,
    output reg [4:0] M_rf_a3,
    output reg [31:0] M_pc_p4,
//Control outputs(MA stage)
    output reg [1:0] M_sel_result,
    output reg M_we_dm,
    output reg M_we_rf,

    //ext pipelinize
    input wire [31:0] E_ext,
    output reg [31:0] M_ext
);
    always@(posedge clk) begin 
    if (rst) begin
            M_alu_o <= 32'b0;
            M_dm_wd <= 32'b0;
            M_rf_a3 <= 5'b0;
            M_pc_p4 <= 32'b0;

            M_sel_result <= 2'b0;
            M_we_dm <= 1'b0;
            M_we_rf <= 1'b0;

            M_ext <= 32'b0;
        end else begin
            M_alu_o <= E_alu_o;
            M_dm_wd <= E_dm_wd;
            M_rf_a3 <= E_rf_a3;
            M_pc_p4 <= E_pc_p4;

            M_sel_result <= E_sel_result;
            M_we_dm <= E_we_dm;
            M_we_rf <= E_we_rf;
            M_ext <= E_ext;
        end
    end
endmodule