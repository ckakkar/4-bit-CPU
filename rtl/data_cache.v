// data_cache.v - Write-through data cache with 2-way set-associative organization
// Cache configuration: 8 sets, 2 ways per set, write-through policy

module data_cache (
    input clk,
    input rst,
    input [7:0] address,           // Memory address
    input read_enable,              // Read request
    input write_enable,             // Write request
    input [7:0] write_data,         // Data to write
    input [7:0] backing_read_data,  // Data from backing store (data memory)
    input backing_valid,            // Backing store data is valid
    output reg [7:0] data_out,      // Cached data
    output reg cache_hit,           // Cache hit indicator
    output reg cache_miss,          // Cache miss indicator
    output reg [7:0] backing_addr,  // Address to backing store
    output reg backing_read_enable, // Read request to backing store
    output reg backing_write_enable,// Write request to backing store
    output reg [7:0] backing_write_data // Write data to backing store
);

    // Cache parameters
    localparam NUM_SETS = 8;
    
    // Simplified cache structure: direct-mapped (1 way)
    reg [7:0] cache_data [0:NUM_SETS-1];  // 8 cache entries
    reg [4:0] cache_tag [0:NUM_SETS-1];   // Tag: upper 5 bits
    reg cache_valid [0:NUM_SETS-1];       // Valid bit
    
    // Address breakdown
    wire [4:0] tag = address[7:3];      // Upper 5 bits
    wire [2:0] set_index = address[2:0]; // Lower 3 bits (8 sets)
    
    integer i;
    
    // Initialize cache on reset
    always @(posedge rst) begin
        for (i = 0; i < NUM_SETS; i = i + 1) begin
            cache_valid[i] <= 0;
            cache_tag[i] <= 5'b0;
            cache_data[i] <= 8'b0;
        end
    end
    
    // Cache operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cache_hit <= 0;
            cache_miss <= 0;
            data_out <= 8'b0;
            backing_addr <= 8'b0;
            backing_read_enable <= 0;
            backing_write_enable <= 0;
            backing_write_data <= 8'b0;
        end else begin
            backing_read_enable <= 0;
            backing_write_enable <= 0;
            
            if (read_enable) begin
                // Read operation - direct-mapped cache
                if (cache_valid[set_index] && cache_tag[set_index] == tag) begin
                    // Cache hit
                    cache_hit <= 1;
                    cache_miss <= 0;
                    data_out <= cache_data[set_index];
                end else begin
                    // Cache miss - request from backing store
                    cache_hit <= 0;
                    cache_miss <= 1;
                    backing_addr <= address;
                    backing_read_enable <= 1;
                end
            end else if (write_enable) begin
                // Write operation - write-through policy
                backing_write_enable <= 1;
                backing_addr <= address;
                backing_write_data <= write_data;
                
                // Also update cache if present (write-allocate)
                if (cache_valid[set_index] && cache_tag[set_index] == tag) begin
                    cache_data[set_index] <= write_data;
                    cache_hit <= 1;
                    cache_miss <= 0;
                end else begin
                    // Write miss - allocate line (write-allocate)
                    cache_hit <= 0;
                    cache_miss <= 1;
                    // Write directly and mark valid
                    cache_tag[set_index] <= tag;
                    cache_valid[set_index] <= 1;
                    cache_data[set_index] <= write_data;
                end
            end else begin
                cache_hit <= 0;
                cache_miss <= 0;
            end
        end
    end
    
    // Handle cache fill from backing store
    always @(posedge clk) begin
        if (backing_valid && cache_miss && read_enable) begin
            // Fill cache line
            cache_tag[set_index] <= tag;
            cache_valid[set_index] <= 1;
            cache_data[set_index] <= backing_read_data;
            data_out <= backing_read_data;
        end
    end

endmodule
