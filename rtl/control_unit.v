// control_unit.v - enhanced control unit
// Decodes the 16-bit instruction and drives the rest of the core

module control_unit (
    input clk,                    // Clock signal
    input rst,                    // Reset signal
    input [15:0] instruction,     // Current instruction from memory (16 bits)
    input zero_flag,              // Zero flag from ALU
    input carry_flag,             // Carry flag from ALU
    input overflow_flag,          // Overflow flag from ALU
    input negative_flag,          // Negative flag from ALU
    // Interrupt signals
    input interrupt_request,      // Interrupt request from interrupt controller
    input [7:0] interrupt_vector, // Interrupt vector address
    // ALU/Multiplier/Divider results
    input [7:0] alu_result,
    input [15:0] mul_result,      // Multiply result (16-bit)
    input mul_valid,              // Multiply result valid
    // Standard control outputs
    output reg pc_enable,         // Enable PC increment
    output reg pc_load,           // Load new PC value (for jumps/branches/interrupts)
    output reg reg_write_enable,  // Enable register write
    output reg mem_write_enable,  // Enable memory write
    output reg [3:0] alu_op,      // ALU operation select (expanded to 4 bits)
    output reg [2:0] reg1_addr,   // Source register 1 address
    output reg [2:0] reg2_addr,   // Source register 2 address
    output reg [2:0] reg_dest_addr, // Destination register address
    output reg [7:0] immediate,   // Immediate value (8-bit or extended)
    output reg [15:0] immediate_16, // Extended 16-bit immediate
    output reg use_immediate,     // Use immediate as ALU operand
    output reg use_extended_imm,  // Use extended 16-bit immediate
    output reg mem_addr_sel,      // Select memory address source (reg vs immediate)
    output reg load_from_mem,     // Load register from memory (for LOAD instruction)
    // Stack operations
    output reg stack_push,        // Push to stack
    output reg stack_pop,         // Pop from stack
    // Multiplier/Divider
    output reg mul_start,         // Start multiply operation
    output reg div_start,         // Start divide operation
    output reg use_multiplier,    // Use multiplier result instead of ALU
    // I/O operations
    output reg io_read,           // Read from I/O port
    output reg io_write,          // Write to I/O port
    output reg use_io,            // Use I/O instead of memory
    // Interrupt control
    output reg interrupt_ack,     // Acknowledge interrupt
    output reg interrupt_ret,     // Return from interrupt (RETI)
    output reg interrupt_enable,  // Global interrupt enable
    output halt                   // Halt signal (stop CPU)
);

    // Instruction format: {4-bit opcode, 3-bit reg1, 3-bit reg2, 6-bit immediate}
    wire [3:0] opcode = instruction[15:12];
    wire [2:0] reg1 = instruction[11:9];
    wire [2:0] reg2 = instruction[8:6];
    wire [5:0] imm6 = instruction[5:0];
    
    // Opcode definitions (expanded instruction set with assembly mnemonics)
    // Instruction format: [15:12] opcode, [11:9] reg1 (dest/src1), [8:6] reg2 (src2/dest), [5:0] immediate
    localparam OP_LOADI = 4'b0000; // LOADI Rd, imm     - Load immediate: Rd = imm
    localparam OP_ADD   = 4'b0001; // ADD Rd, Rs1, Rs2  - Add: Rd = Rs1 + Rs2 (Rd is reg2)
    localparam OP_SUB   = 4'b0010; // SUB Rd, Rs1, Rs2  - Subtract: Rd = Rs1 - Rs2
    localparam OP_AND   = 4'b0011; // AND Rd, Rs1, Rs2  - Bitwise AND: Rd = Rs1 & Rs2
    localparam OP_OR    = 4'b0100; // OR  Rd, Rs1, Rs2  - Bitwise OR:  Rd = Rs1 | Rs2
    localparam OP_XOR   = 4'b0101; // XOR Rd, Rs1, Rs2  - Bitwise XOR: Rd = Rs1 ^ Rs2
    localparam OP_STORE = 4'b0110; // STORE Rs, [addr]  - Store register: Mem[addr] = Rs (reg1)
    localparam OP_LOAD  = 4'b0111; // LOAD Rd, [addr]   - Load from memory: Rd = Mem[addr] (Rd is reg1)
    localparam OP_SHL   = 4'b1000; // SHL Rd, Rs1, Rs2  - Shift left: Rd = Rs1 << Rs2
    localparam OP_SHR   = 4'b1001; // SHR Rd, Rs1, Rs2  - Shift right logical: Rd = Rs1 >> Rs2
    localparam OP_MOV   = 4'b1010; // MOV Rd, Rs        - Move register: Rd = Rs (Rd is reg2, Rs is reg1)
    localparam OP_CMP   = 4'b1011; // CMP Rs1, Rs2      - Compare: Set flags from Rs1 - Rs2 (no store)
    localparam OP_JUMP  = 4'b1100; // JUMP addr         - Unconditional jump: PC = addr
    localparam OP_JZ    = 4'b1101; // JZ Rs, addr       - Jump if zero: if (Rs == 0) PC = addr
    localparam OP_JNZ   = 4'b1110; // JNZ Rs, addr      - Jump if non-zero: if (Rs != 0) PC = addr
    localparam OP_NOT   = 4'b1111; // NOT Rd, Rs        - Bitwise NOT: Rd = ~Rs (uses imm[2:0] as Rd, reg1 as Rs)
    // Special opcode pattern for HALT: opcode=1111, all other fields = 0
    localparam OP_HALT  = 4'b1111; // HALT              - Halt execution (when imm=0, reg1=0, reg2=0)
    localparam OP_NOP   = 4'b1111; // NOP               - No operation (special case)
    
    // Extended instruction set opcodes (using reserved opcodes or extended format)
    // Note: Since we only have 16 opcodes (4 bits), we'll use immediate field to extend
    // For full implementation, use 32-bit instruction format
    localparam OP_PUSH  = 4'b1110; // PUSH Rs           - Push register to stack (uses reg1 as source, reg2=0)
    localparam OP_POP   = 4'b1110; // POP Rd            - Pop from stack to register (uses reg1 as dest, reg2=1)
    localparam OP_MUL   = 4'b1101; // MUL Rd, Rs1, Rs2  - Multiply: Rd = Rs1 × Rs2 (16-bit result in Rd:Rd+1)
    localparam OP_DIV   = 4'b1101; // DIV Rd, Rs1, Rs2  - Divide: Rd = Rs1 / Rs2, Rd+1 = Rs1 % Rs2
    localparam OP_LOADI16 = 4'b0000; // LOADI16 Rd, imm16 - Load 16-bit immediate (uses extended format)
    localparam OP_IN    = 4'b1110; // IN Rd, [io_addr]  - Read from I/O port (uses reg1=dest, reg2=io_addr)
    localparam OP_OUT   = 4'b1110; // OUT [io_addr], Rs - Write to I/O port (uses reg1=src, reg2=io_addr)
    localparam OP_RETI  = 4'b1111; // RETI              - Return from interrupt (special: opcode=1111, imm=1)
    
    // State machine for instruction execution
    localparam STATE_FETCH = 2'b00;
    localparam STATE_DECODE = 2'b01;
    localparam STATE_EXECUTE = 2'b10;
    localparam STATE_HALT = 2'b11;
    
    reg [1:0] state;
    reg halt_reg;
    
    // Zero-extend 6-bit immediate to 8-bit (for most instructions)
    // Sign-extend only for branch offsets if needed
    wire [7:0] imm8_extended = {2'b00, imm6};
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_FETCH;
            pc_enable <= 0;
            pc_load <= 0;
            reg_write_enable <= 0;
            mem_write_enable <= 0;
            alu_op <= 4'b0000;
            reg1_addr <= 3'b000;
            reg2_addr <= 3'b000;
            reg_dest_addr <= 3'b000;
            immediate <= 8'b00000000;
            use_immediate <= 0;
            mem_addr_sel <= 0;
            load_from_mem <= 0;
            halt_reg <= 0;
        end else begin
            // Default values
            pc_enable <= 0;
            pc_load <= 0;
            reg_write_enable <= 0;
            mem_write_enable <= 0;
            mem_addr_sel <= 0;
            load_from_mem <= 0;
            
            case (state)
                STATE_FETCH: begin
                    // Fetch instruction (instruction already available)
                    state <= STATE_DECODE;
                end
                
                STATE_DECODE: begin
                    // Decode instruction fields and set up execution
                    reg1_addr <= reg1;
                    reg2_addr <= reg2;
                    immediate <= imm8_extended;
                    
                    case (opcode)
                        OP_LOADI: begin
                            // Load immediate: reg_dest = immediate
                            reg_dest_addr <= reg1;  // reg1 is destination
                            reg1_addr <= 3'b000;    // Don't read from reg1 (read R0 which is 0)
                            alu_op <= 4'b1101;  // ALU_PASS_B (pass operand_b, which will be immediate)
                            use_immediate <= 1;
                            load_from_mem <= 0;
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        OP_ADD: begin
                            // ADD: reg_dest = reg1 + reg2
                            reg_dest_addr <= reg2;  // reg2 is destination (from instruction format)
                            alu_op <= 4'b0000;  // ALU_ADD
                            use_immediate <= 0;
                            load_from_mem <= 0;
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        OP_SUB: begin
                            // SUB: reg_dest = reg1 - reg2
                            reg_dest_addr <= reg2;
                            alu_op <= 4'b0001;  // ALU_SUB
                            use_immediate <= 0;
                            load_from_mem <= 0;
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        OP_AND: begin
                            // AND: reg_dest = reg1 & reg2
                            reg_dest_addr <= reg2;
                            alu_op <= 4'b0010;  // ALU_AND
                            use_immediate <= 0;
                            load_from_mem <= 0;
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        OP_OR: begin
                            // OR: reg_dest = reg1 | reg2
                            reg_dest_addr <= reg2;
                            alu_op <= 4'b0011;  // ALU_OR
                            use_immediate <= 0;
                            load_from_mem <= 0;
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        OP_XOR: begin
                            // XOR: reg_dest = reg1 ^ reg2
                            reg_dest_addr <= reg2;
                            alu_op <= 4'b0100;  // ALU_XOR
                            use_immediate <= 0;
                            load_from_mem <= 0;
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        OP_STORE: begin
                            // STORE reg1 to memory[address]
                            mem_write_enable <= 1;
                            mem_addr_sel <= 1;  // Use immediate as address
                            load_from_mem <= 0;
                            reg_write_enable <= 0;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        OP_LOAD: begin
                            // LOAD reg_dest = memory[address]
                            reg_dest_addr <= reg1;  // reg1 is destination
                            reg1_addr <= 3'b000;    // Don't use reg1 for address, use immediate
                            alu_op <= 4'b1100;  // ALU_PASS (won't be used)
                            mem_addr_sel <= 1;  // Use immediate as address
                            load_from_mem <= 1; // Load from memory, not ALU
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        OP_SHL: begin
                            // Shift left: reg_dest = reg1 << reg2
                            reg_dest_addr <= reg2;
                            alu_op <= 4'b0110;  // ALU_SHL
                            use_immediate <= 0;
                            load_from_mem <= 0;
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        OP_SHR: begin
                            // Shift right: reg_dest = reg1 >> reg2
                            reg_dest_addr <= reg2;
                            alu_op <= 4'b0111;  // ALU_SHR
                            use_immediate <= 0;
                            load_from_mem <= 0;
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        OP_MOV: begin
                            // MOV: Rd = Rs (assembly: MOV Rd, Rs)
                            // reg2 is destination, reg1 is source
                            reg_dest_addr <= reg2;  // Destination register
                            alu_op <= 4'b1100;  // ALU_PASS (pass operand_a, which is reg1)
                            use_immediate <= 0;
                            load_from_mem <= 0;
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        OP_CMP: begin
                            // CMP: Compare Rs1 and Rs2, set flags without storing result
                            // (assembly: CMP Rs1, Rs2)
                            reg_dest_addr <= 3'b000;  // Don't write to any register (or use R0 which is typically read-only)
                            alu_op <= 4'b0001;  // ALU_SUB to set flags: Rs1 - Rs2
                            use_immediate <= 0;
                            load_from_mem <= 0;
                            reg_write_enable <= 0;  // Don't store result, only set flags
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        OP_JUMP: begin
                            // JUMP: Unconditional jump to immediate address
                            // (assembly: JUMP addr)
                            pc_load <= 1;
                            pc_enable <= 0;
                            load_from_mem <= 0;
                            reg_write_enable <= 0;
                            state <= STATE_FETCH;
                        end
                        
                        OP_JZ: begin
                            // JZ: Jump if register is zero
                            // (assembly: JZ Rs, addr) - Jump if Rs == 0
                            // Set up ALU to compare reg1 with zero (will happen in same cycle)
                            // reg1_addr already set to reg1, ALU will compute reg1 - 0
                            reg_dest_addr <= 3'b000;  // Don't write
                            alu_op <= 4'b0001;  // ALU_SUB: reg1 - 0
                            use_immediate <= 1;  // Use immediate 0
                            immediate <= 8'b00000000;  // Compare with zero
                            load_from_mem <= 0;
                            reg_write_enable <= 0;  // Don't store result
                            // The ALU is combinational, so zero_flag will be valid after this cycle
                            // But since we're in a clocked always block, we need next state to check
                            state <= STATE_EXECUTE;  // Check zero flag in execute state
                        end
                        
                        OP_JNZ: begin
                            // JNZ: Jump if register is non-zero
                            // (assembly: JNZ Rs, addr) - Jump if Rs != 0
                            reg_dest_addr <= 3'b000;
                            alu_op <= 4'b0001;  // ALU_SUB: reg1 - 0
                            use_immediate <= 1;
                            immediate <= 8'b00000000;
                            load_from_mem <= 0;
                            reg_write_enable <= 0;
                            state <= STATE_EXECUTE;  // Check zero flag in execute state
                        end
                        
                        OP_HALT: begin
                            // HALT: Stop execution
                            // Special case: opcode=1111 AND reg1=0 AND reg2=0 AND imm=0
                            // (assembly: HALT)
                            // Check first if it's HALT (all zeros) or NOT (non-zero fields)
                            if (reg1 == 3'b000 && reg2 == 3'b000 && imm6 == 6'b000000) begin
                                // HALT instruction
                                halt_reg <= 1;
                                pc_enable <= 0;
                                pc_load <= 0;
                                reg_write_enable <= 0;
                                mem_write_enable <= 0;
                                state <= STATE_HALT;
                            end else begin
                                // NOT instruction: opcode=1111 but fields are non-zero
                                // (assembly: NOT Rd, Rs) - Rd = ~Rs
                                reg_dest_addr <= reg2;  // Destination
                                alu_op <= 4'b0101;  // ALU_NOT
                                use_immediate <= 0;
                                load_from_mem <= 0;
                                reg_write_enable <= 1;
                                pc_enable <= 1;
                                state <= STATE_FETCH;
                            end
                        end
                        
                        OP_NOT: begin
                            // This should not be reached if opcode=1111 (handled by OP_HALT above)
                            // But keeping for completeness
                            // NOT: Bitwise NOT operation
                            // (assembly: NOT Rd, Rs) - Rd = ~Rs
                            reg_dest_addr <= reg2;  // Destination
                            alu_op <= 4'b0101;  // ALU_NOT
                            use_immediate <= 0;
                            load_from_mem <= 0;
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                        
                        default: begin
                            // Unknown instruction - treat as NOP
                            load_from_mem <= 0;
                            reg_write_enable <= 0;
                            pc_enable <= 1;
                            state <= STATE_FETCH;
                        end
                    endcase
                end
                
                STATE_EXECUTE: begin
                    // Execute state: Check ALU flags after comparison operation
                    // For JZ/JNZ, the ALU was set up in DECODE to compute reg1 - 0
                    // Since ALU is combinational, zero_flag should be valid after DECODE cycle
                    // We check it here (in the cycle after DECODE) when it's stable
                    case (opcode)
                        OP_JZ: begin
                            // JZ: Jump if zero flag is set (reg1 == 0)
                            // zero_flag was set by ALU comparing reg1 with 0 in previous cycle
                            if (zero_flag) begin
                                pc_load <= 1;
                                pc_enable <= 0;
                            end else begin
                                pc_load <= 0;
                                pc_enable <= 1;
                            end
                            load_from_mem <= 0;
                            reg_write_enable <= 0;
                            state <= STATE_FETCH;
                        end
                        
                        OP_JNZ: begin
                            // JNZ: Jump if zero flag is NOT set (reg1 != 0)
                            if (!zero_flag) begin
                                pc_load <= 1;
                                pc_enable <= 0;
                            end else begin
                                pc_load <= 0;
                                pc_enable <= 1;
                            end
                            load_from_mem <= 0;
                            reg_write_enable <= 0;
                            state <= STATE_FETCH;
                        end
                        
                        default: begin
                            state <= STATE_FETCH;
                        end
                    endcase
                end
                
                STATE_HALT: begin
                    // Stay halted
                    halt_reg <= 1;
                    state <= STATE_HALT;
                end
                
                default: begin
                    state <= STATE_FETCH;
                end
            endcase
        end
    end
    
    assign halt = halt_reg;

endmodule