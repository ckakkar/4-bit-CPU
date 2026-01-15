// systolic_system.v - Complete Systolic Array System
// Integrates systolic array, controller, and CPU interface
// Provides high-performance matrix operations for AI workloads

module systolic_system (
    input clk,
    input rst,
    // CPU interface (memory-mapped)
    input [7:0] cpu_addr,            // Memory address
    input cpu_read_enable,            // CPU read request
    input cpu_write_enable,          // CPU write request
    input [7:0] cpu_write_data,      // CPU write data
    output reg [7:0] cpu_read_data,  // CPU read data
    output reg cpu_ready,             // CPU operation ready
    // Memory interface (for loading matrices)
    input [7:0] mem_read_data,        // Memory read data
    input mem_valid,                  // Memory data valid
    output reg [7:0] mem_addr,        // Memory address
    output reg mem_read_enable,       // Memory read request
    output reg mem_write_enable,      // Memory write request
    output reg [7:0] mem_write_data,  // Memory write data
    // Status and control registers
    output reg [31:0] performance_counter, // Performance counter
    output reg [31:0] operation_count      // Operation count
);

    // Systolic array instance
    wire sa_start;
    wire [1:0] sa_operation;
    wire [3:0] sa_rows, sa_cols;
    wire sa_done;
    wire [15:0] sa_result_out_0, sa_result_out_1, sa_result_out_2, sa_result_out_3;
    wire [15:0] sa_result_out_4, sa_result_out_5, sa_result_out_6, sa_result_out_7;
    wire [15:0] sa_result_out_8, sa_result_out_9, sa_result_out_10, sa_result_out_11;
    wire [15:0] sa_result_out_12, sa_result_out_13, sa_result_out_14, sa_result_out_15;
    wire sa_result_valid;
    wire [7:0] sa_data_in_0, sa_data_in_1, sa_data_in_2, sa_data_in_3;
    wire [7:0] sa_data_in_4, sa_data_in_5, sa_data_in_6, sa_data_in_7;
    wire [7:0] sa_data_in_8, sa_data_in_9, sa_data_in_10, sa_data_in_11;
    wire [7:0] sa_data_in_12, sa_data_in_13, sa_data_in_14, sa_data_in_15;
    wire sa_data_valid;
    wire [7:0] sa_weight_in_0, sa_weight_in_1, sa_weight_in_2, sa_weight_in_3;
    wire [7:0] sa_weight_in_4, sa_weight_in_5, sa_weight_in_6, sa_weight_in_7;
    wire [7:0] sa_weight_in_8, sa_weight_in_9, sa_weight_in_10, sa_weight_in_11;
    wire [7:0] sa_weight_in_12, sa_weight_in_13, sa_weight_in_14, sa_weight_in_15;
    wire sa_weight_valid;
    wire [31:0] sa_cycle_count, sa_ops_count;
    
    // Control registers (memory-mapped)
    reg [7:0] control_reg;           // Control register
    reg [7:0] status_reg;             // Status register
    reg [7:0] op_type_reg;            // Operation type
    reg [7:0] rows_reg, cols_reg;     // Matrix dimensions
    reg [7:0] base_addr_a_reg, base_addr_b_reg, base_addr_c_reg; // Base addresses
    
    // Systolic array instantiation
    systolic_array sa_inst (
        .clk(clk),
        .rst(rst),
        .start(sa_start),
        .operation(sa_operation),
        .rows(sa_rows),
        .cols(sa_cols),
        .done(sa_done),
        .data_in_0(sa_data_in_0), .data_in_1(sa_data_in_1),
        .data_in_2(sa_data_in_2), .data_in_3(sa_data_in_3),
        .data_in_4(sa_data_in_4), .data_in_5(sa_data_in_5),
        .data_in_6(sa_data_in_6), .data_in_7(sa_data_in_7),
        .data_in_8(sa_data_in_8), .data_in_9(sa_data_in_9),
        .data_in_10(sa_data_in_10), .data_in_11(sa_data_in_11),
        .data_in_12(sa_data_in_12), .data_in_13(sa_data_in_13),
        .data_in_14(sa_data_in_14), .data_in_15(sa_data_in_15),
        .data_valid(sa_data_valid),
        .weight_in_0(sa_weight_in_0), .weight_in_1(sa_weight_in_1),
        .weight_in_2(sa_weight_in_2), .weight_in_3(sa_weight_in_3),
        .weight_in_4(sa_weight_in_4), .weight_in_5(sa_weight_in_5),
        .weight_in_6(sa_weight_in_6), .weight_in_7(sa_weight_in_7),
        .weight_in_8(sa_weight_in_8), .weight_in_9(sa_weight_in_9),
        .weight_in_10(sa_weight_in_10), .weight_in_11(sa_weight_in_11),
        .weight_in_12(sa_weight_in_12), .weight_in_13(sa_weight_in_13),
        .weight_in_14(sa_weight_in_14), .weight_in_15(sa_weight_in_15),
        .weight_valid(sa_weight_valid),
        .result_out_0(sa_result_out_0), .result_out_1(sa_result_out_1),
        .result_out_2(sa_result_out_2), .result_out_3(sa_result_out_3),
        .result_out_4(sa_result_out_4), .result_out_5(sa_result_out_5),
        .result_out_6(sa_result_out_6), .result_out_7(sa_result_out_7),
        .result_out_8(sa_result_out_8), .result_out_9(sa_result_out_9),
        .result_out_10(sa_result_out_10), .result_out_11(sa_result_out_11),
        .result_out_12(sa_result_out_12), .result_out_13(sa_result_out_13),
        .result_out_14(sa_result_out_14), .result_out_15(sa_result_out_15),
        .result_valid(sa_result_valid),
        .cycle_count(sa_cycle_count),
        .ops_count(sa_ops_count)
    );
    
    // Systolic controller instantiation
    systolic_controller sa_ctrl (
        .clk(clk),
        .rst(rst),
        .cpu_addr(cpu_addr),
        .cpu_read_enable(cpu_read_enable),
        .cpu_write_enable(cpu_write_enable),
        .cpu_write_data(cpu_write_data),
        .cpu_read_data(cpu_read_data),
        .cpu_ready(cpu_ready),
        .op_code(op_type_reg[1:0]),
        .matrix_rows(rows_reg[3:0]),
        .matrix_cols(cols_reg[3:0]),
        .base_addr_a(base_addr_a_reg),
        .base_addr_b(base_addr_b_reg),
        .base_addr_c(base_addr_c_reg),
        .start_op(sa_start),
        .op_done(sa_done),
        .mem_read_data(mem_read_data),
        .mem_valid(mem_valid),
        .mem_addr(mem_addr),
        .mem_read_enable(mem_read_enable),
        .mem_write_enable(mem_write_enable),
        .mem_write_data(mem_write_data),
        .sa_data_in_0(sa_data_in_0), .sa_data_in_1(sa_data_in_1),
        .sa_data_in_2(sa_data_in_2), .sa_data_in_3(sa_data_in_3),
        .sa_data_in_4(sa_data_in_4), .sa_data_in_5(sa_data_in_5),
        .sa_data_in_6(sa_data_in_6), .sa_data_in_7(sa_data_in_7),
        .sa_data_in_8(sa_data_in_8), .sa_data_in_9(sa_data_in_9),
        .sa_data_in_10(sa_data_in_10), .sa_data_in_11(sa_data_in_11),
        .sa_data_in_12(sa_data_in_12), .sa_data_in_13(sa_data_in_13),
        .sa_data_in_14(sa_data_in_14), .sa_data_in_15(sa_data_in_15),
        .sa_data_valid(sa_data_valid),
        .sa_weight_in_0(sa_weight_in_0), .sa_weight_in_1(sa_weight_in_1),
        .sa_weight_in_2(sa_weight_in_2), .sa_weight_in_3(sa_weight_in_3),
        .sa_weight_in_4(sa_weight_in_4), .sa_weight_in_5(sa_weight_in_5),
        .sa_weight_in_6(sa_weight_in_6), .sa_weight_in_7(sa_weight_in_7),
        .sa_weight_in_8(sa_weight_in_8), .sa_weight_in_9(sa_weight_in_9),
        .sa_weight_in_10(sa_weight_in_10), .sa_weight_in_11(sa_weight_in_11),
        .sa_weight_in_12(sa_weight_in_12), .sa_weight_in_13(sa_weight_in_13),
        .sa_weight_in_14(sa_weight_in_14), .sa_weight_in_15(sa_weight_in_15),
        .sa_weight_valid(sa_weight_valid),
        .sa_result_out_0(sa_result_out_0), .sa_result_out_1(sa_result_out_1),
        .sa_result_out_2(sa_result_out_2), .sa_result_out_3(sa_result_out_3),
        .sa_result_out_4(sa_result_out_4), .sa_result_out_5(sa_result_out_5),
        .sa_result_out_6(sa_result_out_6), .sa_result_out_7(sa_result_out_7),
        .sa_result_out_8(sa_result_out_8), .sa_result_out_9(sa_result_out_9),
        .sa_result_out_10(sa_result_out_10), .sa_result_out_11(sa_result_out_11),
        .sa_result_out_12(sa_result_out_12), .sa_result_out_13(sa_result_out_13),
        .sa_result_out_14(sa_result_out_14), .sa_result_out_15(sa_result_out_15),
        .sa_result_valid(sa_result_valid),
        .sa_done(sa_done),
        .total_ops(operation_count),
        .total_cycles(performance_counter)
    );
    
    // Memory-mapped register interface
    // Address map:
    // 0x00: Control register (bit 0: start, bit 1: reset)
    // 0x01: Status register (bit 0: busy, bit 1: done)
    // 0x02: Operation type (0=matrix_mult, 1=convolution)
    // 0x03: Rows
    // 0x04: Columns
    // 0x05: Base address A (low)
    // 0x06: Base address B (low)
    // 0x07: Base address C (low)
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            control_reg <= 8'b0;
            status_reg <= 8'b0;
            op_type_reg <= 8'b0;
            rows_reg <= 8'b0;
            cols_reg <= 8'b0;
            base_addr_a_reg <= 8'b0;
            base_addr_b_reg <= 8'b0;
            base_addr_c_reg <= 8'b0;
            cpu_ready <= 1;
        end else begin
            status_reg[0] <= sa_done ? 0 : (sa_start ? 1 : status_reg[0]); // Busy
            status_reg[1] <= sa_done; // Done
            
            if (cpu_write_enable) begin
                case (cpu_addr)
                    8'h00: control_reg <= cpu_write_data;
                    8'h02: op_type_reg <= cpu_write_data;
                    8'h03: rows_reg <= cpu_write_data;
                    8'h04: cols_reg <= cpu_write_data;
                    8'h05: base_addr_a_reg <= cpu_write_data;
                    8'h06: base_addr_b_reg <= cpu_write_data;
                    8'h07: base_addr_c_reg <= cpu_write_data;
                endcase
            end
            
            if (cpu_read_enable) begin
                case (cpu_addr)
                    8'h00: cpu_read_data <= control_reg;
                    8'h01: cpu_read_data <= status_reg;
                    8'h02: cpu_read_data <= op_type_reg;
                    8'h03: cpu_read_data <= rows_reg;
                    8'h04: cpu_read_data <= cols_reg;
                    8'h05: cpu_read_data <= base_addr_a_reg;
                    8'h06: cpu_read_data <= base_addr_b_reg;
                    8'h07: cpu_read_data <= base_addr_c_reg;
                    default: cpu_read_data <= 8'b0;
                endcase
                cpu_ready <= 1;
            end
        end
    end
    
    // Control signal generation
    assign sa_start = control_reg[0] && !status_reg[0];
    assign sa_operation = op_type_reg[1:0];
    assign sa_rows = rows_reg[3:0];
    assign sa_cols = cols_reg[3:0];

endmodule
