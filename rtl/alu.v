// alu.v - Arithmetic Logic Unit
// Performs arithmetic and logical operations

module alu (
    input  [3:0] operand_a,      // First operand (4 bits)
    input  [3:0] operand_b,      // Second operand (4 bits)
    input  [2:0] alu_op,         // Operation select (3 bits)
    output reg [3:0] result,     // Result (4 bits)
    output reg zero_flag         // Flag: 1 if result is zero
);

    // ALU Operations
    localparam ALU_ADD  = 3'b000;  // Addition
    localparam ALU_SUB  = 3'b001;  // Subtraction
    localparam ALU_AND  = 3'b010;  // Bitwise AND
    localparam ALU_OR   = 3'b011;  // Bitwise OR
    localparam ALU_XOR  = 3'b100;  // Bitwise XOR
    localparam ALU_PASS = 3'b101;  // Pass operand_a through

    always @(*) begin
        case (alu_op)
            ALU_ADD:  result = operand_a + operand_b;
            ALU_SUB:  result = operand_a - operand_b;
            ALU_AND:  result = operand_a & operand_b;
            ALU_OR:   result = operand_a | operand_b;
            ALU_XOR:  result = operand_a ^ operand_b;
            ALU_PASS: result = operand_a;
            default:  result = 4'b0000;
        endcase
        
        // Set zero flag if result is zero
        zero_flag = (result == 4'b0000);
    end

endmodule