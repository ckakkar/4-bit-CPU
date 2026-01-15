# Quick Start Guide - Advanced Features

This guide helps you quickly get started with the advanced features of the Enhanced 8-Bit CPU project.

## 🚀 Quick Commands

### Basic Simulation
```bash
# Simple CPU
make simulate

# Pipelined CPU
make simulate-pipelined

# Enhanced CPU (with stack, multiplier, I/O, interrupts)
make simulate-enhanced
```

### Development Tools
```bash
# Assemble assembly code
make assemble ASM_FILE=examples/fibonacci.asm

# Run test suite
make test

# Analyze performance
make analyze
```

### Waveform Viewing
```bash
# Web browser (recommended)
make web-wave

# Terminal
make wave
```

---

## 📝 Writing Assembly Programs

### 1. Create Assembly File

Create `my_program.asm`:
```assembly
; My first program
START:
    LOADI R1, 5
    LOADI R2, 10
    ADD R3, R1, R2
    HALT
```

### 2. Assemble to Verilog

```bash
make assemble ASM_FILE=my_program.asm
```

This generates `rtl/instruction_memory_generated.v` with your program.

### 3. Update Instruction Memory

Copy the generated code into `rtl/instruction_memory.v`:
```verilog
// Replace the initial block with generated code
initial begin
    // ... generated code ...
end
```

### 4. Run Simulation

```bash
make simulate
```

---

## 🐛 Debugging Programs

### Using Debug Unit

The debug unit provides hardware breakpoints and single-step execution:

```verilog
// In testbench or simulation
debug_enable = 1;
breakpoint_addr = 8'h10;  // Set breakpoint at address 0x10
breakpoint_enable = 1;

// CPU will halt when PC reaches 0x10
// Inspect registers:
inspect_reg_addr = 3'b001;  // Read R1
inspect_reg_data;  // Get R1 value
```

### Single-Step Mode

```verilog
single_step = 1;  // Execute one instruction at a time
// CPU halts after each instruction
```

### Instruction Tracing

```verilog
trace_enable = 1;
trace_depth = 3'b111;  // 8-entry trace buffer

// After execution, read trace buffer:
trace_pc[0] through trace_pc[7];  // PC values
trace_inst[0] through trace_inst[7];  // Instructions
```

---

## 📊 Performance Analysis

### Using Performance Counters

```verilog
// Enable performance counting
enable = 1;

// Run your program
// ...

// Read metrics
counter_select = 4'b0001;  // Instruction count
selected_counter;  // Get value

counter_select = 4'b0110;  // Branch mispredict count
selected_counter;  // Get value
```

### Available Counters

| Select | Counter | Description |
|--------|---------|-------------|
| 0x0 | Cycle Count | Total clock cycles |
| 0x1 | Instruction Count | Instructions retired |
| 0x2 | Cache Hit Count | Cache hits |
| 0x3 | Cache Miss Count | Cache misses |
| 0x4 | Branch Taken Count | Branches taken |
| 0x5 | Branch Not Taken Count | Branches not taken |
| 0x6 | Branch Mispredict Count | Branch mispredictions |
| 0x7 | Stall Count | Pipeline stall cycles |
| 0x8 | Interrupt Count | Interrupts serviced |

### Performance Analyzer Tool

```bash
# Analyze VCD file
make analyze

# Or specify VCD file
make analyze VCD_FILE=cpu_sim.vcd
```

Generates `performance_report.txt` with:
- Total cycles
- Instructions executed
- IPC (Instructions Per Cycle)
- Cache hit rate
- Branch prediction accuracy

---

## ⚡ Power Management

### Automatic Power Management

Power management is automatic:
- **Normal Mode**: All components active
- **Idle Mode**: After 1000 idle cycles, cache and I/O gated (50% savings)
- **Sleep Mode**: Manual sleep (75% savings)
- **Power-Down**: Manual power-down (100% savings)

### Manual Control

```verilog
// Enter sleep mode
sleep_mode = 1;

// Enter power-down mode
power_down = 1;

// Check power savings
power_savings;  // 0-100 percentage
```

---

## 🧪 Testing Your Code

### Automated Test Suite

