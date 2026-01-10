// multiplier_divider.v - Hardware multiplier and divider unit
// Implements 8-bit multiplication and division with 16-bit result/remainder

module multiplier_divider (
    input clk,
    input rst,
    input [7:0] operand_a,       // First operand (multiplicand/dividend)
    input [7:0] operand_b,       // Second operand (multiplier/divisor)
    input multiply,              // 1 = multiply, 0 = divide
    input start,                 // Start operation
    output reg [15:0] result,     // Product (multiply) or quotient (divide) - 16-bit
    output reg [7:0] remainder,   // Remainder (divide only)
    output reg result_valid,      // Result is valid
    output reg divide_by_zero,    // Divide by zero error
    output reg overflow           // Overflow (multiply only - if result > 255)
);

    // Internal state
    reg [2:0] state;
    localparam STATE_IDLE = 3'b000;
    localparam STATE_COMPUTE = 3'b001;
    localparam STATE_DONE = 3'b010;
    
    // Multiplication: iterative shift-and-add algorithm
    // Division: iterative subtract-and-shift algorithm
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= 16'b0;
            remainder <= 8'b0;
            result_valid <= 0;
            divide_by_zero <= 0;
            overflow <= 0;
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    result_valid <= 0;
                    divide_by_zero <= 0;
                    overflow <= 0;
                    
                    if (start) begin
                        state <= STATE_COMPUTE;
                        
                        if (multiply) begin
                            // Multiplication: A × B
                            // Simple: use built-in multiplication (synthesizable)
                            reg [15:0] product;
                            product = operand_a * operand_b;
                            
                            if (product > 16'h00FF) begin
                                // Overflow: result > 255
                                overflow <= 1;
                                result <= 16'h00FF;  // Saturated result
                            end else begin
                                result <= product;
                            end
                            
                            state <= STATE_DONE;
                        end else begin
                            // Division: A / B
                            if (operand_b == 8'b0) begin
                                // Divide by zero
                                divide_by_zero <= 1;
                                result <= 16'hFFFF;  // Error value
                                remainder <= 8'hFF;
                                state <= STATE_DONE;
                            end else begin
                                // Division: quotient = A / B, remainder = A % B
                                // Simple: use built-in division (synthesizable)
                                reg [7:0] quot, rem;
                                quot = operand_a / operand_b;
                                rem = operand_a % operand_b;
                                
                                result <= {8'b0, quot};
                                remainder <= rem;
                                
                                state <= STATE_DONE;
                            end
                        end
                    end
                end
                
                STATE_DONE: begin
                    result_valid <= 1;
                    state <= STATE_IDLE;
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
