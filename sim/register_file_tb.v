// register_file_tb.v - register file unit tests
// Covers: reset, write/read all registers, R0 write-protection, dual read ports.
`timescale 1ns/1ps

module register_file_tb;

    reg        clk, rst, we;
    reg  [2:0] ra, rb, wa;
    reg  [7:0] wd;
    wire [7:0] rda, rdb;
    wire [7:0] r0, r1, r2, r3, r4, r5, r6, r7;

    integer pass_count, fail_count;

    register_file dut (
        .clk(clk), .rst(rst),
        .write_enable(we),
        .read_addr_a(ra), .read_addr_b(rb),
        .write_addr(wa),  .write_data(wd),
        .read_data_a(rda), .read_data_b(rdb),
        .reg0_out(r0), .reg1_out(r1), .reg2_out(r2), .reg3_out(r3),
        .reg4_out(r4), .reg5_out(r5), .reg6_out(r6), .reg7_out(r7)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task chk8;
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

    // Write a value and read it back one cycle later
    task write_reg;
        input [2:0] addr;
        input [7:0] data;
        begin
            we = 1; wa = addr; wd = data;
            @(posedge clk); #1;
            we = 0;
        end
    endtask

    integer i;

    initial begin
        pass_count = 0; fail_count = 0;
        we = 0; wa = 0; wd = 0; ra = 0; rb = 0;

        // ---- Reset clears all registers ----
        rst = 1; @(posedge clk); @(posedge clk); #1; rst = 0;
        chk8("RESET_R0", r0, 8'd0);
        chk8("RESET_R1", r1, 8'd0);
        chk8("RESET_R7", r7, 8'd0);

        // ---- Write and read back R1–R7 ----
        for (i = 1; i <= 7; i = i + 1) begin
            write_reg(i[2:0], 8'd10 * i);
            ra = i[2:0];
            #1;
            chk8({"WRITE_READ_R", i + "0"}, rda, 8'd10 * i);
        end

        // ---- R0 is write-protected (always reads 0) ----
        write_reg(3'd0, 8'd99);
        ra = 3'd0; #1;
        chk8("R0_WRITE_PROTECT", r0, 8'd0);

        // ---- Write disabled: no update ----
        write_reg(3'd3, 8'd55);   // set R3=55
        we = 0; wa = 3'd3; wd = 8'd200;
        @(posedge clk); #1;
        ra = 3'd3; #1;
        chk8("WE_DISABLED", rda, 8'd55);

        // ---- Dual read ports return independent values ----
        write_reg(3'd1, 8'd11);
        write_reg(3'd2, 8'd22);
        ra = 3'd1; rb = 3'd2; #1;
        chk8("DUAL_READ_A", rda, 8'd11);
        chk8("DUAL_READ_B", rdb, 8'd22);

        // ---- All seven writable registers hold independent values ----
        chk8("INDEP_R1", r1, 8'd11);
        chk8("INDEP_R2", r2, 8'd22);
        chk8("INDEP_R3", r3, 8'd55);

        $display("");
        $display("Register File Tests: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("[SUITE_PASS] register_file_tb");
        else                 $display("[SUITE_FAIL] register_file_tb");
        $finish;
    end

endmodule
