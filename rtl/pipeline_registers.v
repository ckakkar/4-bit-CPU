// pipeline_registers.v - Pipeline stage registers for 5-stage pipeline
// Implements IF/ID, ID/EX, EX/MEM, MEM/WB pipeline registers

module pipeline_reg_if_id (
    input clk,
    input rst,
    input stall,
    input flush,
    input [7:0] pc_in,
    input [15:0] instruction_in,
    output reg [7:0] pc_out,
    output reg [15:0] instruction_out
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc_out <= 8'b0;
            instruction_out <= 16'b0;  // NOP
        end else if (!stall) begin
            pc_out <= pc_in;
            instruction_out <= instruction_in;
        end
    end

endmodule

module pipeline_reg_id_ex (
    input clk,
    input rst,
    input stall,
    input flush,
    // Control signals from ID stage
    input reg_write_enable_in,
    input mem_write_enable_in,
    input [3:0] alu_op_in,
    input use_immediate_in,
    input mem_addr_sel_in,
    input load_from_mem_in,
    input [7:0] immediate_in,
    // Data from ID stage
    input [7:0] reg_read_a_in,
    input [7:0] reg_read_b_in,
    input [2:0] reg_dest_addr_in,
    input [2:0] reg1_addr_in,
    input [2:0] reg2_addr_in,
    input [7:0] pc_in,
    input [3:0] opcode_in,
    // Outputs
    output reg reg_write_enable_out,
    output reg mem_write_enable_out,
    output reg [3:0] alu_op_out,
    output reg use_immediate_out,
    output reg mem_addr_sel_out,
    output reg load_from_mem_out,
    output reg [7:0] immediate_out,
    output reg [7:0] reg_read_a_out,
    output reg [7:0] reg_read_b_out,
    output reg [2:0] reg_dest_addr_out,
    output reg [2:0] reg1_addr_out,
    output reg [2:0] reg2_addr_out,
    output reg [7:0] pc_out,
    output reg [3:0] opcode_out
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            reg_write_enable_out <= 0;
            mem_write_enable_out <= 0;
            alu_op_out <= 4'b0;
            use_immediate_out <= 0;
            mem_addr_sel_out <= 0;
            load_from_mem_out <= 0;
            immediate_out <= 8'b0;
            reg_read_a_out <= 8'b0;
            reg_read_b_out <= 8'b0;
            reg_dest_addr_out <= 3'b0;
            reg1_addr_out <= 3'b0;
            reg2_addr_out <= 3'b0;
            pc_out <= 8'b0;
            opcode_out <= 4'b0;
        end else if (!stall) begin
            reg_write_enable_out <= reg_write_enable_in;
            mem_write_enable_out <= mem_write_enable_in;
            alu_op_out <= alu_op_in;
            use_immediate_out <= use_immediate_in;
            mem_addr_sel_out <= mem_addr_sel_in;
            load_from_mem_out <= load_from_mem_in;
            immediate_out <= immediate_in;
            reg_read_a_out <= reg_read_a_in;
            reg_read_b_out <= reg_read_b_in;
            reg_dest_addr_out <= reg_dest_addr_in;
            reg1_addr_out <= reg1_addr_in;
            reg2_addr_out <= reg2_addr_in;
            pc_out <= pc_in;
            opcode_out <= opcode_in;
        end
    end

endmodule

module pipeline_reg_ex_mem (
    input clk,
    input rst,
    input stall,
    input flush,
    // Control signals from EX stage
    input reg_write_enable_in,
    input mem_write_enable_in,
    input load_from_mem_in,
    // Data from EX stage
    input [7:0] alu_result_in,
    input [7:0] mem_write_data_in,
    input [7:0] mem_addr_in,
    input [2:0] reg_dest_addr_in,
    input zero_flag_in,
    input carry_flag_in,
    input overflow_flag_in,
    input negative_flag_in,
    // Outputs
    output reg reg_write_enable_out,
    output reg mem_write_enable_out,
    output reg load_from_mem_out,
    output reg [7:0] alu_result_out,
    output reg [7:0] mem_write_data_out,
    output reg [7:0] mem_addr_out,
    output reg [2:0] reg_dest_addr_out,
    output reg zero_flag_out,
    output reg carry_flag_out,
    output reg overflow_flag_out,
    output reg negative_flag_out
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            reg_write_enable_out <= 0;
            mem_write_enable_out <= 0;
            load_from_mem_out <= 0;
            alu_result_out <= 8'b0;
            mem_write_data_out <= 8'b0;
            mem_addr_out <= 8'b0;
            reg_dest_addr_out <= 3'b0;
            zero_flag_out <= 0;
            carry_flag_out <= 0;
            overflow_flag_out <= 0;
            negative_flag_out <= 0;
        end else if (!stall) begin
            reg_write_enable_out <= reg_write_enable_in;
            mem_write_enable_out <= mem_write_enable_in;
            load_from_mem_out <= load_from_mem_in;
            alu_result_out <= alu_result_in;
            mem_write_data_out <= mem_write_data_in;
            mem_addr_out <= mem_addr_in;
            reg_dest_addr_out <= reg_dest_addr_in;
            zero_flag_out <= zero_flag_in;
            carry_flag_out <= carry_flag_in;
            overflow_flag_out <= overflow_flag_in;
            negative_flag_out <= negative_flag_in;
        end
    end

endmodule

module pipeline_reg_mem_wb (
    input clk,
    input rst,
    input stall,
    input flush,
    // Control signals from MEM stage
    input reg_write_enable_in,
    // Data from MEM stage
    input [7:0] alu_result_in,
    input [7:0] mem_read_data_in,
    input load_from_mem_in,
    input [2:0] reg_dest_addr_in,
    // Outputs
    output reg reg_write_enable_out,
    output reg [7:0] write_data_out,
    output reg [2:0] reg_dest_addr_out
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            reg_write_enable_out <= 0;
            write_data_out <= 8'b0;
            reg_dest_addr_out <= 3'b0;
        end else if (!stall) begin
            reg_write_enable_out <= reg_write_enable_in;
            reg_dest_addr_out <= reg_dest_addr_in;
            // Select write data: memory or ALU result
            write_data_out <= load_from_mem_in ? mem_read_data_in : alu_result_in;
        end
    end

endmodule
