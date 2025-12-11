// cpu.v - Top-Level CPU Module
// Connects all components: ALU, Register File, Program Counter, Instruction Memory, Control Unit

module cpu (
    input clk,              // Clock signal
    input rst,              // Reset signal
    output halt,            // Halt signal (1 when program finishes)
    output [3:0] pc_out,    // Current PC value (for debugging)
    output [3:0] reg0_out,  // R0 value (for debugging)
    output [3:0] reg1_out,  // R1 value (for debugging)
    output [3:0] reg2_out,  // R2 value (for debugging)
    output [3:0] reg3_out   // R3 value (for debugging)
);

    // Internal wires
    wire [3:0] pc;                  // Program counter
    wire [7:0] instruction;         // Current instruction
    wire [3:0] alu_result;          // ALU output
    wire zero_flag;                 // ALU zero flag
    wire [3:0] reg_read_a;          // Register file output A
    wire [3:0] reg_read_b;          // Register file output B
    wire pc_enable;                 // PC increment enable
    wire pc_load;                   // PC load enable
    wire reg_write_enable;          // Register write enable
    wire [2:0] alu_op;              // ALU operation
    
    // Extract operand from instruction for immediate values
    wire [3:0] immediate = instruction[3:0];
    
    // For this simple CPU, we always write to R0 and read from R0 and R1
    wire [1:0] write_addr = 2'b00;  // Always write to R0
    wire [1:0] read_addr_a = 2'b00; // Always read R0
    wire [1:0] read_addr_b = 2'b01; // Always read R1
    
    // Program Counter
    program_counter pc_unit (
        .clk(clk),
        .rst(rst),
        .enable(pc_enable),
        .load(pc_load),
        .load_addr(immediate),
        .pc(pc)
    );
    
    // Instruction Memory
    instruction_memory imem (
        .address(pc),
        .instruction(instruction)
    );
    
    // Register File
    register_file reg_file (
        .clk(clk),
        .rst(rst),
        .write_enable(reg_write_enable),
        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),
        .write_addr(write_addr),
        .write_data(alu_result),
        .read_data_a(reg_read_a),
        .read_data_b(reg_read_b)
    );
    
    // ALU
    alu alu_unit (
        .operand_a(reg_read_a),
        .operand_b(instruction[7:4] == 4'b0000 ? immediate : reg_read_b), // Use immediate for LOAD
        .alu_op(alu_op),
        .result(alu_result),
        .zero_flag(zero_flag)
    );
    
    // Control Unit
    control_unit control (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .zero_flag(zero_flag),
        .pc_enable(pc_enable),
        .pc_load(pc_load),
        .reg_write_enable(reg_write_enable),
        .alu_op(alu_op),
        .halt(halt)
    );
    
    // Debug outputs
    assign pc_out = pc;
    
    // Connect register outputs for debugging
    assign reg0_out = reg_file.registers[0];
    assign reg1_out = reg_file.registers[1];
    assign reg2_out = reg_file.registers[2];
    assign reg3_out = reg_file.registers[3];

endmodule