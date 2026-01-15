// l1_exclusive_cache.v - L1 Exclusive Cache (per-core)
// Exclusive policy: Data in L1 is NOT in L2
// When evicted from L1, data goes to L2 (not present in both simultaneously)

module l1_exclusive_cache (
    input clk,
    input rst,
    input [7:0] address,               // Memory address
    input read_enable,                  // Read request
    input write_enable,                 // Write request
    input [7:0] write_data,            // Data to write
    // L2 interface (for evictions and fills)
    input [7:0] l2_read_data,          // Data from L2
    input l2_valid,                    // L2 data is valid
    input l2_ready,                    // L2 is ready for requests
    output reg [7:0] l2_addr,          // Address to L2
    output reg l2_read_enable,         // Read request to L2
    output reg l2_write_enable,        // Write request to L2 (eviction)
    output reg [7:0] l2_write_data,    // Write data to L2 (eviction)
    // CPU interface
    output reg [7:0] data_out,         // Cached data
    output reg cache_hit,              // Cache hit indicator
    output reg cache_miss,             // Cache miss indicator
    output reg ready,                  // Cache is ready
    // Statistics
    output reg [31:0] hit_count,
    output reg [31:0] miss_count,
    output reg [31:0] eviction_count
);

    // Cache parameters - small and fast
    localparam NUM_SETS = 4;           // 4 sets for L1 (smaller than L2)
    localparam NUM_WAYS = 2;           // 2-way set-associative
    
    // Cache structure
    reg [7:0] cache_data [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg [4:0] cache_tag [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg cache_valid [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg cache_dirty [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg [NUM_SETS-1:0] lru_bit;       // LRU bit per set
    
    // Address breakdown
    wire [4:0] tag = address[7:3];     // Upper 5 bits
    wire [1:0] set_index = address[2:1]; // 2 bits for 4 sets
    wire [0:0] word_offset = address[0]; // Word offset (1 bit)
    
    // State machine
    reg [2:0] state;
    localparam STATE_IDLE = 3'b000;
    localparam STATE_READ_MISS = 3'b001;
    localparam STATE_WRITE_MISS = 3'b010;
    localparam STATE_EVICT = 3'b011;
    localparam STATE_WAIT_L2 = 3'b100;
    
    reg [1:0] victim_set;
    reg [1:0] victim_way;
    reg [7:0] victim_addr;
    reg [7:0] victim_data;
    reg victim_dirty;
    
    integer i, j;
    
    // Initialize cache
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
        eviction_count <= 32'b0;
        state <= STATE_IDLE;
        ready <= 1;
        cache_hit <= 0;
        cache_miss <= 0;
    end
    
    // Cache operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Already initialized
        end else begin
            // Default outputs
            l2_read_enable <= 0;
            l2_write_enable <= 0;
            cache_hit <= 0;
            cache_miss <= 0;
            ready <= 0;
            
            case (state)
                STATE_IDLE: begin
                    ready <= 1;
                    
                    if (read_enable) begin
                        // Check both ways for hit
                        if (cache_valid[set_index][0] && cache_tag[set_index][0] == tag) begin
                            // Hit in way 0
                            cache_hit <= 1;
                            cache_miss <= 0;
                            data_out <= cache_data[set_index][0];
                            lru_bit[set_index] <= 1;
                            hit_count <= hit_count + 1;
                        end else if (cache_valid[set_index][1] && cache_tag[set_index][1] == tag) begin
                            // Hit in way 1
                            cache_hit <= 1;
                            cache_miss <= 0;
                            data_out <= cache_data[set_index][1];
                            lru_bit[set_index] <= 0;
                            hit_count <= hit_count + 1;
                        end else begin
                            // Miss - need to evict and fetch
                            cache_miss <= 1;
                            miss_count <= miss_count + 1;
                            ready <= 0;
                            
                            // Select victim (LRU)
                            if (lru_bit[set_index] == 0) begin
                                victim_way <= 1;
                            end else begin
                                victim_way <= 0;
                            end
                            victim_set <= set_index;
                            
                            // Check if victim is dirty and valid (needs eviction to L2)
                            if (cache_dirty[set_index][victim_way] && cache_valid[set_index][victim_way]) begin
                                // Evict to L2 first (exclusive: data goes to L2)
                                state <= STATE_EVICT;
                                victim_addr <= {cache_tag[set_index][victim_way], set_index, word_offset};
                                victim_data <= cache_data[set_index][victim_way];
                                victim_dirty <= 1;
                            end else begin
                                // No eviction needed, fetch from L2
                                state <= STATE_READ_MISS;
                                l2_addr <= address;
                                l2_read_enable <= 1;
                            end
                        end
                    end else if (write_enable) begin
                        // Write operation
                        if (cache_valid[set_index][0] && cache_tag[set_index][0] == tag) begin
                            // Hit in way 0 - write to cache
                            cache_data[set_index][0] <= write_data;
                            cache_dirty[set_index][0] <= 1;
                            cache_hit <= 1;
                            cache_miss <= 0;
                            lru_bit[set_index] <= 1;
                            hit_count <= hit_count + 1;
                        end else if (cache_valid[set_index][1] && cache_tag[set_index][1] == tag) begin
                            // Hit in way 1 - write to cache
                            cache_data[set_index][1] <= write_data;
                            cache_dirty[set_index][1] <= 1;
                            cache_hit <= 1;
                            cache_miss <= 0;
                            lru_bit[set_index] <= 0;
                            hit_count <= hit_count + 1;
                        end else begin
                            // Write miss - write-allocate
                            cache_miss <= 1;
                            miss_count <= miss_count + 1;
                            ready <= 0;
                            
                            // Select victim
                            if (lru_bit[set_index] == 0) begin
                                victim_way <= 1;
                            end else begin
                                victim_way <= 0;
                            end
                            victim_set <= set_index;
                            
                            // Check if victim needs eviction
                            if (cache_dirty[set_index][victim_way] && cache_valid[set_index][victim_way]) begin
                                state <= STATE_EVICT;
                                victim_addr <= {cache_tag[set_index][victim_way], set_index, word_offset};
                                victim_data <= cache_data[set_index][victim_way];
                                victim_dirty <= 1;
                            end else begin
                                // Allocate line and write
                                state <= STATE_WRITE_MISS;
                                l2_addr <= address;
                                l2_read_enable <= 1;  // Read-allocate
                            end
                        end
                    end
                end
                
                STATE_READ_MISS: begin
                    // Waiting for L2 to provide data
                    if (l2_valid && l2_ready) begin
                        // Fill cache line from L2
                        cache_tag[victim_set][victim_way] <= tag;
                        cache_valid[victim_set][victim_way] <= 1;
                        cache_data[victim_set][victim_way] <= l2_read_data;
                        cache_dirty[victim_set][victim_way] <= 0;
                        data_out <= l2_read_data;
                        lru_bit[victim_set] <= ~lru_bit[victim_set];
                        l2_read_enable <= 0;
                        state <= STATE_IDLE;
                        ready <= 1;
                    end
                end
                
                STATE_WRITE_MISS: begin
                    // Waiting for L2 read (write-allocate)
                    if (l2_valid && l2_ready) begin
                        // Fill cache line and write data
                        cache_tag[victim_set][victim_way] <= tag;
                        cache_valid[victim_set][victim_way] <= 1;
                        cache_data[victim_set][victim_way] <= write_data;  // Write data
                        cache_dirty[victim_set][victim_way] <= 1;
                        data_out <= write_data;
                        lru_bit[victim_set] <= ~lru_bit[victim_set];
                        l2_read_enable <= 0;
                        state <= STATE_IDLE;
                        ready <= 1;
                    end
                end
                
                STATE_EVICT: begin
                    // Evict dirty line to L2 (exclusive: data moves to L2)
                    if (l2_ready) begin
                        l2_write_enable <= 1;
                        l2_addr <= victim_addr;
                        l2_write_data <= victim_data;
                        eviction_count <= eviction_count + 1;
                        
                        // Clear victim line
                        cache_valid[victim_set][victim_way] <= 0;
                        cache_dirty[victim_set][victim_way] <= 0;
                        
                        state <= STATE_WAIT_L2;
                    end
                end
                
                STATE_WAIT_L2: begin
                    // Wait for L2 to accept eviction
                    l2_write_enable <= 0;
                    
                    // Now fetch new data
                    if (read_enable) begin
                        state <= STATE_READ_MISS;
                        l2_addr <= address;
                        l2_read_enable <= 1;
                    end else begin
                        state <= STATE_WRITE_MISS;
                        l2_addr <= address;
                        l2_read_enable <= 1;
                    end
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
