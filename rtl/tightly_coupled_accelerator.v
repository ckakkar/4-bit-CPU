// tightly_coupled_accelerator.v - Tightly-Coupled Accelerator Interface
// Provides unified interface for all domain-specific accelerators
// Enables instruction fusion and low-latency access

module tightly_coupled_accelerator (
    input clk,
    input rst,
    // CPU interface
    input [1:0] accelerator_sel,    // Accelerator select (0=crypto, 1=DSP, 2=AI)
    input [7:0] accelerator_op,      // Accelerator operation
    input enable,                    // Enable accelerator
    input [7:0] data_in [0:15],     // Input data (from registers/memory)
    input [7:0] param [0:15],       // Parameters (keys, coefficients, weights)
    output reg [7:0] data_out [0:15], // Output data (to registers)
    output reg done,                 // Operation complete
    output reg error,                // Operation error
    output reg ready,                // Accelerator ready
    // Instruction fusion interface
    input fusion_enable,             // Fusion mode enabled
    input [1:0] fusion_type,         // Fusion type
    input [7:0] fusion_addr,         // Memory address (for load/store fusion)
    // Statistics
    output reg [31:0] total_ops,     // Total operations
    output reg [31:0] fusion_ops,    // Fused operations
    output reg [31:0] cycle_count    // Total cycles
);

    // Accelerator instances
    wire crypto_done, crypto_error;
    wire [7:0] crypto_out [0:15];
    wire crypto_ready;
    
    wire dsp_done, dsp_error;
    wire [7:0] dsp_out [0:15];
    wire dsp_ready;
    
    wire ai_done, ai_error;
    wire [7:0] ai_out [0:15];
    wire ai_ready;
    
    // Crypto accelerator
    crypto_accelerator crypto_accel (
        .clk(clk),
        .rst(rst),
        .enable(enable && accelerator_sel == 2'b00),
        .operation(accelerator_op[3:0]),
        .data_in(data_in),
        .key(param),
        .data_out(crypto_out),
        .done(crypto_done),
        .error(crypto_error),
        .operation_count(),
        .cycle_count()
    );
    
    // DSP accelerator
    dsp_accelerator dsp_accel (
        .clk(clk),
        .rst(rst),
        .enable(enable && accelerator_sel == 2'b01),
        .operation(accelerator_op[3:0]),
        .data_in(data_in),
        .coeff(param),
        .data_out(dsp_out),
        .done(dsp_done),
        .error(dsp_error),
        .operation_count(),
        .cycle_count()
    );
    
    // AI accelerator
    ai_accelerator ai_accel (
        .clk(clk),
        .rst(rst),
        .enable(enable && accelerator_sel == 2'b10),
        .operation(accelerator_op[3:0]),
        .data_in(data_in),
        .weights(param),
        .data_out(ai_out),
        .done(ai_done),
        .error(ai_error),
        .operation_count(),
        .cycle_count()
    );
    
    // Output multiplexing using generate
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_output_mux
            always @(*) begin
                case (accelerator_sel)
                    2'b00: data_out[k] = crypto_out[k];
                    2'b01: data_out[k] = dsp_out[k];
                    2'b10: data_out[k] = ai_out[k];
                    default: data_out[k] = 8'b0;
                endcase
            end
        end
    endgenerate
    
    always @(*) begin
        case (accelerator_sel)
            2'b00: begin // Crypto
                done = crypto_done;
                error = crypto_error;
                ready = crypto_ready;
            end
            2'b01: begin // DSP
                done = dsp_done;
                error = dsp_error;
                ready = dsp_ready;
            end
            2'b10: begin // AI
                done = ai_done;
                error = ai_error;
                ready = ai_ready;
            end
            default: begin
                done = 0;
                error = 0;
                ready = 1;
            end
        endcase
    end
    
    // Statistics and control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            total_ops <= 32'b0;
            fusion_ops <= 32'b0;
            cycle_count <= 32'b0;
        end else begin
            cycle_count <= cycle_count + 1;
            
            if (enable) begin
                total_ops <= total_ops + 1;
                if (fusion_enable) begin
                    fusion_ops <= fusion_ops + 1;
                end
            end
        end
    end
    
    // Assign ready signals (simplified: always ready when not busy)
    assign crypto_ready = !enable || crypto_done;
    assign dsp_ready = !enable || dsp_done;
    assign ai_ready = !enable || ai_done;

endmodule
