// program_counter.v - Program Counter
// Keeps track of the current instruction address

module program_counter (
    input clk,                    // Clock signal
    input rst,                    // Reset signal (active high)
    input enable,                 // Enable counting (1 = increment, 0 = hold)
    input load,                   // Load new address (for jumps)
    input [3:0] load_addr,        // Address to load (for jump instructions)
    output reg [3:0] pc           // Current program counter value (4 bits = 16 addresses)
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset PC to 0 (start of program)
            pc <= 4'b0000;
        end else if (load) begin
            // Load new address (for jump instructions)
            pc <= load_addr;
        end else if (enable) begin
            // Increment PC to next instruction
            pc <= pc + 1;
        end
        // If neither load nor enable, PC holds its value
    end

endmodule