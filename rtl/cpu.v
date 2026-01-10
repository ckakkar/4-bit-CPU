// cpu.v - enhanced top level CPU
// Wires up the ALU, register file, program counter, instruction memory, data memory and control unit

module cpu (
    input clk,              // Clock signal
    input rst,              // Reset signal
    output halt,            // Halt signal (1 when program finishes)
    output [7:0] pc_out,    // Current PC value (for debugging, expanded to 8-bit)
    output [7:0] reg0_out,  // R0 value (for debugging, expanded to 8-bit)
    output [7:0] reg1_out,  // R1 value (for debugging)
    output [7:0] reg2_out,  // R2 value (for debugging)
    output [7:0] reg3_out,  // R3 value (for debugging)
    output [7:0] reg4_out,  // R4 value (for debugging)
    output [7:0] reg5_out,  // R5 value (for debugging)
    output [7:0] reg6_out,  // R6 value (for debugging)
    output [7:0] reg7_out   // R7 value (for debugging)
);

    // Internal wires (expanded to 8-bit datapath)
    wire [7:0] pc;                      // Program counter (8-bit)
    wire [15:0] instruction;            // Current instruction (16-bit)
    wire [7:0] alu_result;              // ALU output (8-bit)
    wire zero_flag, carry_flag, overflow_flag, negative_flag;  // ALU status flags
    wire [7:0] reg_read_a;              // Register file output A (8-bit)
    wire [7:0] reg_read_b;              // Register file output B (8-bit)
    wire [7:0] mem_read_data;           // Data memory read output
    wire [7:0] mem_addr;                // Data memory address
    wire pc_enable;                     // PC increment enable
    wire pc_load;                       // PC load enable
    wire reg_write_enable;              // Register write enable
    wire mem_write_enable;              // Memory write enable
    wire [3:0] alu_op;                  // ALU operation (expanded to 4 bits)
    wire [2:0] reg1_addr, reg2_addr, reg_dest_addr;  // Register addresses (3 bits)
    wire [7:0] immediate;               // Immediate value (8-bit)
    wire use_immediate;                 // Use immediate as ALU operand
    wire mem_addr_sel;                  // Memory address source select
    wire load_from_mem;                 // Load data from memory instead of ALU
    
    // ALU operand selection
    wire [7:0] alu_operand_b = use_immediate ? immediate : reg_read_b;
    
    // Memory address selection
    assign mem_addr = mem_addr_sel ? immediate : reg_read_a;
    
    // Register write data selection: memory data for LOAD, ALU result otherwise
    wire [7:0] reg_write_data = load_from_mem ? mem_read_data : alu_result;
    
    // Program Counter (expanded to 8-bit)
    program_counter pc_unit (
        .clk(clk),
        .rst(rst),
        .enable(pc_enable),
        .load(pc_load),
        .load_addr(immediate[7:0]),  // Use immediate field for jump address
        .pc(pc)
    );
    
    // Instruction Memory (16-bit instructions, 8-bit addresses)
    instruction_memory imem (
        .address(pc),
        .instruction(instruction)
    );
    
    // Register File (8 registers, 8-bit wide)
    wire [7:0] reg0_debug, reg1_debug, reg2_debug, reg3_debug;
    wire [7:0] reg4_debug, reg5_debug, reg6_debug, reg7_debug;
    
    register_file reg_file (
        .clk(clk),
        .rst(rst),
        .write_enable(reg_write_enable),
        .read_addr_a(reg1_addr),
        .read_addr_b(reg2_addr),
        .write_addr(reg_dest_addr),
        .write_data(reg_write_data),  // Selected write data (memory or ALU)
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
    
    // Data Memory (separate from instruction memory - Harvard architecture)
    data_memory dmem (
        .clk(clk),
        .rst(rst),
        .write_enable(mem_write_enable),
        .address(mem_addr),
        .write_data(reg_read_a),  // Store register value to memory
        .read_data(mem_read_data)
    );
    
    // ALU (8-bit with expanded operations and status flags)
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
    
    // Control Unit (handles 16-bit instruction format)
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
    
    // Connect register outputs for debugging (all 8 registers)
    assign reg0_out = reg0_debug;
    assign reg1_out = reg1_debug;
    assign reg2_out = reg2_debug;
    assign reg3_out = reg3_debug;
    assign reg4_out = reg4_debug;
    assign reg5_out = reg5_debug;
    assign reg6_out = reg6_debug;
    assign reg7_out = reg7_debug;
    
endmodule