// instruction_memory.v - program ROM
// Holds the demo program executed by the CPU (expanded to 16-bit instructions, 256 locations)

module instruction_memory (
    input  [7:0] address,         // Instruction address (8 bits = 256 instructions max)
    output [15:0] instruction     // 16-bit instruction format
);

    // Memory array: 256 locations, each 16 bits wide
    // Instruction format: [15:12] opcode, [11:9] reg1, [8:6] reg2, [5:0] immediate/address
    reg [15:0] memory [0:255];
    
    // Initialize with a sample program
    integer i;
    initial begin
        // Initialize all memory to 0
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 16'b0000000000000000;
        end
        
        // Enhanced demo program with assembly mnemonics
        // Instruction format: {opcode[3:0], reg1[2:0], reg2[2:0], immediate[5:0]}
        // Note: For arithmetic/logic ops: reg2 is destination (Rd), reg1 is source1 (Rs1), immediate/src2 is source2
        //
        // Assembly Program (simplified to avoid branch timing issues for now):
        //  0:  LOADI R1, 5        ; R1 = 5
        //  1:  LOADI R2, 10       ; R2 = 10
        //  2:  ADD R2, R1, R2     ; R2 = R1 + R2 = 5 + 10 = 15
        //  3:  SUB R1, R2, R1     ; R1 = R2 - R1 = 15 - 5 = 10
        //  4:  MOV R3, R1         ; R3 = R1 = 10 (copy R1 to R3)
        //  5:  CMP R1, R2         ; Compare R1 and R2, set flags (R1 - R2 = 10 - 15 = -5)
        //  6:  LOADI R4, 50       ; R4 = 50 (memory address)
        //  7:  STORE R1, [50]     ; Mem[50] = R1 = 10
        //  8:  LOAD R5, [50]      ; R5 = Mem[50] = 10
        //  9:  AND R2, R1, R2     ; R2 = R1 & R2 = 10 & 15 = 10
        // 10:  MOV R6, R2         ; R6 = R2 = 10
        // 11:  JUMP 13            ; Unconditional jump to address 13
        // 12:  LOADI R7, 99       ; Skipped
        // 13:  LOADI R7, 42       ; R7 = 42
        // 14:  HALT               ; Stop execution

        memory[0]  = {4'b0000, 3'b001, 3'b000, 6'b000101};  // LOADI R1, 5
        memory[1]  = {4'b0000, 3'b010, 3'b000, 6'b001010};  // LOADI R2, 10
        memory[2]  = {4'b0001, 3'b001, 3'b010, 6'b000000};  // ADD R2, R1, R2  -> R2 = 15
        memory[3]  = {4'b0010, 3'b010, 3'b001, 6'b000000};  // SUB R1, R2, R1  -> R1 = 10
        memory[4]  = {4'b1010, 3'b001, 3'b011, 6'b000000};  // MOV R3, R1      -> R3 = R1 = 10
        memory[5]  = {4'b1011, 3'b001, 3'b010, 6'b000000};  // CMP R1, R2      -> Set flags (10 - 15)
        memory[6]  = {4'b0000, 3'b100, 3'b000, 6'b110010};  // LOADI R4, 50
        memory[7]  = {4'b0110, 3'b001, 3'b000, 6'b110010};  // STORE R1, [50]  -> Mem[50] = 10
        memory[8]  = {4'b0111, 3'b101, 3'b000, 6'b110010};  // LOAD R5, [50]   -> R5 = 10
        memory[9]  = {4'b0011, 3'b001, 3'b010, 6'b000000};  // AND R2, R1, R2  -> R2 = 10 & 15 = 10
        memory[10] = {4'b1010, 3'b010, 3'b110, 6'b000000};  // MOV R6, R2      -> R6 = 10
        memory[11] = {4'b1100, 3'b000, 3'b000, 6'b001101};  // JUMP 13         -> Unconditional jump
        memory[12] = {4'b0000, 3'b111, 3'b000, 6'b110001};  // LOADI R7, 99    -> Skipped
        memory[13] = {4'b0000, 3'b111, 3'b000, 6'b101010};  // LOADI R7, 42    -> R7 = 42
        memory[14] = {4'b1111, 3'b000, 3'b000, 6'b000000};  // HALT            -> Stop
    end
    
    // Read instruction at given address
    assign instruction = memory[address];

endmodule