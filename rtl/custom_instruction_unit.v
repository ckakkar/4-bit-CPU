// custom_instruction_unit.v - Custom Instruction Extension Unit
// Integrates custom instructions, accelerators, and fusion
// Provides complete custom instruction set extension system

module custom_instruction_unit (
    input clk,
    input rst,
    // CPU interface
    input [15:0] instruction,         // Current instruction
    input [15:0] next_instruction,     // Next instruction (for fusion)
    input instruction_valid,           // Instruction valid
    input next_instruction_valid,      // Next instruction valid
    // Register file interface
    input [7:0] reg_read_data_a,      // Register read port A
    input [7:0] reg_read_data_b,      // Register read port B
    output reg [2:0] reg_read_addr_a, // Register read address A
    output reg [2:0] reg_read_addr_b, // Register read address B
    output reg [2:0] reg_write_addr,  // Register write address
    output reg [7:0] reg_write_data, // Register write data
    output reg reg_write_enable,      // Register write enable
    // Memory interface (for load/store fusion)
    input [7:0] mem_read_data,        // Memory read data
    output reg [7:0] mem_addr,       // Memory address
    output reg mem_read_enable,       // Memory read enable
    output reg mem_write_enable,      // Memory write enable
    output reg [7:0] mem_write_data,  // Memory write data
    // Control signals
    output reg custom_inst_active,    // Custom instruction active
    output reg stall_cpu,              // Stall CPU (waiting for accelerator)
    // Statistics
    output reg [31:0] custom_inst_executed,
    output reg [31:0] fused_inst_executed,
    output reg [31:0] accelerator_cycles
);

    // Custom instruction decoder
    wire [3:0] custom_opcode;
    wire [1:0] accelerator_sel;
    wire [2:0] reg_rs1, reg_rs2, reg_rd;
    wire [7:0] immediate;
    wire custom_inst_valid;
    wire [7:0] accelerator_op;
    wire fusion_enable;
    wire [1:0] fusion_type;
    
    custom_instruction_decoder decoder (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .custom_opcode(custom_opcode),
        .accelerator_sel(accelerator_sel),
        .reg_rs1(reg_rs1),
        .reg_rs2(reg_rs2),
        .reg_rd(reg_rd),
        .immediate(immediate),
        .custom_inst_valid(custom_inst_valid),
        .accelerator_op(accelerator_op),
        .fusion_enable(fusion_enable),
        .fusion_type(fusion_type),
        .custom_inst_count(custom_inst_executed)
    );
    
    // Instruction fusion unit
    wire fusion_detected;
    wire [15:0] fused_instruction;
    wire fused_valid;
    
    instruction_fusion fusion_unit (
        .clk(clk),
        .rst(rst),
        .inst1(instruction),
        .inst2(next_instruction),
        .inst1_valid(instruction_valid),
        .inst2_valid(next_instruction_valid),
        .fusion_detected(fusion_detected),
        .fusion_type(fusion_type),
        .fused_instruction(fused_instruction),
        .fused_valid(fused_valid),
        .fusion_count(fused_inst_executed)
    );
    
    // Tightly-coupled accelerator
    wire accelerator_done, accelerator_error, accelerator_ready;
    wire [7:0] accelerator_data_out [0:15];
    reg [7:0] accelerator_data_in [0:15];
    reg [7:0] accelerator_param [0:15];
    reg accelerator_enable;
    
    tightly_coupled_accelerator accelerator (
        .clk(clk),
        .rst(rst),
        .accelerator_sel(accelerator_sel),
        .accelerator_op(accelerator_op),
        .enable(accelerator_enable),
        .data_in(accelerator_data_in),
        .param(accelerator_param),
        .data_out(accelerator_data_out),
        .done(accelerator_done),
        .error(accelerator_error),
        .ready(accelerator_ready),
        .fusion_enable(fusion_enable),
        .fusion_type(fusion_type),
        .fusion_addr(immediate),
        .total_ops(),
        .fusion_ops(),
        .cycle_count(accelerator_cycles)
    );
    
    // State machine
    reg [2:0] state;
    localparam STATE_IDLE = 3'b000;
    localparam STATE_LOAD = 3'b001;
    localparam STATE_EXECUTE = 3'b010;
    localparam STATE_STORE = 3'b011;
    localparam STATE_DONE = 3'b100;
    
    integer i;
    
    // Initialize
    always @(posedge rst) begin
        state <= STATE_IDLE;
        custom_inst_active <= 0;
        stall_cpu <= 0;
        reg_write_enable <= 0;
        mem_read_enable <= 0;
        mem_write_enable <= 0;
        accelerator_enable <= 0;
    end
    
    // Main control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Already initialized
        end else begin
            reg_write_enable <= 0;
            mem_read_enable <= 0;
            mem_write_enable <= 0;
            accelerator_enable <= 0;
            stall_cpu <= 0;
            
            case (state)
                STATE_IDLE: begin
                    custom_inst_active <= 0;
                    if (custom_inst_valid && instruction_valid) begin
                        custom_inst_active <= 1;
                        stall_cpu <= 1;
                        
                        // Prepare data
                        reg_read_addr_a <= reg_rs1;
                        reg_read_addr_b <= reg_rs2;
                        
                        if (fusion_enable && fusion_type == 2'b01) begin
                            // Load-fuse: load from memory
                            state <= STATE_LOAD;
                            mem_addr <= immediate;
                            mem_read_enable <= 1;
                        end else begin
                            // Normal: use register data
                            accelerator_data_in[0] <= reg_read_data_a;
                            accelerator_data_in[1] <= reg_read_data_b;
                            for (i = 2; i < 16; i = i + 1) begin
                                accelerator_data_in[i] <= 8'b0;
                            end
                            // Load parameters from additional registers (simplified)
                            for (i = 0; i < 16; i = i + 1) begin
                                accelerator_param[i] <= 8'hAA; // Would come from registers
                            end
                            state <= STATE_EXECUTE;
                            accelerator_enable <= 1;
                        end
                    end
                end
                
                STATE_LOAD: begin
                    // Load data from memory (fusion)
                    if (mem_read_data !== 8'hXX) begin // Data available
                        for (i = 0; i < 16; i = i + 1) begin
                            accelerator_data_in[i] <= (i == 0) ? mem_read_data : 8'b0;
                        end
                        mem_read_enable <= 0;
                        state <= STATE_EXECUTE;
                        accelerator_enable <= 1;
                    end
                end
                
                STATE_EXECUTE: begin
                    // Execute accelerator operation
                    if (accelerator_done) begin
                        accelerator_enable <= 0;
                        
                        if (fusion_enable && fusion_type == 2'b10) begin
                            // Store-fuse: store to memory
                            state <= STATE_STORE;
                            mem_addr <= immediate;
                            mem_write_data <= accelerator_data_out[0];
                            mem_write_enable <= 1;
                        end else begin
                            // Normal: write to register
                            reg_write_addr <= reg_rd;
                            reg_write_data <= accelerator_data_out[0];
                            reg_write_enable <= 1;
                            state <= STATE_DONE;
                        end
                    end
                end
                
                STATE_STORE: begin
                    // Store result to memory (fusion)
                    mem_write_enable <= 0;
                    state <= STATE_DONE;
                end
                
                STATE_DONE: begin
                    custom_inst_active <= 0;
                    stall_cpu <= 0;
                    state <= STATE_IDLE;
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
