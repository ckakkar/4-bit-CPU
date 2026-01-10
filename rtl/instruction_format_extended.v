// instruction_format_extended.v - Extended instruction format support
// Supports both 16-bit standard format and 32-bit extended format for 16-bit immediates

module instruction_format_extended (
    input [15:0] instruction_16,  // Standard 16-bit instruction
    input [31:0] instruction_32,  // Extended 32-bit instruction (if supported)
    input use_extended,           // Use extended format (32-bit)
    output [3:0] opcode,          // Instruction opcode
    output [2:0] reg1,            // Register 1 address
    output [2:0] reg2,            // Register 2 address
    output [5:0] immediate_6,     // 6-bit immediate (from 16-bit format)
    output [15:0] immediate_16,   // 16-bit immediate (from extended format)
    output [7:0] immediate_8      // 8-bit immediate (zero-extended from 6-bit)
);

    // Standard 16-bit format: {opcode[3:0], reg1[2:0], reg2[2:0], immediate[5:0]}
    // Extended 32-bit format: {opcode[3:0], reg1[2:0], reg2[2:0], immediate[23:0]}
    // For simplicity, use format: {opcode[3:0], reg1[2:0], reg2[2:0], imm_low[5:0], imm_high[10:0]}
    
    wire [3:0] opcode_16 = instruction_16[15:12];
    wire [3:0] opcode_32 = instruction_32[31:28];
    
    assign opcode = use_extended ? opcode_32 : opcode_16;
    assign reg1 = use_extended ? instruction_32[27:25] : instruction_16[11:9];
    assign reg2 = use_extended ? instruction_32[24:22] : instruction_16[8:6];
    
    // Immediate extraction
    assign immediate_6 = instruction_16[5:0];
    assign immediate_16 = use_extended ? instruction_32[15:0] : {10'b0, instruction_16[5:0]};
    assign immediate_8 = use_extended ? instruction_32[7:0] : {2'b00, instruction_16[5:0]};

endmodule
