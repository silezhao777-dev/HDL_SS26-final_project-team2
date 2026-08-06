// Register file with one write port and two asynchronous read ports.
//
// Writes occur on the rising edge.  The explicit WB-to-ID bypass makes
// a value being written in WB visible to the instruction currently in ID
// before the ID/EX register samples its operands on that same rising edge.
module my_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        rf_we,

    input  wire [4:0]  a1,
    input  wire [4:0]  a2,
    input  wire [4:0]  a3,

    input  wire [31:0] wd,

    output wire [31:0] rd1,
    output wire [31:0] rd2
);

    integer i;
    reg [31:0] REG [0:31];

    wire bypass_rd1;
    wire bypass_rd2;

    assign bypass_rd1 =
        rf_we &&
        (a3 != 5'd0) &&
        (a3 == a1);

    assign bypass_rd2 =
        rf_we &&
        (a3 != 5'd0) &&
        (a3 == a2);

    assign rd1 =
        rst             ? 32'b0 :
        (a1 == 5'd0)    ? 32'b0 :
        bypass_rd1      ? wd :
                          REG[a1];

    assign rd2 =
        rst             ? 32'b0 :
        (a2 == 5'd0)    ? 32'b0 :
        bypass_rd2      ? wd :
                          REG[a2];

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                REG[i] <= 32'b0;
            end
        end
        else if (rf_we && (a3 != 5'd0)) begin
            REG[a3] <= wd;
        end
    end

endmodule
