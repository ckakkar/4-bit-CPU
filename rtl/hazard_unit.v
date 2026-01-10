// hazard_unit.v - Hazard detection and forwarding unit for pipeline
// Detects data hazards and control hazards, generates forwarding and stall signals

module hazard_unit (
    // Pipeline register contents
    input [2:0] id_reg1_addr,      // ID stage register 1 address
    input [2:0] id_reg2_addr,      // ID stage register 2 address
    input [2:0] ex_reg_dest_addr,  // EX stage destination register
    input [2:0] mem_reg_dest_addr, // MEM stage destination register
    input [2:0] wb_reg_dest_addr,  // WB stage destination register
    // Control signals
    input ex_reg_write_enable,     // EX stage will write register
    input mem_reg_write_enable,    // MEM stage will write register
    input wb_reg_write_enable,     // WB stage will write register
    input mem_load_from_mem,       // MEM stage is load instruction
    input ex_is_branch,            // EX stage is branch instruction
    input branch_taken,            // Branch was taken (from branch predictor or ALU)
    // Forwarding outputs
    output reg [1:0] forward_a,    // Forwarding for ALU operand A (00=reg, 01=EX/MEM, 10=MEM/WB, 11=FPU)
    output reg [1:0] forward_b,    // Forwarding for ALU operand B
    // Hazard outputs
    output reg stall_pipeline,     // Stall pipeline (insert bubble)
    output reg flush_if_id,        // Flush IF/ID register (branch mispredict)
    output reg flush_id_ex,        // Flush ID/EX register (branch mispredict)
    output reg flush_ex_mem        // Flush EX/MEM register (branch mispredict)
);

    // Forwarding logic for ALU operand A
    always @(*) begin
        // Forward from MEM stage (highest priority - most recent)
        if (ex_reg_write_enable && mem_reg_dest_addr != 3'b0 && 
            mem_reg_dest_addr == id_reg1_addr) begin
            forward_a = 2'b01;  // Forward from EX/MEM
        end
        // Forward from WB stage (second priority)
        else if (wb_reg_write_enable && wb_reg_dest_addr != 3'b0 && 
                 wb_reg_dest_addr == id_reg1_addr && 
                 !(ex_reg_write_enable && mem_reg_dest_addr == id_reg1_addr)) begin
            forward_a = 2'b10;  // Forward from MEM/WB
        end
        // Forward from FPU (if needed in future)
        else begin
            forward_a = 2'b00;  // Use register file
        end
    end

    // Forwarding logic for ALU operand B
    always @(*) begin
        // Forward from MEM stage (highest priority)
        if (ex_reg_write_enable && mem_reg_dest_addr != 3'b0 && 
            mem_reg_dest_addr == id_reg2_addr) begin
            forward_b = 2'b01;  // Forward from EX/MEM
        end
        // Forward from WB stage (second priority)
        else if (wb_reg_write_enable && wb_reg_dest_addr != 3'b0 && 
                 wb_reg_dest_addr == id_reg2_addr &&
                 !(ex_reg_write_enable && mem_reg_dest_addr == id_reg2_addr)) begin
            forward_b = 2'b10;  // Forward from MEM/WB
        end
        else begin
            forward_b = 2'b00;  // Use register file
        end
    end

    // Load-use hazard detection (stall pipeline)
    always @(*) begin
        // If EX stage is a load and destination matches ID source registers
        if (mem_load_from_mem && ex_reg_write_enable && 
            ((ex_reg_dest_addr == id_reg1_addr && id_reg1_addr != 3'b0) ||
             (ex_reg_dest_addr == id_reg2_addr && id_reg2_addr != 3'b0))) begin
            stall_pipeline = 1'b1;  // Stall for one cycle
        end else begin
            stall_pipeline = 1'b0;
        end
    end

    // Control hazard handling (branch misprediction)
    always @(*) begin
        if (ex_is_branch) begin
            if (branch_taken) begin
                // Branch was taken but predictor said not taken (or vice versa)
                // Need to flush instructions in IF and ID stages
                flush_if_id = 1'b1;
                flush_id_ex = 1'b1;
                flush_ex_mem = 1'b0;
            end else begin
                // Branch not taken, continue normally
                flush_if_id = 1'b0;
                flush_id_ex = 1'b0;
                flush_ex_mem = 1'b0;
            end
        end else begin
            flush_if_id = 1'b0;
            flush_id_ex = 1'b0;
            flush_ex_mem = 1'b0;
        end
    end

endmodule
