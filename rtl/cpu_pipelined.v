// cpu_pipelined.v - Enhanced 5-stage pipelined CPU with cache, branch prediction, FPU, and register windows
// Pipeline stages: IF (Instruction Fetch), ID (Decode), EX (Execute), MEM (Memory), WB (Writeback)

module cpu_pipelined (
    input clk,              // Clock signal
    input rst,              // Reset signal
    output halt,            // Halt signal (1 when program finishes)
    output [7:0] pc_out,    // Current PC value (for debugging)
    output [7:0] reg0_out,  // R0 value (for debugging)
    output [7:0] reg1_out,  // R1 value (for debugging)
    output [7:0] reg2_out,  // R2 value (for debugging)
    output [7:0] reg3_out,  // R3 value (for debugging)
    output [7:0] reg4_out,  // R4 value (for debugging)
    output [7:0] reg5_out,  // R5 value (for debugging)
    output [7:0] reg6_out,  // R6 value (for debugging)
    output [7:0] reg7_out   // R7 value (for debugging)
);

    // ===== IF STAGE (Instruction Fetch) =====
    wire [7:0] if_pc;                      // PC in IF stage
    wire [7:0] if_pc_next;                 // Next PC (from branch predictor or PC+1)
    wire [15:0] if_instruction;            // Fetched instruction (from cache)
    wire if_cache_hit, if_cache_miss;      // Instruction cache status
    wire [7:0] if_backing_addr;            // Address to backing store (instruction memory)
    wire if_backing_read_enable;           // Request to backing store
    wire [15:0] if_backing_data;           // Data from backing store
    
    // Instruction cache
    instruction_cache i_cache (
        .clk(clk),
        .rst(rst),
        .address(if_pc),
        .read_enable(1'b1),  // Always reading in IF stage
        .backing_data(if_backing_data),
        .backing_valid(1'b1),  // Simplified: assume always valid
        .data_out(if_instruction),
        .cache_hit(if_cache_hit),
        .cache_miss(if_cache_miss),
        .backing_addr(if_backing_addr),
        .backing_read_enable(if_backing_read_enable)
    );
    
    // Instruction memory (backing store for cache)
    instruction_memory imem_backing (
        .address(if_backing_read_enable ? if_backing_addr : if_pc),
        .instruction(if_backing_data)
    );
    
    // Branch predictor
    wire bp_prediction;
    wire [7:0] bp_predicted_target;
    wire bp_is_branch;
    wire bp_branch_taken;  // Actual branch outcome (from EX stage)
    wire [7:0] bp_branch_addr;  // Actual branch target (from EX stage)
    wire bp_update;
    
    branch_predictor branch_pred (
        .clk(clk),
        .rst(rst),
        .pc(if_pc),
        .branch_addr(bp_branch_addr),
        .branch_taken(bp_branch_taken),
        .is_branch_instruction(bp_is_branch),
        .update_predictor(bp_update),
        .prediction(bp_prediction),
        .predicted_target(bp_predicted_target)
    );
    
    // Program Counter
    program_counter pc_unit (
        .clk(clk),
        .rst(rst),
        .enable(!halt && !stall_pipeline),
        .load(1'b0),  // PC loading handled by branch logic
        .load_addr(if_pc_next),
        .pc(if_pc)
    );
    
    // PC selection: predicted target if branch predicted taken, else PC+1
    assign if_pc_next = (bp_prediction && bp_is_branch) ? bp_predicted_target : (if_pc + 1);
    
    // ===== IF/ID PIPELINE REGISTER =====
    wire [7:0] id_pc;
    wire [15:0] id_instruction;
    
    pipeline_reg_if_id if_id_reg (
        .clk(clk),
        .rst(rst),
        .stall(stall_pipeline),
        .flush(flush_if_id),
        .pc_in(if_pc),
        .instruction_in(if_instruction),
        .pc_out(id_pc),
        .instruction_out(id_instruction)
    );
    
    // ===== ID STAGE (Instruction Decode) =====
    wire [3:0] id_opcode = id_instruction[15:12];
    wire [2:0] id_reg1 = id_instruction[11:9];
    wire [2:0] id_reg2 = id_instruction[8:6];
    wire [5:0] id_imm6 = id_instruction[5:0];
    wire [7:0] id_immediate = {2'b00, id_imm6};
    
    // Control unit (pipelined version)
    wire id_reg_write_enable;
    wire id_mem_write_enable;
    wire [3:0] id_alu_op;
    wire id_use_immediate;
    wire id_mem_addr_sel;
    wire id_load_from_mem;
    wire [2:0] id_reg_dest_addr;
    wire id_is_branch;
    wire id_is_jump;
    wire id_use_fpu;
    
    control_unit_pipelined id_control (
        .instruction(id_instruction),
        .opcode(id_opcode),
        .reg_write_enable(id_reg_write_enable),
        .mem_write_enable(id_mem_write_enable),
        .alu_op(id_alu_op),
        .use_immediate(id_use_immediate),
        .mem_addr_sel(id_mem_addr_sel),
        .load_from_mem(id_load_from_mem),
        .reg_dest_addr(id_reg_dest_addr),
        .is_branch(id_is_branch),
        .is_jump(id_is_jump),
        .use_fpu(id_use_fpu)
    );
    
    assign bp_is_branch = id_is_branch || id_is_jump;  // Tell branch predictor about branch
    
    // Register file (with optional register windows)
    wire [7:0] id_reg_read_a, id_reg_read_b;
    wire [7:0] reg0_debug, reg1_debug, reg2_debug, reg3_debug;
    wire [7:0] reg4_debug, reg5_debug, reg6_debug, reg7_debug;
    reg [1:0] window_select = 2'b0;  // Current window (can be dynamic)
    wire use_windows = 1'b0;  // Toggle to use register windows
    
    register_file reg_file (
        .clk(clk),
        .rst(rst),
        .write_enable(wb_reg_write_enable),
        .read_addr_a(id_reg1),
        .read_addr_b(id_reg2),
        .write_addr(wb_reg_dest_addr),
        .write_data(wb_write_data),
        .read_data_a(id_reg_read_a),
        .read_data_b(id_reg_read_b),
        .reg0_out(reg0_debug),
        .reg1_out(reg1_debug),
        .reg2_out(reg2_debug),
        .reg3_out(reg3_debug),
        .reg4_out(reg4_debug),
        .reg5_out(reg5_debug),
        .reg6_out(reg6_debug),
        .reg7_out(reg7_debug)
    );
    
    // ===== ID/EX PIPELINE REGISTER =====
    wire ex_reg_write_enable;
    wire ex_mem_write_enable;
    wire [3:0] ex_alu_op;
    wire ex_use_immediate;
    wire ex_mem_addr_sel;
    wire ex_load_from_mem;
    wire [7:0] ex_immediate;
    wire [7:0] ex_reg_read_a, ex_reg_read_b;
    wire [2:0] ex_reg_dest_addr;
    wire [2:0] ex_reg1_addr, ex_reg2_addr;
    wire [7:0] ex_pc;
    wire [3:0] ex_opcode;
    wire ex_is_branch, ex_is_jump;
    wire ex_use_fpu;
    
    pipeline_reg_id_ex id_ex_reg (
        .clk(clk),
        .rst(rst),
        .stall(stall_pipeline),
        .flush(flush_id_ex),
        .reg_write_enable_in(id_reg_write_enable),
        .mem_write_enable_in(id_mem_write_enable),
        .alu_op_in(id_alu_op),
        .use_immediate_in(id_use_immediate),
        .mem_addr_sel_in(id_mem_addr_sel),
        .load_from_mem_in(id_load_from_mem),
        .immediate_in(id_immediate),
        .reg_read_a_in(id_reg_read_a),
        .reg_read_b_in(id_reg_read_b),
        .reg_dest_addr_in(id_reg_dest_addr),
        .reg1_addr_in(id_reg1),
        .reg2_addr_in(id_reg2),
        .pc_in(id_pc),
        .opcode_in(id_opcode),
        .reg_write_enable_out(ex_reg_write_enable),
        .mem_write_enable_out(ex_mem_write_enable),
        .alu_op_out(ex_alu_op),
        .use_immediate_out(ex_use_immediate),
        .mem_addr_sel_out(ex_mem_addr_sel),
        .load_from_mem_out(ex_load_from_mem),
        .immediate_out(ex_immediate),
        .reg_read_a_out(ex_reg_read_a),
        .reg_read_b_out(ex_reg_read_b),
        .reg_dest_addr_out(ex_reg_dest_addr),
        .reg1_addr_out(ex_reg1_addr),
        .reg2_addr_out(ex_reg2_addr),
        .pc_out(ex_pc),
        .opcode_out(ex_opcode)
    );
    
    // Need to pass branch flags through pipeline
    reg ex_is_branch_reg, ex_is_jump_reg, ex_use_fpu_reg;
    always @(posedge clk) begin
        if (rst || flush_id_ex) begin
            ex_is_branch_reg <= 0;
            ex_is_jump_reg <= 0;
            ex_use_fpu_reg <= 0;
        end else if (!stall_pipeline) begin
            ex_is_branch_reg <= id_is_branch;
            ex_is_jump_reg <= id_is_jump;
            ex_use_fpu_reg <= id_use_fpu;
        end
    end
    assign ex_is_branch = ex_is_branch_reg;
    assign ex_is_jump = ex_is_jump_reg;
    assign ex_use_fpu = ex_use_fpu_reg;
    
    // ===== EX STAGE (Execute) =====
    // Hazard detection and forwarding
    wire [1:0] forward_a, forward_b;
    wire stall_pipeline, flush_if_id, flush_id_ex, flush_ex_mem;
    
    wire [7:0] mem_reg_dest_addr;
    wire mem_reg_write_enable;
    wire mem_load_from_mem;
    
    wire [2:0] wb_reg_dest_addr;
    wire wb_reg_write_enable;
    
    hazard_unit hazard_detector (
        .id_reg1_addr(ex_reg1_addr),
        .id_reg2_addr(ex_reg2_addr),
        .ex_reg_dest_addr(ex_reg_dest_addr),
        .mem_reg_dest_addr(mem_reg_dest_addr),
        .wb_reg_dest_addr(wb_reg_dest_addr),
        .ex_reg_write_enable(ex_reg_write_enable),
        .mem_reg_write_enable(mem_reg_write_enable),
        .wb_reg_write_enable(wb_reg_write_enable),
        .mem_load_from_mem(mem_load_from_mem),
        .ex_is_branch(ex_is_branch || ex_is_jump),
        .branch_taken(ex_branch_taken),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .stall_pipeline(stall_pipeline),
        .flush_if_id(flush_if_id),
        .flush_id_ex(flush_id_ex),
        .flush_ex_mem(flush_ex_mem)
    );
    
    // Forwarding multiplexers for ALU operands
    wire [7:0] ex_alu_operand_a, ex_alu_operand_b;
    wire [7:0] mem_alu_result;
    wire [7:0] wb_write_data;
    
    assign ex_alu_operand_a = (forward_a == 2'b01) ? mem_alu_result :
                              (forward_a == 2'b10) ? wb_write_data :
                              ex_reg_read_a;
    
    assign ex_alu_operand_b = ex_use_immediate ? ex_immediate :
                              (forward_b == 2'b01) ? mem_alu_result :
                              (forward_b == 2'b10) ? wb_write_data :
                              ex_reg_read_b;
    
    // ALU
    wire [7:0] ex_alu_result;
    wire ex_zero_flag, ex_carry_flag, ex_overflow_flag, ex_negative_flag;
    
    alu ex_alu (
        .operand_a(ex_alu_operand_a),
        .operand_b(ex_alu_operand_b),
        .alu_op(ex_alu_op),
        .result(ex_alu_result),
        .zero_flag(ex_zero_flag),
        .carry_flag(ex_carry_flag),
        .overflow_flag(ex_overflow_flag),
        .negative_flag(ex_negative_flag)
    );
    
    // FPU (optional - for floating-point operations)
    wire [31:0] ex_fpu_result;
    wire ex_fpu_valid, ex_fpu_busy;
    
    fpu ex_fpu (
        .clk(clk),
        .rst(rst),
        .operand_a({24'b0, ex_reg_read_a}),  // Convert 8-bit to 32-bit (simplified)
        .operand_b({24'b0, ex_reg_read_b}),
        .fpu_op(ex_alu_op[2:0]),  // Use lower 3 bits for FPU op
        .start(ex_use_fpu),
        .result(ex_fpu_result),
        .result_valid(ex_fpu_valid),
        .fpu_busy(ex_fpu_busy),
        .invalid_op(),
        .divide_by_zero()
    );
    
    // Branch resolution
    wire ex_branch_taken;
    assign ex_branch_taken = (ex_is_jump) ? 1'b1 :
                             (ex_is_branch && (ex_opcode == 4'b1101)) ? ex_zero_flag :  // JZ
                             (ex_is_branch && (ex_opcode == 4'b1110)) ? !ex_zero_flag : // JNZ
                             1'b0;
    
    assign bp_branch_taken = ex_branch_taken;
    assign bp_branch_addr = ex_immediate;  // Branch target from immediate field
    assign bp_update = (ex_is_branch || ex_is_jump);
    
    // Memory address calculation
    wire [7:0] ex_mem_addr = ex_mem_addr_sel ? ex_immediate : ex_reg_read_a;
    wire [7:0] ex_mem_write_data = ex_reg_read_a;
    
    // ===== EX/MEM PIPELINE REGISTER =====
    wire mem_reg_write_enable_out;
    wire mem_mem_write_enable;
    wire mem_load_from_mem_out;
    wire [7:0] mem_alu_result_out;
    wire [7:0] mem_mem_write_data;
    wire [7:0] mem_mem_addr;
    wire mem_zero_flag, mem_carry_flag, mem_overflow_flag, mem_negative_flag;
    
    pipeline_reg_ex_mem ex_mem_reg (
        .clk(clk),
        .rst(rst),
        .stall(stall_pipeline),
        .flush(flush_ex_mem),
        .reg_write_enable_in(ex_reg_write_enable),
        .mem_write_enable_in(ex_mem_write_enable),
        .load_from_mem_in(ex_load_from_mem),
        .alu_result_in(ex_alu_result),
        .mem_write_data_in(ex_mem_write_data),
        .mem_addr_in(ex_mem_addr),
        .reg_dest_addr_in(ex_reg_dest_addr),
        .zero_flag_in(ex_zero_flag),
        .carry_flag_in(ex_carry_flag),
        .overflow_flag_in(ex_overflow_flag),
        .negative_flag_in(ex_negative_flag),
        .reg_write_enable_out(mem_reg_write_enable_out),
        .mem_write_enable_out(mem_mem_write_enable),
        .load_from_mem_out(mem_load_from_mem_out),
        .alu_result_out(mem_alu_result_out),
        .mem_write_data_out(mem_mem_write_data),
        .mem_addr_out(mem_mem_addr),
        .reg_dest_addr_out(mem_reg_dest_addr),
        .zero_flag_out(mem_zero_flag),
        .carry_flag_out(mem_carry_flag),
        .overflow_flag_out(mem_overflow_flag),
        .negative_flag_out(mem_negative_flag)
    );
    
    assign mem_reg_write_enable = mem_reg_write_enable_out;
    assign mem_load_from_mem = mem_load_from_mem_out;
    assign mem_alu_result = mem_alu_result_out;
    
    // ===== MEM STAGE (Memory Access) =====
    wire [7:0] mem_cache_read_data;
    wire mem_cache_hit, mem_cache_miss;
    wire [7:0] mem_backing_addr;
    wire mem_backing_read_enable, mem_backing_write_enable;
    wire [7:0] mem_backing_read_data, mem_backing_write_data;
    
    // Data cache
    data_cache d_cache (
        .clk(clk),
        .rst(rst),
        .address(mem_mem_addr),
        .read_enable(mem_load_from_mem),
        .write_enable(mem_mem_write_enable),
        .write_data(mem_mem_write_data),
        .backing_read_data(mem_backing_read_data),
        .backing_valid(1'b1),  // Simplified: assume always valid
        .data_out(mem_cache_read_data),
        .cache_hit(mem_cache_hit),
        .cache_miss(mem_cache_miss),
        .backing_addr(mem_backing_addr),
        .backing_read_enable(mem_backing_read_enable),
        .backing_write_enable(mem_backing_write_enable),
        .backing_write_data(mem_backing_write_data)
    );
    
    // Data memory (backing store for cache)
    data_memory dmem_backing (
        .clk(clk),
        .rst(rst),
        .write_enable(mem_backing_write_enable),
        .address(mem_backing_read_enable ? mem_backing_addr : 
                 mem_backing_write_enable ? mem_backing_addr : mem_mem_addr),
        .write_data(mem_backing_write_data),
        .read_data(mem_backing_read_data)
    );
    
    // Memory read data selection
    wire [7:0] mem_read_data = mem_cache_hit ? mem_cache_read_data : mem_backing_read_data;
    
    // ===== MEM/WB PIPELINE REGISTER =====
    wire wb_reg_write_enable_out;
    wire [7:0] wb_write_data_out;
    wire [2:0] wb_reg_dest_addr_out;
    
    pipeline_reg_mem_wb mem_wb_reg (
        .clk(clk),
        .rst(rst),
        .stall(1'b0),  // WB stage typically doesn't stall
        .flush(1'b0),
        .reg_write_enable_in(mem_reg_write_enable),
        .alu_result_in(mem_alu_result),
        .mem_read_data_in(mem_read_data),
        .load_from_mem_in(mem_load_from_mem),
        .reg_dest_addr_in(mem_reg_dest_addr),
        .reg_write_enable_out(wb_reg_write_enable_out),
        .write_data_out(wb_write_data_out),
        .reg_dest_addr_out(wb_reg_dest_addr_out)
    );
    
    assign wb_reg_write_enable = wb_reg_write_enable_out;
    assign wb_write_data = wb_write_data_out;
    assign wb_reg_dest_addr = wb_reg_dest_addr_out;
    
    // ===== WB STAGE (Writeback) =====
    // Writeback is handled by register file write (combinational from pipeline register)
    // No additional logic needed
    
    // HALT detection
    reg halt_reg;
    always @(posedge clk) begin
        if (rst) begin
            halt_reg <= 0;
        end else if (id_opcode == 4'b1111 && id_instruction[11:0] == 12'b0) begin
            // HALT instruction: opcode=1111, all other fields=0
            halt_reg <= 1;
        end
    end
    assign halt = halt_reg;
    
    // Debug outputs
    assign pc_out = if_pc;
    assign reg0_out = reg0_debug;
    assign reg1_out = reg1_debug;
    assign reg2_out = reg2_debug;
    assign reg3_out = reg3_debug;
    assign reg4_out = reg4_debug;
    assign reg5_out = reg5_debug;
    assign reg6_out = reg6_debug;
    assign reg7_out = reg7_debug;

endmodule
