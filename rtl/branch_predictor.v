// branch_predictor.v - 2-bit saturating counter branch predictor with Branch Target Buffer (BTB)
// Uses pattern history table (PHT) with 2-bit counters and BTB for target addresses

module branch_predictor (
    input clk,
    input rst,
    input [7:0] pc,                 // Program counter (instruction address)
    input [7:0] branch_addr,        // Actual branch target (from EX stage)
    input branch_taken,              // Actual branch outcome (from EX stage)
    input is_branch_instruction,     // Current instruction is a branch
    input update_predictor,          // Update predictor with actual outcome
    output reg prediction,           // Branch prediction (1=taken, 0=not taken)
    output reg [7:0] predicted_target // Predicted branch target
);

    // Branch Target Buffer (BTB) - stores target addresses
    // Pattern History Table (PHT) - stores 2-bit saturating counters
    localparam BTB_SIZE = 16;  // 16 entries in BTB/PHT
    
    reg [7:0] btb_target [0:BTB_SIZE-1];  // Branch target addresses
    reg [1:0] pht_counter [0:BTB_SIZE-1]; // 2-bit saturating counters
    reg btb_valid [0:BTB_SIZE-1];         // Valid bit for BTB entry
    
    // 2-bit saturating counter states
    localparam STATE_STRONG_NOT_TAKEN = 2'b00;
    localparam STATE_WEAK_NOT_TAKEN   = 2'b01;
    localparam STATE_WEAK_TAKEN       = 2'b10;
    localparam STATE_STRONG_TAKEN     = 2'b11;
    
    // Hash function: use lower bits of PC as index
    wire [3:0] btb_index = pc[3:0];  // 4 bits = 16 entries
    
    integer i;
    
    // Initialize predictor on reset
    always @(posedge rst) begin
        for (i = 0; i < BTB_SIZE; i = i + 1) begin
            btb_target[i] <= 8'b0;
            pht_counter[i] <= STATE_WEAK_NOT_TAKEN;  // Initial: slightly biased to not taken
            btb_valid[i] <= 0;
        end
    end
    
    // Prediction logic - combinational
    always @(*) begin
        if (is_branch_instruction && btb_valid[btb_index]) begin
            // Predict based on 2-bit counter
            // States 2'b11 and 2'b10 predict taken
            // States 2'b01 and 2'b00 predict not taken
            prediction = pht_counter[btb_index][1];  // MSB determines prediction
            predicted_target = btb_target[btb_index];
        end else begin
            // No prediction or invalid BTB entry - default to not taken
            prediction = 1'b0;
            predicted_target = pc + 1;  // Sequential next instruction
        end
    end
    
    // Update predictor on branch resolution
    always @(posedge clk) begin
        if (rst) begin
            // Already initialized in reset block
        end else if (update_predictor && is_branch_instruction) begin
            // Update BTB
            btb_target[btb_index] <= branch_addr;
            btb_valid[btb_index] <= 1;
            
            // Update 2-bit saturating counter
            case (pht_counter[btb_index])
                STATE_STRONG_NOT_TAKEN: begin
                    // 00 -> 01 if taken, stay 00 if not taken
                    pht_counter[btb_index] <= branch_taken ? STATE_WEAK_NOT_TAKEN : STATE_STRONG_NOT_TAKEN;
                end
                STATE_WEAK_NOT_TAKEN: begin
                    // 01 -> 10 if taken, 00 if not taken
                    pht_counter[btb_index] <= branch_taken ? STATE_WEAK_TAKEN : STATE_STRONG_NOT_TAKEN;
                end
                STATE_WEAK_TAKEN: begin
                    // 10 -> 11 if taken, 01 if not taken
                    pht_counter[btb_index] <= branch_taken ? STATE_STRONG_TAKEN : STATE_WEAK_NOT_TAKEN;
                end
                STATE_STRONG_TAKEN: begin
                    // 11 -> stay 11 if taken, 10 if not taken
                    pht_counter[btb_index] <= branch_taken ? STATE_STRONG_TAKEN : STATE_WEAK_TAKEN;
                end
            endcase
        end
    end

endmodule
