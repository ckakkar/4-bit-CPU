// cache_hierarchy.v - Multi-Level Cache Hierarchy Controller
// Manages L1 (exclusive), L2 (inclusive), and L3 (shared) cache interactions
// Optimizes for different access patterns

module cache_hierarchy (
    input clk,
    input rst,
    input [1:0] core_id,               // Core identifier (0-3)
    // CPU interface
    input [7:0] cpu_addr,
    input cpu_read_enable,
    input cpu_write_enable,
    input [7:0] cpu_write_data,
    output reg [7:0] cpu_read_data,
    output reg cpu_ready,
    // L3 interface (shared)
    input [7:0] l3_read_data,
    input l3_valid,
    input l3_ready,
    output reg [7:0] l3_addr,
    output reg l3_read_enable,
    output reg l3_write_enable,
    output reg [7:0] l3_write_data,
    // Statistics
    output reg [31:0] l1_hits,
    output reg [31:0] l1_misses,
    output reg [31:0] l2_hits,
    output reg [31:0] l2_misses,
    output reg [31:0] l3_hits,
    output reg [31:0] l3_misses
);

    // L1 cache instance
    wire [7:0] l1_data_out;
    wire l1_cache_hit, l1_cache_miss, l1_ready;
    wire [7:0] l1_l2_addr;
    wire l1_l2_read_enable, l1_l2_write_enable;
    wire [7:0] l1_l2_write_data;
    
    l1_exclusive_cache l1_cache (
        .clk(clk),
        .rst(rst),
        .address(cpu_addr),
        .read_enable(cpu_read_enable),
        .write_enable(cpu_write_enable),
        .write_data(cpu_write_data),
        .l2_read_data(l2_to_l1_data),
        .l2_valid(l2_to_l1_valid),
        .l2_ready(l2_ready_for_l1),
        .l2_addr(l1_l2_addr),
        .l2_read_enable(l1_l2_read_enable),
        .l2_write_enable(l1_l2_write_enable),
        .l2_write_data(l1_l2_write_data),
        .data_out(l1_data_out),
        .cache_hit(l1_cache_hit),
        .cache_miss(l1_cache_miss),
        .ready(l1_ready),
        .hit_count(),
        .miss_count(),
        .eviction_count()
    );
    
    // L2 cache instance
    wire [7:0] l2_data_out;
    wire l2_cache_hit, l2_cache_miss, l2_ready;
    wire [7:0] l2_l3_addr;
    wire l2_l3_read_enable, l2_l3_write_enable;
    wire [7:0] l2_l3_write_data;
    wire [7:0] l2_to_l1_data;
    wire l2_to_l1_valid;
    wire l2_ready_for_l1;
    
    l2_inclusive_cache l2_cache (
        .clk(clk),
        .rst(rst),
        .address(l1_l2_addr),  // Use address from L1
        .read_enable(1'b0),  // CPU doesn't directly access L2
        .write_enable(1'b0),
        .write_data(8'b0),
        .l1_addr(l1_l2_addr),
        .l1_read_enable(l1_l2_read_enable),
        .l1_write_enable(l1_l2_write_enable),
        .l1_write_data(l1_l2_write_data),
        .l1_ready(l1_ready),
        .l1_read_data(l2_to_l1_data),
        .l1_valid(l2_to_l1_valid),
        .l3_read_data(l3_to_l2_data),
        .l3_valid(l3_to_l2_valid),
        .l3_ready(l3_ready_for_l2),
        .l3_addr(l2_l3_addr),
        .l3_read_enable(l2_l3_read_enable),
        .l3_write_enable(l2_l3_write_enable),
        .l3_write_data(l2_l3_write_data),
        .data_out(l2_data_out),
        .cache_hit(l2_cache_hit),
        .cache_miss(l2_cache_miss),
        .ready(l2_ready),
        .hit_count(),
        .miss_count(),
        .eviction_count()
    );
    
    // L3 interface signals
    wire [7:0] l3_to_l2_data;
    wire l3_to_l2_valid;
    wire l3_ready_for_l2;
    
    // Connect L2 to L3
    always @(*) begin
        l3_addr = l2_l3_addr;
        l3_read_enable = l2_l3_read_enable;
        l3_write_enable = l2_l3_write_enable;
        l3_write_data = l2_l3_write_data;
    end
    
    assign l3_to_l2_data = l3_read_data;
    assign l3_to_l2_valid = l3_valid;
    assign l3_ready_for_l2 = l3_ready;
    assign l2_ready_for_l1 = l2_ready;
    
    // Statistics tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            l1_hits <= 32'b0;
            l1_misses <= 32'b0;
            l2_hits <= 32'b0;
            l2_misses <= 32'b0;
            l3_hits <= 32'b0;
            l3_misses <= 32'b0;
        end else begin
            if (l1_cache_hit) l1_hits <= l1_hits + 1;
            if (l1_cache_miss) l1_misses <= l1_misses + 1;
            // L2 hits/misses tracked internally
            // L3 hits/misses would be tracked in L3 module
        end
    end
    
    // CPU interface - data flows through L1
    always @(*) begin
        cpu_read_data = l1_data_out;
        cpu_ready = l1_ready;
    end
    
    // Access pattern optimization
    // Sequential access: prefetch next line
    // Random access: no prefetch
    // Streaming access: aggressive prefetch
    reg [7:0] last_addr;
    reg [1:0] access_pattern;  // 0=random, 1=sequential, 2=streaming
    
    always @(posedge clk) begin
        if (cpu_read_enable || cpu_write_enable) begin
            // Detect access pattern
            if (cpu_addr == last_addr + 1) begin
                access_pattern <= 2'b01;  // Sequential
            end else if (cpu_addr == last_addr + 2) begin
                access_pattern <= 2'b10;  // Streaming (stride 2)
            end else begin
                access_pattern <= 2'b00;  // Random
            end
            last_addr <= cpu_addr;
        end
    end

endmodule
