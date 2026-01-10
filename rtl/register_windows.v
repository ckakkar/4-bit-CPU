// register_windows.v - Register windows with overlapping register sets
// Implements windowed register file for fast context switching
// Configuration: 8 global registers + N windows with 8 registers each

module register_windows (
    input clk,
    input rst,
    input write_enable,           // Write enable
    input [2:0] read_addr_a,      // Read address A (local register number 0-7)
    input [2:0] read_addr_b,      // Read address B
    input [2:0] write_addr,       // Write address (local register number)
    input [7:0] write_data,       // Write data
    input [1:0] window_select,    // Current window number (0-3 for 4 windows)
    input save_window,            // Save current window (context switch)
    input restore_window,         // Restore window (context switch)
    output [7:0] read_data_a,     // Read data A
    output [7:0] read_data_b,     // Read data B
    output [1:0] current_window   // Current active window
);

    // Register window parameters
    localparam NUM_WINDOWS = 4;   // 4 register windows
    localparam REGS_PER_WINDOW = 8; // 8 registers per window
    localparam OVERLAP_SIZE = 4;   // 4 overlapping registers between windows
    
    // Register storage: flattened arrays for each window
    reg [7:0] registers_win0 [0:7];
    reg [7:0] registers_win1 [0:7];
    reg [7:0] registers_win2 [0:7];
    reg [7:0] registers_win3 [0:7];
    reg [1:0] active_window;      // Currently active window
    reg [7:0] global_regs [0:7];  // 8 global registers (shared across all windows)
    
    integer i;
    
    // Initialize registers on reset
    always @(posedge rst) begin
        active_window <= 2'b0;
        for (i = 0; i < 8; i = i + 1) begin
            registers_win0[i] <= 8'b0;
            registers_win1[i] <= 8'b0;
            registers_win2[i] <= 8'b0;
            registers_win3[i] <= 8'b0;
            global_regs[i] <= 8'b0;
        end
    end
    
    // Window selection and context switching
    always @(posedge clk) begin
        if (rst) begin
            active_window <= 2'b0;
        end else begin
            if (save_window) begin
                // Save current window state (could save to memory in full implementation)
                // For now, just mark for saving
            end else if (restore_window) begin
                // Restore window state (would load from memory in full implementation)
                // For now, switch to specified window
                active_window <= window_select;
            end else if (window_select != active_window) begin
                // Switch window
                active_window <= window_select;
            end
        end
    end
    
    // Register addressing with windowing
    // Address mapping:
    //  0-7: Local window registers
    //  Special handling for overlapping registers would go here
    //  Global registers accessed through special addressing (not implemented here for simplicity)
    
    // Read operations (combinational) - select based on active window
    wire [7:0] read_data_a_win0, read_data_a_win1, read_data_a_win2, read_data_a_win3;
    wire [7:0] read_data_b_win0, read_data_b_win1, read_data_b_win2, read_data_b_win3;
    
    assign read_data_a_win0 = (read_addr_a < 8) ? registers_win0[read_addr_a] : 8'b0;
    assign read_data_a_win1 = (read_addr_a < 8) ? registers_win1[read_addr_a] : 8'b0;
    assign read_data_a_win2 = (read_addr_a < 8) ? registers_win2[read_addr_a] : 8'b0;
    assign read_data_a_win3 = (read_addr_a < 8) ? registers_win3[read_addr_a] : 8'b0;
    
    assign read_data_b_win0 = (read_addr_b < 8) ? registers_win0[read_addr_b] : 8'b0;
    assign read_data_b_win1 = (read_addr_b < 8) ? registers_win1[read_addr_b] : 8'b0;
    assign read_data_b_win2 = (read_addr_b < 8) ? registers_win2[read_addr_b] : 8'b0;
    assign read_data_b_win3 = (read_addr_b < 8) ? registers_win3[read_addr_b] : 8'b0;
    
    assign read_data_a = (active_window == 2'b00) ? read_data_a_win0 :
                         (active_window == 2'b01) ? read_data_a_win1 :
                         (active_window == 2'b10) ? read_data_a_win2 : read_data_a_win3;
    
    assign read_data_b = (active_window == 2'b00) ? read_data_b_win0 :
                         (active_window == 2'b01) ? read_data_b_win1 :
                         (active_window == 2'b10) ? read_data_b_win2 : read_data_b_win3;
    
    // Write operation (sequential)
    always @(posedge clk) begin
        if (rst) begin
            // Already initialized in reset block
        end else if (write_enable && write_addr < 8) begin
            case (active_window)
                2'b00: registers_win0[write_addr] <= write_data;
                2'b01: registers_win1[write_addr] <= write_data;
                2'b10: registers_win2[write_addr] <= write_data;
                2'b11: registers_win3[write_addr] <= write_data;
            endcase
        end
    end
    
    assign current_window = active_window;

endmodule
