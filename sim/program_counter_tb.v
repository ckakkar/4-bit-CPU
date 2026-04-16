// program_counter_tb.v - program counter unit tests
// Covers: reset, increment, hold, load, load priority over enable.
`timescale 1ns/1ps

module program_counter_tb;

    reg        clk, rst, enable, load;
    reg  [7:0] load_addr;
    wire [7:0] pc;

    integer pass_count, fail_count;

    program_counter dut (
        .clk(clk), .rst(rst),
        .enable(enable), .load(load),
        .load_addr(load_addr), .pc(pc)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task chk;
        input [255:0] tname;
        input [7:0]   got, exp;
        begin
            if (got === exp) begin
                $display("[PASS] %0s", tname);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s: expected %0d got %0d", tname, exp, got);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        enable = 0; load = 0; load_addr = 0;

        // ---- Reset goes to 0 ----
        rst = 1; @(posedge clk); @(posedge clk); #1; rst = 0;
        chk("RESET_ZERO", pc, 8'd0);

        // ---- Increment: three enable pulses ----
        enable = 1; load = 0;
        @(posedge clk); #1; chk("INC_1", pc, 8'd1);
        @(posedge clk); #1; chk("INC_2", pc, 8'd2);
        @(posedge clk); #1; chk("INC_3", pc, 8'd3);

        // ---- Hold: enable=0 keeps value ----
        enable = 0;
        @(posedge clk); #1; chk("HOLD", pc, 8'd3);
        @(posedge clk); #1; chk("HOLD_2", pc, 8'd3);

        // ---- Load: jump to address ----
        load_addr = 8'd50; load = 1; enable = 0;
        @(posedge clk); #1; chk("LOAD_50", pc, 8'd50);
        load = 0;

        // ---- Increment again from loaded address ----
        enable = 1;
        @(posedge clk); #1; chk("INC_FROM_LOAD", pc, 8'd51);

        // ---- Load takes priority over enable ----
        load_addr = 8'd100; load = 1; enable = 1;
        @(posedge clk); #1; chk("LOAD_PRIO", pc, 8'd100);
        load = 0;

        // ---- Wrap-around at 255 ----
        load_addr = 8'd254; load = 1; enable = 0;
        @(posedge clk); #1; load = 0;
        enable = 1;
        @(posedge clk); #1; chk("WRAP_255", pc, 8'd255);
        @(posedge clk); #1; chk("WRAP_0",   pc, 8'd0);

        $display("");
        $display("Program Counter Tests: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("[SUITE_PASS] program_counter_tb");
        else                 $display("[SUITE_FAIL] program_counter_tb");
        $finish;
    end

endmodule
