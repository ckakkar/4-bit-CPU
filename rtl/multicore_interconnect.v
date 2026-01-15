// multicore_interconnect.v - Multi-core interconnect and shared memory controller
// Implements shared memory bus with arbitration for multi-core CPU system

module multicore_interconnect (
    input clk,
    input rst,
    // Core 0 interface
    input [7:0] core0_addr,
    input [7:0] core0_write_data,
    input core0_read_enable,
    input core0_write_enable,
    output reg [7:0] core0_read_data,
    output reg core0_ready,
    // Core 1 interface
    input [7:0] core1_addr,
    input [7:0] core1_write_data,
    input core1_read_enable,
    input core1_write_enable,
    output reg [7:0] core1_read_data,
    output reg core1_ready,
    // Core 2 interface
    input [7:0] core2_addr,
    input [7:0] core2_write_data,
    input core2_read_enable,
    input core2_write_enable,
    output reg [7:0] core2_read_data,
    output reg core2_ready,
    // Core 3 interface
    input [7:0] core3_addr,
    input [7:0] core3_write_data,
    input core3_read_enable,
    input core3_write_enable,
    output reg [7:0] core3_read_data,
    output reg core3_ready,
    // Shared memory interface
    output reg [7:0] mem_addr,
    output reg [7:0] mem_write_data,
    output reg mem_read_enable,
    output reg mem_write_enable,
    input [7:0] mem_read_data,
    input mem_ready
);

    // Arbitration: Round-robin priority
    reg [1:0] current_master;
    reg [1:0] next_master;
    reg [1:0] state;
    
    localparam STATE_IDLE = 2'b00;
    localparam STATE_ACCESS = 2'b01;
    localparam STATE_WAIT = 2'b10;
    
    localparam CORE_0 = 2'b00;
    localparam CORE_1 = 2'b01;
    localparam CORE_2 = 2'b10;
    localparam CORE_3 = 2'b11;
    
    // Request signals
    wire core0_request = core0_read_enable || core0_write_enable;
    wire core1_request = core1_read_enable || core1_write_enable;
    wire core2_request = core2_read_enable || core2_write_enable;
    wire core3_request = core3_read_enable || core3_write_enable;
    
    // Arbitration logic
    always @(*) begin
        next_master = current_master;
        
        // Round-robin: check next core in sequence
        case (current_master)
            CORE_0: begin
                if (core1_request) next_master = CORE_1;
                else if (core2_request) next_master = CORE_2;
                else if (core3_request) next_master = CORE_3;
                else if (core0_request) next_master = CORE_0;
            end
            CORE_1: begin
                if (core2_request) next_master = CORE_2;
                else if (core3_request) next_master = CORE_3;
                else if (core0_request) next_master = CORE_0;
                else if (core1_request) next_master = CORE_1;
            end
            CORE_2: begin
                if (core3_request) next_master = CORE_3;
                else if (core0_request) next_master = CORE_0;
                else if (core1_request) next_master = CORE_1;
                else if (core2_request) next_master = CORE_2;
            end
            CORE_3: begin
                if (core0_request) next_master = CORE_0;
                else if (core1_request) next_master = CORE_1;
                else if (core2_request) next_master = CORE_2;
                else if (core3_request) next_master = CORE_3;
            end
        endcase
    end
    
    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_master <= CORE_0;
            state <= STATE_IDLE;
            core0_ready <= 0;
            core1_ready <= 0;
            core2_ready <= 0;
            core3_ready <= 0;
            mem_read_enable <= 0;
            mem_write_enable <= 0;
        end else begin
            // Default: no cores ready
            core0_ready <= 0;
            core1_ready <= 0;
            core2_ready <= 0;
            core3_ready <= 0;
            
            case (state)
                STATE_IDLE: begin
                    // Grant access to next master
                    current_master <= next_master;
                    
                    if (next_master == CORE_0 && core0_request) begin
                        mem_addr <= core0_addr;
                        mem_write_data <= core0_write_data;
                        mem_read_enable <= core0_read_enable;
                        mem_write_enable <= core0_write_enable;
                        state <= STATE_ACCESS;
                    end else if (next_master == CORE_1 && core1_request) begin
                        mem_addr <= core1_addr;
                        mem_write_data <= core1_write_data;
                        mem_read_enable <= core1_read_enable;
                        mem_write_enable <= core1_write_enable;
                        state <= STATE_ACCESS;
                    end else if (next_master == CORE_2 && core2_request) begin
                        mem_addr <= core2_addr;
                        mem_write_data <= core2_write_data;
                        mem_read_enable <= core2_read_enable;
                        mem_write_enable <= core2_write_enable;
                        state <= STATE_ACCESS;
                    end else if (next_master == CORE_3 && core3_request) begin
                        mem_addr <= core3_addr;
                        mem_write_data <= core3_write_data;
                        mem_read_enable <= core3_read_enable;
                        mem_write_enable <= core3_write_enable;
                        state <= STATE_ACCESS;
                    end
                end
                
                STATE_ACCESS: begin
                    // Wait for memory to complete
                    if (mem_ready) begin
                        // Provide data to requesting core
                        case (current_master)
                            CORE_0: begin
                                core0_read_data <= mem_read_data;
                                core0_ready <= 1;
                            end
                            CORE_1: begin
                                core1_read_data <= mem_read_data;
                                core1_ready <= 1;
                            end
                            CORE_2: begin
                                core2_read_data <= mem_read_data;
                                core2_ready <= 1;
                            end
                            CORE_3: begin
                                core3_read_data <= mem_read_data;
                                core3_ready <= 1;
                            end
                        endcase
                        
                        mem_read_enable <= 0;
                        mem_write_enable <= 0;
                        state <= STATE_IDLE;
                    end
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
