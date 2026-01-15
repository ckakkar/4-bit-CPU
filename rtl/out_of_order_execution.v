// out_of_order_execution.v - Out-of-order execution engine
// Implements instruction queue, reservation stations, and reorder buffer

module out_of_order_execution (
    input clk,
    input rst,
    // Instruction dispatch
    input [15:0] instruction_in,        // Instruction from decode stage
    input instruction_valid,            // Instruction is valid
    input [7:0] pc_in,                  // PC of instruction
    // Register file interface
    input [7:0] reg_read_a,             // Register A value
    input [7:0] reg_read_b,             // Register B value
    input [2:0] reg1_addr, reg2_addr,   // Register addresses
    input [2:0] reg_dest_addr,          // Destination register
    // ALU interface
    output reg [7:0] alu_operand_a,     // ALU operand A
    output reg [7:0] alu_operand_b,     // ALU operand B
    output reg [3:0] alu_op,            // ALU operation
    output reg alu_start,                // Start ALU operation
    input [7:0] alu_result,             // ALU result
    input alu_ready,                     // ALU result ready
    // Instruction completion
    output reg [7:0] result_data,       // Result data
    output reg [2:0] result_reg,         // Result register
    output reg result_valid,             // Result is valid
    output reg [7:0] result_pc,          // PC of completed instruction
    // Status
    output reg queue_full,               // Instruction queue is full
    output reg queue_empty               // Instruction queue is empty
);

    // Instruction Queue (IQ) - holds decoded instructions waiting for execution
    localparam IQ_SIZE = 8;
    reg [15:0] iq_instruction [0:IQ_SIZE-1];
    reg [7:0] iq_pc [0:IQ_SIZE-1];
    reg [2:0] iq_reg_dest [0:IQ_SIZE-1];
    reg [3:0] iq_alu_op [0:IQ_SIZE-1];
    reg iq_valid [0:IQ_SIZE-1];
    reg [2:0] iq_head, iq_tail;
    reg [3:0] iq_count;
    
    // Reservation Stations (RS) - holds instructions ready for execution
    localparam RS_SIZE = 4;
    reg [7:0] rs_operand_a [0:RS_SIZE-1];
    reg [7:0] rs_operand_b [0:RS_SIZE-1];
    reg [3:0] rs_alu_op [0:RS_SIZE-1];
    reg [2:0] rs_reg_dest [0:RS_SIZE-1];
    reg [7:0] rs_pc [0:RS_SIZE-1];
    reg rs_valid [0:RS_SIZE-1];
    reg rs_ready [0:RS_SIZE-1];  // Operands ready
    reg [1:0] rs_operand_a_tag [0:RS_SIZE-1];  // Tag for operand A (from ROB)
    reg [1:0] rs_operand_b_tag [0:RS_SIZE-1];  // Tag for operand B (from ROB)
    
    // Reorder Buffer (ROB) - maintains program order for completion
    localparam ROB_SIZE = 8;
    reg [7:0] rob_result [0:ROB_SIZE-1];
    reg [2:0] rob_reg_dest [0:ROB_SIZE-1];
    reg [7:0] rob_pc [0:ROB_SIZE-1];
    reg rob_valid [0:ROB_SIZE-1];
    reg rob_ready [0:ROB_SIZE-1];  // Result ready
    reg [2:0] rob_head, rob_tail;
    reg [3:0] rob_count;
    
    // Register alias table (RAT) - maps logical registers to ROB entries
    reg [2:0] rat_rob_entry [0:7];  // Maps register to ROB entry
    reg rat_valid [0:7];             // Register has pending write in ROB
    
    integer i;
    
    // Initialize on reset
    always @(posedge rst) begin
        iq_head <= 0;
        iq_tail <= 0;
        iq_count <= 0;
        rob_head <= 0;
        rob_tail <= 0;
        rob_count <= 0;
        queue_full <= 0;
        queue_empty <= 1;
        
        for (i = 0; i < IQ_SIZE; i = i + 1) begin
            iq_valid[i] <= 0;
        end
        for (i = 0; i < RS_SIZE; i = i + 1) begin
            rs_valid[i] <= 0;
            rs_ready[i] <= 0;
        end
        for (i = 0; i < ROB_SIZE; i = i + 1) begin
            rob_valid[i] <= 0;
            rob_ready[i] <= 0;
        end
        for (i = 0; i < 8; i = i + 1) begin
            rat_valid[i] <= 0;
        end
    end
    
    // Instruction dispatch: Add to instruction queue
    always @(posedge clk) begin
        if (rst) begin
            // Already initialized
        end else if (instruction_valid && !queue_full) begin
            // Add to instruction queue
            iq_instruction[iq_tail] <= instruction_in;
            iq_pc[iq_tail] <= pc_in;
            iq_reg_dest[iq_tail] <= reg_dest_addr;
            iq_alu_op[iq_tail] <= alu_op;  // Would come from decode
            iq_valid[iq_tail] <= 1;
            iq_tail <= (iq_tail + 1) & 3'b111;  // Wrap around
            iq_count <= iq_count + 1;
            
            // Allocate ROB entry
            rob_reg_dest[rob_tail] <= reg_dest_addr;
            rob_pc[rob_tail] <= pc_in;
            rob_valid[rob_tail] <= 1;
            rob_ready[rob_tail] <= 0;
            rob_tail <= (rob_tail + 1) & 3'b111;
            rob_count <= rob_count + 1;
            
            // Update RAT
            if (reg_dest_addr != 3'b0) begin
                rat_rob_entry[reg_dest_addr] <= rob_tail;
                rat_valid[reg_dest_addr] <= 1;
            end
        end
    end
    
    // Issue: Move instructions from IQ to reservation stations when operands ready
    always @(posedge clk) begin
        if (rst) begin
            // Already initialized
        end else begin
            // Check if instruction at head can be issued
            if (iq_valid[iq_head] && rob_count < ROB_SIZE) begin
                // Check if operands are ready
                // (Simplified: assume operands ready if not dependent on ROB)
                // In full implementation, check RAT for operand dependencies
                
                // Find free reservation station
                for (i = 0; i < RS_SIZE; i = i + 1) begin
                    if (!rs_valid[i]) begin
                        // Issue instruction
                        rs_operand_a[i] <= reg_read_a;  // Would check RAT/ROB
                        rs_operand_b[i] <= reg_read_b;
                        rs_alu_op[i] <= iq_alu_op[iq_head];
                        rs_reg_dest[i] <= iq_reg_dest[iq_head];
                        rs_pc[i] <= iq_pc[iq_head];
                        rs_valid[i] <= 1;
                        rs_ready[i] <= 1;  // Operands ready (simplified)
                        
                        // Remove from IQ
                        iq_valid[iq_head] <= 0;
                        iq_head <= (iq_head + 1) & 3'b111;
                        iq_count <= iq_count - 1;
                        break;
                    end
                end
            end
        end
    end
    
    // Execute: Send ready instructions to ALU
    always @(posedge clk) begin
        if (rst) begin
            alu_start <= 0;
        end else begin
            alu_start <= 0;
            
            // Find ready instruction in reservation stations
            for (i = 0; i < RS_SIZE; i = i + 1) begin
                if (rs_valid[i] && rs_ready[i] && !alu_start) begin
                    alu_operand_a <= rs_operand_a[i];
                    alu_operand_b <= rs_operand_b[i];
                    alu_op <= rs_alu_op[i];
                    alu_start <= 1;
                    rs_valid[i] <= 0;  // Remove from RS
                    break;
                end
            end
        end
    end
    
    // Writeback: Write ALU result to ROB
    always @(posedge clk) begin
        if (rst) begin
            // Already initialized
        end else if (alu_ready) begin
            // Find ROB entry for this result (simplified - would track)
            // In full implementation, would track which ROB entry corresponds to ALU operation
            // For now, write to head of ROB
            if (rob_valid[rob_head] && !rob_ready[rob_head]) begin
                rob_result[rob_head] <= alu_result;
                rob_ready[rob_head] <= 1;
            end
        end
    end
    
    // Commit: Retire instructions in order from ROB
    always @(posedge clk) begin
        if (rst) begin
            result_valid <= 0;
        end else begin
            result_valid <= 0;
            
            // Commit instruction at ROB head if ready
            if (rob_valid[rob_head] && rob_ready[rob_head]) begin
                result_data <= rob_result[rob_head];
                result_reg <= rob_reg_dest[rob_head];
                result_pc <= rob_pc[rob_head];
                result_valid <= 1;
                
                // Update RAT
                if (rat_valid[rob_reg_dest[rob_head]]) begin
                    rat_valid[rob_reg_dest[rob_head]] <= 0;
                end
                
                // Remove from ROB
                rob_valid[rob_head] <= 0;
                rob_ready[rob_head] <= 0;
                rob_head <= (rob_head + 1) & 3'b111;
                rob_count <= rob_count - 1;
            end
        end
    end
    
    // Queue status
    always @(*) begin
        queue_full = (iq_count >= IQ_SIZE);
        queue_empty = (iq_count == 0);
    end

endmodule
