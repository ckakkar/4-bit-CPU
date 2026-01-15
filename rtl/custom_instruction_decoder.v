// custom_instruction_decoder.v - Custom Instruction Set Extension Decoder
// RISC-V style custom opcodes for domain-specific instructions
// Supports crypto, DSP, and AI accelerators

module custom_instruction_decoder (
    input clk,
    input rst,
    // Instruction input
    input [15:0] instruction,         // 16-bit instruction
    // Decoded outputs
    output reg [3:0] custom_opcode,   // Custom operation code
    output reg [1:0] accelerator_sel, // Accelerator select (0=crypto, 1=DSP, 2=AI)
    output reg [2:0] reg_rs1,        // Source register 1
    output reg [2:0] reg_rs2,        // Source register 2
    output reg [2:0] reg_rd,         // Destination register
    output reg [7:0] immediate,      // Immediate value
    output reg custom_inst_valid,     // Custom instruction valid
    output reg [7:0] accelerator_op, // Accelerator-specific operation
    // Instruction fusion
    output reg fusion_enable,         // Enable instruction fusion
    output reg [1:0] fusion_type,     // Fusion type (0=none, 1=load-fuse, 2=store-fuse)
    // Statistics
    output reg [31:0] custom_inst_count // Total custom instructions executed
);

    // Custom opcode space (RISC-V style)
    // Base instruction format: [15:12] = 4'b1111 (custom opcode space)
    // [11:10] = accelerator select (00=crypto, 01=DSP, 10=AI, 11=reserved)
    // [9:6] = custom operation
    // [5:3] = rd
    // [2:0] = rs1 (or immediate[2:0])
    
    // Custom opcode detection
    wire is_custom = (instruction[15:12] == 4'b1111);
    
    // Accelerator operations
    // Crypto: 0=AES_ENC, 1=AES_DEC, 2=SHA256, 3=SHA512, 4=HMAC
    // DSP: 0=FFT, 1=IFFT, 2=FIR_FILTER, 3=IIR_FILTER, 4=CORRELATE
    // AI: 0=MATMUL, 1=CONV2D, 2=RELU, 3=SOFTMAX, 4=POOL
    
    // Initialize
    always @(posedge rst) begin
        custom_opcode <= 4'b0;
        accelerator_sel <= 2'b0;
        reg_rs1 <= 3'b0;
        reg_rs2 <= 3'b0;
        reg_rd <= 3'b0;
        immediate <= 8'b0;
        custom_inst_valid <= 0;
        accelerator_op <= 8'b0;
        fusion_enable <= 0;
        fusion_type <= 2'b0;
        custom_inst_count <= 32'b0;
    end
    
    // Decode custom instructions
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Already initialized
        end else begin
            custom_inst_valid <= 0;
            fusion_enable <= 0;
            
            if (is_custom) begin
                // Extract fields
                accelerator_sel <= instruction[11:10];
                custom_opcode <= instruction[9:6];
                reg_rd <= instruction[5:3];
                reg_rs1 <= instruction[2:0];
                reg_rs2 <= 3'b0; // Not used in custom format
                immediate <= {5'b0, instruction[2:0]};
                
                // Map to accelerator operations
                case (instruction[11:10])
                    2'b00: begin // Crypto
                        accelerator_op <= {4'b0, instruction[9:6]};
                        custom_inst_valid <= 1;
                        custom_inst_count <= custom_inst_count + 1;
                    end
                    2'b01: begin // DSP
                        accelerator_op <= {4'b0, instruction[9:6]};
                        custom_inst_valid <= 1;
                        custom_inst_count <= custom_inst_count + 1;
                    end
                    2'b10: begin // AI
                        accelerator_op <= {4'b0, instruction[9:6]};
                        custom_inst_valid <= 1;
                        custom_inst_count <= custom_inst_count + 1;
                    end
                    default: begin
                        custom_inst_valid <= 0;
                    end
                endcase
                
                // Instruction fusion detection
                // Fuse load + compute operations
                if (instruction[9:6] == 4'b0000) begin
                    fusion_enable <= 1;
                    fusion_type <= 2'b01; // Load-fuse
                end else if (instruction[9:6] == 4'b0001) begin
                    fusion_enable <= 1;
                    fusion_type <= 2'b10; // Store-fuse
                end
            end
        end
    end

endmodule
