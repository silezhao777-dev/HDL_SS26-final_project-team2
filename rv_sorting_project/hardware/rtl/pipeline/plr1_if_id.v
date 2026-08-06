module plr1_if_id (
    input wire clk,
    input wire rst,
    input wire en,
    input clr,
    input wire [31:0] F_instr,
    input wire [31:0] F_pc,
    input wire [31:0] F_pc_p4,

    output reg [31:0] D_instr,
    output reg [31:0] D_pc,
    output reg [31:0] D_pc_p4
);
    always @(posedge clk) begin 
        if (rst) begin
            D_instr <= 32'b0;
            D_pc <= 32'b0;
            D_pc_p4 <= 32'b0;
        end
        else if(clr) begin 
            D_instr <= 32'b0;
            D_pc <= 32'b0;
            D_pc_p4 <= 32'b0;
        end 
        else if (en) begin
            D_instr <= F_instr;
            D_pc <= F_pc;
            D_pc_p4 <= F_pc_p4;
        end
    end
endmodule