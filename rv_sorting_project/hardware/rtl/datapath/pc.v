module pc (
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    input  wire [31:0] next_pc,
    output reg  [31:0] pc
);

    always @(posedge clk) begin
        if (rst) begin
            /*
             * The instruction BRAM has one-cycle synchronous read latency.
             *
             * Starting at -4 causes the first next PC to be 0:
             *
             *   0xFFFF_FFFC + 4 = 0x0000_0000
             *
             * Therefore, after reset release, instruction address 0 is
             * requested while the visible PC advances to 0.
             */
            pc <= 32'hFFFF_FFFC;
        end
        else if (en) begin
            pc <= next_pc;
        end
    end

endmodule