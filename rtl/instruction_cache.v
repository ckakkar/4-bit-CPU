// instruction_cache.v - 2-way set-associative instruction cache
// Cache configuration: 8 sets, 2 ways per set, 4 instructions per cache line

module instruction_cache (
    input clk,
    input rst,
    input [7:0] address,           // Instruction address
    input read_enable,              // Read request
    input [15:0] backing_data,      // Data from backing store (instruction memory)
    input backing_valid,            // Backing store data is valid
    output reg [15:0] data_out,     // Cached instruction
    output reg cache_hit,           // Cache hit indicator
    output reg cache_miss,          // Cache miss indicator
    output reg [7:0] backing_addr,  // Address to read from backing store
    output reg backing_read_enable  // Request to backing store
);

    // Cache parameters
    localparam NUM_SETS = 8;
    localparam LINE_SIZE = 4;  // 4 instructions per cache line (for future use)
    
    // Simplified cache structure: flattened arrays
    // For simplicity, use direct-mapped cache (1 way) with 8 entries
    // Tag array: 8 sets × 1 way = 8 tags
    reg [4:0] cache_tag [0:7];  // Tag: upper 5 bits of address
    reg [15:0] cache_data [0:7];  // Cache data (one instruction per entry)
    reg cache_valid [0:7];      // Valid bit
    reg [7:0] lru_counter;      // Simple LRU counter
    
    // Address breakdown
    wire [4:0] tag = address[7:3];      // Upper 5 bits
    wire [2:0] set_index = address[2:0]; // Lower 3 bits (8 sets)
    
    integer i;
    
    // Initialize cache on reset
    always @(posedge rst) begin
        for (i = 0; i < NUM_SETS; i = i + 1) begin
            cache_valid[i] <= 0;
            cache_tag[i] <= 5'b0;
            cache_data[i] <= 16'b0;
        end
        lru_counter <= 8'b0;
    end
    
    // Cache lookup and replacement
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cache_hit <= 0;
            cache_miss <= 0;
            data_out <= 16'b0;
            backing_addr <= 8'b0;
            backing_read_enable <= 0;
        end else if (read_enable) begin
            // Check for cache hit (direct-mapped)
            if (cache_valid[set_index] && cache_tag[set_index] == tag) begin
                // Cache hit
                cache_hit <= 1;
                cache_miss <= 0;
                data_out <= cache_data[set_index];
                backing_read_enable <= 0;
            end else begin
                // Cache miss - request from backing store
                cache_hit <= 0;
                cache_miss <= 1;
                backing_addr <= address;
                backing_read_enable <= 1;
            end
        end else begin
            cache_hit <= 0;
            cache_miss <= 0;
            backing_read_enable <= 0;
        end
    end
    
    // Handle cache fill from backing store
    always @(posedge clk) begin
        if (backing_valid && cache_miss && read_enable) begin
            // Fill cache line
            cache_tag[set_index] <= tag;
            cache_valid[set_index] <= 1;
            cache_data[set_index] <= backing_data;
            data_out <= backing_data;  // Provide data immediately
        end
    end

endmodule
