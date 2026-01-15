// performance_counters.v - Performance counters and profiling unit
// Tracks CPU performance metrics: cycles, instructions, cache hits/misses, branch predictions, etc.

module performance_counters (
    input clk,
    input rst,
    input enable,                      // Enable performance counting
    // CPU events
    input instruction_retired,         // Instruction completed execution
    input cache_hit,                   // Cache hit event
    input cache_miss,                  // Cache miss event
    input branch_taken,                // Branch was taken
    input branch_not_taken,            // Branch was not taken
    input branch_mispredict,           // Branch misprediction
    input stall_cycle,                 // Pipeline stall cycle
    input interrupt_serviced,          // Interrupt service routine executed
    // Counter control
    input [3:0] counter_select,        // Select which counter to read
    input counter_reset,               // Reset all counters
    // Counter outputs
    output reg [31:0] cycle_count,     // Total clock cycles
    output reg [31:0] instruction_count, // Instructions retired
    output reg [31:0] cache_hit_count,  // Cache hits
    output reg [31:0] cache_miss_count, // Cache misses
    output reg [31:0] branch_taken_count, // Branches taken
    output reg [31:0] branch_not_taken_count, // Branches not taken
    output reg [31:0] branch_mispredict_count, // Branch mispredictions
    output reg [31:0] stall_count,     // Pipeline stall cycles
    output reg [31:0] interrupt_count, // Interrupts serviced
    output reg [31:0] selected_counter // Currently selected counter value
);

    // Performance metrics
    always @(posedge clk or posedge rst) begin
        if (rst || counter_reset) begin
            cycle_count <= 32'b0;
            instruction_count <= 32'b0;
            cache_hit_count <= 32'b0;
            cache_miss_count <= 32'b0;
            branch_taken_count <= 32'b0;
            branch_not_taken_count <= 32'b0;
            branch_mispredict_count <= 32'b0;
            stall_count <= 32'b0;
            interrupt_count <= 32'b0;
        end else if (enable) begin
            // Always increment cycle counter
            cycle_count <= cycle_count + 1;
            
            // Event counters
            if (instruction_retired) instruction_count <= instruction_count + 1;
            if (cache_hit) cache_hit_count <= cache_hit_count + 1;
            if (cache_miss) cache_miss_count <= cache_miss_count + 1;
            if (branch_taken) branch_taken_count <= branch_taken_count + 1;
            if (branch_not_taken) branch_not_taken_count <= branch_not_taken_count + 1;
            if (branch_mispredict) branch_mispredict_count <= branch_mispredict_count + 1;
            if (stall_cycle) stall_count <= stall_count + 1;
            if (interrupt_serviced) interrupt_count <= interrupt_count + 1;
        end
    end
    
    // Counter selection (combinational)
    always @(*) begin
        case (counter_select)
            4'b0000: selected_counter = cycle_count;
            4'b0001: selected_counter = instruction_count;
            4'b0010: selected_counter = cache_hit_count;
            4'b0011: selected_counter = cache_miss_count;
            4'b0100: selected_counter = branch_taken_count;
            4'b0101: selected_counter = branch_not_taken_count;
            4'b0110: selected_counter = branch_mispredict_count;
            4'b0111: selected_counter = stall_count;
            4'b1000: selected_counter = interrupt_count;
            default: selected_counter = 32'b0;
        endcase
    end
    
    // Performance metrics (combinational calculations)
    // Instructions per cycle (IPC) = instruction_count / cycle_count
    // Cache hit rate = cache_hit_count / (cache_hit_count + cache_miss_count)
    // Branch prediction accuracy = (branch_taken_count + branch_not_taken_count - branch_mispredict_count) / (branch_taken_count + branch_not_taken_count)

endmodule
