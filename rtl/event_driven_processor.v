// event_driven_processor.v - Event-Driven Asynchronous Processor
// Processes spikes asynchronously, only when events occur
// Reduces power consumption and improves efficiency

module event_driven_processor (
    input clk,
    input rst,
    input enable,                    // Enable processor
    // Event queue interface
    input [7:0] event_addr,          // Event address (neuron/synapse)
    input event_valid,               // Event valid
    input [7:0] event_time,          // Event timestamp
    output reg event_processed,       // Event processed
    // Neuron interface
    output reg [7:0] neuron_addr,     // Target neuron address
    output reg [7:0] spike_vector,    // Spike vector to neurons
    output reg spike_valid,           // Spike valid
    // Weight memory interface
    output reg [7:0] weight_read_addr, // Weight read address
    output reg weight_read_enable,    // Weight read enable
    input [7:0] weight_read_data,     // Weight data
    input weight_read_valid,          // Weight data valid
    // Statistics
    output reg [31:0] events_processed, // Total events processed
    output reg [31:0] active_cycles,    // Active processing cycles
    output reg [31:0] idle_cycles       // Idle cycles (power savings)
);

    // Event-driven processing: only active when events occur
    // Processes spikes asynchronously, reducing power consumption
    
    reg [2:0] state;
    localparam STATE_IDLE = 3'b000;
    localparam STATE_FETCH_WEIGHT = 3'b001;
    localparam STATE_PROPAGATE = 3'b010;
    localparam STATE_DONE = 3'b011;
    
    reg [7:0] current_event_addr;
    reg [7:0] current_event_time;
    reg [7:0] current_weight;
    reg [7:0] target_neuron;
    
    // Initialize
    always @(posedge rst) begin
        state <= STATE_IDLE;
        event_processed <= 0;
        neuron_addr <= 8'b0;
        spike_vector <= 8'b0;
        spike_valid <= 0;
        weight_read_enable <= 0;
        events_processed <= 32'b0;
        active_cycles <= 32'b0;
        idle_cycles <= 32'b0;
    end
    
    // Event-driven state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Already initialized
        end else if (enable) begin
            event_processed <= 0;
            spike_valid <= 0;
            weight_read_enable <= 0;
            
            case (state)
                STATE_IDLE: begin
                    idle_cycles <= idle_cycles + 1;
                    
                    if (event_valid) begin
                        // Event received, start processing
                        state <= STATE_FETCH_WEIGHT;
                        current_event_addr <= event_addr;
                        current_event_time <= event_time;
                        target_neuron <= event_addr[7:3]; // Extract neuron index
                        events_processed <= events_processed + 1;
                        active_cycles <= active_cycles + 1;
                    end
                end
                
                STATE_FETCH_WEIGHT: begin
                    active_cycles <= active_cycles + 1;
                    
                    // Read synaptic weight for this connection
                    weight_read_addr <= current_event_addr;
                    weight_read_enable <= 1;
                    
                    if (weight_read_valid) begin
                        current_weight <= weight_read_data;
                        state <= STATE_PROPAGATE;
                    end
                end
                
                STATE_PROPAGATE: begin
                    active_cycles <= active_cycles + 1;
                    
                    // Propagate spike to target neuron
                    neuron_addr <= target_neuron;
                    spike_vector <= 8'b1 << current_event_addr[2:0]; // Set bit for this synapse
                    spike_valid <= 1;
                    
                    state <= STATE_DONE;
                end
                
                STATE_DONE: begin
                    event_processed <= 1;
                    spike_valid <= 0;
                    state <= STATE_IDLE;
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
