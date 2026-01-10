// control_unit_pipelined.v - Pipelined control unit
// Generates control signals for 5-stage pipeline (IF, ID, EX, MEM, WB)

module control_unit_pipelined (
    input [15:0] instruction,     // Instruction from IF/ID pipeline register
    input [3:0] opcode,           // Extracted opcode
    // Control signals for ID stage (passed to EX)
    output reg reg_write_enable,  // Will write to register file (WB stage)
    output reg mem_write_enable,  // Will write to memory (MEM stage)
    output reg [3:0] alu_op,      // ALU operation
    output reg use_immediate,     // Use immediate as ALU operand
    output reg mem_addr_sel,      // Memory address source (0=reg, 1=immediate)
    output reg load_from_mem,     // Load data from memory (for LOAD instruction)
    output reg [2:0] reg_dest_addr, // Destination register address
    output reg is_branch,         // Is branch instruction
    output reg is_jump,           // Is jump instruction
    output reg use_fpu            // Use FPU instead of ALU (for floating-point ops)
);

    // Instruction format: {4-bit opcode, 3-bit reg1, 3-bit reg2, 6-bit immediate}
    wire [2:0] reg1 = instruction[11:9];
    wire [2:0] reg2 = instruction[8:6];
    wire [5:0] imm6 = instruction[5:0];
    
    // Opcode definitions
    localparam OP_LOADI = 4'b0000;
    localparam OP_ADD   = 4'b0001;
    localparam OP_SUB   = 4'b0010;
    localparam OP_AND   = 4'b0011;
    localparam OP_OR    = 4'b0100;
    localparam OP_XOR   = 4'b0101;
    localparam OP_STORE = 4'b0110;
    localparam OP_LOAD  = 4'b0111;
    localparam OP_SHL   = 4'b1000;
    localparam OP_SHR   = 4'b1001;
    localparam OP_MOV   = 4'b1010;
    localparam OP_CMP   = 4'b1011;
    localparam OP_JUMP  = 4'b1100;
    localparam OP_JZ    = 4'b1101;
    localparam OP_JNZ   = 4'b1110;
    localparam OP_HALT  = 4'b1111;
    
    // Floating-point opcodes (extended - use reserved opcodes or extend format)
    // For now, we'll use special immediate values or extend opcode space
    // This is a simplified implementation
    
    always @(*) begin
        // Default values
        reg_write_enable = 1'b0;
        mem_write_enable = 1'b0;
        alu_op = 4'b0000;
        use_immediate = 1'b0;
        mem_addr_sel = 1'b0;
        load_from_mem = 1'b0;
        reg_dest_addr = 3'b000;
        is_branch = 1'b0;
        is_jump = 1'b0;
        use_fpu = 1'b0;
        
        case (opcode)
            OP_LOADI: begin
                // Load immediate: reg_dest = immediate
                reg_write_enable = 1'b1;
                reg_dest_addr = reg1;  // reg1 is destination
                alu_op = 4'b1101;  // ALU_PASS_B (pass immediate)
                use_immediate = 1'b1;
                load_from_mem = 1'b0;
            end
            
            OP_ADD: begin
                // ADD: reg_dest = reg1 + reg2
                reg_write_enable = 1'b1;
                reg_dest_addr = reg2;  // reg2 is destination
                alu_op = 4'b0000;  // ALU_ADD
                use_immediate = 1'b0;
                load_from_mem = 1'b0;
            end
            
            OP_SUB: begin
                // SUB: reg_dest = reg1 - reg2
                reg_write_enable = 1'b1;
                reg_dest_addr = reg2;
                alu_op = 4'b0001;  // ALU_SUB
                use_immediate = 1'b0;
                load_from_mem = 1'b0;
            end
            
            OP_AND: begin
                // AND: reg_dest = reg1 & reg2
                reg_write_enable = 1'b1;
                reg_dest_addr = reg2;
                alu_op = 4'b0010;  // ALU_AND
                use_immediate = 1'b0;
                load_from_mem = 1'b0;
            end
            
            OP_OR: begin
                // OR: reg_dest = reg1 | reg2
                reg_write_enable = 1'b1;
                reg_dest_addr = reg2;
                alu_op = 4'b0011;  // ALU_OR
                use_immediate = 1'b0;
                load_from_mem = 1'b0;
            end
            
            OP_XOR: begin
                // XOR: reg_dest = reg1 ^ reg2
                reg_write_enable = 1'b1;
                reg_dest_addr = reg2;
                alu_op = 4'b0100;  // ALU_XOR
                use_immediate = 1'b0;
                load_from_mem = 1'b0;
            end
            
            OP_STORE: begin
                // STORE reg1 to memory[address]
                mem_write_enable = 1'b1;
                mem_addr_sel = 1'b1;  // Use immediate as address
                reg_write_enable = 1'b0;
            end
            
            OP_LOAD: begin
                // LOAD reg_dest = memory[address]
                reg_write_enable = 1'b1;
                reg_dest_addr = reg1;  // reg1 is destination
                mem_addr_sel = 1'b1;  // Use immediate as address
                load_from_mem = 1'b1; // Load from memory, not ALU
                alu_op = 4'b1100;  // ALU_PASS (not used)
            end
            
            OP_SHL: begin
                // Shift left: reg_dest = reg1 << reg2
                reg_write_enable = 1'b1;
                reg_dest_addr = reg2;
                alu_op = 4'b0110;  // ALU_SHL
                use_immediate = 1'b0;
                load_from_mem = 1'b0;
            end
            
            OP_SHR: begin
                // Shift right: reg_dest = reg1 >> reg2
                reg_write_enable = 1'b1;
                reg_dest_addr = reg2;
                alu_op = 4'b0111;  // ALU_SHR
                use_immediate = 1'b0;
                load_from_mem = 1'b0;
            end
            
            OP_MOV: begin
                // MOV: Rd = Rs
                reg_write_enable = 1'b1;
                reg_dest_addr = reg2;  // Destination
                alu_op = 4'b1100;  // ALU_PASS (pass operand_a, which is reg1)
                use_immediate = 1'b0;
                load_from_mem = 1'b0;
            end
            
            OP_CMP: begin
                // CMP: Compare Rs1 and Rs2, set flags without storing result
                reg_write_enable = 1'b0;  // Don't store result
                alu_op = 4'b0001;  // ALU_SUB to set flags
                use_immediate = 1'b0;
                load_from_mem = 1'b0;
            end
            
            OP_JUMP: begin
                // JUMP: Unconditional jump
                is_jump = 1'b1;
                reg_write_enable = 1'b0;
            end
            
            OP_JZ: begin
                // JZ: Jump if zero
                is_branch = 1'b1;
                reg_write_enable = 1'b0;
                alu_op = 4'b0001;  // ALU_SUB: reg1 - 0 (to set zero flag)
                use_immediate = 1'b1;  // Use immediate 0
            end
            
            OP_JNZ: begin
                // JNZ: Jump if non-zero
                is_branch = 1'b1;
                reg_write_enable = 1'b0;
                alu_op = 4'b0001;  // ALU_SUB: reg1 - 0
                use_immediate = 1'b1;
            end
            
            OP_HALT: begin
                // HALT: Stop execution (handled by halt signal in main CPU)
                reg_write_enable = 1'b0;
            end
            
            default: begin
                // Unknown instruction - treat as NOP
                reg_write_enable = 1'b0;
            end
        endcase
    end

endmodule
