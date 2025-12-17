// register_file.v - 4x4 register file
// Four 4-bit registers (R0–R3) with two read ports and one write port

module register_file (
    input clk,                    // Clock signal
    input rst,                    // Reset signal (active high)
    input write_enable,           // Write enable: 1 to write, 0 to read only
    input  [1:0] read_addr_a,     // Address of first register to read (2 bits = 4 registers)
    input  [1:0] read_addr_b,     // Address of second register to read
    input  [1:0] write_addr,      // Address of register to write to
    input  [3:0] write_data,      // Data to write (4 bits)
    output [3:0] read_data_a,     // Data read from first register
    output [3:0] read_data_b      // Data read from second register
);

    // 4 registers, each 4 bits wide
    reg [3:0] registers [0:3];
    
    // Read operations (combinational - happens immediately)
    assign read_data_a = registers[read_addr_a];
    assign read_data_b = registers[read_addr_b];
    
    // Write operation (sequential - happens on clock edge)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers to 0
            registers[0] <= 4'b0000;
            registers[1] <= 4'b0000;
            registers[2] <= 4'b0000;
            registers[3] <= 4'b0000;
        end else if (write_enable) begin
            // Write data to specified register
            registers[write_addr] <= write_data;
        end
    end

endmodule