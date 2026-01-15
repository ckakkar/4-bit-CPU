// advanced_branch_predictor.v - Advanced branch predictor with BTB and pattern history
// Implements 2-bit saturating counter with Branch Target Buffer and global/local history

module advanced_branch_predictor (
    input clk,
    input rst,
    input [7:0] pc,                    // Program counter
    input [7:0] branch_addr,           // Actual branch target
    input branch_taken,                 // Actual branch outcome
    input is_branch_instruction,        // Current instruction is a branch
    input update_predictor,             // Update predictor with actual outcome
    // Prediction outputs
    output reg prediction,              // Branch prediction (1=taken, 0=not taken)
    output reg [7:0] predicted_target,  // Predicted branch target
    output reg prediction_valid,        // Prediction is valid
    // Advanced features
    output reg [7:0] prediction_confidence, // Prediction confidence (0-255)
    output reg use_global_history,      // Using global history
    output reg use_local_history        // Using local history
);

    // Branch Target Buffer (BTB) - stores target addresses
    localparam BTB_SIZE = 32;  // 32 entries
    
    // Pattern History Table (PHT) - stores 2-bit saturating counters
    localparam PHT_SIZE = 64;  // 64 entries for better coverage
    
    // Global History Register (GHR) - tracks recent branch outcomes
    localparam GHR_SIZE = 8;   // 8-bit global history
    
    // BTB entries
    reg [7:0] btb_target [0:BTB_SIZE-1];
    reg [4:0] btb_tag [0:BTB_SIZE-1];  // Tag: upper 5 bits of PC
    reg btb_valid [0:BTB_SIZE-1];
    
    // PHT entries (2-bit saturating counters)
    reg [1:0] pht_counter [0:PHT_SIZE-1];
    
    // Global History Register
    reg [GHR_SIZE-1:0] global_history;
    
    // Local History Table (LHT) - per-branch history
    reg [GHR_SIZE-1:0] local_history [0:BTB_SIZE-1];
    
    // 2-bit saturating counter states
    localparam STATE_STRONG_NOT_TAKEN = 2'b00;
    localparam STATE_WEAK_NOT_TAKEN   = 2'b01;
    localparam STATE_WEAK_TAKEN       = 2'b10;
    localparam STATE_STRONG_TAKEN     = 2'b11;
    
    // Hash functions
    wire [4:0] btb_index = pc[4:0];  // 5 bits = 32 entries
    wire [4:0] btb_tag_val = pc[7:3];  // Upper 5 bits as tag
    
    // PHT index: combine PC and global history
    wire [5:0] pht_index = (pc[5:0] ^ global_history[5:0]) & 6'b111111;
    
    integer i;
    
    // Initialize predictor on reset
    always @(posedge rst) begin
        for (i = 0; i < BTB_SIZE; i = i + 1) begin
            btb_target[i] <= 8'b0;
            btb_tag[i] <= 5'b0;
            btb_valid[i] <= 0;
            local_history[i] <= {GHR_SIZE{1'b0}};
        end
        for (i = 0; i < PHT_SIZE; i = i + 1) begin
            pht_counter[i] <= STATE_WEAK_NOT_TAKEN;  // Slightly biased to not taken
        end
        global_history <= {GHR_SIZE{1'b0}};
        prediction_valid <= 0;
        use_global_history <= 1;
        use_local_history <= 0;
    end
    
    // Prediction logic - combinational
    always @(*) begin
        if (is_branch_instruction && btb_valid[btb_index] && btb_tag[btb_index] == btb_tag_val) begin
            // BTB hit - use PHT for direction prediction
            prediction = pht_counter[pht_index][1];  // MSB determines prediction
            predicted_target = btb_target[btb_index];
            prediction_valid = 1;
            
            // Confidence based on counter state
            if (pht_counter[pht_index] == STATE_STRONG_TAKEN || 
                pht_counter[pht_index] == STATE_STRONG_NOT_TAKEN) begin
                prediction_confidence = 8'd255;  // High confidence
            end else begin
                prediction_confidence = 8'd128;  // Low confidence
            end
        end else begin
            // No prediction or invalid BTB entry - default to not taken
            prediction = 1'b0;
            predicted_target = pc + 1;  // Sequential next instruction
            prediction_valid = 0;
            prediction_confidence = 8'b0;
        end
    end
    
    // Update predictor on branch resolution
    always @(posedge clk) begin
        if (rst) begin
            // Already initialized
        end else if (update_predictor && is_branch_instruction) begin
            // Update BTB
            btb_target[btb_index] <= branch_addr;
            btb_tag[btb_index] <= btb_tag_val;
            btb_valid[btb_index] <= 1;
            
            // Update local history for this branch
            local_history[btb_index] <= {local_history[btb_index][GHR_SIZE-2:0], branch_taken};
            
            // Update global history
            global_history <= {global_history[GHR_SIZE-2:0], branch_taken};
            
            // Update 2-bit saturating counter in PHT
            case (pht_counter[pht_index])
                STATE_STRONG_NOT_TAKEN: begin
                    pht_counter[pht_index] <= branch_taken ? STATE_WEAK_NOT_TAKEN : STATE_STRONG_NOT_TAKEN;
                end
                STATE_WEAK_NOT_TAKEN: begin
                    pht_counter[pht_index] <= branch_taken ? STATE_WEAK_TAKEN : STATE_STRONG_NOT_TAKEN;
                end
                STATE_WEAK_TAKEN: begin
                    pht_counter[pht_index] <= branch_taken ? STATE_STRONG_TAKEN : STATE_WEAK_NOT_TAKEN;
                end
                STATE_STRONG_TAKEN: begin
                    pht_counter[pht_index] <= branch_taken ? STATE_STRONG_TAKEN : STATE_WEAK_TAKEN;
                end
            endcase
        end
    end

endmodule
