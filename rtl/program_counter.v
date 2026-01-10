// program_counter.v - program counter
// Tracks which instruction the core is currently fetching (expanded to 8-bit)

module program_counter (
    input clk,                    // Clock signal
    input rst,                    // Reset signal (active high)
    input enable,                 // Enable counting (1 = increment, 0 = hold)
    input load,                   // Load new address (for jumps)
    input [7:0] load_addr,        // Address to load (for jump instructions, 8 bits = 256 addresses)
    output reg [7:0] pc           // Current program counter value (8 bits = 256 addresses)
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset PC to 0 (start of program)
            pc <= 8'b00000000;
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