// debug_unit.v - Advanced debug support unit
// Provides breakpoints, single-step mode, instruction tracing, and register/memory inspection

module debug_unit (
    input clk,
    input rst,
    // CPU interface
    input [7:0] pc,                    // Current program counter
    input [15:0] instruction,          // Current instruction
    input [7:0] reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7, // Register values
    input [7:0] mem_addr,              // Memory address being accessed
    input [7:0] mem_data,              // Memory data
    input mem_read,                    // Memory read operation
    input mem_write,                   // Memory write operation
    // Debug control
    input debug_enable,                // Enable debug mode
    input single_step,                  // Single-step mode (execute one instruction)
    input [7:0] breakpoint_addr,       // Breakpoint address (PC)
    input breakpoint_enable,           // Enable breakpoint
    input trace_enable,                // Enable instruction tracing
    input [2:0] trace_depth,           // Trace buffer depth (0-7 = 1-8 entries)
    // Debug outputs
    output reg debug_halt,             // Halt CPU for debugging
    output reg breakpoint_hit,         // Breakpoint was hit
    output reg [7:0] debug_pc,         // Debug PC value
    output reg [15:0] debug_instruction, // Debug instruction
    output reg [7:0] debug_regs [0:7], // Debug register snapshot
    output reg [7:0] debug_mem_addr,   // Debug memory address
    output reg [7:0] debug_mem_data,   // Debug memory data
    output reg debug_mem_read,          // Debug memory read flag
    output reg debug_mem_write,         // Debug memory write flag
    // Trace buffer
    output reg [7:0] trace_pc [0:7],   // Trace PC buffer
    output reg [15:0] trace_inst [0:7], // Trace instruction buffer
    output reg [2:0] trace_count,      // Number of trace entries
    output reg trace_full,             // Trace buffer is full
    // Watchpoints
    input [7:0] watchpoint_addr,       // Watchpoint address (memory)
    input watchpoint_enable,           // Enable watchpoint
    output reg watchpoint_hit,         // Watchpoint was hit
    // Register inspection
    input [2:0] inspect_reg_addr,      // Register address to inspect
    output [7:0] inspect_reg_data,     // Register data at address
    // Memory inspection
    input [7:0] inspect_mem_addr,      // Memory address to inspect
    output [7:0] inspect_mem_data      // Memory data at address
);

    // Internal state
    reg [2:0] state;
    localparam STATE_IDLE = 3'b000;
    localparam STATE_SINGLE_STEP = 3'b001;
    localparam STATE_BREAKPOINT = 3'b010;
    localparam STATE_WATCHPOINT = 3'b011;
    localparam STATE_TRACING = 3'b100;
    
    reg step_complete;
    reg [2:0] trace_index;
    
    integer i;
    
    // Initialize on reset
    always @(posedge rst) begin
        debug_halt <= 0;
        breakpoint_hit <= 0;
        watchpoint_hit <= 0;
        trace_count <= 0;
        trace_full <= 0;
        trace_index <= 0;
        step_complete <= 0;
        state <= STATE_IDLE;
        for (i = 0; i < 8; i = i + 1) begin
            trace_pc[i] <= 8'b0;
            trace_inst[i] <= 16'b0;
            debug_regs[i] <= 8'b0;
        end
    end
    
    // Debug state machine
    always @(posedge clk) begin
        if (rst) begin
            // Already initialized
        end else begin
            // Capture current state
            debug_pc <= pc;
            debug_instruction <= instruction;
            debug_regs[0] <= reg0;
            debug_regs[1] <= reg1;
            debug_regs[2] <= reg2;
            debug_regs[3] <= reg3;
            debug_regs[4] <= reg4;
            debug_regs[5] <= reg5;
            debug_regs[6] <= reg6;
            debug_regs[7] <= reg7;
            debug_mem_addr <= mem_addr;
            debug_mem_data <= mem_data;
            debug_mem_read <= mem_read;
            debug_mem_write <= mem_write;
            
            if (debug_enable) begin
                case (state)
                    STATE_IDLE: begin
                        debug_halt <= 0;
                        breakpoint_hit <= 0;
                        watchpoint_hit <= 0;
                        
                        // Check for breakpoint
                        if (breakpoint_enable && pc == breakpoint_addr) begin
                            state <= STATE_BREAKPOINT;
                            breakpoint_hit <= 1;
                            debug_halt <= 1;
                        end
                        // Check for watchpoint
                        else if (watchpoint_enable && (mem_read || mem_write) && mem_addr == watchpoint_addr) begin
                            state <= STATE_WATCHPOINT;
                            watchpoint_hit <= 1;
                            debug_halt <= 1;
                        end
                        // Single-step mode
                        else if (single_step) begin
                            state <= STATE_SINGLE_STEP;
                            debug_halt <= 0;  // Allow one instruction
                            step_complete <= 0;
                        end
                        // Tracing mode
                        else if (trace_enable) begin
                            state <= STATE_TRACING;
                            debug_halt <= 0;
                        end else begin
                            debug_halt <= 0;
                        end
                    end
                    
                    STATE_SINGLE_STEP: begin
                        // Execute one instruction, then halt
                        if (!step_complete) begin
                            step_complete <= 1;
                            debug_halt <= 0;
                        end else begin
                            debug_halt <= 1;
                            state <= STATE_IDLE;
                            step_complete <= 0;
                        end
                    end
                    
                    STATE_BREAKPOINT: begin
                        // Halted at breakpoint - wait for debugger command
                        debug_halt <= 1;
                        if (!breakpoint_enable) begin
                            state <= STATE_IDLE;
                            breakpoint_hit <= 0;
                        end
                    end
                    
                    STATE_WATCHPOINT: begin
                        // Halted at watchpoint - wait for debugger command
                        debug_halt <= 1;
                        if (!watchpoint_enable) begin
                            state <= STATE_IDLE;
                            watchpoint_hit <= 0;
                        end
                    end
                    
                    STATE_TRACING: begin
                        // Record instruction in trace buffer
                        if (trace_count < trace_depth + 1) begin
                            trace_pc[trace_index] <= pc;
                            trace_inst[trace_index] <= instruction;
                            trace_index <= (trace_index + 1) & 3'b111;  // Wrap around
                            trace_count <= trace_count + 1;
                        end else begin
                            trace_full <= 1;
                        end
                        
                        if (!trace_enable) begin
                            state <= STATE_IDLE;
                        end
                    end
                    
                    default: begin
                        state <= STATE_IDLE;
                    end
                endcase
            end else begin
                debug_halt <= 0;
                state <= STATE_IDLE;
            end
        end
    end
    
    // Register inspection (combinational)
    assign inspect_reg_data = (inspect_reg_addr == 3'b000) ? reg0 :
                             (inspect_reg_addr == 3'b001) ? reg1 :
                             (inspect_reg_addr == 3'b010) ? reg2 :
                             (inspect_reg_addr == 3'b011) ? reg3 :
                             (inspect_reg_addr == 3'b100) ? reg4 :
                             (inspect_reg_addr == 3'b101) ? reg5 :
                             (inspect_reg_addr == 3'b110) ? reg6 : reg7;
    
    // Memory inspection (would need memory interface - placeholder)
    assign inspect_mem_data = 8'b0;  // Would connect to memory read port

endmodule
