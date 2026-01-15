// spiking_neuron.v - Spiking Neuron Model
// Implements leaky integrate-and-fire (LIF) neuron model
// Event-driven asynchronous processing

module spiking_neuron (
    input clk,
    input rst,
    input enable,                    // Enable neuron
    // Input spikes (event-driven)
    input [7:0] input_spikes,       // Input spike vector (8 inputs)
    input [63:0] input_weights,     // Synaptic weights (8 weights × 8 bits)
    input spike_valid,               // Input spike valid
    // Neuron parameters
    input [7:0] threshold,          // Firing threshold
    input [7:0] leak_rate,          // Leak rate (membrane decay)
    input [7:0] reset_voltage,      // Reset voltage after spike
    // Output
    output reg spike_out,           // Output spike
    output reg spike_valid_out,     // Spike output valid
    output reg [7:0] membrane_potential, // Current membrane potential
    // State
    output reg [7:0] spike_count,   // Total spikes generated
    output reg [31:0] last_spike_time // Time of last spike
);

    // Leaky Integrate-and-Fire (LIF) neuron model
    // Membrane potential: V(t) = V(t-1) * leak + sum(weights * spikes)
    // Spike when V(t) >= threshold
    
    reg [7:0] membrane_voltage;
    reg [7:0] input_sum;
    reg [31:0] time_counter;
    integer i;
    
    // Initialize
    always @(posedge rst) begin
        membrane_voltage <= 8'b0;
        membrane_potential <= 8'b0;
        spike_out <= 0;
        spike_valid_out <= 0;
        spike_count <= 8'b0;
        last_spike_time <= 32'b0;
        time_counter <= 32'b0;
    end
    
    // Event-driven processing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Already initialized
        end else if (enable) begin
            time_counter <= time_counter + 1;
            
            // Leak: decay membrane potential
            if (membrane_voltage > 0) begin
                // Leak: V = V * (1 - leak_rate/256)
                if (membrane_voltage > leak_rate) begin
                    membrane_voltage <= membrane_voltage - leak_rate;
                end else begin
                    membrane_voltage <= 8'b0;
                end
            end
            
            // Process input spikes (event-driven)
            if (spike_valid) begin
                // Integrate: sum weighted input spikes
                input_sum <= 0;
                for (i = 0; i < 8; i = i + 1) begin
                    if (input_spikes[i]) begin
                        input_sum <= input_sum + input_weights[(i*8+7):(i*8)];
                    end
                end
                
                // Update membrane potential
                membrane_voltage <= membrane_voltage + input_sum;
            end
            
            // Check for spike generation
            if (membrane_voltage >= threshold) begin
                // Neuron fires
                spike_out <= 1;
                spike_valid_out <= 1;
                spike_count <= spike_count + 1;
                last_spike_time <= time_counter;
                
                // Reset membrane potential
                membrane_voltage <= reset_voltage;
            end else begin
                spike_out <= 0;
                spike_valid_out <= 0;
            end
            
            // Update output
            membrane_potential <= membrane_voltage;
        end
    end

endmodule
