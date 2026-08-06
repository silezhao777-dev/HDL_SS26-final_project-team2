// sign extender
module sign_ext (
    input wire [31:0] instr,
    input wire [2:0] sel_ext,
    output reg [31:0] imm_ext
);

    localparam EXT_I = 3'b000;
    localparam EXT_S = 3'b001;
    localparam EXT_B = 3'b010;
    localparam EXT_J = 3'b011;
    localparam EXT_U = 3'b100;

    always @(*) begin 
        case (sel_ext)
            EXT_I: begin
                imm_ext = {{20{instr[31]}}, instr[31:20]};
            end

            EXT_S: begin
                imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            EXT_B: begin
                imm_ext = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            EXT_J: begin
                imm_ext = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end

            EXT_U: begin
                imm_ext = {instr[31:12], 12'b0};
            end

            default: begin
                imm_ext = 32'b0;
            end
        endcase
    end


endmodule