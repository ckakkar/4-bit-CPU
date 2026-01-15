// synaptic_memory.v - Synaptic Weight Storage
// Analog memory for storing synaptic weights
// Supports read/write and learning updates

module synaptic_memory (
    input clk,
    input rst,
    // Memory interface
    input [7:0] read_addr,          // Read address (neuron/synapse index)
    input read_enable,              // Read enable
    output reg [7:0] read_data,    // Read data (weight value)
    output reg read_valid,          // Read data valid
    input [7:0] write_addr,         // Write address
    input write_enable,              // Write enable
    input [7:0] write_data,         // Write data (weight value)
    // Learning interface
    input learn_enable,             // Enable learning update
    input [7:0] learn_addr,         // Synapse address for learning
    input [7:0] learn_delta,        // Weight change (signed)
    // Analog memory array (internal)
    reg [7:0] weight_array [0:255]; // 256 synapses (8-bit weights)
    // Statistics
    output reg [31:0] read_count,   // Total reads
    output reg [31:0] write_count,  // Total writes
    output reg [31:0] learn_count   // Total learning updates
);

    integer i;
    
    // Initialize
    always @(posedge rst) begin
        read_count <= 32'b0;
        write_count <= 32'b0;
        learn_count <= 32'b0;
        read_data <= 8'b0;
        read_valid <= 0;
        
        // Initialize weights to small random values (simplified)
        for (i = 0; i < 256; i = i + 1) begin
            weight_array[i] <= 8'h80; // Midpoint (zero in signed representation)
        end
    end
    
    // Memory operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Already initialized
        end else begin
            // Read operation
            read_valid <= 0;
            if (read_enable) begin
                read_data <= weight_array[read_addr];
                read_valid <= 1;
                read_count <= read_count + 1;
            end
            
            // Write operation
            if (write_enable) begin
                weight_array[write_addr] <= write_data;
                write_count <= write_count + 1;
            end
            
            // Learning update (STDP or other learning rules)
            if (learn_enable) begin
                // Update weight: new_weight = old_weight + delta
                // Handle overflow/underflow
                if (learn_delta[7]) begin
                    // Negative delta (decrement)
                    if (weight_array[learn_addr] > (8'h80 - learn_delta)) begin
                        weight_array[learn_addr] <= weight_array[learn_addr] + learn_delta;
                    end else begin
                        weight_array[learn_addr] <= 8'h00; // Clamp to minimum
                    end
                end else begin
                    // Positive delta (increment)
                    if (weight_array[learn_addr] < (8'hFF - learn_delta)) begin
                        weight_array[learn_addr] <= weight_array[learn_addr] + learn_delta;
                    end else begin
                        weight_array[learn_addr] <= 8'hFF; // Clamp to maximum
                    end
                end
                learn_count <= learn_count + 1;
            end
        end
    end

endmodule
