// systolic_pe.v - Processing Element for Systolic Array
// Performs multiply-accumulate (MAC) operation
// Data flows from top and left, results flow to bottom and right

module systolic_pe (
    input clk,
    input rst,
    input enable,                    // Enable computation
    // Data inputs (from neighbors)
    input [7:0] data_in_top,         // Data from top PE
    input [7:0] data_in_left,         // Data from left PE
    input [7:0] weight_in_top,       // Weight from top PE
    input [7:0] weight_in_left,      // Weight from left PE
    input [15:0] partial_sum_in,      // Partial sum from top PE
    // Control signals
    input weight_load,                // Load weight into PE
    input accumulate,                 // Accumulate mode (for convolution)
    // Data outputs (to neighbors)
    output reg [7:0] data_out_bottom, // Data to bottom PE
    output reg [7:0] data_out_right,  // Data to right PE
    output reg [7:0] weight_out_bottom, // Weight to bottom PE
    output reg [7:0] weight_out_right,  // Weight to right PE
    output reg [15:0] partial_sum_out,    // Partial sum to bottom PE
    // Local state
    output reg [7:0] local_weight,   // Stored weight in this PE
    output reg [15:0] local_sum       // Local accumulator
);

    // Internal registers
    reg [7:0] local_data;
    reg [7:0] local_weight_reg;
    reg [15:0] accumulator;
    
    // Multiply-accumulate operation
    wire [15:0] product = data_in_left * weight_in_top;
    wire [15:0] new_sum = accumulate ? (partial_sum_in + product) : product;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out_bottom <= 8'b0;
            data_out_right <= 8'b0;
            weight_out_bottom <= 8'b0;
            weight_out_right <= 8'b0;
            partial_sum_out <= 16'b0;
            local_weight <= 8'b0;
            local_sum <= 16'b0;
            local_data <= 8'b0;
            local_weight_reg <= 8'b0;
            accumulator <= 16'b0;
        end else if (enable) begin
            // Load weight if requested
            if (weight_load) begin
                local_weight_reg <= weight_in_top;
                local_weight <= weight_in_top;
            end
            
            // Pass data through (systolic flow)
            data_out_bottom <= data_in_top;
            data_out_right <= data_in_left;
            weight_out_bottom <= weight_in_top;
            weight_out_right <= weight_in_left;
            
            // Perform multiply-accumulate
            if (weight_load) begin
                // First cycle: just load weight
                accumulator <= 16'b0;
            end else begin
                // Compute: MAC operation
                accumulator <= new_sum;
                partial_sum_out <= new_sum;
            end
            
            // Update local state
            local_data <= data_in_left;
            local_sum <= accumulator;
        end else begin
            // Pass through when disabled (no computation)
            data_out_bottom <= data_in_top;
            data_out_right <= data_in_left;
            weight_out_bottom <= weight_in_top;
            weight_out_right <= weight_in_left;
            partial_sum_out <= partial_sum_in;
        end
    end

endmodule
