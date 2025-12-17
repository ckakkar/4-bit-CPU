// instruction_memory.v - program ROM
// Holds the tiny demo program executed by the CPU

module instruction_memory (
    input  [3:0] address,         // Instruction address (4 bits = 16 instructions max)
    output [7:0] instruction      // 8-bit instruction (4-bit opcode + 4-bit operand)
);

    // Memory array: 16 locations, each 8 bits wide
    reg [7:0] memory [0:15];
    
    // Initialize with a sample program
    initial begin
        // Simple program to exercise arithmetic, logic and conditional branches.
        // Format: {4-bit opcode, 4-bit operand/address}
        //
        //  0: LOAD R0, 0
        //  1: LOAD R1, 1
        //  2: ADD  R0, R1    -> R0 = 1, last_zero = 0
        //  3: JZ   7         -> not taken (last_zero = 0)
        //  4: SUB  R0, R1    -> R0 = 0, last_zero = 1
        //  5: JNZ  7         -> not taken (last_zero = 1)
        //  6: JZ   8         -> taken   (last_zero = 1)
        //  7: LOAD R0, 3     -> should be skipped
        //  8: HALT

        memory[0]  = 8'b0000_0000;  // LOAD R0, 0
        memory[1]  = 8'b0000_0001;  // LOAD R1, 1
        memory[2]  = 8'b0010_0001;  // ADD R0, R1
        memory[3]  = 8'b1000_0111;  // JZ 7
        memory[4]  = 8'b0011_0001;  // SUB R0, R1
        memory[5]  = 8'b1001_0111;  // JNZ 7
        memory[6]  = 8'b1000_1000;  // JZ 8
        memory[7]  = 8'b0000_0011;  // LOAD R0, 3
        memory[8]  = 8'b0111_0000;  // HALT
        memory[8]  = 8'b0000_0000;  // NOP (unused)
        memory[9]  = 8'b0000_0000;  // NOP (unused)
        memory[10] = 8'b0000_0000;  // NOP (unused)
        memory[11] = 8'b0000_0000;  // NOP (unused)
        memory[12] = 8'b0000_0000;  // NOP (unused)
        memory[13] = 8'b0000_0000;  // NOP (unused)
        memory[14] = 8'b0000_0000;  // NOP (unused)
        memory[15] = 8'b0000_0000;  // NOP (unused)
    end
    
    // Read instruction at given address
    assign instruction = memory[address];

endmodule