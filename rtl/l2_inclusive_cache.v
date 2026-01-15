// l2_inclusive_cache.v - L2 Inclusive Cache (per-core)
// Inclusive policy: L2 contains all data that is in L1
// When data is in L1, it must also be present in L2

module l2_inclusive_cache (
    input clk,
    input rst,
    input [7:0] address,               // Memory address
    input read_enable,                 // Read request
    input write_enable,                 // Write request
    input [7:0] write_data,           // Data to write
    // L1 interface (for fills and invalidations)
    input [7:0] l1_addr,              // Address from L1
    input l1_read_enable,             // L1 read request
    input l1_write_enable,            // L1 write request (eviction)
    input [7:0] l1_write_data,        // Data from L1 (eviction)
    input l1_ready,                   // L1 is ready
    output reg [7:0] l1_read_data,    // Data to L1
    output reg l1_valid,              // L1 data is valid
    // L3 interface (for fills and evictions)
    input [7:0] l3_read_data,         // Data from L3
    input l3_valid,                   // L3 data is valid
    input l3_ready,                   // L3 is ready
    output reg [7:0] l3_addr,         // Address to L3
    output reg l3_read_enable,        // Read request to L3
    output reg l3_write_enable,       // Write request to L3 (eviction)
    output reg [7:0] l3_write_data,   // Write data to L3
    // CPU interface (direct access, bypasses L1)
    output reg [7:0] data_out,        // Cached data
    output reg cache_hit,             // Cache hit indicator
    output reg cache_miss,            // Cache miss indicator
    output reg ready,                 // Cache is ready
    // Statistics
    output reg [31:0] hit_count,
    output reg [31:0] miss_count,
    output reg [31:0] eviction_count
);

    // Cache parameters - larger than L1
    localparam NUM_SETS = 8;          // 8 sets for L2
    localparam NUM_WAYS = 4;          // 4-way set-associative
    
    // Cache structure
    reg [7:0] cache_data [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg [4:0] cache_tag [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg cache_valid [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg cache_dirty [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg cache_in_l1 [0:NUM_SETS-1][0:NUM_WAYS-1];  // Track if data is also in L1 (inclusive)
    reg [1:0] lru_counter [0:NUM_SETS-1][0:NUM_WAYS-1];  // LRU counter (0 = most recent)
    
    // Address breakdown - use l1_addr for L1 requests, address for direct CPU requests
    wire [4:0] tag = l1_read_enable || l1_write_enable ? l1_addr[7:3] : address[7:3];
    wire [2:0] set_index = l1_read_enable || l1_write_enable ? l1_addr[2:0] : address[2:0];
    wire [4:0] l1_tag = l1_addr[7:3];
    wire [2:0] l1_set_index = l1_addr[2:0];
    
    // State machine
    reg [2:0] state;
    localparam STATE_IDLE = 3'b000;
    localparam STATE_READ_MISS = 3'b001;
    localparam STATE_WRITE_MISS = 3'b010;
    localparam STATE_EVICT = 3'b011;
    localparam STATE_WAIT_L3 = 3'b100;
    localparam STATE_FILL_L1 = 3'b101;
    
    reg [2:0] victim_set;
    reg [1:0] victim_way;
    reg [7:0] victim_addr;
    reg [7:0] victim_data;
    reg victim_dirty;
    reg [7:0] pending_addr;
    reg pending_read;
    
    integer i, j;
    
    // Initialize cache
    always @(posedge rst) begin
        for (i = 0; i < NUM_SETS; i = i + 1) begin
            for (j = 0; j < NUM_WAYS; j = j + 1) begin
                cache_valid[i][j] <= 0;
                cache_dirty[i][j] <= 0;
                cache_in_l1[i][j] <= 0;
                cache_tag[i][j] <= 5'b0;
                cache_data[i][j] <= 8'b0;
                lru_counter[i][j] <= 2'b11;  // Initialize to LRU
            end
        end
        hit_count <= 32'b0;
        miss_count <= 32'b0;
        eviction_count <= 32'b0;
        state <= STATE_IDLE;
        ready <= 1;
        cache_hit <= 0;
        cache_miss <= 0;
        l1_valid <= 0;
    end
    
    // LRU update function
    function [1:0] find_lru_way;
        input [2:0] set;
        integer k;
        reg [1:0] max_way;
        reg [1:0] max_val;
        begin
            max_way = 0;
            max_val = lru_counter[set][0];
            for (k = 1; k < NUM_WAYS; k = k + 1) begin
                if (lru_counter[set][k] > max_val) begin
                    max_val = lru_counter[set][k];
                    max_way = k;
                end
            end
            find_lru_way = max_way;
        end
    endfunction
    
    // Update LRU counters
    task update_lru;
        input [2:0] set;
        input [1:0] way;
        integer k;
        begin
            for (k = 0; k < NUM_WAYS; k = k + 1) begin
                if (k == way) begin
                    lru_counter[set][k] <= 2'b00;  // Most recently used
                end else if (lru_counter[set][k] < 2'b11) begin
                    lru_counter[set][k] <= lru_counter[set][k] + 1;
                end
            end
        end
    endtask
    
    // Cache operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Already initialized
        end else begin
            // Default outputs
            l3_read_enable <= 0;
            l3_write_enable <= 0;
            l1_valid <= 0;
            cache_hit <= 0;
            cache_miss <= 0;
            ready <= 0;
            
            case (state)
                STATE_IDLE: begin
                    ready <= 1;
                    
                    // Handle L1 requests (inclusive: L1 gets data from L2)
                    if (l1_read_enable && l1_ready) begin
                        // Check for hit in L2
                        for (i = 0; i < NUM_WAYS; i = i + 1) begin
                            if (cache_valid[l1_set_index][i] && cache_tag[l1_set_index][i] == l1_tag) begin
                                // Hit - provide to L1
                                l1_read_data <= cache_data[l1_set_index][i];
                                l1_valid <= 1;
                                cache_in_l1[l1_set_index][i] <= 1;  // Mark as in L1
                                update_lru(l1_set_index, i);
                                hit_count <= hit_count + 1;
                                state <= STATE_IDLE;
                            end
                        end
                        
                        // Miss - need to fetch from L3
                        if (!l1_valid) begin
                            state <= STATE_READ_MISS;
                            pending_addr <= l1_addr;
                            pending_read <= 1;
                            l3_addr <= l1_addr;
                            l3_read_enable <= 1;
                            miss_count <= miss_count + 1;
                        end
                    end else if (l1_write_enable && l1_ready) begin
                        // L1 eviction - data comes to L2 (inclusive: L2 must have it)
                        // Find or allocate entry in L2
                        for (i = 0; i < NUM_WAYS; i = i + 1) begin
                            if (cache_valid[l1_set_index][i] && cache_tag[l1_set_index][i] == l1_tag) begin
                                // Update existing entry
                                cache_data[l1_set_index][i] <= l1_write_data;
                                cache_dirty[l1_set_index][i] <= 1;
                                cache_in_l1[l1_set_index][i] <= 0;  // No longer in L1
                                update_lru(l1_set_index, i);
                                state <= STATE_IDLE;
                            end
                        end
                        
                        // Need to allocate
                        if (state == STATE_IDLE) begin
                            victim_way <= find_lru_way(l1_set_index);
                            victim_set <= l1_set_index;
                            
                            // Check if victim needs eviction
                            if (cache_dirty[l1_set_index][victim_way] && cache_valid[l1_set_index][victim_way]) begin
                                state <= STATE_EVICT;
                                victim_addr <= {cache_tag[l1_set_index][victim_way], l1_set_index};
                                victim_data <= cache_data[l1_set_index][victim_way];
                                victim_dirty <= 1;
                            end else begin
                                // Allocate line
                                cache_tag[l1_set_index][victim_way] <= l1_tag;
                                cache_valid[l1_set_index][victim_way] <= 1;
                                cache_data[l1_set_index][victim_way] <= l1_write_data;
                                cache_dirty[l1_set_index][victim_way] <= 1;
                                cache_in_l1[l1_set_index][victim_way] <= 0;
                                update_lru(l1_set_index, victim_way);
                                state <= STATE_IDLE;
                            end
                        end
                    end else if (read_enable) begin
                        // Direct CPU read (bypasses L1)
                        for (i = 0; i < NUM_WAYS; i = i + 1) begin
                            if (cache_valid[set_index][i] && cache_tag[set_index][i] == tag) begin
                                cache_hit <= 1;
                                cache_miss <= 0;
                                data_out <= cache_data[set_index][i];
                                update_lru(set_index, i);
                                hit_count <= hit_count + 1;
                                state <= STATE_IDLE;
                            end
                        end
                        
                        if (!cache_hit) begin
                            cache_miss <= 1;
                            miss_count <= miss_count + 1;
                            state <= STATE_READ_MISS;
                            pending_addr <= address;
                            pending_read <= 1;
                            l3_addr <= address;
                            l3_read_enable <= 1;
                        end
                    end else if (write_enable) begin
                        // Direct CPU write
                        for (i = 0; i < NUM_WAYS; i = i + 1) begin
                            if (cache_valid[set_index][i] && cache_tag[set_index][i] == tag) begin
                                cache_data[set_index][i] <= write_data;
                                cache_dirty[set_index][i] <= 1;
                                cache_hit <= 1;
                                cache_miss <= 0;
                                update_lru(set_index, i);
                                hit_count <= hit_count + 1;
                                state <= STATE_IDLE;
                            end
                        end
                        
                        if (!cache_hit) begin
                            cache_miss <= 1;
                            miss_count <= miss_count + 1;
                            state <= STATE_WRITE_MISS;
                            pending_addr <= address;
                            pending_read <= 0;
                            l3_addr <= address;
                            l3_read_enable <= 1;  // Write-allocate
                        end
                    end
                end
                
                STATE_READ_MISS: begin
                    // Waiting for L3 to provide data
                    if (l3_valid && l3_ready) begin
                        // Extract set_index from pending address (use wire extraction)
                        // Find victim
                        victim_way <= find_lru_way(pending_addr[2:0]);
                        victim_set <= pending_addr[2:0];
                        
                        // Check if victim needs eviction
                        if (cache_dirty[pending_addr[2:0]][victim_way] && cache_valid[pending_addr[2:0]][victim_way]) begin
                            state <= STATE_EVICT;
                            victim_addr <= {cache_tag[pending_addr[2:0]][victim_way], pending_addr[2:0]};
                            victim_data <= cache_data[pending_addr[2:0]][victim_way];
                            victim_dirty <= 1;
                            pending_addr <= pending_addr;  // Keep pending address
                        end else begin
                            // Fill cache line
                            cache_tag[pending_addr[2:0]][victim_way] <= pending_addr[7:3];
                            cache_valid[pending_addr[2:0]][victim_way] <= 1;
                            cache_data[pending_addr[2:0]][victim_way] <= l3_read_data;
                            cache_dirty[pending_addr[2:0]][victim_way] <= 0;
                            cache_in_l1[pending_addr[2:0]][victim_way] <= 0;
                            update_lru(pending_addr[2:0], victim_way);
                            
                            // Provide to requester
                            if (pending_read) begin
                                l1_read_data <= l3_read_data;
                                l1_valid <= 1;
                                cache_in_l1[pending_addr[2:0]][victim_way] <= 1;
                            end else begin
                                data_out <= l3_read_data;
                            end
                            
                            l3_read_enable <= 0;
                            state <= STATE_IDLE;
                            ready <= 1;
                        end
                    end
                end
                
                STATE_WRITE_MISS: begin
                    // Waiting for L3 read (write-allocate)
                    if (l3_valid && l3_ready) begin
                        victim_way <= find_lru_way(pending_addr[2:0]);
                        victim_set <= pending_addr[2:0];
                        
                        if (cache_dirty[pending_addr[2:0]][victim_way] && cache_valid[pending_addr[2:0]][victim_way]) begin
                            state <= STATE_EVICT;
                            victim_addr <= {cache_tag[pending_addr[2:0]][victim_way], pending_addr[2:0]};
                            victim_data <= cache_data[pending_addr[2:0]][victim_way];
                            victim_dirty <= 1;
                        end else begin
                            // Fill and write
                            cache_tag[pending_addr[2:0]][victim_way] <= pending_addr[7:3];
                            cache_valid[pending_addr[2:0]][victim_way] <= 1;
                            cache_data[pending_addr[2:0]][victim_way] <= write_data;
                            cache_dirty[pending_addr[2:0]][victim_way] <= 1;
                            cache_in_l1[pending_addr[2:0]][victim_way] <= 0;
                            update_lru(pending_addr[2:0], victim_way);
                            data_out <= write_data;
                            l3_read_enable <= 0;
                            state <= STATE_IDLE;
                            ready <= 1;
                        end
                    end
                end
                
                STATE_EVICT: begin
                    // Evict dirty line to L3
                    if (l3_ready) begin
                        l3_write_enable <= 1;
                        l3_addr <= victim_addr;
                        l3_write_data <= victim_data;
                        eviction_count <= eviction_count + 1;
                        
                        // Clear victim line
                        cache_valid[victim_set][victim_way] <= 0;
                        cache_dirty[victim_set][victim_way] <= 0;
                        cache_in_l1[victim_set][victim_way] <= 0;
                        
                        state <= STATE_WAIT_L3;
                    end
                end
                
                STATE_WAIT_L3: begin
                    // Wait for L3 to accept eviction
                    l3_write_enable <= 0;
                    
                    // Now fill with new data
                    if (pending_read) begin
                        state <= STATE_READ_MISS;
                        l3_addr <= pending_addr;
                        l3_read_enable <= 1;
                    end else begin
                        state <= STATE_WRITE_MISS;
                        l3_addr <= pending_addr;
                        l3_read_enable <= 1;
                    end
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
