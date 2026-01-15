// instruction_fusion.v - Instruction Fusion Unit
// Fuses multiple instructions into single accelerator operations
// Reduces instruction overhead and improves performance

module instruction_fusion (
    input clk,
    input rst,
    // Instruction stream
    input [15:0] inst1,              // First instruction
    input [15:0] inst2,              // Second instruction (next in stream)
    input inst1_valid,               // First instruction valid
    input inst2_valid,               // Second instruction valid
    // Fusion detection
    output reg fusion_detected,       // Fusion pattern detected
    output reg [1:0] fusion_type,     // Fusion type (0=none, 1=load-fuse, 2=store-fuse, 3=compute-fuse)
    output reg [15:0] fused_instruction, // Fused instruction
    output reg fused_valid,          // Fused instruction valid
    // Statistics
    output reg [31:0] fusion_count    // Total fusions performed
);

    // Fusion patterns
    // Pattern 1: LOAD + COMPUTE → Load data directly into accelerator
    // Pattern 2: COMPUTE + STORE → Store result directly from accelerator
    // Pattern 3: COMPUTE + COMPUTE → Fuse multiple operations
    
    // Instruction opcodes
    wire [3:0] op1 = inst1[15:12];
    wire [3:0] op2 = inst2[15:12];
    wire [3:0] reg1_1 = inst1[11:9];
    wire [3:0] reg2_1 = inst1[8:6];
    wire [3:0] reg1_2 = inst2[11:9];
    wire [3:0] reg2_2 = inst2[8:6];
    
    // Opcode definitions
    localparam OP_LOAD = 4'h7;
    localparam OP_STORE = 4'h6;
    localparam OP_CUSTOM = 4'hF; // Custom instruction space
    
    // Initialize
    always @(posedge rst) begin
        fusion_detected <= 0;
        fusion_type <= 2'b0;
        fused_instruction <= 16'b0;
        fused_valid <= 0;
        fusion_count <= 32'b0;
    end
    
    // Fusion detection logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Already initialized
        end else begin
            fusion_detected <= 0;
            fused_valid <= 0;
            
            if (inst1_valid && inst2_valid) begin
                // Pattern 1: LOAD + CUSTOM (load-fuse)
                if (op1 == OP_LOAD && op2 == OP_CUSTOM && reg1_1 == reg2_2) begin
                    // LOAD R1, [addr] + CUSTOM R1, ... → Fused load into accelerator
                    fusion_detected <= 1;
                    fusion_type <= 2'b01; // Load-fuse
                    fused_instruction <= {inst2[15:6], inst1[5:0]}; // Custom op with load address
                    fused_valid <= 1;
                    fusion_count <= fusion_count + 1;
                end
                // Pattern 2: CUSTOM + STORE (store-fuse)
                else if (op1 == OP_CUSTOM && op2 == OP_STORE && reg1_1 == reg1_2) begin
                    // CUSTOM R1, ... + STORE R1, [addr] → Fused store from accelerator
                    fusion_detected <= 1;
                    fusion_type <= 2'b10; // Store-fuse
                    fused_instruction <= {inst1[15:6], inst2[5:0]}; // Custom op with store address
                    fused_valid <= 1;
                    fusion_count <= fusion_count + 1;
                end
                // Pattern 3: CUSTOM + CUSTOM (compute-fuse)
                else if (op1 == OP_CUSTOM && op2 == OP_CUSTOM && 
                         inst1[11:10] == inst2[11:10]) begin
                    // Same accelerator, fuse operations
                    fusion_detected <= 1;
                    fusion_type <= 2'b11; // Compute-fuse
                    // Combine operations (simplified)
                    fused_instruction <= {inst1[15:10], inst1[9:6] | inst2[9:6], inst1[5:0]};
                    fused_valid <= 1;
                    fusion_count <= fusion_count + 1;
                end
            end
        end
    end

endmodule
