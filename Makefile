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

# Files - Enhanced CPU (stack, multiplier, I/O, interrupts)
RTL_FILES_ENHANCED = $(RTL_DIR)/alu.v \
                     $(RTL_DIR)/register_file.v \
                     $(RTL_DIR)/program_counter.v \
                     $(RTL_DIR)/instruction_memory.v \
                     $(RTL_DIR)/data_memory.v \
                     $(RTL_DIR)/stack_unit.v \
                     $(RTL_DIR)/multiplier_divider.v \
                     $(RTL_DIR)/memory_mapped_io.v \
                     $(RTL_DIR)/interrupt_controller.v \
                     $(RTL_DIR)/instruction_format_extended.v \
                     $(RTL_DIR)/cpu_enhanced.v

# Files - Ultra Advanced CPU (multi-core, OOO, speculative, virtual memory, OS, real-time)
RTL_FILES_ULTRA = $(RTL_DIR)/alu.v \
                  $(RTL_DIR)/register_file.v \
                  $(RTL_DIR)/program_counter.v \
                  $(RTL_DIR)/instruction_memory.v \
                  $(RTL_DIR)/data_memory.v \
                  $(RTL_DIR)/multicore_interconnect.v \
                  $(RTL_DIR)/cpu_multicore.v \
                  $(RTL_DIR)/out_of_order_execution.v \
                  $(RTL_DIR)/speculative_execution.v \
                  $(RTL_DIR)/mmu.v \
                  $(RTL_DIR)/os_support.v \
                  $(RTL_DIR)/realtime_scheduler.v \
                  $(RTL_DIR)/instruction_set_extension.v \
                  $(RTL_DIR)/cpu_advanced_unified.v

# Files - CPU with Multi-Level Cache Hierarchy
RTL_FILES_CACHED = $(RTL_DIR)/alu.v \
                   $(RTL_DIR)/register_file.v \
                   $(RTL_DIR)/program_counter.v \
                   $(RTL_DIR)/instruction_memory.v \
                   $(RTL_DIR)/data_memory.v \
                   $(RTL_DIR)/control_unit.v \
                   $(RTL_DIR)/l1_exclusive_cache.v \
                   $(RTL_DIR)/l2_inclusive_cache.v \
                   $(RTL_DIR)/l3_shared_cache.v \
                   $(RTL_DIR)/cache_hierarchy.v \
                   $(RTL_DIR)/cpu_with_cache.v

# Files - Multi-Core CPU with Cache Hierarchy
RTL_FILES_MULTICORE_CACHED = $(RTL_DIR)/alu.v \
                             $(RTL_DIR)/register_file.v \
                             $(RTL_DIR)/program_counter.v \
                             $(RTL_DIR)/instruction_memory.v \
                             $(RTL_DIR)/data_memory.v \
                             $(RTL_DIR)/control_unit.v \
                             $(RTL_DIR)/l1_exclusive_cache.v \
                             $(RTL_DIR)/l2_inclusive_cache.v \
                             $(RTL_DIR)/l3_shared_cache.v \
                             $(RTL_DIR)/cache_hierarchy.v \
                             $(RTL_DIR)/cpu_with_cache.v \
                             $(RTL_DIR)/cpu_multicore_cached.v

# Files - Systolic Array System
RTL_FILES_SYSTOLIC = $(RTL_DIR)/systolic_pe.v \
                     $(RTL_DIR)/systolic_array.v \
                     $(RTL_DIR)/systolic_controller.v \
                     $(RTL_DIR)/data_memory.v \
                     $(RTL_DIR)/systolic_system.v

# Files - Quantum-Classical Hybrid System
RTL_FILES_QUANTUM = $(RTL_DIR)/quantum_coprocessor.v \
                    $(RTL_DIR)/quantum_controller.v \
                    $(RTL_DIR)/quantum_error_correction.v \
                    $(RTL_DIR)/quantum_factoring.v \
                    $(RTL_DIR)/quantum_search.v \
                    $(RTL_DIR)/quantum_optimization.v \
                    $(RTL_DIR)/data_memory.v \
                    $(RTL_DIR)/quantum_system.v

# Files - Custom Instruction Set Extensions
RTL_FILES_CUSTOM_INST = $(RTL_DIR)/custom_instruction_decoder.v \
                        $(RTL_DIR)/crypto_accelerator.v \
                        $(RTL_DIR)/dsp_accelerator.v \
                        $(RTL_DIR)/ai_accelerator.v \
                        $(RTL_DIR)/instruction_fusion.v \
                        $(RTL_DIR)/tightly_coupled_accelerator.v \
                        $(RTL_DIR)/custom_instruction_unit.v

