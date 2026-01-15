// l3_shared_cache.v - L3 Shared Cache (shared between all cores)
// Shared policy: All cores share the same L3 cache
// Handles requests from multiple L2 caches with arbitration

module l3_shared_cache (
    input clk,
    input rst,
    // Core 0 L2 interface
    input [7:0] core0_addr,
    input core0_read_enable,
    input core0_write_enable,
    input [7:0] core0_write_data,
    output reg [7:0] core0_read_data,
    output reg core0_valid,
    output reg core0_ready,
    // Core 1 L2 interface
    input [7:0] core1_addr,
    input core1_read_enable,
    input core1_write_enable,
    input [7:0] core1_write_data,
    output reg [7:0] core1_read_data,
    output reg core1_valid,
    output reg core1_ready,
    // Core 2 L2 interface
    input [7:0] core2_addr,
    input core2_read_enable,
    input core2_write_enable,
    input [7:0] core2_write_data,
    output reg [7:0] core2_read_data,
    output reg core2_valid,
    output reg core2_ready,
    // Core 3 L2 interface
    input [7:0] core3_addr,
    input core3_read_enable,
    input core3_write_enable,
    input [7:0] core3_write_data,
    output reg [7:0] core3_read_data,
    output reg core3_valid,
    output reg core3_ready,
    // Main memory interface
    input [7:0] mem_read_data,
    input mem_valid,
    input mem_ready,
    output reg [7:0] mem_addr,
    output reg mem_read_enable,
    output reg mem_write_enable,
    output reg [7:0] mem_write_data,
    // Statistics
    output reg [31:0] hit_count,
    output reg [31:0] miss_count,
    output reg [31:0] eviction_count
);

    // Cache parameters - largest cache
    localparam NUM_SETS = 16;         // 16 sets for L3
    localparam NUM_WAYS = 8;          // 8-way set-associative
    
    // Cache structure
    reg [7:0] cache_data [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg [4:0] cache_tag [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg cache_valid [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg cache_dirty [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg [2:0] lru_counter [0:NUM_SETS-1][0:NUM_WAYS-1];  // LRU counter (0 = most recent)
    
    // Address breakdown - use current request address
    reg [7:0] current_addr;
    wire [4:0] current_tag = current_addr[7:3];
    wire [3:0] current_set_index = current_addr[3:0];  // 4 bits for 16 sets
    
    // Arbitration state
    reg [1:0] current_master;
    reg [1:0] next_master;
    reg [2:0] state;
    
    localparam STATE_IDLE = 3'b000;
    localparam STATE_READ_MISS = 3'b001;
    localparam STATE_WRITE_MISS = 3'b010;
    localparam STATE_EVICT = 3'b011;
    localparam STATE_WAIT_MEM = 3'b100;
    
    localparam CORE_0 = 2'b00;
    localparam CORE_1 = 2'b01;
    localparam CORE_2 = 2'b10;
    localparam CORE_3 = 2'b11;
    
    reg [3:0] victim_set;
    reg [2:0] victim_way;
    reg [7:0] victim_addr;
    reg [7:0] victim_data;
    reg victim_dirty;
    reg [7:0] pending_addr;
    reg pending_read;
    reg [1:0] pending_master;
    
    integer i, j;
    
    // Request signals
    wire core0_request = core0_read_enable || core0_write_enable;
    wire core1_request = core1_read_enable || core1_write_enable;
    wire core2_request = core2_read_enable || core2_write_enable;
    wire core3_request = core3_read_enable || core3_write_enable;
    
    // Initialize cache
    always @(posedge rst) begin
        for (i = 0; i < NUM_SETS; i = i + 1) begin
            for (j = 0; j < NUM_WAYS; j = j + 1) begin
                cache_valid[i][j] <= 0;
                cache_dirty[i][j] <= 0;
                cache_tag[i][j] <= 5'b0;
                cache_data[i][j] <= 8'b0;
                lru_counter[i][j] <= 3'b111;  // Initialize to LRU
            end
        end
        hit_count <= 32'b0;
        miss_count <= 32'b0;
        eviction_count <= 32'b0;
        state <= STATE_IDLE;
        current_master <= CORE_0;
        core0_valid <= 0;
        core1_valid <= 0;
        core2_valid <= 0;
        core3_valid <= 0;
        core0_ready <= 1;
        core1_ready <= 1;
        core2_ready <= 1;
        core3_ready <= 1;
    end
    
    // Round-robin arbitration
    always @(*) begin
        next_master = current_master;
        
        case (current_master)
            CORE_0: begin
                if (core1_request) next_master = CORE_1;
                else if (core2_request) next_master = CORE_2;
                else if (core3_request) next_master = CORE_3;
                else if (core0_request) next_master = CORE_0;
            end
            CORE_1: begin
                if (core2_request) next_master = CORE_2;
                else if (core3_request) next_master = CORE_3;
                else if (core0_request) next_master = CORE_0;
                else if (core1_request) next_master = CORE_1;
            end
            CORE_2: begin
                if (core3_request) next_master = CORE_3;
                else if (core0_request) next_master = CORE_0;
                else if (core1_request) next_master = CORE_1;
                else if (core2_request) next_master = CORE_2;
            end
            CORE_3: begin
                if (core0_request) next_master = CORE_0;
                else if (core1_request) next_master = CORE_1;
                else if (core2_request) next_master = CORE_2;
                else if (core3_request) next_master = CORE_3;
            end
        endcase
    end
    
    // Find LRU way
    function [2:0] find_lru_way;
        input [3:0] set;
        integer k;
        reg [2:0] max_way;
        reg [2:0] max_val;
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
        input [3:0] set;
        input [2:0] way;
        integer k;
        begin
            for (k = 0; k < NUM_WAYS; k = k + 1) begin
                if (k == way) begin
                    lru_counter[set][k] <= 3'b000;  // Most recently used
                end else if (lru_counter[set][k] < 3'b111) begin
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
            mem_read_enable <= 0;
            mem_write_enable <= 0;
            core0_valid <= 0;
            core1_valid <= 0;
            core2_valid <= 0;
            core3_valid <= 0;
            
            case (state)
                STATE_IDLE: begin
                    // Grant access to next master
                    current_master <= next_master;
                    
                    // Select request based on current master
                    if (next_master == CORE_0 && core0_request) begin
                        current_addr <= core0_addr;
                        mem_addr <= core0_addr;
                        pending_addr <= core0_addr;
                        pending_master <= CORE_0;
                        pending_read <= core0_read_enable;
                        
                        // Check for hit
                        for (i = 0; i < NUM_WAYS; i = i + 1) begin
                            if (cache_valid[current_set_index][i] && cache_tag[current_set_index][i] == current_tag) begin
                                // Hit
                                if (core0_read_enable) begin
                                    core0_read_data <= cache_data[current_set_index][i];
                                    core0_valid <= 1;
                                end else begin
                                    cache_data[current_set_index][i] <= core0_write_data;
                                    cache_dirty[current_set_index][i] <= 1;
                                    core0_valid <= 1;
                                end
                                update_lru(current_set_index, i);
                                hit_count <= hit_count + 1;
                                state <= STATE_IDLE;
                            end
                        end
                        
                        // Miss
                        if (!core0_valid) begin
                            miss_count <= miss_count + 1;
                            victim_way <= find_lru_way(current_set_index);
                            victim_set <= current_set_index;
                            
                            if (cache_dirty[current_set_index][victim_way] && cache_valid[current_set_index][victim_way]) begin
                            state <= STATE_EVICT;
                            victim_addr <= {cache_tag[current_set_index][victim_way], current_set_index};
                            victim_data <= cache_data[current_set_index][victim_way];
                                victim_dirty <= 1;
                            end else begin
                                state <= core0_read_enable ? STATE_READ_MISS : STATE_WRITE_MISS;
                                mem_read_enable <= 1;
                            end
                        end
                    end else if (next_master == CORE_1 && core1_request) begin
                        current_addr <= core1_addr;
                        mem_addr <= core1_addr;
                        pending_addr <= core1_addr;
                        pending_master <= CORE_1;
                        pending_read <= core1_read_enable;
                        
                        for (i = 0; i < NUM_WAYS; i = i + 1) begin
                            if (cache_valid[current_set_index][i] && cache_tag[current_set_index][i] == current_tag) begin
                                if (core1_read_enable) begin
                                    core1_read_data <= cache_data[current_set_index][i];
                                    core1_valid <= 1;
                                end else begin
                                    cache_data[current_set_index][i] <= core1_write_data;
                                    cache_dirty[current_set_index][i] <= 1;
                                    core1_valid <= 1;
                                end
                                update_lru(current_set_index, i);
                                hit_count <= hit_count + 1;
                                state <= STATE_IDLE;
                            end
                        end
                        
                        if (!core1_valid) begin
                            miss_count <= miss_count + 1;
                            victim_way <= find_lru_way(current_set_index);
                            victim_set <= current_set_index;
                            
                            if (cache_dirty[current_set_index][victim_way] && cache_valid[current_set_index][victim_way]) begin
                            state <= STATE_EVICT;
                            victim_addr <= {cache_tag[current_set_index][victim_way], current_set_index};
                            victim_data <= cache_data[current_set_index][victim_way];
                                victim_dirty <= 1;
                            end else begin
                                state <= core1_read_enable ? STATE_READ_MISS : STATE_WRITE_MISS;
                                mem_read_enable <= 1;
                            end
                        end
                    end else if (next_master == CORE_2 && core2_request) begin
                        current_addr <= core2_addr;
                        mem_addr <= core2_addr;
                        pending_addr <= core2_addr;
                        pending_master <= CORE_2;
                        pending_read <= core2_read_enable;
                        
                        for (i = 0; i < NUM_WAYS; i = i + 1) begin
                            if (cache_valid[current_set_index][i] && cache_tag[current_set_index][i] == current_tag) begin
                                if (core2_read_enable) begin
                                    core2_read_data <= cache_data[current_set_index][i];
                                    core2_valid <= 1;
                                end else begin
                                    cache_data[current_set_index][i] <= core2_write_data;
                                    cache_dirty[current_set_index][i] <= 1;
                                    core2_valid <= 1;
                                end
                                update_lru(current_set_index, i);
                                hit_count <= hit_count + 1;
                                state <= STATE_IDLE;
                            end
                        end
                        
                        if (!core2_valid) begin
                            miss_count <= miss_count + 1;
                            victim_way <= find_lru_way(current_set_index);
                            victim_set <= current_set_index;
                            
                            if (cache_dirty[current_set_index][victim_way] && cache_valid[current_set_index][victim_way]) begin
                            state <= STATE_EVICT;
                            victim_addr <= {cache_tag[current_set_index][victim_way], current_set_index};
                            victim_data <= cache_data[current_set_index][victim_way];
                                victim_dirty <= 1;
                            end else begin
                                state <= core2_read_enable ? STATE_READ_MISS : STATE_WRITE_MISS;
                                mem_read_enable <= 1;
                            end
                        end
                    end else if (next_master == CORE_3 && core3_request) begin
                        current_addr <= core3_addr;
                        mem_addr <= core3_addr;
                        pending_addr <= core3_addr;
                        pending_master <= CORE_3;
                        pending_read <= core3_read_enable;
                        
                        for (i = 0; i < NUM_WAYS; i = i + 1) begin
                            if (cache_valid[current_set_index][i] && cache_tag[current_set_index][i] == current_tag) begin
                                if (core3_read_enable) begin
                                    core3_read_data <= cache_data[current_set_index][i];
                                    core3_valid <= 1;
                                end else begin
                                    cache_data[current_set_index][i] <= core3_write_data;
                                    cache_dirty[current_set_index][i] <= 1;
                                    core3_valid <= 1;
                                end
                                update_lru(current_set_index, i);
                                hit_count <= hit_count + 1;
                                state <= STATE_IDLE;
                            end
                        end
                        
                        if (!core3_valid) begin
                            miss_count <= miss_count + 1;
                            victim_way <= find_lru_way(current_set_index);
                            victim_set <= current_set_index;
                            
                            if (cache_dirty[current_set_index][victim_way] && cache_valid[current_set_index][victim_way]) begin
                            state <= STATE_EVICT;
                            victim_addr <= {cache_tag[current_set_index][victim_way], current_set_index};
                            victim_data <= cache_data[current_set_index][victim_way];
                                victim_dirty <= 1;
                            end else begin
                                state <= core3_read_enable ? STATE_READ_MISS : STATE_WRITE_MISS;
                                mem_read_enable <= 1;
                            end
                        end
                    end
                end
                
                STATE_READ_MISS: begin
                    // Waiting for memory
                    if (mem_valid && mem_ready) begin
                        // Fill cache line
                        cache_tag[victim_set][victim_way] <= pending_addr[7:3];
                        cache_valid[victim_set][victim_way] <= 1;
                        cache_data[victim_set][victim_way] <= mem_read_data;
                        cache_dirty[victim_set][victim_way] <= 0;
                        update_lru(victim_set, victim_way);
                        
                        // Provide to requesting core
                        case (pending_master)
                            CORE_0: begin
                                core0_read_data <= mem_read_data;
                                core0_valid <= 1;
                            end
                            CORE_1: begin
                                core1_read_data <= mem_read_data;
                                core1_valid <= 1;
                            end
                            CORE_2: begin
                                core2_read_data <= mem_read_data;
                                core2_valid <= 1;
                            end
                            CORE_3: begin
                                core3_read_data <= mem_read_data;
                                core3_valid <= 1;
                            end
                        endcase
                        
                        mem_read_enable <= 0;
                        state <= STATE_IDLE;
                    end
                end
                
                STATE_WRITE_MISS: begin
                    // Waiting for memory (write-allocate)
                    if (mem_valid && mem_ready) begin
                        // Fill and write
                        cache_tag[victim_set][victim_way] <= tag;
                        cache_valid[victim_set][victim_way] <= 1;
                        cache_dirty[victim_set][victim_way] <= 1;
                        update_lru(victim_set, victim_way);
                        
                        case (pending_master)
                            CORE_0: begin
                                cache_data[victim_set][victim_way] <= core0_write_data;
                                core0_valid <= 1;
                            end
                            CORE_1: begin
                                cache_data[victim_set][victim_way] <= core1_write_data;
                                core1_valid <= 1;
                            end
                            CORE_2: begin
                                cache_data[victim_set][victim_way] <= core2_write_data;
                                core2_valid <= 1;
                            end
                            CORE_3: begin
                                cache_data[victim_set][victim_way] <= core3_write_data;
                                core3_valid <= 1;
                            end
                        endcase
                        
                        mem_read_enable <= 0;
                        state <= STATE_IDLE;
                    end
                end
                
                STATE_EVICT: begin
                    // Evict dirty line to memory
                    if (mem_ready) begin
                        mem_write_enable <= 1;
                        mem_addr <= victim_addr;
                        mem_write_data <= victim_data;
                        eviction_count <= eviction_count + 1;
                        
                        cache_valid[victim_set][victim_way] <= 0;
                        cache_dirty[victim_set][victim_way] <= 0;
                        
                        state <= STATE_WAIT_MEM;
                    end
                end
                
                STATE_WAIT_MEM: begin
                    mem_write_enable <= 0;
                    
                    // Now fetch new data
                    state <= pending_read ? STATE_READ_MISS : STATE_WRITE_MISS;
                    mem_addr <= pending_addr;
                    mem_read_enable <= 1;
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
