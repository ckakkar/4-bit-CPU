// advanced_cache.v - Advanced cache with write-back policy and LRU replacement
// Implements 2-way set-associative cache with write-back, write-allocate policy

module advanced_cache (
    input clk,
    input rst,
    input [7:0] address,               // Memory address
    input read_enable,                  // Read request
    input write_enable,                 // Write request
    input [7:0] write_data,             // Data to write
    input [7:0] backing_read_data,      // Data from backing store
    input backing_valid,                // Backing store data is valid
    output reg [7:0] data_out,          // Cached data
    output reg cache_hit,               // Cache hit indicator
    output reg cache_miss,              // Cache miss indicator
    output reg [7:0] backing_addr,      // Address to backing store
    output reg backing_read_enable,     // Read request to backing store
    output reg backing_write_enable,    // Write request to backing store (write-back)
    output reg [7:0] backing_write_data, // Write data to backing store
    output reg [7:0] backing_write_addr, // Write address to backing store
    // Cache statistics
    output reg [31:0] hit_count,        // Total cache hits
    output reg [31:0] miss_count,       // Total cache misses
    output reg [31:0] writeback_count   // Total writebacks
);

    // Cache parameters
    localparam NUM_SETS = 8;
    localparam NUM_WAYS = 2;
    
    // Cache structure: [set][way]
    reg [7:0] cache_data [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg [4:0] cache_tag [0:NUM_SETS-1][0:NUM_WAYS-1];  // Tag: upper 5 bits
    reg cache_valid [0:NUM_SETS-1][0:NUM_WAYS-1];      // Valid bit
    reg cache_dirty [0:NUM_SETS-1][0:NUM_WAYS-1];      // Dirty bit (for write-back)
    reg [NUM_SETS-1:0] lru_bit;                        // LRU bit per set (0=way0, 1=way1)
    
    // Address breakdown
    wire [4:0] tag = address[7:3];      // Upper 5 bits
    wire [2:0] set_index = address[2:0]; // Lower 3 bits (8 sets)
    
    // State machine for cache operations
    reg [1:0] state;
    localparam STATE_IDLE = 2'b00;
    localparam STATE_READ_MISS = 2'b01;
    localparam STATE_WRITE_MISS = 2'b10;
    localparam STATE_WRITEBACK = 2'b11;
    
    reg [2:0] victim_set;
    reg [1:0] victim_way;
    reg [7:0] victim_addr;
    reg [7:0] victim_data;
    
    integer i, j;
    
    // Initialize cache on reset
    always @(posedge rst) begin
        for (i = 0; i < NUM_SETS; i = i + 1) begin
            for (j = 0; j < NUM_WAYS; j = j + 1) begin
                cache_valid[i][j] <= 0;
                cache_dirty[i][j] <= 0;
                cache_tag[i][j] <= 5'b0;
                cache_data[i][j] <= 8'b0;
            end
            lru_bit[i] <= 0;
        end
        hit_count <= 32'b0;
        miss_count <= 32'b0;
        writeback_count <= 32'b0;
        state <= STATE_IDLE;
    end
    
    // Cache operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Already initialized
        end else begin
            case (state)
                STATE_IDLE: begin
                    backing_read_enable <= 0;
                    backing_write_enable <= 0;
                    cache_hit <= 0;
                    cache_miss <= 0;
                    
                    if (read_enable) begin
                        // Read operation
                        if (cache_valid[set_index][0] && cache_tag[set_index][0] == tag) begin
                            // Hit in way 0
                            cache_hit <= 1;
                            cache_miss <= 0;
                            data_out <= cache_data[set_index][0];
                            lru_bit[set_index] <= 1;  // Update LRU
                            hit_count <= hit_count + 1;
                        end else if (cache_valid[set_index][1] && cache_tag[set_index][1] == tag) begin
                            // Hit in way 1
                            cache_hit <= 1;
                            cache_miss <= 0;
                            data_out <= cache_data[set_index][1];
                            lru_bit[set_index] <= 0;  // Update LRU
                            hit_count <= hit_count + 1;
                        end else begin
                            // Cache miss - need to allocate
                            cache_miss <= 1;
                            miss_count <= miss_count + 1;
                            
                            // Check if victim line is dirty
                            if (lru_bit[set_index] == 0) begin
                                // Way 1 is LRU
                                victim_way <= 1;
                                if (cache_dirty[set_index][1] && cache_valid[set_index][1]) begin
                                    // Need to write back
                                    state <= STATE_WRITEBACK;
                                    victim_addr <= {cache_tag[set_index][1], set_index, 3'b0};
                                    victim_data <= cache_data[set_index][1];
                                    victim_set <= set_index;
                                end else begin
                                    // No writeback needed
                                    state <= STATE_READ_MISS;
                                    backing_addr <= address;
                                    backing_read_enable <= 1;
                                end
                            end else begin
                                // Way 0 is LRU
                                victim_way <= 0;
                                if (cache_dirty[set_index][0] && cache_valid[set_index][0]) begin
                                    // Need to write back
                                    state <= STATE_WRITEBACK;
                                    victim_addr <= {cache_tag[set_index][0], set_index, 3'b0};
                                    victim_data <= cache_data[set_index][0];
                                    victim_set <= set_index;
                                end else begin
                                    // No writeback needed
                                    state <= STATE_READ_MISS;
                                    backing_addr <= address;
                                    backing_read_enable <= 1;
                                end
                            end
                        end
                    end else if (write_enable) begin
                        // Write operation
                        if (cache_valid[set_index][0] && cache_tag[set_index][0] == tag) begin
                            // Hit in way 0 - write to cache
                            cache_data[set_index][0] <= write_data;
                            cache_dirty[set_index][0] <= 1;  // Mark dirty
                            cache_hit <= 1;
                            cache_miss <= 0;
                            lru_bit[set_index] <= 1;
                            hit_count <= hit_count + 1;
                        end else if (cache_valid[set_index][1] && cache_tag[set_index][1] == tag) begin
                            // Hit in way 1 - write to cache
                            cache_data[set_index][1] <= write_data;
                            cache_dirty[set_index][1] <= 1;  // Mark dirty
                            cache_hit <= 1;
                            cache_miss <= 0;
                            lru_bit[set_index] <= 0;
                            hit_count <= hit_count + 1;
                        end else begin
                            // Write miss - write-allocate
                            cache_miss <= 1;
                            miss_count <= miss_count + 1;
                            
                            // Check if victim line is dirty
                            if (lru_bit[set_index] == 0) begin
                                victim_way <= 1;
                                if (cache_dirty[set_index][1] && cache_valid[set_index][1]) begin
                                    state <= STATE_WRITEBACK;
                                    victim_addr <= {cache_tag[set_index][1], set_index, 3'b0};
                                    victim_data <= cache_data[set_index][1];
                                    victim_set <= set_index;
                                end else begin
                                    state <= STATE_WRITE_MISS;
                                    backing_addr <= address;
                                    backing_read_enable <= 1;  // Read-allocate
                                end
                            end else begin
                                victim_way <= 0;
                                if (cache_dirty[set_index][0] && cache_valid[set_index][0]) begin
                                    state <= STATE_WRITEBACK;
                                    victim_addr <= {cache_tag[set_index][0], set_index, 3'b0};
                                    victim_data <= cache_data[set_index][0];
                                    victim_set <= set_index;
                                end else begin
                                    state <= STATE_WRITE_MISS;
                                    backing_addr <= address;
                                    backing_read_enable <= 1;
                                end
                            end
                        end
                    end
                end
                
                STATE_READ_MISS: begin
                    // Waiting for backing store read
                    if (backing_valid) begin
                        // Fill cache line
                        cache_tag[victim_set][victim_way] <= tag;
                        cache_valid[victim_set][victim_way] <= 1;
                        cache_data[victim_set][victim_way] <= backing_read_data;
                        cache_dirty[victim_set][victim_way] <= 0;
                        data_out <= backing_read_data;
                        lru_bit[victim_set] <= ~lru_bit[victim_set];
                        backing_read_enable <= 0;
                        state <= STATE_IDLE;
                    end
                end
                
                STATE_WRITE_MISS: begin
                    // Waiting for backing store read (write-allocate)
                    if (backing_valid) begin
                        // Fill cache line and write data
                        cache_tag[victim_set][victim_way] <= tag;
                        cache_valid[victim_set][victim_way] <= 1;
                        cache_data[victim_set][victim_way] <= write_data;  // Write data, not read data
                        cache_dirty[victim_set][victim_way] <= 1;  // Mark dirty
                        data_out <= write_data;
                        lru_bit[victim_set] <= ~lru_bit[victim_set];
                        backing_read_enable <= 0;
                        state <= STATE_IDLE;
                    end
                end
                
                STATE_WRITEBACK: begin
                    // Write back dirty line
                    backing_write_enable <= 1;
                    backing_write_addr <= victim_addr;
                    backing_write_data <= victim_data;
                    writeback_count <= writeback_count + 1;
                    
                    // Clear dirty bit
                    cache_dirty[victim_set][victim_way] <= 0;
                    
                    // Then proceed to read/write miss
                    if (read_enable) begin
                        state <= STATE_READ_MISS;
                        backing_addr <= address;
                        backing_read_enable <= 1;
                    end else begin
                        state <= STATE_WRITE_MISS;
                        backing_addr <= address;
                        backing_read_enable <= 1;
                    end
                    backing_write_enable <= 0;
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
