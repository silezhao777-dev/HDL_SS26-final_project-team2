`timescale 1ns/1ps

module tb_rv_pipeline_sync_bram;

    reg clk = 1'b0;
    reg sys_resetn = 1'b0;
    reg run_resetn = 1'b0;

    wire        imem_enb;
    wire [3:0]  imem_web;
    wire [31:0] imem_addrb;
    wire [31:0] imem_dinb;
    reg  [31:0] imem_doutb;

    wire        dmem_enb;
    wire [3:0]  dmem_web;
    wire [31:0] dmem_addrb;
    wire [31:0] dmem_dinb;
    reg  [31:0] dmem_doutb;

    reg [31:0] imem [0:2047];
    reg [31:0] dmem [0:2047];

    integer i;

    rv_pipeline DUT (
        .clk         (clk),
        .sys_resetn  (sys_resetn),
        .run_resetn  (run_resetn),

        .imem_enb    (imem_enb),
        .imem_web    (imem_web),
        .imem_addrb  (imem_addrb),
        .imem_dinb   (imem_dinb),
        .imem_doutb  (imem_doutb),

        .dmem_enb    (dmem_enb),
        .dmem_web    (dmem_web),
        .dmem_addrb  (dmem_addrb),
        .dmem_dinb   (dmem_dinb),
        .dmem_doutb  (dmem_doutb)
    );

    always #10 clk = ~clk;

    // One-cycle synchronous instruction BRAM model.
    always @(posedge clk) begin
        if (imem_enb)
            imem_doutb <= imem[imem_addrb[12:2]];
    end

    // One-cycle synchronous data BRAM model with byte write enables.
    always @(posedge clk) begin
        if (dmem_enb) begin
            if (dmem_web[0])
                dmem[dmem_addrb[12:2]][7:0] <= dmem_dinb[7:0];

            if (dmem_web[1])
                dmem[dmem_addrb[12:2]][15:8] <= dmem_dinb[15:8];

            if (dmem_web[2])
                dmem[dmem_addrb[12:2]][23:16] <= dmem_dinb[23:16];

            if (dmem_web[3])
                dmem[dmem_addrb[12:2]][31:24] <= dmem_dinb[31:24];

            dmem_doutb <= dmem[dmem_addrb[12:2]];
        end
    end

    initial begin
        imem_doutb = 32'b0;
        dmem_doutb = 32'b0;

        for (i = 0; i < 2048; i = i + 1) begin
            imem[i] = 32'h00000013;
            dmem[i] = 32'b0;
        end

        imem[0] = 32'h00500093;
        imem[1] = 32'h00708113;
        imem[2] = 32'h002081B3;
        imem[3] = 32'h04302023;
        imem[4] = 32'h04002303;
        imem[5] = 32'h006303B3;
        imem[6] = 32'h04702423;
        imem[7] = 32'h12345237;
        imem[8] = 32'h00720293;
        imem[9] = 32'h04502223;
        imem[10] = 32'h00108463;
        imem[11] = 32'h04002623;
        imem[12] = 32'h05500413;
        imem[13] = 32'h04802623;
        imem[14] = 32'h008004EF;
        imem[15] = 32'h04002823;
        imem[16] = 32'h04902823;
        imem[17] = 32'h0000006F;

        repeat (4) @(posedge clk);
        sys_resetn = 1'b1;
        run_resetn = 1'b1;

        repeat (80) @(posedge clk);

        run_resetn = 1'b0;
        repeat (2) @(posedge clk);

        if (dmem[16] !== 32'h00000011) begin
            $display("FAIL: DMEM[0x40] = %08x", dmem[16]);
            $finish;
        end

        if (dmem[17] !== 32'h12345007) begin
            $display("FAIL: DMEM[0x44] = %08x", dmem[17]);
            $finish;
        end

        if (dmem[18] !== 32'h00000022) begin
            $display("FAIL: DMEM[0x48] = %08x", dmem[18]);
            $finish;
        end

        if (dmem[19] !== 32'h00000055) begin
            $display("FAIL: DMEM[0x4C] = %08x", dmem[19]);
            $finish;
        end

        if (dmem[20] !== 32'h0000003C) begin
            $display("FAIL: DMEM[0x50] = %08x", dmem[20]);
            $finish;
        end

        $display("PASS: synchronous BRAM, load-use, forwarding, BEQ, JAL, and LUI");
        $finish;
    end

endmodule