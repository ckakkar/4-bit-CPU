// realtime_scheduler.v - Real-time system scheduler
// Implements priority-based real-time scheduling with deadlines

module realtime_scheduler (
    input clk,
    input rst,
    // Task management
    input [7:0] task_id,                // Task identifier
    input [3:0] task_priority,          // Task priority (0=highest, 15=lowest)
    input [15:0] task_deadline,          // Task deadline (clock cycles)
    input task_ready,                   // Task is ready to execute
    input task_complete,                // Task completed execution
    // Scheduling
    output reg [7:0] scheduled_task,    // Currently scheduled task
    output reg schedule_valid,          // Schedule is valid
    output reg deadline_missed,         // Deadline missed
    // Timer
    input timer_tick,                   // Timer tick
    output reg [15:0] current_time,     // Current time
    // Task status
    output reg [15:0] task_remaining_time [0:15], // Remaining execution time per task
    output reg task_active [0:15],      // Task is active
    output reg task_missed_deadline [0:15] // Task missed deadline
);

    // Task queue: 16 tasks maximum
    localparam MAX_TASKS = 16;
    
    // Task control blocks
    reg [3:0] task_priorities [0:MAX_TASKS-1];
    reg [15:0] task_deadlines [0:MAX_TASKS-1];
    reg [15:0] task_wcet [0:MAX_TASKS-1];  // Worst-case execution time
    reg task_valid [0:MAX_TASKS-1];
    reg [15:0] task_start_time [0:MAX_TASKS-1];
    
    // Scheduling algorithm: Rate Monotonic (RM) or Earliest Deadline First (EDF)
    reg use_edf;  // 1 = EDF, 0 = RM
    
    integer i;
    
    // Initialize on reset
    always @(posedge rst) begin
        current_time <= 16'b0;
        scheduled_task <= 8'b0;
        schedule_valid <= 0;
        deadline_missed <= 0;
        use_edf <= 1;  // Use EDF by default
        
        for (i = 0; i < MAX_TASKS; i = i + 1) begin
            task_valid[i] <= 0;
            task_active[i] <= 0;
            task_missed_deadline[i] <= 0;
            task_remaining_time[i] <= 16'b0;
        end
    end
    
    // Time management
    always @(posedge clk) begin
        if (rst) begin
            current_time <= 16'b0;
        end else if (timer_tick) begin
            current_time <= current_time + 1;
        end
    end
    
    // Task registration
    always @(posedge clk) begin
        if (rst) begin
            // Already initialized
        end else if (task_ready && task_id < MAX_TASKS) begin
            // Register new task
            task_priorities[task_id] <= task_priority;
            task_deadlines[task_id] <= task_deadline;
            task_wcet[task_id] <= task_deadline;  // Simplified: WCET = deadline
            task_valid[task_id] <= 1;
            task_start_time[task_id] <= current_time;
            task_active[task_id] <= 1;
            task_remaining_time[task_id] <= task_deadline;
        end
    end
    
    // Scheduling: Earliest Deadline First (EDF)
    always @(posedge clk) begin
        if (rst) begin
            schedule_valid <= 0;
        end else begin
            schedule_valid <= 0;
            deadline_missed <= 0;
            
            if (use_edf) begin
                // EDF: Schedule task with earliest deadline
                reg [7:0] earliest_task = 8'hFF;
                reg [15:0] earliest_deadline = 16'hFFFF;
                
                for (i = 0; i < MAX_TASKS; i = i + 1) begin
                    if (task_valid[i] && task_active[i]) begin
                        reg [15:0] abs_deadline = task_start_time[i] + task_deadlines[i];
                        if (abs_deadline < earliest_deadline) begin
                            earliest_deadline = abs_deadline;
                            earliest_task = i;
                        end
                        
                        // Check for deadline miss
                        if (current_time > abs_deadline) begin
                            task_missed_deadline[i] <= 1;
                            deadline_missed <= 1;
                        end
                    end
                end
                
                if (earliest_task != 8'hFF) begin
                    scheduled_task <= earliest_task;
                    schedule_valid <= 1;
                end
            end else begin
                // Rate Monotonic: Schedule highest priority task
                reg [7:0] highest_priority_task = 8'hFF;
                reg [3:0] highest_priority = 4'hF;
                
                for (i = 0; i < MAX_TASKS; i = i + 1) begin
                    if (task_valid[i] && task_active[i]) begin
                        if (task_priorities[i] < highest_priority) begin
                            highest_priority = task_priorities[i];
                            highest_priority_task = i;
                        end
                    end
                end
                
                if (highest_priority_task != 8'hFF) begin
                    scheduled_task <= highest_priority_task;
                    schedule_valid <= 1;
                end
            end
        end
    end
    
    // Task completion
    always @(posedge clk) begin
        if (rst) begin
            // Already initialized
        end else if (task_complete) begin
            task_active[task_id] <= 0;
            task_remaining_time[task_id] <= 16'b0;
        end
    end
    
    // Update remaining time
    always @(posedge clk) begin
        if (rst) begin
            // Already initialized
        end else if (timer_tick && schedule_valid) begin
            if (task_remaining_time[scheduled_task] > 0) begin
                task_remaining_time[scheduled_task] <= task_remaining_time[scheduled_task] - 1;
            end
        end
    end

endmodule
