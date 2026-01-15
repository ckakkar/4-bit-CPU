// error_detection.v - Error detection and correction unit
// Implements parity checking and basic error detection for memory and data paths

module error_detection (
    input clk,
    input rst,
    // Data inputs
    input [7:0] data_in,               // Data to check
    input [15:0] instruction_in,       // Instruction to check
    // Error detection
    input enable_parity,               // Enable parity checking
    input enable_ecc,                  // Enable error correction (future)
    // Parity bits
    input data_parity,                 // Parity bit for data
    input instruction_parity,          // Parity bit for instruction
    // Error outputs
    output reg data_error,             // Data parity error detected
    output reg instruction_error,      // Instruction parity error detected
    output reg [7:0] error_count,      // Total error count
    output reg error_flag,             // Any error detected
    // Corrected data (for ECC - future)
    output [7:0] data_corrected,       // Corrected data (if ECC enabled)
    output [15:0] instruction_corrected // Corrected instruction
);

    // Parity calculation (even parity)
    function parity_even;
        input [7:0] data;
        integer i;
        begin
            parity_even = 0;
            for (i = 0; i < 8; i = i + 1) begin
                parity_even = parity_even ^ data[i];
            end
        end
    endfunction
    
    function parity_even_16;
        input [15:0] data;
        integer i;
        begin
            parity_even_16 = 0;
            for (i = 0; i < 16; i = i + 1) begin
                parity_even_16 = parity_even_16 ^ data[i];
            end
        end
    endfunction
    
    // Calculate expected parity
    wire expected_data_parity = parity_even(data_in);
    wire expected_instruction_parity = parity_even_16(instruction_in);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_error <= 0;
            instruction_error <= 0;
            error_count <= 8'b0;
            error_flag <= 0;
        end else begin
            data_error <= 0;
            instruction_error <= 0;
            
            if (enable_parity) begin
                // Check data parity
                if (data_parity != expected_data_parity) begin
                    data_error <= 1;
                    error_count <= error_count + 1;
                    error_flag <= 1;
                end
                
                // Check instruction parity
                if (instruction_parity != expected_instruction_parity) begin
                    instruction_error <= 1;
                    error_count <= error_count + 1;
                    error_flag <= 1;
                end
            end
        end
    end
    
    // For now, corrected data is just the input (ECC not implemented)
    assign data_corrected = data_in;
    assign instruction_corrected = instruction_in;

endmodule
