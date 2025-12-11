// cpu_tb.v - CPU Testbench
// Simulates the CPU and generates waveforms for debugging

`timescale 1ns/1ps

module cpu_tb;

    // Testbench signals
    reg clk;
    reg rst;
    wire halt;
    wire [3:0] pc_out;
    wire [3:0] reg0_out;
    wire [3:0] reg1_out;
    wire [3:0] reg2_out;
    wire [3:0] reg3_out;
    
    // Instantiate the CPU
    cpu cpu_inst (
        .clk(clk),
        .rst(rst),
        .halt(halt),
        .pc_out(pc_out),
        .reg0_out(reg0_out),
        .reg1_out(reg1_out),
        .reg2_out(reg2_out),
        .reg3_out(reg3_out)
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
        $display("    Simple 4-bit CPU Simulation");
        $display("=================================================");
        $display("Time(ns) | PC | Halt | R0 | R1 | R2 | R3 | Instruction");
        $display("-------------------------------------------------");
        
        // Reset sequence
        rst = 1;
        #20;  // Hold reset for 20ns
        rst = 0;
        
        // Monitor signals during execution
        repeat (50) begin
            @(posedge clk);
            #1; // Small delay to see values after clock edge
            $display("%7t |  %d |   %b  | %2d | %2d | %2d | %2d | %b", 
                     $time, pc_out, halt, reg0_out, reg1_out, reg2_out, reg3_out,
                     cpu_inst.instruction);
            
            // Stop if CPU halts
            if (halt) begin
                $display("-------------------------------------------------");
                $display("CPU HALTED at time %0t ns", $time);
                $display("=================================================");
                $display("Final Register Values:");
                $display("  R0 = %d (binary: %b)", reg0_out, reg0_out);
                $display("  R1 = %d (binary: %b)", reg1_out, reg1_out);
                $display("  R2 = %d (binary: %b)", reg2_out, reg2_out);
                $display("  R3 = %d (binary: %b)", reg3_out, reg3_out);
                $display("=================================================");
                #20;
                $finish;
            end
        end
        
        // If we get here, CPU didn't halt
        $display("WARNING: CPU did not halt after 50 cycles");
        $finish;
    end
    
    // Timeout watchdog (in case something goes wrong)
    initial begin
        #5000;  // 5000ns timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule