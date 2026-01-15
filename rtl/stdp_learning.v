// stdp_learning.v - Spike-Timing Dependent Plasticity (STDP)
// Brain-inspired learning rule
// Strengthens synapses when pre-synaptic spike precedes post-synaptic spike

module stdp_learning (
    input clk,
    input rst,
    input enable,                   // Enable learning
    // Spike timing
    input [7:0] pre_spike_time,     // Pre-synaptic spike time
    input [7:0] post_spike_time,    // Post-synaptic spike time
    input pre_spike_valid,          // Pre-synaptic spike valid
    input post_spike_valid,         // Post-synaptic spike valid
    // Synapse information
    input [7:0] synapse_addr,       // Synapse address
    input [7:0] current_weight,     // Current synaptic weight
    // Learning parameters
    input [7:0] learning_rate,      // Learning rate (0-255)
    input [7:0] time_window,        // STDP time window
    // Output
    output reg [7:0] weight_delta,  // Weight change (signed)
    output reg weight_update_valid,  // Weight update valid
    // Statistics
    output reg [31:0] stdp_updates, // Total STDP updates
    output reg [31:0] potentiation_count, // Long-term potentiation (LTP)
    output reg [31:0] depression_count     // Long-term depression (LTD)
);

    // STDP rule:
    // If pre-spike before post-spike (Δt > 0): LTP (strengthen)
    // If post-spike before pre-spike (Δt < 0): LTD (weaken)
    // Δw = A+ * exp(-Δt/τ+) for Δt > 0
    // Δw = -A- * exp(Δt/τ-) for Δt < 0
    
    reg [7:0] time_delta;
    reg [7:0] time_delta_abs;
    reg signed [8:0] signed_delta;
    reg [7:0] stdp_strength;
    
    // Initialize
    always @(posedge rst) begin
        weight_delta <= 8'b0;
        weight_update_valid <= 0;
        stdp_updates <= 32'b0;
        potentiation_count <= 32'b0;
        depression_count <= 32'b0;
    end
    
    // STDP computation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Already initialized
        end else if (enable && pre_spike_valid && post_spike_valid) begin
            weight_update_valid <= 0;
            
            // Calculate time difference
            if (post_spike_time >= pre_spike_time) begin
                // Pre before post: LTP (potentiation)
                time_delta <= post_spike_time - pre_spike_time;
                signed_delta <= post_spike_time - pre_spike_time;
            end else begin
                // Post before pre: LTD (depression)
                time_delta <= pre_spike_time - post_spike_time;
                signed_delta <= pre_spike_time - post_spike_time;
            end
            
            time_delta_abs <= (post_spike_time >= pre_spike_time) ? 
                              (post_spike_time - pre_spike_time) : 
                              (pre_spike_time - post_spike_time);
            
            // Check if within time window
            if (time_delta_abs <= time_window) begin
                // Calculate STDP strength (simplified exponential)
                // Real implementation would use lookup table or approximation
                if (post_spike_time >= pre_spike_time) begin
                    // LTP: Δw = learning_rate * exp(-Δt/τ)
                    // Simplified: Δw = learning_rate * (1 - Δt/time_window)
                    if (time_window > 0) begin
                        stdp_strength <= (learning_rate * (time_window - time_delta_abs)) / time_window;
                    end else begin
                        stdp_strength <= learning_rate;
                    end
                    weight_delta <= stdp_strength;
                    potentiation_count <= potentiation_count + 1;
                end else begin
                    // LTD: Δw = -learning_rate * exp(Δt/τ)
                    // Simplified: Δw = -learning_rate * (1 - Δt/time_window)
                    if (time_window > 0) begin
                        stdp_strength <= (learning_rate * (time_window - time_delta_abs)) / time_window;
                    end else begin
                        stdp_strength <= learning_rate;
                    end
                    weight_delta <= {1'b1, stdp_strength[6:0]}; // Negative (two's complement)
                    depression_count <= depression_count + 1;
                end
                
                weight_update_valid <= 1;
                stdp_updates <= stdp_updates + 1;
            end else begin
                // Outside time window, no update
                weight_delta <= 8'b0;
                weight_update_valid <= 0;
            end
        end
    end

endmodule
