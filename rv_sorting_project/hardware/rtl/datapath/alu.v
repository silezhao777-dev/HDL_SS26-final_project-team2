module alu(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] alu_control,
    output reg [31:0] alu_result,
    output wire zero
);

    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_SLL = 4'b0010;
    localparam ALU_SLT = 4'b0011;
    localparam ALU_SLTU = 4'b0100;
    localparam ALU_XOR = 4'b0101;
    localparam ALU_SRL = 4'b0110;
    localparam ALU_SRA = 4'b0111;
    localparam ALU_OR = 4'b1000;
    localparam ALU_AND = 4'b1001;

    assign zero = (alu_result == 32'b0);

    always @(*) begin 
        case (alu_control)
            ALU_ADD: begin 
                alu_result = a + b;
            end

            ALU_SUB: begin
                alu_result = a - b;
            end

            ALU_SLL: begin
                alu_result = a << b[4:0];
            end

            //set less than
            ALU_SLT: begin 
                alu_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            end

            //set less than unsigned
            ALU_SLTU: begin
                alu_result = (a < b) ? 32'd1 : 32'd0;
            end

            ALU_XOR: begin
                alu_result = a ^ b;
            end

            ALU_SRL: begin 
                alu_result = a >> b[4:0];
            end

            ALU_SRA: begin
                alu_result = $signed(a) >>> b[4:0];
            end

            ALU_OR: begin
                alu_result = a | b;
            end

            ALU_AND: begin 
                alu_result  = a & b;
            end

            default: begin
                alu_result = 32'b0;
            end
        endcase
    end

endmodule