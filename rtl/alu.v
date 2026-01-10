// alu.v - arithmetic / logic unit
// Enhanced 8-bit ALU with status flags

module alu (
    input  [7:0] operand_a,      // First operand (8 bits)
    input  [7:0] operand_b,      // Second operand (8 bits)
    input  [3:0] alu_op,         // Operation select (4 bits for more ops)
    output reg [7:0] result,     // Result (8 bits)
    output reg zero_flag,        // Flag: 1 if result is zero
    output reg carry_flag,       // Flag: 1 if carry/borrow occurred
    output reg overflow_flag,    // Flag: 1 if signed overflow occurred
    output reg negative_flag     // Flag: 1 if result is negative (MSB = 1)
);

    // ALU Operations (expanded to 4 bits for more operations)
    localparam ALU_ADD  = 4'b0000;  // Addition
    localparam ALU_SUB  = 4'b0001;  // Subtraction
    localparam ALU_AND  = 4'b0010;  // Bitwise AND
    localparam ALU_OR   = 4'b0011;  // Bitwise OR
    localparam ALU_XOR  = 4'b0100;  // Bitwise XOR
    localparam ALU_NOT  = 4'b0101;  // Bitwise NOT (operand_a)
    localparam ALU_SHL  = 4'b0110;  // Shift left
    localparam ALU_SHR  = 4'b0111;  // Shift right (logical)
    localparam ALU_SAR  = 4'b1000;  // Shift right (arithmetic, sign-extend)
    localparam ALU_LT   = 4'b1001;  // Less than (signed comparison)
    localparam ALU_LTU  = 4'b1010;  // Less than unsigned
    localparam ALU_EQ   = 4'b1011;  // Equality comparison
    localparam ALU_PASS = 4'b1100;  // Pass operand_a through
    localparam ALU_PASS_B = 4'b1101;  // Pass operand_b through (for immediate load)

    // Internal wires for arithmetic operations
    wire [8:0] add_result;  // 9-bit for carry detection
    wire [8:0] sub_result;
    
    assign add_result = {1'b0, operand_a} + {1'b0, operand_b};
    assign sub_result = {1'b0, operand_a} - {1'b0, operand_b};

    always @(*) begin
        // Default flags
        carry_flag = 1'b0;
        overflow_flag = 1'b0;
        
        case (alu_op)
            ALU_ADD: begin
                result = add_result[7:0];
                carry_flag = add_result[8];
                // Signed overflow: both operands same sign, result different sign
                overflow_flag = (~operand_a[7] & ~operand_b[7] & result[7]) |
                                (operand_a[7] & operand_b[7] & ~result[7]);
            end
            ALU_SUB: begin
                result = sub_result[7:0];
                carry_flag = sub_result[8];  // Actually borrow flag (inverted)
                // Signed overflow: different sign operands, result sign != operand_a sign
                overflow_flag = (~operand_a[7] & operand_b[7] & result[7]) |
                                (operand_a[7] & ~operand_b[7] & ~result[7]);
            end
            ALU_AND:  result = operand_a & operand_b;
            ALU_OR:   result = operand_a | operand_b;
            ALU_XOR:  result = operand_a ^ operand_b;
            ALU_NOT:  result = ~operand_a;
            ALU_SHL:  begin
                result = operand_a << operand_b[2:0];  // Shift by lower 3 bits
                carry_flag = (operand_b[2:0] > 0) ? operand_a[8 - operand_b[2:0]] : 1'b0;
            end
            ALU_SHR:  begin
                result = operand_a >> operand_b[2:0];
                carry_flag = (operand_b[2:0] > 0) ? operand_a[operand_b[2:0] - 1] : 1'b0;
            end
            ALU_SAR:  begin
                result = $signed(operand_a) >>> operand_b[2:0];
                carry_flag = (operand_b[2:0] > 0) ? operand_a[operand_b[2:0] - 1] : 1'b0;
            end
            ALU_LT:   result = ($signed(operand_a) < $signed(operand_b)) ? 8'd1 : 8'd0;
            ALU_LTU:  result = (operand_a < operand_b) ? 8'd1 : 8'd0;
            ALU_EQ:   result = (operand_a == operand_b) ? 8'd1 : 8'd0;
            ALU_PASS: result = operand_a;
            ALU_PASS_B: result = operand_b;  // Pass operand_b (for immediate values)
            default:  result = 8'b00000000;
        endcase
        
        // Status flags
        zero_flag = (result == 8'b00000000);
        negative_flag = result[7];
    end

endmodule