// memory_mapped_io.v - Memory-mapped I/O controller
// Provides I/O ports mapped to memory addresses for peripheral access

module memory_mapped_io (
    input clk,
    input rst,
    input [7:0] address,         // I/O address (memory-mapped)
    input read_enable,           // Read from I/O port
    input write_enable,          // Write to I/O port
    input [7:0] write_data,      // Data to write to I/O port
    output reg [7:0] read_data,  // Data read from I/O port
    output io_valid,             // I/O operation valid
    
    // Peripheral I/O ports (examples)
    // GPIO port 0 (address 0xF0-0xF7: 8 ports)
    input [7:0] gpio_input,      // GPIO input data
    output reg [7:0] gpio_output, // GPIO output data
    output reg [7:0] gpio_direction, // GPIO direction (1=output, 0=input)
    
    // Timer port (address 0xF8)
    output reg [7:0] timer_value, // Timer counter value
    
    // UART port (address 0xF9-0xFA)
    input uart_rx_data_ready,    // UART RX data ready
    input [7:0] uart_rx_data,    // UART RX data
    output reg uart_tx_start,    // UART TX start
    output reg [7:0] uart_tx_data, // UART TX data
    input uart_tx_busy,          // UART TX busy
    
    // Status/Control register (address 0xFF)
    input [7:0] status_flags,    // System status flags
    output reg [7:0] control_flags // Control flags
);

    // Memory-mapped I/O address space: 0xF0-0xFF (16 addresses)
    localparam IO_BASE = 8'hF0;
    localparam IO_MASK = 8'hF0;  // Top 4 bits must be 0xF
    
    // I/O address offsets
    localparam GPIO_BASE = 8'hF0;    // GPIO ports 0-7
    localparam TIMER_ADDR = 8'hF8;   // Timer
    localparam UART_TX_ADDR = 8'hF9; // UART TX
    localparam UART_RX_ADDR = 8'hFA; // UART RX
    localparam STATUS_ADDR = 8'hFF;  // Status/Control
    
    wire [3:0] io_offset = address[3:0];  // Lower 4 bits for I/O offset
    wire is_io_address = (address & 8'hF0) == IO_BASE;
    
    assign io_valid = is_io_address && (read_enable || write_enable);
    
    // I/O operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gpio_output <= 8'b0;
            gpio_direction <= 8'b0;
            timer_value <= 8'b0;
            uart_tx_start <= 0;
            uart_tx_data <= 8'b0;
            control_flags <= 8'b0;
            read_data <= 8'b0;
        end else begin
            uart_tx_start <= 0;  // Pulse signal
            
            if (is_io_address) begin
                if (read_enable) begin
                    // Read from I/O port
                    case (address)
                        GPIO_BASE: begin
                            // GPIO port 0 - read input
                            read_data <= gpio_direction[0] ? gpio_output : gpio_input;
                        end
                        GPIO_BASE + 1: begin
                            // GPIO port 1
                            read_data <= gpio_direction[1] ? gpio_output : gpio_input;
                        end
                        GPIO_BASE + 2: begin
                            // GPIO port 2
                            read_data <= gpio_direction[2] ? gpio_output : gpio_input;
                        end
                        GPIO_BASE + 3: begin
                            // GPIO port 3
                            read_data <= gpio_direction[3] ? gpio_output : gpio_input;
                        end
                        GPIO_BASE + 4: begin
                            // GPIO port 4
                            read_data <= gpio_direction[4] ? gpio_output : gpio_input;
                        end
                        GPIO_BASE + 5: begin
                            // GPIO port 5
                            read_data <= gpio_direction[5] ? gpio_output : gpio_input;
                        end
                        GPIO_BASE + 6: begin
                            // GPIO port 6
                            read_data <= gpio_direction[6] ? gpio_output : gpio_input;
                        end
                        GPIO_BASE + 7: begin
                            // GPIO port 7 / GPIO direction register
                            read_data <= gpio_direction;
                        end
                        TIMER_ADDR: begin
                            // Timer counter (read-only)
                            read_data <= timer_value;
                        end
                        UART_RX_ADDR: begin
                            // UART RX data and status
                            read_data <= uart_rx_data;
                        end
                        STATUS_ADDR: begin
                            // Status register (read-only)
                            read_data <= status_flags;
                        end
                        default: begin
                            read_data <= 8'b0;
                        end
                    endcase
                end else if (write_enable) begin
                    // Write to I/O port
                    case (address)
                        GPIO_BASE: begin
                            // GPIO port 0 - write output
                            if (gpio_direction[0]) gpio_output[0] <= write_data[0];
                        end
                        GPIO_BASE + 1: begin
                            // GPIO port 1
                            if (gpio_direction[1]) gpio_output[1] <= write_data[1];
                        end
                        GPIO_BASE + 2: begin
                            // GPIO port 2
                            if (gpio_direction[2]) gpio_output[2] <= write_data[2];
                        end
                        GPIO_BASE + 3: begin
                            // GPIO port 3
                            if (gpio_direction[3]) gpio_output[3] <= write_data[3];
                        end
                        GPIO_BASE + 4: begin
                            // GPIO port 4
                            if (gpio_direction[4]) gpio_output[4] <= write_data[4];
                        end
                        GPIO_BASE + 5: begin
                            // GPIO port 5
                            if (gpio_direction[5]) gpio_output[5] <= write_data[5];
                        end
                        GPIO_BASE + 6: begin
                            // GPIO port 6
                            if (gpio_direction[6]) gpio_output[6] <= write_data[6];
                        end
                        GPIO_BASE + 7: begin
                            // GPIO direction register
                            gpio_direction <= write_data;
                        end
                        TIMER_ADDR: begin
                            // Timer reset/reload (write reload value)
                            timer_value <= write_data;
                        end
                        UART_TX_ADDR: begin
                            // UART TX data - start transmission
                            if (!uart_tx_busy) begin
                                uart_tx_data <= write_data;
                                uart_tx_start <= 1;
                            end
                        end
                        STATUS_ADDR: begin
                            // Control register
                            control_flags <= write_data;
                        end
                    endcase
                end
            end
        end
    end
    
    // Timer counter (free-running counter)
    always @(posedge clk) begin
        if (rst) begin
            timer_value <= 8'b0;
        end else begin
            timer_value <= timer_value + 1;  // Increment every clock cycle
        end
    end

endmodule
