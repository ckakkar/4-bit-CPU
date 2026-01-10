// data_memory.v - data RAM
// Separate data memory from instruction memory (Harvard architecture)

module data_memory (
    input clk,                    // Clock signal
    input rst,                    // Reset signal (active high)
    input write_enable,           // Write enable: 1 to write, 0 to read
    input  [7:0] address,         // Memory address (8 bits = 256 locations)
    input  [7:0] write_data,      // Data to write (8 bits)
    output [7:0] read_data        // Data read from memory (8 bits, combinational)
);

    // Memory array: 256 locations, each 8 bits wide
    reg [7:0] memory [0:255];
    
    // Initialize memory to zeros
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 8'b00000000;
        end
    end
    
    // Combinational read (data available immediately)
    assign read_data = memory[address];
    
    // Sequential write (happens on clock edge)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 256; i = i + 1) begin
                memory[i] <= 8'b00000000;
            end
        end else if (write_enable) begin
            // Write operation
            memory[address] <= write_data;
        end
    end

endmodule
