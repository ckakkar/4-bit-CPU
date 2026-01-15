// ai_accelerator.v - AI/Neural Network Accelerator
// Implements matrix multiply, convolution, activation functions
// Tightly-coupled with CPU for high performance

module ai_accelerator (
    input clk,
    input rst,
    input enable,                    // Enable accelerator
    input [3:0] operation,           // Operation (0=MATMUL, 1=CONV2D, 2=RELU, 3=SOFTMAX, 4=POOL)
    input [7:0] data_in [0:15],     // Input data (16 values)
    input [7:0] weights [0:15],     // Weights/coefficients
    output reg [7:0] data_out [0:15], // Output data (16 values)
    output reg done,                 // Operation complete
    output reg error,                // Operation error
    // Statistics
    output reg [31:0] operation_count, // Total operations
    output reg [31:0] cycle_count      // Total cycles
);

    // Operation codes
    localparam OP_MATMUL = 4'b0000;
    localparam OP_CONV2D = 4'b0001;
    localparam OP_RELU = 4'b0010;
    localparam OP_SOFTMAX = 4'b0011;
    localparam OP_POOL = 4'b0100;
    
    // State machine
    reg [2:0] state;
    localparam STATE_IDLE = 3'b000;
    localparam STATE_MATMUL = 3'b001;
    localparam STATE_CONV2D = 3'b010;
    localparam STATE_ACTIVATION = 3'b011;
    localparam STATE_DONE = 3'b100;
    
    // Matrix multiply state
    reg [7:0] mat_a [0:15];
    reg [7:0] mat_b [0:15];
    reg [3:0] mat_row, mat_col;
    reg [15:0] mat_accum;
    
    // Convolution state
    reg [7:0] conv_input [0:15]; // 4x4 input (simplified)
    reg [7:0] conv_kernel [0:8]; // 3x3 kernel
    reg [2:0] conv_row, conv_col;
    reg [15:0] conv_accum;
    
    // Activation state
    reg [7:0] act_input [0:15];
    reg [15:0] act_sum; // For softmax
    
    integer i, j;
    
    // ReLU activation: max(0, x)
    function [7:0] relu;
        input [7:0] x;
        begin
            relu = (x[7]) ? 8'b0 : x; // If negative (signed), return 0
        end
    endfunction
    
    // Softmax: exp(x_i) / sum(exp(x_j))
    function [7:0] softmax;
        input [7:0] x;
        input [15:0] sum_exp;
        reg [15:0] exp_val;
        begin
            // Simplified: use x directly (would compute exp in real implementation)
            exp_val = x;
            softmax = (exp_val * 255) / sum_exp; // Normalize to 0-255
        end
    endfunction
    
    // Max pooling: max value in window
    function [7:0] max_pool;
        input [7:0] window [0:3]; // 2x2 window
        reg [7:0] max_val;
        integer k;
        begin
            max_val = window[0];
            for (k = 1; k < 4; k = k + 1) begin
                if (window[k] > max_val) begin
                    max_val = window[k];
                end
            end
            max_pool = max_val;
        end
    endfunction
    
    // Initialize
    always @(posedge rst) begin
        state <= STATE_IDLE;
        done <= 0;
        error <= 0;
        operation_count <= 32'b0;
        cycle_count <= 32'b0;
        mat_row <= 4'b0;
        mat_col <= 4'b0;
        conv_row <= 3'b0;
        conv_col <= 3'b0;
        
        for (i = 0; i < 16; i = i + 1) begin
            data_out[i] <= 8'b0;
            mat_a[i] <= 8'b0;
            mat_b[i] <= 8'b0;
            conv_input[i] <= 8'b0;
            act_input[i] <= 8'b0;
        end
        for (i = 0; i < 9; i = i + 1) begin
            conv_kernel[i] <= 8'b0;
        end
    end
    
    // Main accelerator logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Already initialized
        end else begin
            cycle_count <= cycle_count + 1;
            done <= 0;
            error <= 0;
            
            case (state)
                STATE_IDLE: begin
                    if (enable) begin
                        operation_count <= operation_count + 1;
                        case (operation)
                            OP_MATMUL: begin
                                state <= STATE_MATMUL;
                                mat_row <= 4'b0;
                                mat_col <= 4'b0;
                                // Assume 4x4 matrices (16 elements each)
                                for (i = 0; i < 16; i = i + 1) begin
                                    mat_a[i] <= data_in[i];
                                    mat_b[i] <= weights[i];
                                end
                            end
                            OP_CONV2D: begin
                                state <= STATE_CONV2D;
                                conv_row <= 3'b0;
                                conv_col <= 3'b0;
                                for (i = 0; i < 16; i = i + 1) begin
                                    conv_input[i] <= data_in[i];
                                end
                                for (i = 0; i < 9; i = i + 1) begin
                                    conv_kernel[i] <= weights[i];
                                end
                            end
                            OP_RELU, OP_SOFTMAX, OP_POOL: begin
                                state <= STATE_ACTIVATION;
                                for (i = 0; i < 16; i = i + 1) begin
                                    act_input[i] <= data_in[i];
                                end
                            end
                            default: begin
                                error <= 1;
                                state <= STATE_DONE;
                            end
                        endcase
                    end
                end
                
                STATE_MATMUL: begin
                    // Matrix multiply: C = A × B
                    // Compute one element per cycle
                    if (mat_row < 4) begin
                        if (mat_col < 4) begin
                            mat_accum <= 0;
                            for (i = 0; i < 4; i = i + 1) begin
                                mat_accum <= mat_accum + (mat_a[mat_row * 4 + i] * mat_b[i * 4 + mat_col]);
                            end
                            data_out[mat_row * 4 + mat_col] <= mat_accum[7:0];
                            mat_col <= mat_col + 1;
                        end else begin
                            mat_row <= mat_row + 1;
                            mat_col <= 4'b0;
                        end
                    end else begin
                        state <= STATE_DONE;
                        done <= 1;
                    end
                end
                
                STATE_CONV2D: begin
                    // 2D Convolution: output = input * kernel
                    // Assume 4x4 input, 3x3 kernel, 2x2 output
                    if (conv_row < 2) begin
                        if (conv_col < 2) begin
                            conv_accum <= 0;
                            for (i = 0; i < 3; i = i + 1) begin
                                for (j = 0; j < 3; j = j + 1) begin
                                    conv_accum <= conv_accum + 
                                        (conv_input[(conv_row + i) * 4 + (conv_col + j)] * 
                                         conv_kernel[i * 3 + j]);
                                end
                            end
                            data_out[conv_row * 2 + conv_col] <= conv_accum[7:0];
                            conv_col <= conv_col + 1;
                        end else begin
                            conv_row <= conv_row + 1;
                            conv_col <= 3'b0;
                        end
                    end else begin
                        state <= STATE_DONE;
                        done <= 1;
                    end
                end
                
                STATE_ACTIVATION: begin
                    case (operation)
                        OP_RELU: begin
                            // ReLU activation
                            for (i = 0; i < 16; i = i + 1) begin
                                data_out[i] <= relu(act_input[i]);
                            end
                            state <= STATE_DONE;
                            done <= 1;
                        end
                        OP_SOFTMAX: begin
                            // Softmax activation
                            act_sum <= 0;
                            for (i = 0; i < 16; i = i + 1) begin
                                act_sum <= act_sum + act_input[i]; // Simplified
                            end
                            for (i = 0; i < 16; i = i + 1) begin
                                data_out[i] <= softmax(act_input[i], act_sum);
                            end
                            state <= STATE_DONE;
                            done <= 1;
                        end
                        OP_POOL: begin
                            // Max pooling (2x2 windows on 4x4 input)
                            reg [7:0] pool_window [0:3];
                            integer pool_i, pool_j;
                            for (pool_i = 0; pool_i < 2; pool_i = pool_i + 1) begin
                                for (pool_j = 0; pool_j < 2; pool_j = pool_j + 1) begin
                                    pool_window[0] = act_input[pool_i * 4 + pool_j];
                                    pool_window[1] = act_input[pool_i * 4 + pool_j + 1];
                                    pool_window[2] = act_input[(pool_i + 1) * 4 + pool_j];
                                    pool_window[3] = act_input[(pool_i + 1) * 4 + pool_j + 1];
                                    data_out[pool_i * 2 + pool_j] <= max_pool(pool_window);
                                end
                            end
                            state <= STATE_DONE;
                            done <= 1;
                        end
                    endcase
                end
                
                STATE_DONE: begin
                    state <= STATE_IDLE;
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
