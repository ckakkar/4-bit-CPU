// systolic_array.v - 2D Systolic Array for Matrix Operations
// Implements a grid of processing elements for matrix multiply and convolution
// Data flows between neighbors with minimal control overhead

module systolic_array (
    input clk,
    input rst,
    // Control interface
    input start,                     // Start computation
    input [1:0] operation,           // 0=matrix_mult, 1=convolution, 2=idle
    input [3:0] rows,                 // Number of rows in input matrix
    input [3:0] cols,                 // Number of columns in input matrix
    output reg done,                  // Computation complete
    // Data input interface (matrix A - input data)
    input [7:0] data_in_0, data_in_1, data_in_2, data_in_3,
    input [7:0] data_in_4, data_in_5, data_in_6, data_in_7,
    input [7:0] data_in_8, data_in_9, data_in_10, data_in_11,
    input [7:0] data_in_12, data_in_13, data_in_14, data_in_15,
    input data_valid,                // Input data is valid
    // Weight input interface (matrix B - weights)
    input [7:0] weight_in_0, weight_in_1, weight_in_2, weight_in_3,
    input [7:0] weight_in_4, weight_in_5, weight_in_6, weight_in_7,
    input [7:0] weight_in_8, weight_in_9, weight_in_10, weight_in_11,
    input [7:0] weight_in_12, weight_in_13, weight_in_14, weight_in_15,
    input weight_valid,              // Input weight is valid
    // Result output interface
    output reg [15:0] result_out_0, result_out_1, result_out_2, result_out_3,
    output reg [15:0] result_out_4, result_out_5, result_out_6, result_out_7,
    output reg [15:0] result_out_8, result_out_9, result_out_10, result_out_11,
    output reg [15:0] result_out_12, result_out_13, result_out_14, result_out_15,
    output reg result_valid,         // Result is valid
    // Statistics
    output reg [31:0] cycle_count,   // Number of cycles for operation
    output reg [31:0] ops_count      // Number of operations performed
);

    // Array dimensions (configurable, max 16x16)
    localparam ARRAY_SIZE = 16;
    
    // Processing element array - flattened arrays for Verilog compatibility
    reg [7:0] pe_data_h [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];   // Horizontal data flow
    reg [7:0] pe_data_v [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];   // Vertical data flow
    reg [7:0] pe_weight_h [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1]; // Horizontal weight flow
    reg [7:0] pe_weight_v [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1]; // Vertical weight flow
    reg [15:0] pe_sum [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];      // Partial sum flow (vertical)
    reg pe_enable [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg pe_weight_load [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg pe_accumulate [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    
    // Internal result storage
    reg [15:0] result [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    
    // Input data array (for easier indexing)
    wire [7:0] data_in [0:15];
    wire [7:0] weight_in [0:15];
    
    // Assign input arrays
    assign data_in[0] = data_in_0; assign data_in[1] = data_in_1;
    assign data_in[2] = data_in_2; assign data_in[3] = data_in_3;
    assign data_in[4] = data_in_4; assign data_in[5] = data_in_5;
    assign data_in[6] = data_in_6; assign data_in[7] = data_in_7;
    assign data_in[8] = data_in_8; assign data_in[9] = data_in_9;
    assign data_in[10] = data_in_10; assign data_in[11] = data_in_11;
    assign data_in[12] = data_in_12; assign data_in[13] = data_in_13;
    assign data_in[14] = data_in_14; assign data_in[15] = data_in_15;
    
    assign weight_in[0] = weight_in_0; assign weight_in[1] = weight_in_1;
    assign weight_in[2] = weight_in_2; assign weight_in[3] = weight_in_3;
    assign weight_in[4] = weight_in_4; assign weight_in[5] = weight_in_5;
    assign weight_in[6] = weight_in_6; assign weight_in[7] = weight_in_7;
    assign weight_in[8] = weight_in_8; assign weight_in[9] = weight_in_9;
    assign weight_in[10] = weight_in_10; assign weight_in[11] = weight_in_11;
    assign weight_in[12] = weight_in_12; assign weight_in[13] = weight_in_13;
    assign weight_in[14] = weight_in_14; assign weight_in[15] = weight_in_15;
    
    // State machine
    reg [2:0] state;
    localparam STATE_IDLE = 3'b000;
    localparam STATE_LOAD_WEIGHTS = 3'b001;
    localparam STATE_COMPUTE = 3'b010;
    localparam STATE_DRAIN = 3'b011;
    localparam STATE_DONE = 3'b100;
    
    reg [4:0] cycle_counter;
    reg [3:0] weight_load_row;
    reg [3:0] compute_row;
    reg [3:0] drain_row;
    reg [3:0] result_row;
    
    integer i, j;
    
    // PE signals (individual wires for each PE)
    wire [7:0] pe_data_out_bottom [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    wire [7:0] pe_data_out_right [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    wire [7:0] pe_weight_out_bottom [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    wire [7:0] pe_weight_out_right [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    wire [15:0] pe_partial_sum_out [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    
    // Initialize PE array - instantiate each PE
    genvar row, col;
    generate
        for (row = 0; row < ARRAY_SIZE; row = row + 1) begin : gen_rows
            for (col = 0; col < ARRAY_SIZE; col = col + 1) begin : gen_cols
                systolic_pe pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .enable(pe_enable[row][col]),
                    .data_in_top((row == 0) ? data_in[col] : pe_data_v[row-1][col]),
                    .data_in_left((col == 0) ? 8'b0 : pe_data_h[row][col-1]),
                    .weight_in_top((row == 0) ? weight_in[col] : pe_weight_v[row-1][col]),
                    .weight_in_left((col == 0) ? 8'b0 : pe_weight_h[row][col-1]),
                    .partial_sum_in((row == 0) ? 16'b0 : pe_sum[row-1][col]),
                    .weight_load(pe_weight_load[row][col]),
                    .accumulate(pe_accumulate[row][col]),
                    .data_out_bottom(pe_data_out_bottom[row][col]),
                    .data_out_right(pe_data_out_right[row][col]),
                    .weight_out_bottom(pe_weight_out_bottom[row][col]),
                    .weight_out_right(pe_weight_out_right[row][col]),
                    .partial_sum_out(pe_partial_sum_out[row][col]),
                    .local_weight(),
                    .local_sum()
                );
            end
        end
    endgenerate
    
    // Connect PE outputs to internal arrays using generate
    generate
        for (row = 0; row < ARRAY_SIZE; row = row + 1) begin : gen_conn_rows
            for (col = 0; col < ARRAY_SIZE; col = col + 1) begin : gen_conn_cols
                always @(*) begin
                    pe_data_v[row][col] = pe_data_out_bottom[row][col];
                    pe_data_h[row][col] = pe_data_out_right[row][col];
                    pe_weight_v[row][col] = pe_weight_out_bottom[row][col];
                    pe_weight_h[row][col] = pe_weight_out_right[row][col];
                    pe_sum[row][col] = pe_partial_sum_out[row][col];
                end
            end
        end
    endgenerate
    
    // Control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            done <= 0;
            cycle_counter <= 5'b0;
            weight_load_row <= 4'b0;
            compute_row <= 4'b0;
            drain_row <= 4'b0;
            result_row <= 4'b0;
            result_valid <= 0;
            cycle_count <= 32'b0;
            ops_count <= 32'b0;
            
            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                    result[i][j] <= 16'b0;
                    pe_enable[i][j] <= 0;
                    pe_weight_load[i][j] <= 0;
                    pe_accumulate[i][j] <= 0;
                end
            end
            result_out_0 <= 16'b0; result_out_1 <= 16'b0;
            result_out_2 <= 16'b0; result_out_3 <= 16'b0;
            result_out_4 <= 16'b0; result_out_5 <= 16'b0;
            result_out_6 <= 16'b0; result_out_7 <= 16'b0;
            result_out_8 <= 16'b0; result_out_9 <= 16'b0;
            result_out_10 <= 16'b0; result_out_11 <= 16'b0;
            result_out_12 <= 16'b0; result_out_13 <= 16'b0;
            result_out_14 <= 16'b0; result_out_15 <= 16'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    done <= 0;
                    result_valid <= 0;
                    cycle_counter <= 5'b0;
                    
                    if (start && operation != 2'b10) begin
                        state <= STATE_LOAD_WEIGHTS;
                        weight_load_row <= 4'b0;
                        cycle_count <= 32'b0;
                        ops_count <= 32'b0;
                    end
                end
                
                STATE_LOAD_WEIGHTS: begin
                    // Load weights into the array (diagonal loading)
                    cycle_count <= cycle_count + 1;
                    
                    // Enable PEs in diagonal pattern for weight loading
                    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                            if (i == weight_load_row && j <= weight_load_row) begin
                                pe_enable[i][j] <= 1;
                                pe_weight_load[i][j] <= 1;
                            end else begin
                                pe_enable[i][j] <= 0;
                                pe_weight_load[i][j] <= 0;
                            end
                            pe_accumulate[i][j] <= (operation == 2'b01); // Accumulate for convolution
                        end
                    end
                    
                    if (weight_valid && weight_load_row < rows) begin
                        weight_load_row <= weight_load_row + 1;
                    end
                    
                    if (weight_load_row >= rows - 1) begin
                        state <= STATE_COMPUTE;
                        compute_row <= 4'b0;
                        cycle_counter <= 5'b0;
                    end
                end
                
                STATE_COMPUTE: begin
                    // Perform matrix multiplication or convolution
                    cycle_count <= cycle_count + 1;
                    cycle_counter <= cycle_counter + 1;
                    
                    // Enable all PEs for computation
                    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                            if (i < rows && j < cols) begin
                                pe_enable[i][j] <= 1;
                                pe_weight_load[i][j] <= 0;
                                pe_accumulate[i][j] <= (operation == 2'b01); // Accumulate for convolution
                            end else begin
                                pe_enable[i][j] <= 0;
                            end
                        end
                    end
                    
                    // Feed input data
                    if (data_valid && compute_row < rows) begin
                        compute_row <= compute_row + 1;
                        ops_count <= ops_count + cols;
                    end
                    
                    // Check if computation is complete
                    // For matrix multiply: need rows + cols - 1 cycles
                    // For convolution: depends on kernel size
                    if (cycle_counter >= (rows + cols - 1)) begin
                        state <= STATE_DRAIN;
                        drain_row <= 4'b0;
                    end
                end
                
                STATE_DRAIN: begin
                    // Drain results from the array
                    cycle_count <= cycle_count + 1;
                    
                    // Disable computation, just pass through
                    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                            pe_enable[i][j] <= 0;
                            pe_weight_load[i][j] <= 0;
                        end
                    end
                    
                    // Read results from bottom row
                    if (drain_row < rows) begin
                        for (j = 0; j < cols; j = j + 1) begin
                            result[drain_row][j] <= pe_sum[rows-1][j];
                        end
                        // Output results
                        result_out_0 <= pe_sum[rows-1][0];
                        result_out_1 <= pe_sum[rows-1][1];
                        result_out_2 <= pe_sum[rows-1][2];
                        result_out_3 <= pe_sum[rows-1][3];
                        result_out_4 <= pe_sum[rows-1][4];
                        result_out_5 <= pe_sum[rows-1][5];
                        result_out_6 <= pe_sum[rows-1][6];
                        result_out_7 <= pe_sum[rows-1][7];
                        result_out_8 <= pe_sum[rows-1][8];
                        result_out_9 <= pe_sum[rows-1][9];
                        result_out_10 <= pe_sum[rows-1][10];
                        result_out_11 <= pe_sum[rows-1][11];
                        result_out_12 <= pe_sum[rows-1][12];
                        result_out_13 <= pe_sum[rows-1][13];
                        result_out_14 <= pe_sum[rows-1][14];
                        result_out_15 <= pe_sum[rows-1][15];
                        result_valid <= 1;
                        drain_row <= drain_row + 1;
                    end else begin
                        result_valid <= 0;
                        state <= STATE_DONE;
                    end
                end
                
                STATE_DONE: begin
                    done <= 1;
                    state <= STATE_IDLE;
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
