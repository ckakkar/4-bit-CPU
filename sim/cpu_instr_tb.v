// cpu_instr_tb.v - CPU instruction integration tests
// Each test loads a short program into instruction memory via hierarchical access,
// resets the CPU, runs until halt (or timeout), then checks register/memory state.
//
// Instruction encoding: {opcode[3:0], reg1[2:0], reg2[2:0], imm6[5:0]}
//   Most arithmetic: dest=reg2, src1=reg1, src2=reg2  (2-address)
//   LOADI/LOAD/STORE : dest/src=reg1, address/value=imm6  (max imm = 63)
//   JUMP/JZ/JNZ     : target=imm6
//   R0 is always 0 and write-protected.
`timescale 1ns/1ps

module cpu_instr_tb;

    reg  clk, rst;
    wire halt;
    wire [7:0] pc_out;
    wire [7:0] reg0_out, reg1_out, reg2_out, reg3_out;
    wire [7:0] reg4_out, reg5_out, reg6_out, reg7_out;

    integer pass_count, fail_count;

    cpu cpu_inst (
        .clk(clk), .rst(rst), .halt(halt), .pc_out(pc_out),
        .reg0_out(reg0_out), .reg1_out(reg1_out), .reg2_out(reg2_out),
        .reg3_out(reg3_out), .reg4_out(reg4_out), .reg5_out(reg5_out),
        .reg6_out(reg6_out), .reg7_out(reg7_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    task chk8;
        input [255:0] tname;
        input [7:0]   got, exp;
        begin
            if (got === exp) begin
                $display("[PASS] %0s", tname);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s: expected %0d (0x%02h)  got %0d (0x%02h)",
                         tname, exp, exp, got, got);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Fill instruction memory with HALT, then write the given slots
    task clear_imem;
        integer k;
        begin
            for (k = 0; k < 256; k = k + 1)
                cpu_inst.imem.memory[k] = 16'hF000; // HALT
        end
    endtask

    // Two-cycle reset
    task do_reset;
        begin
            rst = 1;
            @(posedge clk); @(posedge clk);
            #1; rst = 0;
        end
    endtask

    // Run up to 80 clock cycles or until halt
    task run_until_halt;
        integer i;
        begin
            for (i = 0; i < 80; i = i + 1)
                if (!halt) @(posedge clk);
            #1;
        end
    endtask

    // -----------------------------------------------------------------------
    // Tests
    // -----------------------------------------------------------------------

    initial begin
        pass_count = 0; fail_count = 0;
        rst = 0;

        // ==================================================================
        // LOADI - load 6-bit immediate (max=63) into register
        // ==================================================================
        $display("\n-- LOADI --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd42}; // LOADI R1, 42
        cpu_inst.imem.memory[1] = {4'b0000, 3'd2, 3'd0, 6'd63}; // LOADI R2, 63 (max)
        cpu_inst.imem.memory[2] = {4'b0000, 3'd3, 3'd0, 6'd0};  // LOADI R3, 0
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("LOADI_R1_42",     reg1_out, 8'd42);
        chk8("LOADI_R2_63_max", reg2_out, 8'd63);
        chk8("LOADI_R3_0",      reg3_out, 8'd0);
        chk8("LOADI_R0_stays0", reg0_out, 8'd0); // R0 write-protected

        // ==================================================================
        // ADD  -  R[r2] = R[r1] + R[r2]
        // ==================================================================
        $display("\n-- ADD --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd15}; // LOADI R1, 15
        cpu_inst.imem.memory[1] = {4'b0000, 3'd2, 3'd0, 6'd10}; // LOADI R2, 10
        cpu_inst.imem.memory[2] = {4'b0001, 3'd1, 3'd2, 6'd0};  // ADD  R2=R1+R2=25
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("ADD_15plus10_eq25", reg2_out, 8'd25);

        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd0};  // LOADI R1, 0
        cpu_inst.imem.memory[1] = {4'b0000, 3'd2, 3'd0, 6'd7};  // LOADI R2, 7
        cpu_inst.imem.memory[2] = {4'b0001, 3'd1, 3'd2, 6'd0};  // ADD  R2=0+7=7
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("ADD_zero_addend", reg2_out, 8'd7);

        // ==================================================================
        // SUB  -  R[r2] = R[r1] - R[r2]
        // ==================================================================
        $display("\n-- SUB --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd30}; // LOADI R1, 30
        cpu_inst.imem.memory[1] = {4'b0000, 3'd2, 3'd0, 6'd10}; // LOADI R2, 10
        cpu_inst.imem.memory[2] = {4'b0010, 3'd1, 3'd2, 6'd0};  // SUB  R2=R1-R2=20
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("SUB_30minus10_eq20", reg2_out, 8'd20);

        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd7};  // LOADI R1, 7
        cpu_inst.imem.memory[1] = {4'b0000, 3'd2, 3'd0, 6'd7};  // LOADI R2, 7
        cpu_inst.imem.memory[2] = {4'b0010, 3'd1, 3'd2, 6'd0};  // SUB  R2=7-7=0
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("SUB_equal_zero", reg2_out, 8'd0);

        // ==================================================================
        // AND  -  R[r2] = R[r1] & R[r2]
        // ==================================================================
        $display("\n-- AND --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd63}; // LOADI R1, 63 (0x3F)
        cpu_inst.imem.memory[1] = {4'b0000, 3'd2, 3'd0, 6'd15}; // LOADI R2, 15 (0x0F)
        cpu_inst.imem.memory[2] = {4'b0011, 3'd1, 3'd2, 6'd0};  // AND  R2=63&15=15
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("AND_63and15_eq15", reg2_out, 8'd15);

        // ==================================================================
        // OR  -  R[r2] = R[r1] | R[r2]
        // ==================================================================
        $display("\n-- OR --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd48}; // LOADI R1, 48 (0x30)
        cpu_inst.imem.memory[1] = {4'b0000, 3'd2, 3'd0, 6'd15}; // LOADI R2, 15 (0x0F)
        cpu_inst.imem.memory[2] = {4'b0100, 3'd1, 3'd2, 6'd0};  // OR   R2=48|15=63
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("OR_48or15_eq63", reg2_out, 8'd63);

        // ==================================================================
        // XOR  -  R[r2] = R[r1] ^ R[r2]
        // ==================================================================
        $display("\n-- XOR --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd63}; // LOADI R1, 63 (0b00111111)
        cpu_inst.imem.memory[1] = {4'b0000, 3'd2, 3'd0, 6'd15}; // LOADI R2, 15 (0b00001111)
        cpu_inst.imem.memory[2] = {4'b0101, 3'd1, 3'd2, 6'd0};  // XOR  R2=63^15=48
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("XOR_63xor15_eq48", reg2_out, 8'd48);

        // ==================================================================
        // NOT  -  R[r2] = ~R[r1]  (opcode=1111 with non-zero fields ≠ HALT)
        // ==================================================================
        $display("\n-- NOT --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd15}; // LOADI R1, 0x0F
        cpu_inst.imem.memory[1] = {4'b1111, 3'd1, 3'd2, 6'd0};  // NOT  R2=~R1=0xF0=240
        cpu_inst.imem.memory[2] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("NOT_0x0F_eq_0xF0", reg2_out, 8'd240);

        // ==================================================================
        // MOV  -  R[r2] = R[r1]
        // ==================================================================
        $display("\n-- MOV --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd55}; // LOADI R1, 55
        cpu_inst.imem.memory[1] = {4'b1010, 3'd1, 3'd2, 6'd0};  // MOV  R2=R1=55
        cpu_inst.imem.memory[2] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("MOV_R2_eq_55",   reg2_out, 8'd55);
        chk8("MOV_R1_unchanged", reg1_out, 8'd55);

        // ==================================================================
        // SHL  -  R[r2] = R[r1] << R[r2]
        // ==================================================================
        $display("\n-- SHL --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd1};  // LOADI R1, 1
        cpu_inst.imem.memory[1] = {4'b0000, 3'd2, 3'd0, 6'd3};  // LOADI R2, 3 (shift)
        cpu_inst.imem.memory[2] = {4'b1000, 3'd1, 3'd2, 6'd0};  // SHL  R2=1<<3=8
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("SHL_1_shl_3_eq8", reg2_out, 8'd8);

        // ==================================================================
        // SHR  -  R[r2] = R[r1] >> R[r2]
        // ==================================================================
        $display("\n-- SHR --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd32}; // LOADI R1, 32
        cpu_inst.imem.memory[1] = {4'b0000, 3'd2, 3'd0, 6'd2};  // LOADI R2, 2 (shift)
        cpu_inst.imem.memory[2] = {4'b1001, 3'd1, 3'd2, 6'd0};  // SHR  R2=32>>2=8
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("SHR_32_shr_2_eq8", reg2_out, 8'd8);

        // ==================================================================
        // STORE + LOAD  (memory round-trip)
        // ==================================================================
        $display("\n-- STORE/LOAD --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd42}; // LOADI R1, 42
        cpu_inst.imem.memory[1] = {4'b0110, 3'd1, 3'd0, 6'd10}; // STORE R1, [10]
        cpu_inst.imem.memory[2] = {4'b0111, 3'd2, 3'd0, 6'd10}; // LOAD  R2, [10]
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("STORE_LOAD_addr10", reg2_out, 8'd42);

        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd3, 3'd0, 6'd7};  // LOADI R3, 7
        cpu_inst.imem.memory[1] = {4'b0110, 3'd3, 3'd0, 6'd63}; // STORE R3, [63]
        cpu_inst.imem.memory[2] = {4'b0111, 3'd4, 3'd0, 6'd63}; // LOAD  R4, [63]
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("STORE_LOAD_addr63", reg4_out, 8'd7);

        // ==================================================================
        // JUMP  -  unconditional branch skips the instruction at addr+1
        // ==================================================================
        $display("\n-- JUMP --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd55}; // LOADI R1, 55
        cpu_inst.imem.memory[1] = {4'b1100, 3'd0, 3'd0, 6'd3};  // JUMP  3
        cpu_inst.imem.memory[2] = {4'b0000, 3'd1, 3'd0, 6'd0};  // LOADI R1, 0  (SKIPPED)
        cpu_inst.imem.memory[3] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("JUMP_skips_instr", reg1_out, 8'd55);

        // ==================================================================
        // JZ  -  jump if register == 0 (taken when R1=0)
        // ==================================================================
        $display("\n-- JZ taken --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd0};  // LOADI R1, 0
        cpu_inst.imem.memory[1] = {4'b1101, 3'd1, 3'd0, 6'd4};  // JZ    R1, 4
        cpu_inst.imem.memory[2] = {4'b0000, 3'd2, 3'd0, 6'd60}; // LOADI R2, 60 (SKIPPED)
        cpu_inst.imem.memory[3] = {4'b0000, 3'd2, 3'd0, 6'd60}; // LOADI R2, 60 (SKIPPED)
        cpu_inst.imem.memory[4] = {4'b0000, 3'd2, 3'd0, 6'd42}; // LOADI R2, 42
        cpu_inst.imem.memory[5] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("JZ_taken_R2_42", reg2_out, 8'd42);

        // ==================================================================
        // JZ  -  not taken when R1 != 0
        // ==================================================================
        $display("\n-- JZ not taken --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd5};  // LOADI R1, 5
        cpu_inst.imem.memory[1] = {4'b1101, 3'd1, 3'd0, 6'd4};  // JZ    R1, 4 (NOT taken)
        cpu_inst.imem.memory[2] = {4'b0000, 3'd2, 3'd0, 6'd42}; // LOADI R2, 42
        cpu_inst.imem.memory[3] = 16'hF000;
        cpu_inst.imem.memory[4] = {4'b0000, 3'd2, 3'd0, 6'd60}; // LOADI R2, 60 (SKIPPED)
        cpu_inst.imem.memory[5] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("JZ_not_taken_R2_42", reg2_out, 8'd42);

        // ==================================================================
        // JNZ  -  jump if register != 0 (taken when R1=5)
        // ==================================================================
        $display("\n-- JNZ taken --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd5};  // LOADI R1, 5
        cpu_inst.imem.memory[1] = {4'b1110, 3'd1, 3'd0, 6'd4};  // JNZ   R1, 4
        cpu_inst.imem.memory[2] = {4'b0000, 3'd2, 3'd0, 6'd60}; // LOADI R2, 60 (SKIPPED)
        cpu_inst.imem.memory[3] = {4'b0000, 3'd2, 3'd0, 6'd60}; // LOADI R2, 60 (SKIPPED)
        cpu_inst.imem.memory[4] = {4'b0000, 3'd2, 3'd0, 6'd42}; // LOADI R2, 42
        cpu_inst.imem.memory[5] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("JNZ_taken_R2_42", reg2_out, 8'd42);

        // ==================================================================
        // JNZ  -  not taken when R1 == 0
        // ==================================================================
        $display("\n-- JNZ not taken --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd0};  // LOADI R1, 0
        cpu_inst.imem.memory[1] = {4'b1110, 3'd1, 3'd0, 6'd4};  // JNZ   R1, 4 (NOT taken)
        cpu_inst.imem.memory[2] = {4'b0000, 3'd2, 3'd0, 6'd42}; // LOADI R2, 42
        cpu_inst.imem.memory[3] = 16'hF000;
        cpu_inst.imem.memory[4] = {4'b0000, 3'd2, 3'd0, 6'd60}; // LOADI R2, 60 (SKIPPED)
        cpu_inst.imem.memory[5] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("JNZ_not_taken_R2_42", reg2_out, 8'd42);

        // ==================================================================
        // Multi-instruction ADD chain  (R2 = 1+2+3+4 = 10)
        // ==================================================================
        $display("\n-- Multi-instruction sequence --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd1};  // LOADI R1, 1
        cpu_inst.imem.memory[1] = {4'b0000, 3'd2, 3'd0, 6'd2};  // LOADI R2, 2
        cpu_inst.imem.memory[2] = {4'b0001, 3'd1, 3'd2, 6'd0};  // ADD   R2=1+2=3
        cpu_inst.imem.memory[3] = {4'b0000, 3'd1, 3'd0, 6'd3};  // LOADI R1, 3
        cpu_inst.imem.memory[4] = {4'b0001, 3'd1, 3'd2, 6'd0};  // ADD   R2=3+3=6
        cpu_inst.imem.memory[5] = {4'b0000, 3'd1, 3'd0, 6'd4};  // LOADI R1, 4
        cpu_inst.imem.memory[6] = {4'b0001, 3'd1, 3'd2, 6'd0};  // ADD   R2=4+6=10
        cpu_inst.imem.memory[7] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("ADD_chain_R2_10", reg2_out, 8'd10);

        // ==================================================================
        // JNZ conditional skip  (verify R2 unchanged when jump taken)
        // ==================================================================
        $display("\n-- JNZ conditional skip --");
        clear_imem();
        cpu_inst.imem.memory[0] = {4'b0000, 3'd1, 3'd0, 6'd3};  // LOADI R1, 3
        cpu_inst.imem.memory[1] = {4'b0000, 3'd2, 3'd0, 6'd10}; // LOADI R2, 10
        cpu_inst.imem.memory[2] = {4'b1110, 3'd1, 3'd0, 6'd4};  // JNZ   R1, 4
        cpu_inst.imem.memory[3] = {4'b0000, 3'd2, 3'd0, 6'd60}; // LOADI R2, 60 (SKIPPED)
        cpu_inst.imem.memory[4] = 16'hF000;
        do_reset(); run_until_halt();
        chk8("JNZ_skip_preserves_R2", reg2_out, 8'd10);

        // ==================================================================
        // Summary
        // ==================================================================
        $display("");
        $display("CPU Instruction Tests: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("[SUITE_PASS] cpu_instr_tb");
        else                 $display("[SUITE_FAIL] cpu_instr_tb");
        $finish;
    end

    // Watchdog: 50 µs timeout
    initial begin
        #50000000;
        $display("[FAIL] cpu_instr_tb: WATCHDOG TIMEOUT");
        $finish;
    end

endmodule
