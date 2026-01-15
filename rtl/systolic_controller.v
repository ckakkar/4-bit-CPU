// systolic_controller.v - Controller for Systolic Array Operations
// Manages matrix multiply and convolution operations
// Provides CPU interface for systolic array

module systolic_controller (
    input clk,
    input rst,
    // CPU interface
    input [7:0] cpu_addr,            // Memory address for data access
    input cpu_read_enable,            // CPU read request
    input cpu_write_enable,          // CPU write request
    input [7:0] cpu_write_data,      // CPU write data
    output reg [7:0] cpu_read_data,  // CPU read data
    output reg cpu_ready,             // CPU operation ready
    // Operation control
    input [1:0] op_code,             // 0=matrix_mult, 1=convolution, 2=load_data, 3=load_weights
    input [3:0] matrix_rows,          // Number of rows
    input [3:0] matrix_cols,          // Number of columns
    input [7:0] base_addr_a,         // Base address for matrix A
    input [7:0] base_addr_b,         // Base address for matrix B
    input [7:0] base_addr_c,         // Base address for matrix C (result)
    input start_op,                   // Start operation
    output reg op_done,               // Operation complete
    // Memory interface (for loading matrices)
    input [7:0] mem_read_data,        // Memory read data
    input mem_valid,                  // Memory data valid
    output reg [7:0] mem_addr,        // Memory address
    output reg mem_read_enable,       // Memory read request
    output reg mem_write_enable,      // Memory write request
    output reg [7:0] mem_write_data   // Memory write data
    // Systolic array interface
    output reg [7:0] sa_data_in_0, sa_data_in_1, sa_data_in_2, sa_data_in_3,
    output reg [7:0] sa_data_in_4, sa_data_in_5, sa_data_in_6, sa_data_in_7,
    output reg [7:0] sa_data_in_8, sa_data_in_9, sa_data_in_10, sa_data_in_11,
    output reg [7:0] sa_data_in_12, sa_data_in_13, sa_data_in_14, sa_data_in_15,
    output reg sa_data_valid,
    output reg [7:0] sa_weight_in_0, sa_weight_in_1, sa_weight_in_2, sa_weight_in_3,
    output reg [7:0] sa_weight_in_4, sa_weight_in_5, sa_weight_in_6, sa_weight_in_7,
    output reg [7:0] sa_weight_in_8, sa_weight_in_9, sa_weight_in_10, sa_weight_in_11,
    output reg [7:0] sa_weight_in_12, sa_weight_in_13, sa_weight_in_14, sa_weight_in_15,
    output reg sa_weight_valid,
    input [15:0] sa_result_out_0, sa_result_out_1, sa_result_out_2, sa_result_out_3,
    input [15:0] sa_result_out_4, sa_result_out_5, sa_result_out_6, sa_result_out_7,
    input [15:0] sa_result_out_8, sa_result_out_9, sa_result_out_10, sa_result_out_11,
    input [15:0] sa_result_out_12, sa_result_out_13, sa_result_out_14, sa_result_out_15,
    input sa_result_valid,
    input sa_done,
    // Statistics
    output reg [31:0] total_ops,     // Total operations performed
    output reg [31:0] total_cycles    // Total cycles used
);

    // Internal state
    reg [2:0] state;
    localparam STATE_IDLE = 3'b000;
    localparam STATE_LOAD_MATRIX_A = 3'b001;
    localparam STATE_LOAD_MATRIX_B = 3'b010;
    localparam STATE_RUN_OP = 3'b011;
    localparam STATE_STORE_RESULT = 3'b100;
    
    // Matrix storage (simplified - store in registers)
    reg [7:0] matrix_a [0:15][0:15];  // Input matrix A
    reg [7:0] matrix_b [0:15][0:15];  // Weight matrix B
    reg [15:0] matrix_c [0:15][0:15]; // Result matrix C
    
    reg [3:0] load_row, load_col;
    reg [3:0] store_row, store_col;
    reg [7:0] base_addr_a_reg, base_addr_b_reg, base_addr_c_reg;
    
    
    integer i, j;
    
    // Initialize
    always @(posedge rst) begin
        state <= STATE_IDLE;
        op_done <= 0;
        cpu_ready <= 1;
        sa_data_valid <= 0;
        sa_weight_valid <= 0;
        base_addr_a_reg <= 8'b0;
        base_addr_b_reg <= 8'b0;
        base_addr_c_reg <= 8'b0;
        load_row <= 4'b0;
        load_col <= 4'b0;
        store_row <= 4'b0;
        store_col <= 4'b0;
        total_ops <= 32'b0;
        total_cycles <= 32'b0;
        
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                matrix_a[i][j] <= 8'b0;
                matrix_b[i][j] <= 8'b0;
                matrix_c[i][j] <= 16'b0;
            end
        end
    end
    
    // Main state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Already initialized
        end else begin
            total_cycles <= total_cycles + 1;
            cpu_ready <= 0;
            sa_data_valid <= 0;
            sa_weight_valid <= 0;
            mem_read_enable <= 0;
            mem_write_enable <= 0;
            
            // Update base addresses from inputs
            base_addr_a_reg <= base_addr_a;
            base_addr_b_reg <= base_addr_b;
            base_addr_c_reg <= base_addr_c;
            
            case (state)
                STATE_IDLE: begin
                    cpu_ready <= 1;
                    op_done <= 0;
                    
                    if (start_op) begin
                        case (op_code)
                            2'b00: begin // Matrix multiply
                                state <= STATE_LOAD_MATRIX_A;
                                load_row <= 4'b0;
                                load_col <= 4'b0;
                            end
                            2'b01: begin // Convolution
                                state <= STATE_LOAD_MATRIX_A;
                                load_row <= 4'b0;
                                load_col <= 4'b0;
                            end
                            2'b10: begin // Load data
                                state <= STATE_LOAD_MATRIX_A;
                                load_row <= 4'b0;
                                load_col <= 4'b0;
                            end
                            2'b11: begin // Load weights
                                state <= STATE_LOAD_MATRIX_B;
                                load_row <= 4'b0;
                                load_col <= 4'b0;
                            end
                        endcase
                    end
                end
                
                STATE_LOAD_MATRIX_A: begin
                    // Load matrix A from memory
                    if (mem_valid) begin
                        matrix_a[load_row][load_col] <= mem_read_data;
                        
                        if (load_col < matrix_cols - 1) begin
                            load_col <= load_col + 1;
                            mem_addr <= base_addr_a_reg + (load_row * matrix_cols) + load_col + 1;
                            mem_read_enable <= 1;
                        end else if (load_row < matrix_rows - 1) begin
                            load_row <= load_row + 1;
                            load_col <= 4'b0;
                            mem_addr <= base_addr_a_reg + ((load_row + 1) * matrix_cols);
                            mem_read_enable <= 1;
                        end else begin
                            // Matrix A loaded, load matrix B
                            state <= STATE_LOAD_MATRIX_B;
                            load_row <= 4'b0;
                            load_col <= 4'b0;
                        end
                    end else begin
                        mem_addr <= base_addr_a_reg + (load_row * matrix_cols) + load_col;
                        mem_read_enable <= 1;
                    end
                end
                
                STATE_LOAD_MATRIX_B: begin
                    // Load matrix B (weights) from memory
                    if (mem_valid) begin
                        matrix_b[load_row][load_col] <= mem_read_data;
                        
                        if (load_col < matrix_cols - 1) begin
                            load_col <= load_col + 1;
                            mem_addr <= base_addr_b_reg + (load_row * matrix_cols) + load_col + 1;
                            mem_read_enable <= 1;
                        end else if (load_row < matrix_rows - 1) begin
                            load_row <= load_row + 1;
                            load_col <= 4'b0;
                            mem_addr <= base_addr_b_reg + ((load_row + 1) * matrix_cols);
                            mem_read_enable <= 1;
                        end else begin
                            // Both matrices loaded, start computation
                            state <= STATE_RUN_OP;
                            load_row <= 4'b0;
                            load_col <= 4'b0;
                        end
                    end else begin
                        mem_addr <= base_addr_b_reg + (load_row * matrix_cols) + load_col;
                        mem_read_enable <= 1;
                    end
                end
                
                STATE_RUN_OP: begin
                    // Feed data to systolic array
                    // Feed one row of matrix A and one column of matrix B per cycle
                    
                    // Prepare data inputs (row from matrix A)
                    sa_data_in_0 <= matrix_a[load_row][0];
                    sa_data_in_1 <= matrix_a[load_row][1];
                    sa_data_in_2 <= matrix_a[load_row][2];
                    sa_data_in_3 <= matrix_a[load_row][3];
                    sa_data_in_4 <= matrix_a[load_row][4];
                    sa_data_in_5 <= matrix_a[load_row][5];
                    sa_data_in_6 <= matrix_a[load_row][6];
                    sa_data_in_7 <= matrix_a[load_row][7];
                    sa_data_in_8 <= (matrix_cols > 8) ? matrix_a[load_row][8] : 8'b0;
                    sa_data_in_9 <= (matrix_cols > 9) ? matrix_a[load_row][9] : 8'b0;
                    sa_data_in_10 <= (matrix_cols > 10) ? matrix_a[load_row][10] : 8'b0;
                    sa_data_in_11 <= (matrix_cols > 11) ? matrix_a[load_row][11] : 8'b0;
                    sa_data_in_12 <= (matrix_cols > 12) ? matrix_a[load_row][12] : 8'b0;
                    sa_data_in_13 <= (matrix_cols > 13) ? matrix_a[load_row][13] : 8'b0;
                    sa_data_in_14 <= (matrix_cols > 14) ? matrix_a[load_row][14] : 8'b0;
                    sa_data_in_15 <= (matrix_cols > 15) ? matrix_a[load_row][15] : 8'b0;
                    
                    // Prepare weight inputs (column from matrix B)
                    sa_weight_in_0 <= matrix_b[0][load_col];
                    sa_weight_in_1 <= matrix_b[1][load_col];
                    sa_weight_in_2 <= matrix_b[2][load_col];
                    sa_weight_in_3 <= matrix_b[3][load_col];
                    sa_weight_in_4 <= matrix_b[4][load_col];
                    sa_weight_in_5 <= matrix_b[5][load_col];
                    sa_weight_in_6 <= matrix_b[6][load_col];
                    sa_weight_in_7 <= matrix_b[7][load_col];
                    sa_weight_in_8 <= (matrix_rows > 8) ? matrix_b[8][load_col] : 8'b0;
                    sa_weight_in_9 <= (matrix_rows > 9) ? matrix_b[9][load_col] : 8'b0;
                    sa_weight_in_10 <= (matrix_rows > 10) ? matrix_b[10][load_col] : 8'b0;
                    sa_weight_in_11 <= (matrix_rows > 11) ? matrix_b[11][load_col] : 8'b0;
                    sa_weight_in_12 <= (matrix_rows > 12) ? matrix_b[12][load_col] : 8'b0;
                    sa_weight_in_13 <= (matrix_rows > 13) ? matrix_b[13][load_col] : 8'b0;
                    sa_weight_in_14 <= (matrix_rows > 14) ? matrix_b[14][load_col] : 8'b0;
                    sa_weight_in_15 <= (matrix_rows > 15) ? matrix_b[15][load_col] : 8'b0;
                    
                    sa_data_valid <= 1;
                    sa_weight_valid <= 1;
                    
                    // Collect results
                    if (sa_result_valid) begin
                        matrix_c[store_row][0] <= sa_result_out_0;
                        matrix_c[store_row][1] <= sa_result_out_1;
                        matrix_c[store_row][2] <= sa_result_out_2;
                        matrix_c[store_row][3] <= sa_result_out_3;
                        matrix_c[store_row][4] <= sa_result_out_4;
                        matrix_c[store_row][5] <= sa_result_out_5;
                        matrix_c[store_row][6] <= sa_result_out_6;
                        matrix_c[store_row][7] <= sa_result_out_7;
                        matrix_c[store_row][8] <= sa_result_out_8;
                        matrix_c[store_row][9] <= sa_result_out_9;
                        matrix_c[store_row][10] <= sa_result_out_10;
                        matrix_c[store_row][11] <= sa_result_out_11;
                        matrix_c[store_row][12] <= sa_result_out_12;
                        matrix_c[store_row][13] <= sa_result_out_13;
                        matrix_c[store_row][14] <= sa_result_out_14;
                        matrix_c[store_row][15] <= sa_result_out_15;
                        store_row <= store_row + 1;
                        total_ops <= total_ops + matrix_cols;
                    end
                    
                    if (sa_done) begin
                        state <= STATE_STORE_RESULT;
                        store_row <= 4'b0;
                        store_col <= 4'b0;
                    end
                end
                
                STATE_STORE_RESULT: begin
                    // Store results back to memory
                    mem_addr <= base_addr_c_reg + (store_row * matrix_cols) + store_col;
                    mem_write_data <= matrix_c[store_row][store_col][7:0]; // Low byte
                    mem_write_enable <= 1;
                    
                    if (store_col < matrix_cols) begin
                        store_col <= store_col + 1;
                    end else if (store_row < matrix_rows) begin
                        store_row <= store_row + 1;
                        store_col <= 4'b0;
                    end else begin
                        state <= STATE_IDLE;
                        op_done <= 1;
                        cpu_ready <= 1;
                        mem_write_enable <= 0;
                    end
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
