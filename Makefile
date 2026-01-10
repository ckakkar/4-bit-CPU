# Makefile for Simple CPU Project

# Directories
RTL_DIR = rtl
SIM_DIR = sim

# Files - Simple CPU (non-pipelined)
RTL_FILES = $(RTL_DIR)/alu.v \
            $(RTL_DIR)/register_file.v \
            $(RTL_DIR)/program_counter.v \
            $(RTL_DIR)/instruction_memory.v \
            $(RTL_DIR)/data_memory.v \
            $(RTL_DIR)/control_unit.v \
            $(RTL_DIR)/cpu.v

# Files - Pipelined CPU (advanced features)
RTL_FILES_PIPELINED = $(RTL_DIR)/alu.v \
                      $(RTL_DIR)/register_file.v \
                      $(RTL_DIR)/program_counter.v \
                      $(RTL_DIR)/instruction_memory.v \
                      $(RTL_DIR)/data_memory.v \
                      $(RTL_DIR)/pipeline_registers.v \
                      $(RTL_DIR)/hazard_unit.v \
                      $(RTL_DIR)/instruction_cache.v \
                      $(RTL_DIR)/data_cache.v \
                      $(RTL_DIR)/branch_predictor.v \
                      $(RTL_DIR)/register_windows.v \
                      $(RTL_DIR)/fpu.v \
                      $(RTL_DIR)/control_unit_pipelined.v \
                      $(RTL_DIR)/cpu_pipelined.v

TB_FILE = $(SIM_DIR)/cpu_tb.v

# Output files
VVP_FILE = cpu_sim.vvp
VCD_FILE = cpu_sim.vcd
VVP_FILE_PIPELINED = cpu_pipelined_sim.vvp
VCD_FILE_PIPELINED = cpu_pipelined_sim.vcd

# Default target
all: simulate

# Compile Verilog files
compile:
	@echo "==================================================="
	@echo "Compiling Verilog files with iverilog..."
	@echo "==================================================="
	iverilog -g2012 -o $(VVP_FILE) $(RTL_FILES) $(TB_FILE)
	@echo "Compilation successful!"
	@echo ""

# Run simulation
simulate: compile
	@echo "==================================================="
	@echo "Running simulation..."
	@echo "==================================================="
	vvp $(VVP_FILE)
	@echo ""
	@echo "Simulation complete! VCD file generated: $(VCD_FILE)"
	@echo ""

# View waveforms in terminal (Python script)
wave: simulate
	@echo "==================================================="
	@echo "Opening waveform viewer in terminal..."
	@echo "==================================================="
	@python3 tools/vcd_viewer.py $(VCD_FILE)

# View waveforms in web browser (recommended for Mac M2)
web-wave: simulate
	@echo "==================================================="
	@echo "Opening waveform viewer in browser..."
	@echo "==================================================="
	@echo "Open the file: tools/waveform_viewer.html"
	@echo "Then drag and drop $(VCD_FILE) into the browser"
	@open tools/waveform_viewer.html || xdg-open tools/waveform_viewer.html || echo "Please open tools/waveform_viewer.html in your browser"

# View waveforms using gtkwave (if available)
gtkwave: simulate
	@echo "Opening GTKWave..."
	@if command -v gtkwave > /dev/null; then \
		gtkwave $(VCD_FILE) &; \
	else \
		echo "ERROR: gtkwave not found."; \
		echo "Try 'make wave' (terminal) or 'make web-wave' (browser) instead!"; \
	fi

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	rm -f $(VVP_FILE) $(VCD_FILE)
	@echo "Clean complete!"

# Compile pipelined CPU
compile-pipelined:
	@echo "==================================================="
	@echo "Compiling Pipelined CPU with iverilog..."
	@echo "==================================================="
	iverilog -g2012 -o $(VVP_FILE_PIPELINED) $(RTL_FILES_PIPELINED) $(SIM_DIR)/cpu_tb.v
	@echo "Compilation successful!"
	@echo ""

# Simulate pipelined CPU
simulate-pipelined: compile-pipelined
	@echo "==================================================="
	@echo "Running pipelined CPU simulation..."
	@echo "==================================================="
	vvp $(VVP_FILE_PIPELINED)
	@echo ""
	@echo "Simulation complete! VCD file generated: $(VCD_FILE_PIPELINED)"
	@echo ""

# Clean all generated files
clean-all:
	@echo "Cleaning all generated files..."
	rm -f $(VVP_FILE) $(VCD_FILE) $(VVP_FILE_PIPELINED) $(VCD_FILE_PIPELINED)
	@echo "Clean complete!"

# Help
help:
	@echo "Simple CPU Project - Makefile Commands"
	@echo "======================================="
	@echo "Simple CPU (non-pipelined):"
	@echo "make compile   - Compile Verilog files"
	@echo "make simulate  - Compile and run simulation"
	@echo ""
	@echo "Pipelined CPU (advanced features):"
	@echo "make compile-pipelined  - Compile pipelined CPU"
	@echo "make simulate-pipelined - Run pipelined CPU simulation"
	@echo ""
	@echo "Waveform Viewers (choose one):"
	@echo "make wave      - View in terminal (text-based, works everywhere)"
	@echo "make web-wave  - View in browser (recommended for Mac M2)"
	@echo "make gtkwave   - Use GTKWave (if installed)"
	@echo ""
	@echo "make clean     - Remove simple CPU generated files"
	@echo "make clean-all - Remove all generated files"
	@echo "make help      - Show this help message"

.PHONY: all compile simulate wave web-wave gtkwave clean compile-pipelined simulate-pipelined clean-all help