// cpu_tb.v - simple CPU testbench
// Drives the core, dumps a VCD and prints a small execution trace

`timescale 1ns/1ps

module cpu_tb;

    // Testbench signals (expanded to 8-bit)
    reg clk;
    reg rst;
    wire halt;
    wire [7:0] pc_out;
    wire [7:0] reg0_out;
    wire [7:0] reg1_out;
    wire [7:0] reg2_out;
    wire [7:0] reg3_out;
    wire [7:0] reg4_out;
    wire [7:0] reg5_out;
    wire [7:0] reg6_out;
    wire [7:0] reg7_out;
    
    // Instantiate the CPU
    cpu cpu_inst (
        .clk(clk),
        .rst(rst),
        .halt(halt),
        .pc_out(pc_out),
        .reg0_out(reg0_out),
        .reg1_out(reg1_out),
        .reg2_out(reg2_out),
        .reg3_out(reg3_out),
        .reg4_out(reg4_out),
        .reg5_out(reg5_out),
        .reg6_out(reg6_out),
        .reg7_out(reg7_out)
    );
    
    // Clock generation: 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test sequence
    initial begin
        // Create VCD file for waveform viewing
        $dumpfile("cpu_sim.vcd");
        $dumpvars(0, cpu_tb);
        
        // Display header
        $display("=================================================");
        $display("    Enhanced 8-bit CPU Simulation");
        $display("=================================================");
        $display("Time(ns) | PC | Halt | R0 | R1 | R2 | R3 | R4 | R5 | R6 | R7 | Instruction | Assembly");
        $display("-------------------------------------------------");
        
        // Reset sequence
        rst = 1;
        #20;  // Hold reset for 20ns
        rst = 0;
        
        // Monitor signals during execution
        repeat (150) begin
            @(posedge clk);
            #1; // Small delay to see values after clock edge
            
            // Decode instruction to assembly mnemonic for display
            begin
                reg [3:0] opcode;
                reg [2:0] reg1, reg2;
                reg [5:0] imm6;
                reg [7:0] imm8;
                
                opcode = cpu_inst.instruction[15:12];
                reg1 = cpu_inst.instruction[11:9];
                reg2 = cpu_inst.instruction[8:6];
                imm6 = cpu_inst.instruction[5:0];
                imm8 = {2'b00, imm6};
                
                case (opcode)
                    4'h0: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | LOADI R%d, %d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg1, imm8);
                    4'h1: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | ADD R%d, R%d, R%d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg2, reg1, reg2);
                    4'h2: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | SUB R%d, R%d, R%d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg2, reg1, reg2);
                    4'h3: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | AND R%d, R%d, R%d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg2, reg1, reg2);
                    4'h4: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | OR R%d, R%d, R%d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg2, reg1, reg2);
                    4'h5: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | XOR R%d, R%d, R%d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg2, reg1, reg2);
                    4'h6: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | STORE R%d, [%d]", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg1, imm8);
                    4'h7: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | LOAD R%d, [%d]", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg1, imm8);
                    4'h8: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | SHL R%d, R%d, R%d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg2, reg1, reg2);
                    4'h9: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | SHR R%d, R%d, R%d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg2, reg1, reg2);
                    4'hA: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | MOV R%d, R%d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg2, reg1);
                    4'hB: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | CMP R%d, R%d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg1, reg2);
                    4'hC: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | JUMP %d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, imm8);
                    4'hD: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | JZ R%d, %d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg1, imm8);
                    4'hE: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | JNZ R%d, %d", 
                                   $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                   reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg1, imm8);
                    4'hF: begin
                        if (reg1 == 0 && reg2 == 0 && imm6 == 0)
                            $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | HALT", 
                                     $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                     reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction);
                        else
                            $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | NOT R%d, R%d", 
                                     $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                     reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction, reg2, reg1);
                    end
                    default: $display("%7t | %3d |   %b  | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %3d | %04h      | INVALID", 
                                      $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out, 
                                      reg4_out, reg5_out, reg6_out, reg7_out, cpu_inst.instruction);
                endcase
            end
            
            // Stop if CPU halts
            if (halt) begin
                $display("-------------------------------------------------");
                $display("CPU HALTED at time %0t ns", $time);
                $display("=================================================");
                $display("Final Register Values:");
                $display("  R0 = %d (hex: %h, binary: %b)", reg0_out, reg0_out, reg0_out);
                $display("  R1 = %d (hex: %h, binary: %b)", reg1_out, reg1_out, reg1_out);
                $display("  R2 = %d (hex: %h, binary: %b)", reg2_out, reg2_out, reg2_out);
                $display("  R3 = %d (hex: %h, binary: %b)", reg3_out, reg3_out, reg3_out);
                $display("  R4 = %d (hex: %h, binary: %b)", reg4_out, reg4_out, reg4_out);
                $display("  R5 = %d (hex: %h, binary: %b)", reg5_out, reg5_out, reg5_out);
                $display("  R6 = %d (hex: %h, binary: %b)", reg6_out, reg6_out, reg6_out);
                $display("  R7 = %d (hex: %h, binary: %b)", reg7_out, reg7_out, reg7_out);
                $display("=================================================");

                // Basic self-check: verify some registers have expected values
                // After program: 
                //   R1 = 10 (from SUB), R2 = 10 (from AND), R3 = 10 (from MOV)
                //   R4 = 50 (from LOADI), R5 = 10 (from LOAD [50])
                //   R6 = 10 (from MOV), R7 = 42 (from LOADI)
                if (reg1_out == 8'd10 && reg2_out == 8'd10 && reg3_out == 8'd10 && 
                    reg4_out == 8'd50 && reg5_out == 8'd10 && reg6_out == 8'd10 && reg7_out == 8'd42) begin
                    $display("TEST PASSED: All registers match expected values!");
                    $display("  R1=10, R2=10, R3=10, R4=50, R5=10 (from memory), R6=10, R7=42");
                end else begin
                    $display("TEST WARNING: Some registers don't match expected values.");
                    $display("  Expected: R1=10, R2=10, R3=10, R4=50, R5=10, R6=10, R7=42");
                    $display("  Got:      R1=%d, R2=%d, R3=%d, R4=%d, R5=%d, R6=%d, R7=%d", 
                             reg1_out, reg2_out, reg3_out, reg4_out, reg5_out, reg6_out, reg7_out);
                end

                #20;
                $finish;
            end
        end
        
        // If we get here, CPU didn't halt
        $display("WARNING: CPU did not halt after 100 cycles");
        $finish;
    end
    
    // Timeout watchdog (in case something goes wrong)
    initial begin
        #10000;  // 10000ns timeout (increased for more complex CPU)
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule