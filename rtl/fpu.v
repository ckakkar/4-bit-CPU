// fpu.v - IEEE 754 Floating-Point Unit
// Supports single-precision (32-bit) floating-point operations
// Operations: ADD, SUB, MUL, DIV, CMP, CONV

module fpu (
    input clk,
    input rst,
    input [31:0] operand_a,       // First operand (32-bit IEEE 754)
    input [31:0] operand_b,       // Second operand (32-bit IEEE 754)
    input [2:0] fpu_op,           // FPU operation (3 bits for 8 ops)
    input start,                  // Start operation
    output reg [31:0] result,     // FPU result (32-bit IEEE 754)
    output reg result_valid,      // Result is valid
    output reg fpu_busy,          // FPU is busy (multi-cycle operation)
    output reg invalid_op,        // Invalid operation flag
    output reg divide_by_zero     // Divide by zero flag
);

    // FPU operations
    localparam FPU_ADD = 3'b000;
    localparam FPU_SUB = 3'b001;
    localparam FPU_MUL = 3'b010;
    localparam FPU_DIV = 3'b011;
    localparam FPU_CMP = 3'b100;  // Compare (returns 1 if a > b, 0 otherwise)
    localparam FPU_INT_TO_FLOAT = 3'b101;
    localparam FPU_FLOAT_TO_INT = 3'b110;
    localparam FPU_NEG = 3'b111;   // Negate: result = -operand_a
    
    // IEEE 754 single-precision format:
    // Bit [31]: Sign bit
    // Bits [30:23]: Exponent (8 bits, biased by 127)
    // Bits [22:0]: Mantissa (23 bits, implicit leading 1)
    
    // Extract fields from IEEE 754 format
    wire sign_a = operand_a[31];
    wire sign_b = operand_b[31];
    wire [7:0] exp_a = operand_a[30:23];
    wire [7:0] exp_b = operand_b[30:23];
    wire [22:0] mant_a = operand_a[22:0];
    wire [22:0] mant_b = operand_b[22:0];
    
    // Internal state
    reg [2:0] state;
    localparam STATE_IDLE = 3'b000;
    localparam STATE_NORMALIZE = 3'b001;
    localparam STATE_COMPUTE = 3'b010;
    localparam STATE_ROUND = 3'b011;
    localparam STATE_DONE = 3'b100;
    
    // Internal computation registers
    reg [31:0] result_temp;
    reg sign_result;
    reg [7:0] exp_result;
    reg [23:0] mant_result;  // 24 bits: 1 implicit + 23 explicit
    
    // Simplified FPU implementation
    // Note: This is a simplified version. Full IEEE 754 compliance requires:
    // - Proper handling of special values (NaN, Inf, zero)
    // - Rounding modes (round to nearest even, etc.)
    // - Denormalized numbers
    // - Proper exception handling
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= 32'b0;
            result_valid <= 0;
            fpu_busy <= 0;
            invalid_op <= 0;
            divide_by_zero <= 0;
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    result_valid <= 0;
                    invalid_op <= 0;
                    divide_by_zero <= 0;
                    
                    if (start) begin
                        fpu_busy <= 1;
                        state <= STATE_COMPUTE;
                        
                        case (fpu_op)
                            FPU_ADD: begin
                                // Addition: align exponents, add mantissas
                                // Simplified: assume same exponent for now
                                if (exp_a == exp_b) begin
                                    sign_result <= sign_a;  // Simplified
                                    exp_result <= exp_a;
                                    mant_result <= {1'b1, mant_a} + {1'b1, mant_b};
                                    // Normalization would go here
                                end else begin
                                    // Exponent alignment needed (simplified)
                                    if (exp_a > exp_b) begin
                                        sign_result <= sign_a;
                                        exp_result <= exp_a;
                                        mant_result <= {1'b1, mant_a} + ({1'b1, mant_b} >> (exp_a - exp_b));
                                    end else begin
                                        sign_result <= sign_b;
                                        exp_result <= exp_b;
                                        mant_result <= {1'b1, mant_b} + ({1'b1, mant_a} >> (exp_b - exp_a));
                                    end
                                end
                                // Check for overflow in mantissa
                                if (mant_result[24]) begin
                                    exp_result <= exp_result + 1;
                                    mant_result <= mant_result >> 1;
                                end
                                state <= STATE_DONE;
                            end
                            
                            FPU_SUB: begin
                                // Subtraction: similar to addition but subtract mantissas
                                // Simplified implementation
                                if (exp_a == exp_b) begin
                                    sign_result <= sign_a;
                                    exp_result <= exp_a;
                                    if ({1'b1, mant_a} > {1'b1, mant_b}) begin
                                        mant_result <= {1'b1, mant_a} - {1'b1, mant_b};
                                    end else begin
                                        mant_result <= {1'b1, mant_b} - {1'b1, mant_a};
                                        sign_result <= ~sign_a;
                                    end
                                end else begin
                                    // Handle different exponents (simplified)
                                    sign_result <= sign_a;
                                    exp_result <= (exp_a > exp_b) ? exp_a : exp_b;
                                    mant_result <= (exp_a > exp_b) ? 
                                                  ({1'b1, mant_a} - ({1'b1, mant_b} >> (exp_a - exp_b))) :
                                                  ({1'b1, mant_b} - ({1'b1, mant_a} >> (exp_b - exp_a)));
                                end
                                state <= STATE_DONE;
                            end
                            
                            FPU_MUL: begin
                                // Multiplication: add exponents, multiply mantissas
                                sign_result <= sign_a ^ sign_b;
                                exp_result <= exp_a + exp_b - 8'd127;  // Remove bias from one
                                
                                // Multiply mantissas (24 bits × 24 bits = 48 bits)
                                // Simplified: use 32-bit multiplication
                                reg [31:0] mant_product;
                                mant_product = ({1'b1, mant_a} * {1'b1, mant_b});
                                
                                // Normalize result
                                if (mant_product[31]) begin
                                    exp_result <= exp_result + 1;
                                    mant_result <= mant_product[30:7];  // Take upper bits
                                end else begin
                                    mant_result <= mant_product[29:6];
                                end
                                
                                state <= STATE_DONE;
                            end
                            
                            FPU_DIV: begin
                                // Division: subtract exponents, divide mantissas
                                if (mant_b == 23'b0 && exp_b == 8'b0) begin
                                    // Divide by zero
                                    divide_by_zero <= 1;
                                    result <= 32'h7F800000;  // Positive infinity
                                    state <= STATE_DONE;
                                end else begin
                                    sign_result <= sign_a ^ sign_b;
                                    exp_result <= exp_a - exp_b + 8'd127;  // Add bias back
                                    
                                    // Divide mantissas (simplified: use integer division)
                                    // Full implementation would use iterative division
                                    reg [47:0] dividend, divisor, quotient;
                                    dividend = {1'b1, mant_a, 23'b0};  // 48-bit
                                    divisor = {1'b1, mant_b};
                                    
                                    // Simplified division (would need iterative algorithm)
                                    quotient = dividend / divisor;  // Synthesis tool will implement
                                    mant_result <= quotient[29:6];  // Extract mantissa
                                    
                                    state <= STATE_DONE;
                                end
                            end
                            
                            FPU_CMP: begin
                                // Compare: returns 1.0 if a > b, 0.0 otherwise
                                if (sign_a < sign_b) begin
                                    // a is positive, b is negative
                                    result <= 32'h3F800000;  // 1.0
                                end else if (sign_a > sign_b) begin
                                    // a is negative, b is positive
                                    result <= 32'h0;  // 0.0
                                end else if (exp_a > exp_b) begin
                                    // Same sign, compare exponents
                                    result <= (sign_a == 0) ? 32'h3F800000 : 32'h0;
                                end else if (exp_a < exp_b) begin
                                    result <= (sign_a == 0) ? 32'h0 : 32'h3F800000;
                                end else if (mant_a > mant_b) begin
                                    // Same exponent, compare mantissas
                                    result <= (sign_a == 0) ? 32'h3F800000 : 32'h0;
                                end else begin
                                    result <= (sign_a == 0) ? 32'h0 : 32'h3F800000;
                                end
                                state <= STATE_DONE;
                            end
                            
                            FPU_NEG: begin
                                // Negate: flip sign bit
                                result <= {~operand_a[31], operand_a[30:0]};
                                state <= STATE_DONE;
                            end
                            
                            FPU_INT_TO_FLOAT: begin
                                // Convert 8-bit integer to float (simplified)
                                // IEEE 754 representation of integer value
                                if (operand_a[7:0] == 8'b0) begin
                                    result <= 32'b0;  // Zero
                                end else begin
                                    // Find leading one, set exponent, shift mantissa
                                    integer leading_one;
                                    reg [7:0] int_val;
                                    int_val = operand_a[7:0];
                                    
                                    // Simplified: assume value fits in normalized range
                                    leading_one = 6;  // Simplified
                                    exp_result <= 8'd127 + leading_one;  // Bias + position
                                    mant_result <= {int_val, 16'b0} >> (23 - leading_one);
                                    sign_result <= 0;  // Assume positive
                                end
                                state <= STATE_DONE;
                            end
                            
                            FPU_FLOAT_TO_INT: begin
                                // Convert float to 8-bit integer (simplified)
                                // Extract integer part from mantissa based on exponent
                                if (exp_a < 8'd127) begin
                                    // Less than 1.0
                                    result <= 32'b0;
                                end else begin
                                    reg [7:0] shift_amt;
                                    shift_amt = exp_a - 8'd127;
                                    if (shift_amt > 7) begin
                                        result <= 32'hFF;  // Overflow
                                    end else begin
                                        result <= ({1'b1, mant_a} >> (23 - shift_amt)) & 8'hFF;
                                    end
                                end
                                state <= STATE_DONE;
                            end
                            
                            default: begin
                                invalid_op <= 1;
                                result <= 32'h7FC00000;  // NaN
                                state <= STATE_DONE;
                            end
                        endcase
                    end else begin
                        fpu_busy <= 0;
                    end
                end
                
                STATE_DONE: begin
                    // Assemble result (except for special cases already handled)
                    if (fpu_op != FPU_CMP && fpu_op != FPU_NEG && 
                        fpu_op != FPU_INT_TO_FLOAT && fpu_op != FPU_FLOAT_TO_INT) begin
                        result <= {sign_result, exp_result, mant_result[22:0]};
                    end
                    
                    result_valid <= 1;
                    fpu_busy <= 0;
                    state <= STATE_IDLE;
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
