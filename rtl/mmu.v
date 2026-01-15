// mmu.v - Memory Management Unit
// Implements virtual memory with page tables and TLB (Translation Lookaside Buffer)

module mmu (
    input clk,
    input rst,
    // Virtual address input
    input [7:0] virtual_addr,           // Virtual address (8-bit for simplicity)
    input [1:0] access_type,            // Access type: 00=read, 01=write, 10=execute
    // Physical address output
    output reg [7:0] physical_addr,      // Physical address
    output reg translation_valid,       // Translation is valid
    output reg page_fault,              // Page fault occurred
    output reg access_violation,         // Access violation (permission denied)
    // Page table base register
    input [7:0] page_table_base,        // Base address of page table
    // TLB interface
    output reg tlb_miss,                // TLB miss (need page table walk)
    output reg tlb_hit,                 // TLB hit (translation cached)
    // Memory interface for page table walk
    output reg [7:0] pt_walk_addr,      // Address for page table walk
    output reg pt_walk_enable,          // Enable page table walk
    input [7:0] pt_walk_data,           // Data from page table
    input pt_walk_ready                 // Page table walk data ready
);

    // Page size: 16 bytes (4-bit page offset)
    // Virtual address: [7:4] = page number, [3:0] = page offset
    // Physical address: [7:4] = frame number, [3:0] = page offset (same)
    
    // TLB: 8 entries
    localparam TLB_SIZE = 8;
    reg [3:0] tlb_vpn [0:TLB_SIZE-1];  // Virtual page number
    reg [3:0] tlb_pfn [0:TLB_SIZE-1];  // Physical frame number
    reg tlb_valid [0:TLB_SIZE-1];      // TLB entry valid
    reg tlb_dirty [0:TLB_SIZE-1];      // Dirty bit
    reg [1:0] tlb_permissions [0:TLB_SIZE-1]; // Permissions: 00=none, 01=read, 10=write, 11=read/write
    reg [TLB_SIZE-1:0] tlb_lru;        // LRU bits for TLB replacement
    
    // Page table entry format (8 bits):
    // [7:4] = Physical frame number
    // [3:2] = Permissions (00=none, 01=read, 10=write, 11=read/write)
    // [1] = Valid bit
    // [0] = Present bit
    
    wire [3:0] vpn = virtual_addr[7:4];  // Virtual page number
    wire [3:0] page_offset = virtual_addr[3:0];  // Page offset
    
    reg [2:0] state;
    localparam STATE_IDLE = 3'b000;
    localparam STATE_TLB_LOOKUP = 3'b001;
    localparam STATE_PAGE_TABLE_WALK = 3'b010;
    localparam STATE_UPDATE_TLB = 3'b011;
    localparam STATE_FAULT = 3'b100;
    
    integer i;
    
    // Initialize TLB on reset
    always @(posedge rst) begin
        for (i = 0; i < TLB_SIZE; i = i + 1) begin
            tlb_valid[i] <= 0;
            tlb_dirty[i] <= 0;
            tlb_vpn[i] <= 4'b0;
            tlb_pfn[i] <= 4'b0;
            tlb_permissions[i] <= 2'b0;
        end
        tlb_lru <= {TLB_SIZE{1'b0}};
        state <= STATE_IDLE;
    end
    
    // Address translation
    always @(posedge clk) begin
        if (rst) begin
            translation_valid <= 0;
            page_fault <= 0;
            access_violation <= 0;
            tlb_miss <= 0;
            tlb_hit <= 0;
            pt_walk_enable <= 0;
        end else begin
            translation_valid <= 0;
            page_fault <= 0;
            access_violation <= 0;
            tlb_miss <= 0;
            tlb_hit <= 0;
            pt_walk_enable <= 0;
            
            case (state)
                STATE_IDLE: begin
                    state <= STATE_TLB_LOOKUP;
                end
                
                STATE_TLB_LOOKUP: begin
                    // Search TLB for virtual page number
                    reg tlb_found;
                    reg [2:0] tlb_index;
                    tlb_found = 0;
                    
                    for (i = 0; i < TLB_SIZE; i = i + 1) begin
                        if (tlb_valid[i] && tlb_vpn[i] == vpn) begin
                            tlb_found = 1;
                            tlb_index = i;
                            break;
                        end
                    end
                    
                    if (tlb_found) begin
                        // TLB hit
                        tlb_hit <= 1;
                        
                        // Check permissions
                        if ((access_type == 2'b00 && tlb_permissions[tlb_index][0] == 0) ||
                            (access_type == 2'b01 && tlb_permissions[tlb_index][1] == 0)) begin
                            // Access violation
                            access_violation <= 1;
                            state <= STATE_FAULT;
                        end else begin
                            // Translation successful
                            physical_addr <= {tlb_pfn[tlb_index], page_offset};
                            translation_valid <= 1;
                            
                            // Update dirty bit on write
                            if (access_type == 2'b01) begin
                                tlb_dirty[tlb_index] <= 1;
                            end
                            
                            // Update LRU
                            tlb_lru[tlb_index] <= 1;
                            
                            state <= STATE_IDLE;
                        end
                    end else begin
                        // TLB miss - need page table walk
                        tlb_miss <= 1;
                        state <= STATE_PAGE_TABLE_WALK;
                        pt_walk_addr <= page_table_base + vpn;  // Page table entry address
                        pt_walk_enable <= 1;
                    end
                end
                
                STATE_PAGE_TABLE_WALK: begin
                    if (pt_walk_ready) begin
                        // Read page table entry
                        reg [7:0] pte = pt_walk_data;
                        reg [3:0] pfn = pte[7:4];
                        reg [1:0] perm = pte[3:2];
                        reg valid = pte[1];
                        reg present = pte[0];
                        
                        if (!present || !valid) begin
                            // Page fault
                            page_fault <= 1;
                            state <= STATE_FAULT;
                        end else begin
                            // Check permissions
                            if ((access_type == 2'b00 && perm[0] == 0) ||
                                (access_type == 2'b01 && perm[1] == 0)) begin
                                // Access violation
                                access_violation <= 1;
                                state <= STATE_FAULT;
                            end else begin
                                // Translation successful - update TLB
                                state <= STATE_UPDATE_TLB;
                                
                                // Find LRU TLB entry to replace
                                reg [2:0] lru_index = 0;
                                for (i = 0; i < TLB_SIZE; i = i + 1) begin
                                    if (!tlb_lru[i]) begin
                                        lru_index = i;
                                        break;
                                    end
                                end
                                
                                // Update TLB entry
                                tlb_vpn[lru_index] <= vpn;
                                tlb_pfn[lru_index] <= pfn;
                                tlb_permissions[lru_index] <= perm;
                                tlb_valid[lru_index] <= 1;
                                tlb_dirty[lru_index] <= (access_type == 2'b01);
                                tlb_lru[lru_index] <= 1;
                                
                                // Generate physical address
                                physical_addr <= {pfn, page_offset};
                                translation_valid <= 1;
                                
                                pt_walk_enable <= 0;
                                state <= STATE_IDLE;
                            end
                        end
                    end
                end
                
                STATE_FAULT: begin
                    // Page fault or access violation
                    state <= STATE_IDLE;
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