```bash
# Run all tests
make test
```

The test suite:
- Tests individual instructions
- Tests complete programs
- Verifies register values
- Checks memory contents
- Generates test report

### Writing Custom Tests

Edit `tools/test_suite.py` to add your own tests:

```python
suite.add_test(InstructionTest(
    "ADD Test",
    "ADD R1, R2, R3",
    {1: 5}  # Expected: R1 = 5
))
```

---

## 📚 Example Programs

### Fibonacci Sequence

```bash
# Assemble and view
cat examples/fibonacci.asm

# Assemble it
make assemble ASM_FILE=examples/fibonacci.asm
```

### Bubble Sort

```bash
cat examples/bubble_sort.asm
make assemble ASM_FILE=examples/bubble_sort.asm
```

### Interrupt Example

```bash
cat examples/interrupt_example.asm
make assemble ASM_FILE=examples/interrupt_example.asm
```

---

## 🔍 Common Workflows

### Workflow 1: Write and Test a New Program

1. Write assembly code: `my_program.asm`
2. Assemble: `make assemble ASM_FILE=my_program.asm`
3. Update instruction memory with generated code
4. Simulate: `make simulate`
5. View waveforms: `make web-wave`
6. Analyze performance: `make analyze`

### Workflow 2: Debug a Failing Program

1. Enable debug unit in testbench
2. Set breakpoint at problematic address
3. Run simulation - CPU halts at breakpoint
4. Inspect registers and memory
5. Use single-step to trace execution
6. Check instruction trace buffer

### Workflow 3: Optimize Performance

1. Run program with performance counters enabled
2. Analyze VCD: `make analyze`
3. Check IPC, cache hit rate, branch accuracy
4. Identify bottlenecks
5. Optimize code (reduce stalls, improve cache usage)
6. Re-run and compare metrics

---

## 🛠️ Advanced Features Reference

### Debug Unit
- Breakpoints: `breakpoint_addr`, `breakpoint_enable`
- Single-step: `single_step`
- Tracing: `trace_enable`, `trace_depth`
- Watchpoints: `watchpoint_addr`, `watchpoint_enable`
- Inspection: `inspect_reg_addr`, `inspect_mem_addr`

### Performance Counters
- Enable: `enable`
- Select counter: `counter_select`
- Read value: `selected_counter`
- Reset: `counter_reset`

### Power Management
- Sleep: `sleep_mode`
- Power-down: `power_down`
- Status: `power_savings`, `sleep_active`, `power_down_active`

### Advanced Cache
- Statistics: `hit_count`, `miss_count`, `writeback_count`
- Write-back policy (automatic)
- LRU replacement (automatic)

### Advanced Branch Predictor
- Prediction: `prediction`, `predicted_target`
- Confidence: `prediction_confidence`
- History: `use_global_history`, `use_local_history`

---

## 📖 Next Steps

1. **Read Documentation**:
   - `README.md` - Complete project documentation
   - `ADVANCED_FEATURES.md` - Advanced features guide
   - `PIPELINED_CPU_IMPLEMENTATION.md` - Pipeline details
   - `ENHANCED_CPU_FEATURES.md` - Enhanced features

2. **Try Examples**:
   - Assemble example programs
   - Run simulations
   - Analyze performance

3. **Write Your Own**:
   - Create assembly programs
   - Test with debug unit
   - Optimize with performance counters

4. **Explore Advanced Features**:
   - Experiment with power management
   - Test cache performance
   - Analyze branch prediction

---

## 💡 Tips

- **Start Simple**: Begin with basic programs, then add complexity
- **Use Debug Unit**: Breakpoints and single-step are invaluable
- **Monitor Performance**: Use performance counters to find bottlenecks
- **Check Waveforms**: Visual inspection often reveals issues
- **Read Examples**: Study example programs to learn patterns
- **Test Incrementally**: Test small pieces before combining

---

## 🆘 Getting Help

- Check `README.md` for detailed documentation
- Review `ADVANCED_FEATURES.md` for feature details
- Look at example programs in `examples/`
- Examine testbench code in `sim/cpu_tb.v`
- Review component code in `rtl/` for implementation details

---

**Happy Coding! 🚀**