# Files - Neuromorphic Computing System
RTL_FILES_NEUROMORPHIC = $(RTL_DIR)/spiking_neuron.v \
                         $(RTL_DIR)/synaptic_memory.v \
                         $(RTL_DIR)/stdp_learning.v \
                         $(RTL_DIR)/event_driven_processor.v \
                         $(RTL_DIR)/neuromorphic_layer.v \
                         $(RTL_DIR)/data_memory.v \
                         $(RTL_DIR)/neuromorphic_system.v

TB_FILE = $(SIM_DIR)/cpu_tb.v

# Output files
VVP_FILE = cpu_sim.vvp
VCD_FILE = cpu_sim.vcd
VVP_FILE_PIPELINED = cpu_pipelined_sim.vvp
VCD_FILE_PIPELINED = cpu_pipelined_sim.vcd
VVP_FILE_ENHANCED = cpu_enhanced_sim.vvp
VCD_FILE_ENHANCED = cpu_enhanced_sim.vcd
VVP_FILE_ULTRA = cpu_ultra_sim.vvp
VCD_FILE_ULTRA = cpu_ultra_sim.vcd
VVP_FILE_CACHED = cpu_cached_sim.vvp
VCD_FILE_CACHED = cpu_cached_sim.vcd
VVP_FILE_MULTICORE_CACHED = cpu_multicore_cached_sim.vvp
VCD_FILE_MULTICORE_CACHED = cpu_multicore_cached_sim.vcd
VVP_FILE_SYSTOLIC = systolic_sim.vvp
VCD_FILE_SYSTOLIC = systolic_sim.vcd
VVP_FILE_QUANTUM = quantum_sim.vvp
VCD_FILE_QUANTUM = quantum_sim.vcd
VVP_FILE_CUSTOM_INST = custom_inst_sim.vvp
VCD_FILE_CUSTOM_INST = custom_inst_sim.vcd
VVP_FILE_NEUROMORPHIC = neuromorphic_sim.vvp
VCD_FILE_NEUROMORPHIC = neuromorphic_sim.vcd

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

# Compile enhanced CPU
compile-enhanced:
	@echo "==================================================="
	@echo "Compiling Enhanced CPU with iverilog..."
	@echo "==================================================="
	iverilog -g2012 -o $(VVP_FILE_ENHANCED) $(RTL_FILES_ENHANCED) $(SIM_DIR)/cpu_tb.v
	@echo "Compilation successful!"
	@echo ""

# Simulate enhanced CPU
simulate-enhanced: compile-enhanced
	@echo "==================================================="
	@echo "Running enhanced CPU simulation..."
	@echo "==================================================="
	vvp $(VVP_FILE_ENHANCED)
	@echo ""
	@echo "Simulation complete! VCD file generated: $(VCD_FILE_ENHANCED)"
	@echo ""

# Compile ultra advanced CPU
compile-ultra:
	@echo "==================================================="
	@echo "Compiling Ultra Advanced CPU with iverilog..."
	@echo "==================================================="
	iverilog -g2012 -o $(VVP_FILE_ULTRA) $(RTL_FILES_ULTRA) $(SIM_DIR)/cpu_tb.v
	@echo "Compilation successful!"
	@echo ""

# Simulate ultra advanced CPU
simulate-ultra: compile-ultra
	@echo "==================================================="
	@echo "Running ultra advanced CPU simulation..."
	@echo "==================================================="
	vvp $(VVP_FILE_ULTRA)
	@echo ""
	@echo "Simulation complete! VCD file generated: $(VCD_FILE_ULTRA)"
	@echo ""

# Compile with advanced compiler
compile-advanced:
	@echo "==================================================="
	@echo "Compiling with advanced compiler..."
	@echo "==================================================="
	@if [ -z "$(ASM_FILE)" ]; then \
		echo "Usage: make compile-advanced ASM_FILE=file.asm"; \
		exit 1; \
	fi
	@python3 tools/advanced_compiler.py $(ASM_FILE) $(ASM_FILE).optimized
	@echo "Advanced compilation complete! Optimized file: $(ASM_FILE).optimized"

# Compile CPU with cache hierarchy
compile-cached:
	@echo "==================================================="
	@echo "Compiling CPU with Multi-Level Cache Hierarchy..."
	@echo "==================================================="
	iverilog -g2012 -o $(VVP_FILE_CACHED) $(RTL_FILES_CACHED) $(SIM_DIR)/cpu_tb.v
	@echo "Compilation successful!"
	@echo ""

# Simulate CPU with cache hierarchy
simulate-cached: compile-cached
	@echo "==================================================="
	@echo "Running CPU with cache hierarchy simulation..."
	@echo "==================================================="
	vvp $(VVP_FILE_CACHED)
	@echo ""
	@echo "Simulation complete! VCD file generated: $(VCD_FILE_CACHED)"
	@echo ""

