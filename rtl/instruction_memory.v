// instruction_memory.v - Instruction Memory
// Stores the program instructions (ROM - Read Only Memory)

module instruction_memory (
    input  [3:0] address,         // Instruction address (4 bits = 16 instructions max)
    output [7:0] instruction      // 8-bit instruction (4-bit opcode + 4-bit operand)
);

    // Memory array: 16 locations, each 8 bits wide
    reg [7:0] memory [0:15];
    
    // Initialize with a sample program
    initial begin
        // Simple program to demonstrate CPU functionality
        // Format: {4-bit opcode, 4-bit operand/address}
        
        memory[0]  = 8'b0000_0101;  // LOAD R0, 5      - Load immediate value 5 into R0
        memory[1]  = 8'b0000_0011;  // LOAD R1, 3      - Load immediate value 3 into R1
        memory[2]  = 8'b0010_0001;  // ADD R0, R1      - R0 = R0 + R1 (5 + 3 = 8)
        memory[3]  = 8'b0000_0010;  // LOAD R2, 2      - Load immediate value 2 into R2
        memory[4]  = 8'b0011_0010;  // SUB R0, R2      - R0 = R0 - R2 (8 - 2 = 6)
        memory[5]  = 8'b0100_0001;  // AND R0, R1      - R0 = R0 & R1 (bitwise AND)
        memory[6]  = 8'b0101_0001;  // OR R0, R1       - R0 = R0 | R1 (bitwise OR)
        memory[7]  = 8'b0111_0000;  // HALT            - Stop execution
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