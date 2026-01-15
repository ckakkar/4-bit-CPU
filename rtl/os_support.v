// os_support.v - Operating System Support Hardware
// Implements privilege levels, system calls, memory protection, and context switching

module os_support (
    input clk,
    input rst,
    // Current execution context
    input [1:0] current_privilege,      // Privilege level: 00=kernel, 01=supervisor, 10=user, 11=reserved
    input [7:0] current_pid,           // Current process ID
    // System call interface
    input syscall_request,               // System call requested
    input [3:0] syscall_number,          // System call number
    input [7:0] syscall_arg0, syscall_arg1, syscall_arg2, // System call arguments
    output reg syscall_complete,         // System call completed
    output reg [7:0] syscall_result,     // System call return value
    // Memory protection
    input [7:0] mem_access_addr,        // Memory access address
    input mem_access_read,               // Memory read access
    input mem_access_write,              // Memory write access
    output reg mem_access_allowed,       // Memory access allowed
    output reg mem_protection_fault,     // Memory protection fault
    // Context switching
    input context_switch_request,       // Request context switch
    input [7:0] new_pid,                 // New process ID
    output reg context_switch_complete,  // Context switch completed
    // Process control block (PCB) - simplified
    output reg [7:0] saved_pc [0:15],   // Saved PC for 16 processes
    output reg [7:0] saved_regs [0:15][0:7], // Saved registers for 16 processes
    output reg [1:0] saved_privilege [0:15], // Saved privilege level
    output reg process_valid [0:15],    // Process is valid
    // Timer and scheduling
    input timer_tick,                    // Timer tick (for preemptive scheduling)
    output reg preempt_request,          // Request preemption
    output reg [7:0] timeslice_remaining  // Remaining time slice
);

    // Process Control Block (PCB) - simplified for 16 processes
    localparam MAX_PROCESSES = 16;
    
    // System call handler
    reg [2:0] syscall_state;
    localparam SYSCALL_IDLE = 3'b000;
    localparam SYSCALL_EXECUTE = 3'b001;
    localparam SYSCALL_COMPLETE = 3'b010;
    
    // Memory protection regions (simplified - 4 regions)
    reg [7:0] mem_region_base [0:3];     // Region base address
    reg [7:0] mem_region_limit [0:3];    // Region limit address
    reg [1:0] mem_region_privilege [0:3]; // Required privilege level
    reg mem_region_read [0:3];           // Read permission
    reg mem_region_write [0:3];          // Write permission
    reg mem_region_valid [0:3];          // Region is valid
    
    // Time slice management
    reg [7:0] timeslice_counter;
    localparam TIMESLICE_SIZE = 8'd100;  // 100 clock cycles per time slice
    
    integer i;
    
    // Initialize on reset
    always @(posedge rst) begin
        current_privilege <= 2'b00;  // Start in kernel mode
        syscall_complete <= 0;
        mem_access_allowed <= 1;  // Allow all initially
        mem_protection_fault <= 0;
        context_switch_complete <= 0;
        preempt_request <= 0;
        timeslice_remaining <= TIMESLICE_SIZE;
        syscall_state <= SYSCALL_IDLE;
        
        for (i = 0; i < MAX_PROCESSES; i = i + 1) begin
            process_valid[i] <= 0;
            saved_privilege[i] <= 2'b00;
        end
        for (i = 0; i < 4; i = i + 1) begin
            mem_region_valid[i] <= 0;
        end
    end
    
    // System call handler
    always @(posedge clk) begin
        if (rst) begin
            // Already initialized
        end else begin
            syscall_complete <= 0;
            
            case (syscall_state)
                SYSCALL_IDLE: begin
                    if (syscall_request) begin
                        syscall_state <= SYSCALL_EXECUTE;
                        
                        // Handle system call (simplified)
                        case (syscall_number)
                            4'b0000: begin
                                // SYS_EXIT - terminate process
                                syscall_result <= 8'b0;
                            end
                            4'b0001: begin
                                // SYS_READ - read from I/O
                                syscall_result <= syscall_arg0;  // Simplified
                            end
                            4'b0010: begin
                                // SYS_WRITE - write to I/O
                                syscall_result <= 8'b1;  // Success
                            end
                            4'b0011: begin
                                // SYS_FORK - create new process
                                syscall_result <= 8'd1;  // New PID (simplified)
                            end
                            default: begin
                                syscall_result <= 8'hFF;  // Invalid syscall
                            end
                        endcase
                    end
                end
                
                SYSCALL_EXECUTE: begin
                    // System call execution (would take multiple cycles in real implementation)
                    syscall_state <= SYSCALL_COMPLETE;
                end
                
                SYSCALL_COMPLETE: begin
                    syscall_complete <= 1;
                    syscall_state <= SYSCALL_IDLE;
                end
            endcase
        end
    end
    
    // Memory protection check
    always @(posedge clk) begin
        if (rst) begin
            mem_access_allowed <= 1;
            mem_protection_fault <= 0;
        end else begin
            mem_access_allowed <= 0;
            mem_protection_fault <= 0;
            
            // Check memory regions
            for (i = 0; i < 4; i = i + 1) begin
                if (mem_region_valid[i] && 
                    mem_access_addr >= mem_region_base[i] &&
                    mem_access_addr <= mem_region_limit[i]) begin
                    // Address in region
                    if (current_privilege < mem_region_privilege[i]) begin
                        // Insufficient privilege
                        mem_protection_fault <= 1;
                    end else if (mem_access_read && !mem_region_read[i]) begin
                        // Read not allowed
                        mem_protection_fault <= 1;
                    end else if (mem_access_write && !mem_region_write[i]) begin
                        // Write not allowed
                        mem_protection_fault <= 1;
                    end else begin
                        mem_access_allowed <= 1;
                    end
                    break;
                end
            end
        end
    end
    
    // Context switching
    always @(posedge clk) begin
        if (rst) begin
            context_switch_complete <= 0;
        end else begin
            context_switch_complete <= 0;
            
            if (context_switch_request) begin
                // Save current context (would save PC, registers, etc.)
                // Load new context
                // This is simplified - full implementation would save/restore all state
                context_switch_complete <= 1;
            end
        end
    end
    
    // Preemptive scheduling (time slice)
    always @(posedge clk) begin
        if (rst) begin
            timeslice_remaining <= TIMESLICE_SIZE;
            preempt_request <= 0;
        end else begin
            if (timer_tick) begin
                if (timeslice_remaining > 0) begin
                    timeslice_remaining <= timeslice_remaining - 1;
                end else begin
                    // Time slice expired - request preemption
                    preempt_request <= 1;
                    timeslice_remaining <= TIMESLICE_SIZE;
                end
            end else if (preempt_request) begin
                preempt_request <= 0;
            end
        end
    end

endmodule
