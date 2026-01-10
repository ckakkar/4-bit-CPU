// interrupt_controller.v - Hardware interrupt controller with interrupt vector table
// Supports multiple interrupt sources with priority and interrupt vector table

module interrupt_controller (
    input clk,
    input rst,
    input interrupt_enable,      // Global interrupt enable flag
    input [7:0] interrupt_mask,  // Interrupt mask (1 = enabled, 0 = masked)
    // Interrupt sources
    input int_timer,             // Timer interrupt
    input int_uart_rx,           // UART RX interrupt (data ready)
    input int_uart_tx,           // UART TX interrupt (transmit complete)
    input int_gpio,              // GPIO interrupt (edge detected)
    input int_external_0,        // External interrupt 0
    input int_external_1,        // External interrupt 1
    input int_external_2,        // External interrupt 2
    input int_external_3,        // External interrupt 3
    // Interrupt handling
    input interrupt_ack,         // Interrupt acknowledge (from CPU)
    input interrupt_ret,         // Interrupt return (RETI instruction)
    output reg interrupt_request, // Interrupt request to CPU
    output reg [7:0] interrupt_vector, // Interrupt vector (ISR address)
    output reg [7:0] interrupt_id,     // Interrupt ID (for debugging)
    // Status
    output reg in_interrupt,     // Currently in interrupt service routine
    output [7:0] pending_interrupts // Pending interrupt status
);

    // Interrupt vector table (ISR addresses)
    // Each interrupt has a vector address pointing to its ISR
    localparam INT_VECTOR_TIMER = 8'h10;    // Timer ISR at address 0x10
    localparam INT_VECTOR_UART_RX = 8'h12;  // UART RX ISR at address 0x12
    localparam INT_VECTOR_UART_TX = 8'h14;  // UART TX ISR at address 0x14
    localparam INT_VECTOR_GPIO = 8'h16;     // GPIO ISR at address 0x16
    localparam INT_VECTOR_EXT0 = 8'h18;     // External 0 ISR at address 0x18
    localparam INT_VECTOR_EXT1 = 8'h1A;     // External 1 ISR at address 0x1A
    localparam INT_VECTOR_EXT2 = 8'h1C;     // External 2 ISR at address 0x1C
    localparam INT_VECTOR_EXT3 = 8'h1E;     // External 3 ISR at address 0x1E
    
    // Interrupt priority (higher number = higher priority)
    localparam PRIORITY_TIMER = 4'd7;   // Highest priority
    localparam PRIORITY_UART_RX = 4'd6;
    localparam PRIORITY_UART_TX = 4'd5;
    localparam PRIORITY_GPIO = 4'd4;
    localparam PRIORITY_EXT0 = 4'd3;
    localparam PRIORITY_EXT1 = 4'd2;
    localparam PRIORITY_EXT2 = 4'd1;
    localparam PRIORITY_EXT3 = 4'd0;    // Lowest priority
    
    // Interrupt state
    reg [7:0] interrupt_pending;  // Pending interrupts (latched)
    reg [7:0] interrupt_priority; // Current highest priority interrupt
    reg [2:0] state;
    
    localparam STATE_IDLE = 3'b000;
    localparam STATE_REQUEST = 3'b001;
    localparam STATE_ACK = 3'b010;
    localparam STATE_SERVICING = 3'b011;
    
    // Collect all interrupt sources
    wire [7:0] interrupt_sources = {
        int_external_3,
        int_external_2,
        int_external_1,
        int_external_0,
        int_gpio,
        int_uart_tx,
        int_uart_rx,
        int_timer
    };
    
    // Masked interrupts (enabled and pending)
    wire [7:0] masked_interrupts = interrupt_sources & interrupt_mask;
    
    assign pending_interrupts = interrupt_pending;
    
    // Latch interrupts (edge-sensitive)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            interrupt_pending <= 8'b0;
            interrupt_request <= 0;
            interrupt_vector <= 8'b0;
            interrupt_id <= 8'b0;
            in_interrupt <= 0;
            state <= STATE_IDLE;
            interrupt_priority <= 8'b0;
        end else begin
            // Latch rising edges of interrupt sources
            interrupt_pending <= interrupt_pending | masked_interrupts;
            
            case (state)
                STATE_IDLE: begin
                    in_interrupt <= 0;
                    if (interrupt_enable && |interrupt_pending) begin
                        // Determine highest priority interrupt
                        if (interrupt_pending[0] && interrupt_mask[0]) begin
                            // Timer interrupt (highest priority)
                            interrupt_vector <= INT_VECTOR_TIMER;
                            interrupt_id <= 8'd0;
                            interrupt_priority <= PRIORITY_TIMER;
                            interrupt_request <= 1;
                            state <= STATE_REQUEST;
                        end else if (interrupt_pending[1] && interrupt_mask[1]) begin
                            // UART RX interrupt
                            interrupt_vector <= INT_VECTOR_UART_RX;
                            interrupt_id <= 8'd1;
                            interrupt_priority <= PRIORITY_UART_RX;
                            interrupt_request <= 1;
                            state <= STATE_REQUEST;
                        end else if (interrupt_pending[2] && interrupt_mask[2]) begin
                            // UART TX interrupt
                            interrupt_vector <= INT_VECTOR_UART_TX;
                            interrupt_id <= 8'd2;
                            interrupt_priority <= PRIORITY_UART_TX;
                            interrupt_request <= 1;
                            state <= STATE_REQUEST;
                        end else if (interrupt_pending[3] && interrupt_mask[3]) begin
                            // GPIO interrupt
                            interrupt_vector <= INT_VECTOR_GPIO;
                            interrupt_id <= 8'd3;
                            interrupt_priority <= PRIORITY_GPIO;
                            interrupt_request <= 1;
                            state <= STATE_REQUEST;
                        end else if (interrupt_pending[4] && interrupt_mask[4]) begin
                            // External 0 interrupt
                            interrupt_vector <= INT_VECTOR_EXT0;
                            interrupt_id <= 8'd4;
                            interrupt_priority <= PRIORITY_EXT0;
                            interrupt_request <= 1;
                            state <= STATE_REQUEST;
                        end else if (interrupt_pending[5] && interrupt_mask[5]) begin
                            // External 1 interrupt
                            interrupt_vector <= INT_VECTOR_EXT1;
                            interrupt_id <= 8'd5;
                            interrupt_priority <= PRIORITY_EXT1;
                            interrupt_request <= 1;
                            state <= STATE_REQUEST;
                        end else if (interrupt_pending[6] && interrupt_mask[6]) begin
                            // External 2 interrupt
                            interrupt_vector <= INT_VECTOR_EXT2;
                            interrupt_id <= 8'd6;
                            interrupt_priority <= PRIORITY_EXT2;
                            interrupt_request <= 1;
                            state <= STATE_REQUEST;
                        end else if (interrupt_pending[7] && interrupt_mask[7]) begin
                            // External 3 interrupt
                            interrupt_vector <= INT_VECTOR_EXT3;
                            interrupt_id <= 8'd7;
                            interrupt_priority <= PRIORITY_EXT3;
                            interrupt_request <= 1;
                            state <= STATE_REQUEST;
                        end
                    end
                end
                
                STATE_REQUEST: begin
                    if (interrupt_ack) begin
                        // CPU acknowledged interrupt
                        interrupt_request <= 0;
                        in_interrupt <= 1;
                        // Clear pending bit for this interrupt
                        interrupt_pending[interrupt_id] <= 0;
                        state <= STATE_SERVICING;
                    end
                end
                
                STATE_SERVICING: begin
                    // Waiting for ISR to complete
                    if (interrupt_ret) begin
                        // RETI instruction - return from interrupt
                        in_interrupt <= 0;
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
