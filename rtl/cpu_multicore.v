// cpu_multicore.v - Multi-core CPU system
// Implements 4 CPU cores with shared memory and interconnect

module cpu_multicore (
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

    // Shared memory
    wire [7:0] shared_mem_addr;
    wire [7:0] shared_mem_write_data;
    wire shared_mem_read_enable;
    wire shared_mem_write_enable;
    wire [7:0] shared_mem_read_data;
    wire shared_mem_ready;
    
    // Shared data memory (for multi-core)
    data_memory shared_dmem (
        .clk(clk),
        .rst(rst),
        .write_enable(shared_mem_write_enable),
        .address(shared_mem_addr),
        .write_data(shared_mem_write_data),
        .read_data(shared_mem_read_data)
    );
    assign shared_mem_ready = 1;  // Memory is always ready (simplified)
    
    // Core 0
    wire [7:0] core0_mem_addr, core0_mem_write_data;
    wire core0_mem_read, core0_mem_write;
    wire [7:0] core0_mem_read_data;
    wire core0_mem_ready;
    
    cpu core0 (
        .clk(clk),
        .rst(rst),
        .halt(core0_halt),
        .pc_out(core0_pc),
        .reg0_out(core0_reg0),
        .reg1_out(core0_reg1),
        .reg2_out(core0_reg2),
        .reg3_out(core0_reg3),
        .reg4_out(core0_reg4),
        .reg5_out(core0_reg5),
        .reg6_out(core0_reg6),
        .reg7_out(core0_reg7)
    );
    
    // Core 1
    wire [7:0] core1_mem_addr, core1_mem_write_data;
    wire core1_mem_read, core1_mem_write;
    wire [7:0] core1_mem_read_data;
    wire core1_mem_ready;
    
    cpu core1 (
        .clk(clk),
        .rst(rst),
        .halt(core1_halt),
        .pc_out(core1_pc),
        .reg0_out(),
        .reg1_out(),
        .reg2_out(),
        .reg3_out(),
        .reg4_out(),
        .reg5_out(),
        .reg6_out(),
        .reg7_out()
    );
    
    // Core 2
    wire [7:0] core2_mem_addr, core2_mem_write_data;
    wire core2_mem_read, core2_mem_write;
    wire [7:0] core2_mem_read_data;
    wire core2_mem_ready;
    
    cpu core2 (
        .clk(clk),
        .rst(rst),
        .halt(core2_halt),
        .pc_out(core2_pc),
        .reg0_out(),
        .reg1_out(),
        .reg2_out(),
        .reg3_out(),
        .reg4_out(),
        .reg5_out(),
        .reg6_out(),
        .reg7_out()
    );
    
    // Core 3
    wire [7:0] core3_mem_addr, core3_mem_write_data;
    wire core3_mem_read, core3_mem_write;
    wire [7:0] core3_mem_read_data;
    wire core3_mem_ready;
    
    cpu core3 (
        .clk(clk),
        .rst(rst),
        .halt(core3_halt),
        .pc_out(core3_pc),
        .reg0_out(),
        .reg1_out(),
        .reg2_out(),
        .reg3_out(),
        .reg4_out(),
        .reg5_out(),
        .reg6_out(),
        .reg7_out()
    );
    
    // Interconnect
    multicore_interconnect interconnect (
        .clk(clk),
        .rst(rst),
        .core0_addr(core0_mem_addr),
        .core0_write_data(core0_mem_write_data),
        .core0_read_enable(core0_mem_read),
        .core0_write_enable(core0_mem_write),
        .core0_read_data(core0_mem_read_data),
        .core0_ready(core0_mem_ready),
        .core1_addr(core1_mem_addr),
        .core1_write_data(core1_mem_write_data),
        .core1_read_enable(core1_mem_read),
        .core1_write_enable(core1_mem_write),
        .core1_read_data(core1_mem_read_data),
        .core1_ready(core1_mem_ready),
        .core2_addr(core2_mem_addr),
        .core2_write_data(core2_mem_write_data),
        .core2_read_enable(core2_mem_read),
        .core2_write_enable(core2_mem_write),
        .core2_read_data(core2_mem_read_data),
        .core2_ready(core2_mem_ready),
        .core3_addr(core3_mem_addr),
        .core3_write_data(core3_mem_write_data),
        .core3_read_enable(core3_mem_read),
        .core3_write_enable(core3_mem_write),
        .core3_read_data(core3_mem_read_data),
        .core3_ready(core3_mem_ready),
        .mem_addr(shared_mem_addr),
        .mem_write_data(shared_mem_write_data),
        .mem_read_enable(shared_mem_read_enable),
        .mem_write_enable(shared_mem_write_enable),
        .mem_read_data(shared_mem_read_data),
        .mem_ready(shared_mem_ready)
    );
    
    // System status
    assign cores_running = {!core3_halt, !core2_halt, !core1_halt, !core0_halt};

endmodule
