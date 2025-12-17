// control_unit.v - simple control unit
// Decodes the 8-bit instruction and drives the rest of the core

module control_unit (
    input clk,                    // Clock signal
    input rst,                    // Reset signal
    input [7:0] instruction,      // Current instruction from memory
    input zero_flag,              // Zero flag from ALU
    output reg pc_enable,         // Enable PC increment
    output reg pc_load,           // Load new PC value (for jumps)
    output reg reg_write_enable,  // Enable register write
    output reg [2:0] alu_op,      // ALU operation select
    output reg halt               // Halt signal (stop CPU)
);

    // Instruction format: {4-bit opcode, 4-bit operand}
    wire [3:0] opcode = instruction[7:4];
    wire [3:0] operand = instruction[3:0];
    
    // Opcode definitions
    localparam OP_LOAD = 4'b0000;  // Load immediate value into R0
    localparam OP_STORE = 4'b0001; // Store (reserved, not used here)
    localparam OP_ADD  = 4'b0010;  // R0 <- R0 + R1
    localparam OP_SUB  = 4'b0011;  // R0 <- R0 - R1
    localparam OP_AND  = 4'b0100;  // R0 <- R0 & R1
    localparam OP_OR   = 4'b0101;  // R0 <- R0 | R1
    localparam OP_JUMP = 4'b0110;  // Unconditional jump
    localparam OP_HALT = 4'b0111;  // Halt execution
    localparam OP_JZ   = 4'b1000;  // Jump if last result was zero
    localparam OP_JNZ  = 4'b1001;  // Jump if last result was non-zero
    
    // State machine for instruction execution
    localparam STATE_FETCH = 2'b00;
    localparam STATE_DECODE = 2'b01;
    localparam STATE_EXECUTE = 2'b10;
    localparam STATE_HALT = 2'b11;
    
    reg [1:0] state;
    reg       last_zero;           // Latched copy of the ALU zero flag
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_FETCH;
            pc_enable <= 0;
            pc_load <= 0;
            reg_write_enable <= 0;
            alu_op <= 3'b000;
            halt <= 0;
            last_zero <= 1'b0;
        end else begin
            case (state)
                STATE_FETCH: begin
                    // Fetch instruction (already done by instruction memory)
                    pc_enable <= 0;
                    pc_load <= 0;
                    reg_write_enable <= 0;
                    state <= STATE_DECODE;
                end
                
                STATE_DECODE: begin
                    // Decode and execute instruction
                    case (opcode)
                        OP_LOAD: begin
                            // Load immediate value into R0
                            alu_op <= 3'b101;  // PASS operand through ALU
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            pc_load <= 0;
                            last_zero <= zero_flag;
                            state <= STATE_FETCH;
                        end
                        
                        OP_ADD: begin
                            // Add operation
                            alu_op <= 3'b000;  // ADD
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            pc_load <= 0;
                            last_zero <= zero_flag;
                            state <= STATE_FETCH;
                        end
                        
                        OP_SUB: begin
                            // Subtract operation
                            alu_op <= 3'b001;  // SUB
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            pc_load <= 0;
                            last_zero <= zero_flag;
                            state <= STATE_FETCH;
                        end
                        
                        OP_AND: begin
                            // AND operation
                            alu_op <= 3'b010;  // AND
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            pc_load <= 0;
                            last_zero <= zero_flag;
                            state <= STATE_FETCH;
                        end
                        
                        OP_OR: begin
                            // OR operation
                            alu_op <= 3'b011;  // OR
                            reg_write_enable <= 1;
                            pc_enable <= 1;
                            pc_load <= 0;
                            last_zero <= zero_flag;
                            state <= STATE_FETCH;
                        end
                        
                        OP_JUMP: begin
                            // Unconditional jump to address in operand
                            pc_load <= 1;
                            pc_enable <= 0;
                            reg_write_enable <= 0;
                            state <= STATE_FETCH;
                        end

                        OP_JZ: begin
                            // Jump if last ALU result was zero
                            if (last_zero) begin
                                pc_load <= 1;
                                pc_enable <= 0;
                            end else begin
                                pc_load <= 0;
                                pc_enable <= 1;
                            end
                            reg_write_enable <= 0;
                            state <= STATE_FETCH;
                        end

                        OP_JNZ: begin
                            // Jump if last ALU result was non-zero
                            if (!last_zero) begin
                                pc_load <= 1;
                                pc_enable <= 0;
                            end else begin
                                pc_load <= 0;
                                pc_enable <= 1;
                            end
                            reg_write_enable <= 0;
                            state <= STATE_FETCH;
                        end
                        
                        OP_HALT: begin
                            // Halt execution
                            halt <= 1;
                            pc_enable <= 0;
                            pc_load <= 0;
                            reg_write_enable <= 0;
                            state <= STATE_HALT;
                        end
                        
                        default: begin
                            // Unknown instruction - treat as NOP
                            pc_enable <= 1;
                            pc_load <= 0;
                            reg_write_enable <= 0;
                            state <= STATE_FETCH;
                        end
                    endcase
                end
                
                STATE_HALT: begin
                    // Stay halted
                    halt <= 1;
                    pc_enable <= 0;
                    pc_load <= 0;
                    reg_write_enable <= 0;
                    state <= STATE_HALT;
                end
                
                default: begin
                    state <= STATE_FETCH;
                end
            endcase
        end
    end

endmodule