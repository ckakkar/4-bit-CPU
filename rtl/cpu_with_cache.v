// cpu_with_cache.v - CPU with Multi-Level Cache Hierarchy
// Integrates L1 (exclusive), L2 (inclusive), and L3 (shared) caches

module cpu_with_cache (
    input clk,
    input rst,
    input [1:0] core_id,               // Core identifier (0-3)
    output halt,                      // Halt signal
    output [7:0] pc_out,              // Current PC value
    output [7:0] reg0_out,             // R0 value
    output [7:0] reg1_out,            // R1 value
    output [7:0] reg2_out,            // R2 value
    output [7:0] reg3_out,            // R3 value
    output [7:0] reg4_out,            // R4 value
    output [7:0] reg5_out,            // R5 value
    output [7:0] reg6_out,            // R6 value
    output [7:0] reg7_out,            // R7 value
    // L3 cache interface (shared)
    input [7:0] l3_read_data,
    input l3_valid,
    input l3_ready,
    output [7:0] l3_addr,
    output l3_read_enable,
    output l3_write_enable,
    output [7:0] l3_write_data
);

    // Internal CPU signals
    wire [7:0] pc;
    wire [15:0] instruction;
    wire [7:0] alu_result;
    wire zero_flag, carry_flag, overflow_flag, negative_flag;
    wire [7:0] reg_read_a, reg_read_b;
    wire [7:0] mem_read_data;
    wire [7:0] mem_addr;
    wire pc_enable, pc_load;
    wire reg_write_enable;
    wire mem_write_enable;
    wire [3:0] alu_op;
    wire [2:0] reg1_addr, reg2_addr, reg_dest_addr;
    wire [7:0] immediate;
    wire use_immediate;
    wire mem_addr_sel;
    wire load_from_mem;
    
    // ALU operand selection
    wire [7:0] alu_operand_b = use_immediate ? immediate : reg_read_b;
    
    // Memory address selection
    assign mem_addr = mem_addr_sel ? immediate : reg_read_a;
    
    // Register write data selection
    wire [7:0] reg_write_data = load_from_mem ? mem_read_data : alu_result;
    
    // Program Counter
    program_counter pc_unit (
        .clk(clk),
        .rst(rst),
        .enable(pc_enable),
        .load(pc_load),
        .load_addr(immediate[7:0]),
        .pc(pc)
    );
    
    // Instruction Memory (no cache for instructions in this version)
    instruction_memory imem (
        .address(pc),
        .instruction(instruction)
    );
    
    // Register File
    wire [7:0] reg0_debug, reg1_debug, reg2_debug, reg3_debug;
    wire [7:0] reg4_debug, reg5_debug, reg6_debug, reg7_debug;
    
    register_file reg_file (
        .clk(clk),
        .rst(rst),
        .write_enable(reg_write_enable),
        .read_addr_a(reg1_addr),
        .read_addr_b(reg2_addr),
        .write_addr(reg_dest_addr),
        .write_data(reg_write_data),
        .read_data_a(reg_read_a),
        .read_data_b(reg_read_b),
        .reg0_out(reg0_debug),
        .reg1_out(reg1_debug),
        .reg2_out(reg2_debug),
        .reg3_out(reg3_debug),
        .reg4_out(reg4_debug),
        .reg5_out(reg5_debug),
        .reg6_out(reg6_debug),
        .reg7_out(reg7_debug)
    );
    
    // Multi-Level Cache Hierarchy (for data memory)
    wire [7:0] cache_read_data;
    wire cache_ready;
    wire cpu_read_enable = load_from_mem && !mem_write_enable;
    
    cache_hierarchy cache_hier (
        .clk(clk),
        .rst(rst),
        .core_id(core_id),
        .cpu_addr(mem_addr),
        .cpu_read_enable(cpu_read_enable),
        .cpu_write_enable(mem_write_enable),
        .cpu_write_data(reg_read_a),
        .cpu_read_data(cache_read_data),
        .cpu_ready(cache_ready),
        .l3_read_data(l3_read_data),
        .l3_valid(l3_valid),
        .l3_ready(l3_ready),
        .l3_addr(l3_addr),
        .l3_read_enable(l3_read_enable),
        .l3_write_enable(l3_write_enable),
        .l3_write_data(l3_write_data),
        .l1_hits(),
        .l1_misses(),
        .l2_hits(),
        .l2_misses(),
        .l3_hits(),
        .l3_misses()
    );
    
    // Memory read data comes from cache
    assign mem_read_data = cache_read_data;
    
    // ALU
    alu alu_unit (
        .operand_a(reg_read_a),
        .operand_b(alu_operand_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero_flag(zero_flag),
        .carry_flag(carry_flag),
        .overflow_flag(overflow_flag),
        .negative_flag(negative_flag)
    );
    
    // Control Unit
    control_unit control (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .zero_flag(zero_flag),
        .carry_flag(carry_flag),
        .overflow_flag(overflow_flag),
        .negative_flag(negative_flag),
        .pc_enable(pc_enable),
        .pc_load(pc_load),
        .reg_write_enable(reg_write_enable),
        .mem_write_enable(mem_write_enable),
        .alu_op(alu_op),
        .reg1_addr(reg1_addr),
        .reg2_addr(reg2_addr),
        .reg_dest_addr(reg_dest_addr),
        .immediate(immediate),
        .use_immediate(use_immediate),
        .mem_addr_sel(mem_addr_sel),
        .load_from_mem(load_from_mem),
        .halt(halt)
    );
    
    // Debug outputs
    assign pc_out = pc;
    assign reg0_out = reg0_debug;
    assign reg1_out = reg1_debug;
    assign reg2_out = reg2_debug;
    assign reg3_out = reg3_debug;
    assign reg4_out = reg4_debug;
    assign reg5_out = reg5_debug;
    assign reg6_out = reg6_debug;
    assign reg7_out = reg7_debug;

endmodule
