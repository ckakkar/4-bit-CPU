// stack_unit.v - Stack operations unit
// Implements PUSH and POP instructions with stack pointer management

module stack_unit (
    input clk,
    input rst,
    input push_enable,           // Push operation enable
    input pop_enable,            // Pop operation enable
    input [7:0] push_data,       // Data to push
    input [7:0] stack_base,      // Stack base address (top of stack memory)
    output reg [7:0] stack_pointer, // Current stack pointer
    output reg [7:0] pop_data,   // Data popped from stack
    output stack_empty,          // Stack is empty flag
    output stack_full,           // Stack is full flag
    output stack_valid           // Pop data is valid
);

    // Stack parameters
    localparam STACK_SIZE = 64;  // 64 bytes stack (can grow down from base)
    localparam STACK_LIMIT = 8;  // Minimum stack pointer (safety limit)
    
    reg [7:0] stack_memory [0:STACK_SIZE-1];
    reg valid_reg;
    
    integer i;
    
    // Initialize stack on reset
    always @(posedge rst) begin
        stack_pointer <= stack_base;  // Start at base (top of stack)
        pop_data <= 8'b0;
        valid_reg <= 0;
        for (i = 0; i < STACK_SIZE; i = i + 1) begin
            stack_memory[i] <= 8'b0;
        end
    end
    
    // Stack operations
    always @(posedge clk) begin
        if (rst) begin
            stack_pointer <= stack_base;
            pop_data <= 8'b0;
            valid_reg <= 0;
        end else begin
            valid_reg <= 0;
            
            if (push_enable && !stack_full) begin
                // PUSH: Decrement stack pointer, then store data
                if (stack_pointer > STACK_LIMIT) begin
                    stack_pointer <= stack_pointer - 1;
                    stack_memory[stack_pointer - 1] <= push_data;
                end
            end else if (pop_enable && !stack_empty) begin
                // POP: Read data, then increment stack pointer
                pop_data <= stack_memory[stack_pointer];
                valid_reg <= 1;
                if (stack_pointer < stack_base) begin
                    stack_pointer <= stack_pointer + 1;
                end
            end
        end
    end
    
    // Stack status flags
    assign stack_empty = (stack_pointer >= stack_base);
    assign stack_full = (stack_pointer <= STACK_LIMIT);
    assign stack_valid = valid_reg;

endmodule
