// alu_tb.v - ALU unit tests
// Tests all 14 operations, edge cases, and all four status flags.
`timescale 1ns/1ps

module alu_tb;

    reg  [7:0] a, b;
    reg  [3:0] op;
    wire [7:0] result;
    wire       zero_flag, carry_flag, overflow_flag, negative_flag;

    integer pass_count, fail_count;

    alu dut (
        .operand_a(a), .operand_b(b), .alu_op(op),
        .result(result),
        .zero_flag(zero_flag), .carry_flag(carry_flag),
        .overflow_flag(overflow_flag), .negative_flag(negative_flag)
    );

    task chk;
        input [255:0] tname;
        input [7:0]   exp_result;
        input         exp_z, exp_c, exp_v, exp_n;
        begin
            #1;
            if (result === exp_result && zero_flag === exp_z &&
                carry_flag === exp_c && overflow_flag === exp_v &&
                negative_flag === exp_n) begin
                $display("[PASS] %0s", tname);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s: want r=%0d z=%b c=%b v=%b n=%b  got r=%0d z=%b c=%b v=%b n=%b",
                    tname,
                    exp_result, exp_z, exp_c, exp_v, exp_n,
                    result, zero_flag, carry_flag, overflow_flag, negative_flag);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;

        // ---- ADD (op=0000) ----
        a=8'd10;  b=8'd20;  op=4'b0000; chk("ADD_basic",        8'd30,  0,0,0,0);
        a=8'd0;   b=8'd0;   op=4'b0000; chk("ADD_zero",         8'd0,   1,0,0,0);
        a=8'd255; b=8'd1;   op=4'b0000; chk("ADD_carry_wrap",   8'd0,   1,1,0,0);
        a=8'd100; b=8'd100; op=4'b0000; chk("ADD_signed_ovf",   8'd200, 0,0,1,1);
        a=8'd128; b=8'd128; op=4'b0000; chk("ADD_neg_ovf",      8'd0,   1,1,1,0);

        // ---- SUB (op=0001) ----
        a=8'd30;  b=8'd10;  op=4'b0001; chk("SUB_basic",     8'd20,  0,0,0,0);
        a=8'd10;  b=8'd10;  op=4'b0001; chk("SUB_zero",      8'd0,   1,0,0,0);
        a=8'd5;   b=8'd10;  op=4'b0001; chk("SUB_borrow",    8'd251, 0,1,0,1);
        a=8'd127; b=8'd255; op=4'b0001; chk("SUB_ovf",       8'd128, 0,1,1,1);

        // ---- AND (op=0010) ----
        a=8'hF0; b=8'hAA; op=4'b0010; chk("AND_basic", 8'hA0, 0,0,0,1);
        a=8'hF0; b=8'h0F; op=4'b0010; chk("AND_zero",  8'h00, 1,0,0,0);
        a=8'hFF; b=8'hFF; op=4'b0010; chk("AND_all1",  8'hFF, 0,0,0,1);

        // ---- OR (op=0011) ----
        a=8'hF0; b=8'h0F; op=4'b0011; chk("OR_basic",  8'hFF, 0,0,0,1);
        a=8'h00; b=8'h00; op=4'b0011; chk("OR_zero",   8'h00, 1,0,0,0);

        // ---- XOR (op=0100) ----
        a=8'hCC; b=8'hAA; op=4'b0100; chk("XOR_basic", 8'h66, 0,0,0,0);
        a=8'hAA; b=8'hAA; op=4'b0100; chk("XOR_self",  8'h00, 1,0,0,0);

        // ---- NOT (op=0101) ----
        a=8'hF0; b=8'h00; op=4'b0101; chk("NOT_basic",    8'h0F, 0,0,0,0);
        a=8'hFF; b=8'h00; op=4'b0101; chk("NOT_all_ones", 8'h00, 1,0,0,0);
        a=8'h00; b=8'h00; op=4'b0101; chk("NOT_zero",     8'hFF, 0,0,0,1);

        // ---- SHL (op=0110) ----
        a=8'd1;  b=8'd3; op=4'b0110; chk("SHL_basic",   8'd8,  0,0,0,0);
        a=8'd42; b=8'd0; op=4'b0110; chk("SHL_by_zero", 8'd42, 0,0,0,0);
        a=8'h80; b=8'd1; op=4'b0110; chk("SHL_carry",   8'h00, 1,1,0,0);
        a=8'h01; b=8'd7; op=4'b0110; chk("SHL_msb",     8'h80, 0,0,0,1);

        // ---- SHR (op=0111) ----
        a=8'd64; b=8'd2; op=4'b0111; chk("SHR_basic",   8'd16, 0,0,0,0);
        a=8'd1;  b=8'd1; op=4'b0111; chk("SHR_carry",   8'd0,  1,1,0,0);
        a=8'hFF; b=8'd4; op=4'b0111; chk("SHR_logical", 8'h0F, 0,1,0,0);

        // ---- SAR (op=1000) ----
        a=8'h80; b=8'd1; op=4'b1000; chk("SAR_negative", 8'hC0, 0,0,0,1);
        a=8'd64; b=8'd1; op=4'b1000; chk("SAR_positive", 8'd32, 0,0,0,0);
        a=8'hFF; b=8'd1; op=4'b1000; chk("SAR_neg_one",  8'hFF, 0,1,0,1);

        // ---- LT signed (op=1001) ----
        a=8'd5;  b=8'd10; op=4'b1001; chk("LT_true",   8'd1, 0,0,0,0);
        a=8'd10; b=8'd5;  op=4'b1001; chk("LT_false",  8'd0, 1,0,0,0);
        a=8'hFF; b=8'd1;  op=4'b1001; chk("LT_signed", 8'd1, 0,0,0,0);
        a=8'd5;  b=8'd5;  op=4'b1001; chk("LT_equal",  8'd0, 1,0,0,0);

        // ---- LTU unsigned (op=1010) ----
        a=8'd1;  b=8'hFF; op=4'b1010; chk("LTU_true",  8'd1, 0,0,0,0);
        a=8'hFF; b=8'd1;  op=4'b1010; chk("LTU_false", 8'd0, 1,0,0,0);

        // ---- EQ (op=1011) ----
        a=8'd42; b=8'd42; op=4'b1011; chk("EQ_true",  8'd1, 0,0,0,0);
        a=8'd42; b=8'd43; op=4'b1011; chk("EQ_false", 8'd0, 1,0,0,0);

        // ---- PASS_A (op=1100) ----
        a=8'd99; b=8'd0; op=4'b1100; chk("PASS_A",      8'd99, 0,0,0,0);
        a=8'hFF; b=8'd0; op=4'b1100; chk("PASS_A_neg",  8'hFF, 0,0,0,1);

        // ---- PASS_B (op=1101) ----
        a=8'd0;  b=8'd77; op=4'b1101; chk("PASS_B",     8'd77, 0,0,0,0);
        a=8'd0;  b=8'hFF; op=4'b1101; chk("PASS_B_neg", 8'hFF, 0,0,0,1);

        $display("");
        $display("ALU Tests: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("[SUITE_PASS] alu_tb");
        else                 $display("[SUITE_FAIL] alu_tb");
        $finish;
    end

endmodule
