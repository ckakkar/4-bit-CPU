// instruction_set_extension.v - Custom instruction set extension framework
// Allows adding custom instructions without modifying core CPU

module instruction_set_extension (
    input clk,
    input rst,
    // Instruction interface
    input [15:0] instruction,          // Current instruction
    input [3:0] opcode,                // Instruction opcode
    input [2:0] reg1, reg2,            // Register addresses
    input [5:0] immediate,             // Immediate value
    // Register interface
    input [7:0] reg_read_a,            // Register A value
    input [7:0] reg_read_b,            // Register B value
    output reg [7:0] reg_write_data,    // Data to write to register
    output reg [2:0] reg_write_addr,   // Register to write
    output reg reg_write_enable,       // Enable register write
    // Extension interface
    output reg extension_active,       // Extension is handling instruction
    output reg [7:0] extension_result, // Extension result
    output reg extension_valid,        // Extension result valid
    // Custom instruction handlers
    input [7:0] custom_handler_result, // Result from custom handler
    input custom_handler_valid          // Custom handler result valid
);

    // Extension opcode space: 0xE0-0xEF (reserved for extensions)
    localparam EXT_OPCODE_BASE = 4'hE;
    localparam EXT_OPCODE_MASK = 4'hE;
    
    // Custom instruction opcodes
    localparam EXT_POPCNT = 4'hE0;     // Population count (count set bits)
    localparam EXT_CLZ = 4'hE1;        // Count leading zeros
    localparam EXT_CTZ = 4'hE2;        // Count trailing zeros
    localparam EXT_REV = 4'hE3;        // Bit reverse
    localparam EXT_CRC = 4'hE4;        // CRC calculation
    localparam EXT_SIMD_ADD = 4'hE5;   // SIMD addition (4x2-bit)
    localparam EXT_SIMD_MUL = 4'hE6;   // SIMD multiplication
    localparam EXT_CUSTOM0 = 4'hE7;     // User-defined custom instruction 0
    localparam EXT_CUSTOM1 = 4'hE8;     // User-defined custom instruction 1
    localparam EXT_CUSTOM2 = 4'hE9;     // User-defined custom instruction 2
    
    reg [2:0] state;
    localparam STATE_IDLE = 3'b000;
    localparam STATE_EXECUTE = 3'b001;
    localparam STATE_COMPLETE = 3'b010;
    
    // Check if instruction is extension
    wire is_extension = (opcode[3:1] == 3'b111);  // Opcodes 0xE-0xF with extension bit
    
    always @(posedge clk) begin
        if (rst) begin
            extension_active <= 0;
            extension_valid <= 0;
            reg_write_enable <= 0;
            state <= STATE_IDLE;
        end else begin
            extension_valid <= 0;
            reg_write_enable <= 0;
            
            if (is_extension) begin
                extension_active <= 1;
                state <= STATE_EXECUTE;
                
                case (opcode)
                    EXT_POPCNT: begin
                        // Population count: count number of set bits
                        reg [3:0] count = 0;
                        integer j;
                        for (j = 0; j < 8; j = j + 1) begin
                            if (reg_read_a[j]) count = count + 1;
                        end
                        extension_result <= {4'b0, count};
                        reg_write_addr <= reg2;
                        reg_write_data <= {4'b0, count};
                        reg_write_enable <= 1;
                        extension_valid <= 1;
                        state <= STATE_COMPLETE;
                    end
                    
                    EXT_CLZ: begin
                        // Count leading zeros
                        reg [3:0] count = 0;
                        integer j;
                        for (j = 7; j >= 0; j = j - 1) begin
                            if (reg_read_a[j] == 0) count = count + 1;
                            else break;
                        end
                        extension_result <= {4'b0, count};
                        reg_write_addr <= reg2;
                        reg_write_data <= {4'b0, count};
                        reg_write_enable <= 1;
                        extension_valid <= 1;
                        state <= STATE_COMPLETE;
                    end
                    
                    EXT_CTZ: begin
                        // Count trailing zeros
                        reg [3:0] count = 0;
                        integer j;
                        for (j = 0; j < 8; j = j + 1) begin
                            if (reg_read_a[j] == 0) count = count + 1;
                            else break;
                        end
                        extension_result <= {4'b0, count};
                        reg_write_addr <= reg2;
                        reg_write_data <= {4'b0, count};
                        reg_write_enable <= 1;
                        extension_valid <= 1;
                        state <= STATE_COMPLETE;
                    end
                    
                    EXT_REV: begin
                        // Bit reverse
                        reg [7:0] reversed = 0;
                        integer j;
                        for (j = 0; j < 8; j = j + 1) begin
                            reversed[j] = reg_read_a[7-j];
                        end
                        extension_result <= reversed;
                        reg_write_addr <= reg2;
                        reg_write_data <= reversed;
                        reg_write_enable <= 1;
                        extension_valid <= 1;
                        state <= STATE_COMPLETE;
                    end
                    
                    EXT_SIMD_ADD: begin
                        // SIMD addition: 4x2-bit addition
                        reg [1:0] sum0, sum1, sum2, sum3;
                        sum0 = reg_read_a[1:0] + reg_read_b[1:0];
                        sum1 = reg_read_a[3:2] + reg_read_b[3:2];
                        sum2 = reg_read_a[5:4] + reg_read_b[5:4];
                        sum3 = reg_read_a[7:6] + reg_read_b[7:6];
                        extension_result <= {sum3, sum2, sum1, sum0};
                        reg_write_addr <= reg2;
                        reg_write_data <= {sum3, sum2, sum1, sum0};
                        reg_write_enable <= 1;
                        extension_valid <= 1;
                        state <= STATE_COMPLETE;
                    end
                    
                    EXT_CUSTOM0, EXT_CUSTOM1, EXT_CUSTOM2: begin
                        // User-defined custom instructions
                        // Use external custom handler
                        if (custom_handler_valid) begin
                            extension_result <= custom_handler_result;
                            reg_write_addr <= reg2;
                            reg_write_data <= custom_handler_result;
                            reg_write_enable <= 1;
                            extension_valid <= 1;
                            state <= STATE_COMPLETE;
                        end
                    end
                    
                    default: begin
                        // Unknown extension - no operation
                        extension_active <= 0;
                        state <= STATE_IDLE;
                    end
                endcase
            end else begin
                extension_active <= 0;
                state <= STATE_IDLE;
            end
        end
    end

endmodule
