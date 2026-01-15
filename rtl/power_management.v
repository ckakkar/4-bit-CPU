// power_management.v - Power management and clock gating unit
// Implements clock gating, power domains, and sleep modes

module power_management (
    input clk,
    input rst,
    // Power control
    input power_down,                  // Power down request
    input sleep_mode,                  // Sleep mode request
    input [3:0] power_domain_control,  // Power domain control (4 domains)
    // CPU status
    input cpu_idle,                    // CPU is idle (no useful work)
    input halt,                        // CPU is halted
    // Clock gating control
    output reg clk_gated,              // Clock is gated
    output reg [3:0] domain_clk_enable, // Clock enable for each power domain
    // Power status
    output reg power_down_active,      // Power down is active
    output reg sleep_active,           // Sleep mode is active
    output reg [7:0] power_savings     // Power savings percentage (0-100)
);

    // Power domains
    // Domain 0: Core CPU (always on when not powered down)
    // Domain 1: Cache subsystem
    // Domain 2: I/O peripherals
    // Domain 3: Debug and performance counters
    
    reg [2:0] state;
    localparam STATE_NORMAL = 3'b000;
    localparam STATE_IDLE = 3'b001;
    localparam STATE_SLEEP = 3'b010;
    localparam STATE_POWER_DOWN = 3'b011;
    
    reg [31:0] idle_counter;  // Count idle cycles
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_NORMAL;
            clk_gated <= 0;
            domain_clk_enable <= 4'b1111;  // All domains enabled
            power_down_active <= 0;
            sleep_active <= 0;
            idle_counter <= 32'b0;
            power_savings <= 8'b0;
        end else begin
            case (state)
                STATE_NORMAL: begin
                    if (power_down) begin
                        state <= STATE_POWER_DOWN;
                        clk_gated <= 1;
                        domain_clk_enable <= 4'b0000;  // Gate all domains
                        power_down_active <= 1;
                        power_savings <= 8'd100;  // 100% power savings
                    end else if (sleep_mode) begin
                        state <= STATE_SLEEP;
                        clk_gated <= 1;
                        domain_clk_enable <= 4'b0001;  // Only core domain
                        sleep_active <= 1;
                        power_savings <= 8'd75;  // 75% power savings
                    end else if (cpu_idle || halt) begin
                        idle_counter <= idle_counter + 1;
                        if (idle_counter > 32'd1000) begin
                            // After 1000 idle cycles, enter idle mode
                            state <= STATE_IDLE;
                            domain_clk_enable[1] <= 0;  // Gate cache
                            domain_clk_enable[2] <= 0;  // Gate I/O
                            domain_clk_enable[3] <= 0;  // Gate debug
                            power_savings <= 8'd50;  // 50% power savings
                        end
                    end else begin
                        idle_counter <= 32'b0;
                        domain_clk_enable <= 4'b1111;  // All domains enabled
                        power_savings <= 8'b0;
                    end
                end
                
                STATE_IDLE: begin
                    if (!cpu_idle && !halt) begin
                        state <= STATE_NORMAL;
                        domain_clk_enable <= 4'b1111;
                        idle_counter <= 32'b0;
                        power_savings <= 8'b0;
                    end else if (power_down) begin
                        state <= STATE_POWER_DOWN;
                        clk_gated <= 1;
                        domain_clk_enable <= 4'b0000;
                        power_down_active <= 1;
                        power_savings <= 8'd100;
                    end
                end
                
                STATE_SLEEP: begin
                    if (!sleep_mode) begin
                        state <= STATE_NORMAL;
                        clk_gated <= 0;
                        domain_clk_enable <= 4'b1111;
                        sleep_active <= 0;
                        power_savings <= 8'b0;
                    end else if (power_down) begin
                        state <= STATE_POWER_DOWN;
                        power_down_active <= 1;
                        power_savings <= 8'd100;
                    end
                end
                
                STATE_POWER_DOWN: begin
                    if (!power_down) begin
                        state <= STATE_NORMAL;
                        clk_gated <= 0;
                        domain_clk_enable <= 4'b1111;
                        power_down_active <= 0;
                        power_savings <= 8'b0;
                    end
                end
                
                default: begin
                    state <= STATE_NORMAL;
                end
            endcase
        end
    end

endmodule
