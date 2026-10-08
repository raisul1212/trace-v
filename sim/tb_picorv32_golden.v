`timescale 1ns/1ps
// Testbench for picorv32. A hand-assembled RV32I program sums 1..10 and
// stores the result (55) to address 0x10000000. The memory model drives
// mem_ready and mem_rdata on the falling clock edge, and resetn is also
// released on the falling edge, so that the gate-level netlist, whose clock
// tree delays the rising edge at the flops, sees stable inputs.
// Clock period is set with +period=<ns> (default 10). The SDF file
// "picorv32.sdf" is annotated from the current directory.
// Prints "RESULT <value>" and "VERDICT PASS" when the stored value is 55.
module tb;
    reg clk = 0, resetn = 0;
    real period = 10.0;                // overridden by +period=<ns>
    initial begin
        if ($value$plusargs("period=%f", period)) ;
        $sdf_annotate("picorv32.sdf", uut);
    end
    always #(period/2.0) clk = ~clk;

    wire trap, mem_valid, mem_instr;
    reg  mem_ready = 0;
    wire [31:0] mem_addr, mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata = 0;

    picorv32 uut (
        .clk(clk), .resetn(resetn), .trap(trap),
        .mem_valid(mem_valid), .mem_instr(mem_instr), .mem_ready(mem_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .pcpi_wr(1'b0), .pcpi_rd(32'b0), .pcpi_wait(1'b0), .pcpi_ready(1'b0),
        .irq(32'b0)
    );

    reg [31:0] mem [0:255];
    reg [31:0] result = 32'hDEADBEEF;
    reg got = 0;
    integer i, cycles = 0;

    initial begin
        for (i = 0; i < 256; i = i + 1) mem[i] = 32'h00000000;
        mem[0] = 32'h00000093;   // addi x1, x0, 0     sum = 0
        mem[1] = 32'h00100113;   // addi x2, x0, 1     i = 1
        mem[2] = 32'h00B00193;   // addi x3, x0, 11    limit
        mem[3] = 32'h002080B3;   // add  x1, x1, x2    sum += i   <- loop
        mem[4] = 32'h00110113;   // addi x2, x2, 1     i++
        mem[5] = 32'hFE314CE3;   // blt  x2, x3, -8    if i<11 -> loop
        mem[6] = 32'h10000237;   // lui  x4, 0x10000
        mem[7] = 32'h00122023;   // sw   x1, 0(x4)
        mem[8] = 32'h0000006F;   // jal  x0, 0         halt
        repeat (8) @(posedge clk);
        @(negedge clk) resetn <= 1;   // RESET TOO: released on the falling edge (header)
    end

    // NEGEDGE: see the header. The core samples on its (late) rising edge;
    // half a period of margin covers any clock-tree insertion delay down to
    // the shortest clock this sweep asks for.
    always @(negedge clk) begin
        mem_ready <= 0;
        if (mem_valid && !mem_ready) begin
            mem_ready <= 1;
            if (mem_wstrb != 4'b0000) begin
                if (mem_addr == 32'h10000000) begin
                    result <= mem_wdata;
                    got <= 1;
                end else if (mem_addr < 1024)
                    mem[mem_addr >> 2] <= mem_wdata;
            end else begin
                mem_rdata <= (mem_addr < 1024) ? mem[mem_addr >> 2] : 32'h0;
            end
        end
    end

    always @(posedge clk) begin
        cycles <= cycles + 1;
        if (got) begin
            $display("RESULT %0d", result);
            if (result == 32'd55) $display("VERDICT PASS");
            else                 $display("VERDICT FAIL");
            $finish;
        end
        if (trap) begin
            $display("RESULT trap"); $display("VERDICT FAIL"); $finish;
        end
        if (cycles > 20000) begin
            $display("RESULT timeout"); $display("VERDICT FAIL"); $finish;
        end
    end
endmodule