# Compile multi-core CPU with cache hierarchy
compile-multicore-cached:
	@echo "==================================================="
	@echo "Compiling Multi-Core CPU with Cache Hierarchy..."
	@echo "==================================================="
	iverilog -g2012 -o $(VVP_FILE_MULTICORE_CACHED) $(RTL_FILES_MULTICORE_CACHED) $(SIM_DIR)/cpu_tb.v
	@echo "Compilation successful!"
	@echo ""

# Simulate multi-core CPU with cache hierarchy
simulate-multicore-cached: compile-multicore-cached
	@echo "==================================================="
	@echo "Running multi-core CPU with cache simulation..."
	@echo "==================================================="
	vvp $(VVP_FILE_MULTICORE_CACHED)
	@echo ""
	@echo "Simulation complete! VCD file generated: $(VCD_FILE_MULTICORE_CACHED)"
	@echo ""

# Compile systolic array system
compile-systolic:
	@echo "==================================================="
	@echo "Compiling Systolic Array System..."
	@echo "==================================================="
	iverilog -g2012 -o $(VVP_FILE_SYSTOLIC) $(RTL_FILES_SYSTOLIC) $(SIM_DIR)/cpu_tb.v
	@echo "Compilation successful!"
	@echo ""

# Simulate systolic array system
simulate-systolic: compile-systolic
	@echo "==================================================="
	@echo "Running systolic array simulation..."
	@echo "==================================================="
	vvp $(VVP_FILE_SYSTOLIC)
	@echo ""
	@echo "Simulation complete! VCD file generated: $(VCD_FILE_SYSTOLIC)"
	@echo ""

# Compile quantum system
compile-quantum:
	@echo "==================================================="
	@echo "Compiling Quantum-Classical Hybrid System..."
	@echo "==================================================="
	iverilog -g2012 -o $(VVP_FILE_QUANTUM) $(RTL_FILES_QUANTUM) $(SIM_DIR)/cpu_tb.v
	@echo "Compilation successful!"
	@echo ""

# Simulate quantum system
simulate-quantum: compile-quantum
	@echo "==================================================="
	@echo "Running quantum system simulation..."
	@echo "==================================================="
	vvp $(VVP_FILE_QUANTUM)
	@echo ""
	@echo "Simulation complete! VCD file generated: $(VCD_FILE_QUANTUM)"
	@echo ""

# Compile custom instruction extensions
compile-custom-inst:
	@echo "==================================================="
	@echo "Compiling Custom Instruction Set Extensions..."
	@echo "==================================================="
	iverilog -g2012 -o $(VVP_FILE_CUSTOM_INST) $(RTL_FILES_CUSTOM_INST) $(SIM_DIR)/cpu_tb.v
	@echo "Compilation successful!"
	@echo ""

# Simulate custom instruction extensions
simulate-custom-inst: compile-custom-inst
	@echo "==================================================="
	@echo "Running custom instruction extensions simulation..."
	@echo "==================================================="
	vvp $(VVP_FILE_CUSTOM_INST)
	@echo ""
	@echo "Simulation complete! VCD file generated: $(VCD_FILE_CUSTOM_INST)"
	@echo ""

# Compile neuromorphic system
compile-neuromorphic:
	@echo "==================================================="
	@echo "Compiling Neuromorphic Computing System..."
	@echo "==================================================="
	iverilog -g2012 -o $(VVP_FILE_NEUROMORPHIC) $(RTL_FILES_NEUROMORPHIC) $(SIM_DIR)/cpu_tb.v
	@echo "Compilation successful!"
	@echo ""

# Simulate neuromorphic system
simulate-neuromorphic: compile-neuromorphic
	@echo "==================================================="
	@echo "Running neuromorphic system simulation..."
	@echo "==================================================="
	vvp $(VVP_FILE_NEUROMORPHIC)
	@echo ""
	@echo "Simulation complete! VCD file generated: $(VCD_FILE_NEUROMORPHIC)"
	@echo ""

# Clean all generated files
clean-all:
	@echo "Cleaning all generated files..."
	rm -f $(VVP_FILE) $(VCD_FILE) $(VVP_FILE_PIPELINED) $(VCD_FILE_PIPELINED) \
	      $(VVP_FILE_ENHANCED) $(VCD_FILE_ENHANCED) $(VVP_FILE_ULTRA) $(VCD_FILE_ULTRA) \
	      $(VVP_FILE_CACHED) $(VCD_FILE_CACHED) $(VVP_FILE_MULTICORE_CACHED) $(VCD_FILE_MULTICORE_CACHED) \
	      $(VVP_FILE_SYSTOLIC) $(VCD_FILE_SYSTOLIC) $(VVP_FILE_QUANTUM) $(VCD_FILE_QUANTUM) \
	      $(VVP_FILE_CUSTOM_INST) $(VCD_FILE_CUSTOM_INST) $(VVP_FILE_NEUROMORPHIC) $(VCD_FILE_NEUROMORPHIC)
	@echo "Clean complete!"

