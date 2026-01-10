// register_file.v - 8x8 register file
// Eight 8-bit registers (R0–R7) with two read ports and one write port

module register_file (
    input clk,                    // Clock signal
    input rst,                    // Reset signal (active high)
    input write_enable,           // Write enable: 1 to write, 0 to read only
    input  [2:0] read_addr_a,     // Address of first register to read (3 bits = 8 registers)
    input  [2:0] read_addr_b,     // Address of second register to read
    input  [2:0] write_addr,      // Address of register to write to
    input  [7:0] write_data,      // Data to write (8 bits)
    output [7:0] read_data_a,     // Data read from first register
    output [7:0] read_data_b      // Data read from second register
);

    // 8 registers, each 8 bits wide
    reg [7:0] registers [0:7];
    
    // Read operations (combinational - happens immediately)
    assign read_data_a = registers[read_addr_a];
    assign read_data_b = registers[read_addr_b];
    
    // Write operation (sequential - happens on clock edge)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers to 0
            registers[0] <= 8'b00000000;
            registers[1] <= 8'b00000000;
            registers[2] <= 8'b00000000;
            registers[3] <= 8'b00000000;
            registers[4] <= 8'b00000000;
            registers[5] <= 8'b00000000;
            registers[6] <= 8'b00000000;
            registers[7] <= 8'b00000000;
        end else if (write_enable && write_addr != 3'b000) begin
            // Write data to specified register (R0 is typically read-only or special)
            // For simplicity, we allow writing to R0 but it's conventional to protect it
            registers[write_addr] <= write_data;
        end
    end

endmodule