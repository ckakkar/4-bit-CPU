// cpu_multicore_cached.v - Multi-core CPU system with Multi-Level Cache Hierarchy
// Implements 4 CPU cores with L1 (exclusive), L2 (inclusive), and L3 (shared) caches

module cpu_multicore_cached (
    input clk,
    input rst,
    // Core outputs (for debugging)
    output [7:0] core0_pc, core1_pc, core2_pc, core3_pc,
    output [7:0] core0_reg0, core0_reg1, core0_reg2, core0_reg3,
    output [7:0] core0_reg4, core0_reg5, core0_reg6, core0_reg7,
    output core0_halt, core1_halt, core2_halt, core3_halt,
    // System status
    output [3:0] cores_running  // Bit mask of running cores
);

    // L3 Shared Cache interface signals
    wire [7:0] core0_l3_addr, core1_l3_addr, core2_l3_addr, core3_l3_addr;
    wire core0_l3_read_enable, core1_l3_read_enable, core2_l3_read_enable, core3_l3_read_enable;
    wire core0_l3_write_enable, core1_l3_write_enable, core2_l3_write_enable, core3_l3_write_enable;
    wire [7:0] core0_l3_write_data, core1_l3_write_data, core2_l3_write_data, core3_l3_write_data;
    wire [7:0] core0_l3_read_data, core1_l3_read_data, core2_l3_read_data, core3_l3_read_data;
    wire core0_l3_valid, core1_l3_valid, core2_l3_valid, core3_l3_valid;
    wire core0_l3_ready, core1_l3_ready, core2_l3_ready, core3_l3_ready;
    
    // Main memory interface (backing store for L3)
    wire [7:0] mem_addr;
    wire [7:0] mem_write_data;
    wire mem_read_enable;
    wire mem_write_enable;
    wire [7:0] mem_read_data;
    wire mem_ready;
    
    // Shared data memory (backing store)
    data_memory shared_dmem (
        .clk(clk),
        .rst(rst),
        .write_enable(mem_write_enable),
        .address(mem_addr),
        .write_data(mem_write_data),
        .read_data(mem_read_data)
    );
    assign mem_ready = 1;  // Memory is always ready (simplified)
    
    // Core 0 with cache hierarchy
    cpu_with_cache core0 (
        .clk(clk),
        .rst(rst),
        .core_id(2'b00),
        .halt(core0_halt),
        .pc_out(core0_pc),
        .reg0_out(core0_reg0),
        .reg1_out(core0_reg1),
        .reg2_out(core0_reg2),
        .reg3_out(core0_reg3),
        .reg4_out(core0_reg4),
        .reg5_out(core0_reg5),
        .reg6_out(core0_reg6),
        .reg7_out(core0_reg7),
        .l3_read_data(core0_l3_read_data),
        .l3_valid(core0_l3_valid),
        .l3_ready(core0_l3_ready),
        .l3_addr(core0_l3_addr),
        .l3_read_enable(core0_l3_read_enable),
        .l3_write_enable(core0_l3_write_enable),
        .l3_write_data(core0_l3_write_data)
    );
    
    // Core 1 with cache hierarchy
    cpu_with_cache core1 (
        .clk(clk),
        .rst(rst),
        .core_id(2'b01),
        .halt(core1_halt),
        .pc_out(core1_pc),
        .reg0_out(),
        .reg1_out(),
        .reg2_out(),
        .reg3_out(),
        .reg4_out(),
        .reg5_out(),
        .reg6_out(),
        .reg7_out(),
        .l3_read_data(core1_l3_read_data),
        .l3_valid(core1_l3_valid),
        .l3_ready(core1_l3_ready),
        .l3_addr(core1_l3_addr),
        .l3_read_enable(core1_l3_read_enable),
        .l3_write_enable(core1_l3_write_enable),
        .l3_write_data(core1_l3_write_data)
    );
    
    // Core 2 with cache hierarchy
    cpu_with_cache core2 (
        .clk(clk),
        .rst(rst),
        .core_id(2'b10),
        .halt(core2_halt),
        .pc_out(core2_pc),
        .reg0_out(),
        .reg1_out(),
        .reg2_out(),
        .reg3_out(),
        .reg4_out(),
        .reg5_out(),
        .reg6_out(),
        .reg7_out(),
        .l3_read_data(core2_l3_read_data),
        .l3_valid(core2_l3_valid),
        .l3_ready(core2_l3_ready),
        .l3_addr(core2_l3_addr),
        .l3_read_enable(core2_l3_read_enable),
        .l3_write_enable(core2_l3_write_enable),
        .l3_write_data(core2_l3_write_data)
    );
    
    // Core 3 with cache hierarchy
    cpu_with_cache core3 (
        .clk(clk),
        .rst(rst),
        .core_id(2'b11),
        .halt(core3_halt),
        .pc_out(core3_pc),
        .reg0_out(),
        .reg1_out(),
        .reg2_out(),
        .reg3_out(),
        .reg4_out(),
        .reg5_out(),
        .reg6_out(),
        .reg7_out(),
        .l3_read_data(core3_l3_read_data),
        .l3_valid(core3_l3_valid),
        .l3_ready(core3_l3_ready),
        .l3_addr(core3_l3_addr),
        .l3_read_enable(core3_l3_read_enable),
        .l3_write_enable(core3_l3_write_enable),
        .l3_write_data(core3_l3_write_data)
    );
    
    // L3 Shared Cache (shared between all cores)
    l3_shared_cache l3_cache (
        .clk(clk),
        .rst(rst),
        // Core 0 interface
        .core0_addr(core0_l3_addr),
        .core0_read_enable(core0_l3_read_enable),
        .core0_write_enable(core0_l3_write_enable),
        .core0_write_data(core0_l3_write_data),
        .core0_read_data(core0_l3_read_data),
        .core0_valid(core0_l3_valid),
        .core0_ready(core0_l3_ready),
        // Core 1 interface
        .core1_addr(core1_l3_addr),
        .core1_read_enable(core1_l3_read_enable),
        .core1_write_enable(core1_l3_write_enable),
        .core1_write_data(core1_l3_write_data),
        .core1_read_data(core1_l3_read_data),
        .core1_valid(core1_l3_valid),
        .core1_ready(core1_l3_ready),
        // Core 2 interface
        .core2_addr(core2_l3_addr),
        .core2_read_enable(core2_l3_read_enable),
        .core2_write_enable(core2_l3_write_enable),
        .core2_write_data(core2_l3_write_data),
        .core2_read_data(core2_l3_read_data),
        .core2_valid(core2_l3_valid),
        .core2_ready(core2_l3_ready),
        // Core 3 interface
        .core3_addr(core3_l3_addr),
        .core3_read_enable(core3_l3_read_enable),
        .core3_write_enable(core3_l3_write_enable),
        .core3_write_data(core3_l3_write_data),
        .core3_read_data(core3_l3_read_data),
        .core3_valid(core3_l3_valid),
        .core3_ready(core3_l3_ready),
        // Main memory interface
        .mem_read_data(mem_read_data),
        .mem_valid(mem_ready),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_read_enable(mem_read_enable),
        .mem_write_enable(mem_write_enable),
        .mem_write_data(mem_write_data),
        // Statistics
        .hit_count(),
        .miss_count(),
        .eviction_count()
    );
    
    // System status
    assign cores_running = {!core3_halt, !core2_halt, !core1_halt, !core0_halt};

endmodule