# Assemble assembly file
assemble:
	@echo "==================================================="
	@echo "Assembling assembly file..."
	@echo "==================================================="
	@if [ -z "$(ASM_FILE)" ]; then \
		echo "Usage: make assemble ASM_FILE=examples/fibonacci.asm"; \
		exit 1; \
	fi
	@python3 tools/assembler.py $(ASM_FILE) rtl/instruction_memory_generated.v
	@echo "Assembly complete! Generated: rtl/instruction_memory_generated.v"

# Run test suite
test:
	@echo "==================================================="
	@echo "Running CPU test suite..."
	@echo "==================================================="
	@python3 tools/test_suite.py
	@echo "Test suite complete!"

# Analyze performance
analyze:
	@echo "==================================================="
	@echo "Analyzing CPU performance..."
	@echo "==================================================="
	@if [ -z "$(VCD_FILE)" ]; then \
		python3 tools/performance_analyzer.py cpu_sim.vcd; \
	else \
		python3 tools/performance_analyzer.py $(VCD_FILE); \
	fi
	@echo "Performance analysis complete! See performance_report.txt"

# Help
help:
	@echo "Simple CPU Project - Makefile Commands"
	@echo "======================================="
	@echo ""
	@echo "Basic CPU Implementations:"
	@echo "  make compile          - Compile simple CPU (non-pipelined)"
	@echo "  make simulate         - Compile and run simple CPU simulation"
	@echo "  make compile-pipelined - Compile pipelined CPU"
	@echo "  make simulate-pipelined - Run pipelined CPU simulation"
	@echo "  make compile-enhanced - Compile enhanced CPU (stack, multiplier, I/O)"
	@echo "  make simulate-enhanced - Run enhanced CPU simulation"
	@echo "  make compile-ultra    - Compile ultra advanced CPU (multi-core, OOO, etc.)"
	@echo "  make simulate-ultra   - Run ultra advanced CPU simulation"
	@echo ""
	@echo "Advanced Features:"
	@echo "  make compile-cached   - Compile CPU with multi-level cache hierarchy"
	@echo "  make simulate-cached  - Run CPU with cache hierarchy simulation"
	@echo "  make compile-multicore-cached - Compile multi-core CPU with cache"
	@echo "  make simulate-multicore-cached - Run multi-core cached CPU simulation"
	@echo "  make compile-systolic - Compile systolic array system"
	@echo "  make simulate-systolic - Run systolic array simulation"
	@echo "  make compile-quantum   - Compile quantum-classical hybrid system"
	@echo "  make simulate-quantum - Run quantum system simulation"
	@echo "  make compile-custom-inst - Compile custom instruction extensions"
	@echo "  make simulate-custom-inst - Run custom instruction simulation"
	@echo "  make compile-neuromorphic - Compile neuromorphic computing system"
	@echo "  make simulate-neuromorphic - Run neuromorphic system simulation"
	@echo ""
	@echo "Development Tools:"
	@echo "  make assemble ASM_FILE=file.asm - Assemble assembly to Verilog"
	@echo "  make compile-advanced ASM_FILE=file.asm - Compile with optimizations"
	@echo "  make test              - Run automated test suite"
	@echo "  make analyze [VCD_FILE=file.vcd] - Analyze performance from VCD"
	@echo ""
	@echo "Waveform Viewers (choose one):"
	@echo "  make wave             - View in terminal (text-based, works everywhere)"
	@echo "  make web-wave         - View in browser (recommended for Mac M2)"
	@echo "  make gtkwave          - Use GTKWave (if installed)"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean            - Remove simple CPU generated files"
	@echo "  make clean-all        - Remove all generated files"
	@echo ""
	@echo "  make help             - Show this help message"

.PHONY: all compile simulate wave web-wave gtkwave clean compile-pipelined simulate-pipelined compile-enhanced simulate-enhanced compile-ultra simulate-ultra compile-advanced clean-all help assemble test analyze compile-cached simulate-cached compile-multicore-cached simulate-multicore-cached compile-systolic simulate-systolic compile-quantum simulate-quantum compile-custom-inst simulate-custom-inst compile-neuromorphic simulate-neuromorphic