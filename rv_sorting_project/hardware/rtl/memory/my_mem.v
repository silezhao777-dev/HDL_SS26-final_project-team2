// Simple synchronous-read memory model.
//
// This model matches the timing contract used by the external BRAM ports:
// the address is sampled on the rising edge and rd changes after that edge.
module my_mem #(
    parameter MEM_DEPTH = 256
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        mem_we,

    input  wire [31:0] a,
    input  wire [31:0] wd,

    output reg  [31:0] rd
);

    reg [31:0] RAM [0:MEM_DEPTH-1];
    wire [31:0] word_addr;

    assign word_addr = a[31:2];

    always @(posedge clk) begin
        if (rst) begin
            rd <= 32'b0;
        end
        else begin
            if (mem_we)
                RAM[word_addr] <= wd;

            rd <= RAM[word_addr];
        end
    end

endmodule
