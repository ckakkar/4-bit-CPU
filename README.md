# Enhanced 8-Bit CPU Project

A comprehensive, educational 8-bit CPU implementation in Verilog featuring a Harvard architecture, expanded instruction set, and complete simulation infrastructure. This project demonstrates the fundamentals of CPU design, including instruction fetch-decode-execute cycles, ALU operations, register file management, and memory systems.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Instruction Set](#instruction-set)
5. [Installation](#installation)
6. [Quick Start](#quick-start)
7. [Project Structure](#project-structure)
8. [Component Details](#component-details)
9. [Running Simulations](#running-simulations)
10. [Viewing Waveforms](#viewing-waveforms)
11. [Example Programs](#example-programs)
12. [Creating Custom Programs](#creating-custom-programs)
13. [Makefile Reference](#makefile-reference)
14. [Troubleshooting](#troubleshooting)
15. [Development Guide](#development-guide)
16. [Future Extensions](#future-extensions)

---

## Project Overview

This repository contains a complete 8-bit CPU implementation designed for educational purposes. The CPU features:

- **Harvard Architecture**: Separate instruction and data memory spaces for improved performance
- **8-Bit Datapath**: All internal data paths, registers, and ALU operate on 8-bit values
- **8 General-Purpose Registers**: Register file with 8 registers (R0-R7), each 8 bits wide
- **256-Instruction Program Space**: Support for up to 256 instructions (8-bit program counter)
- **16-Bit Instruction Format**: Rich instruction encoding supporting immediate values, register addressing, and memory operations
- **Enhanced ALU**: 14 arithmetic and logical operations with comprehensive status flags
- **Control Unit**: State machine-based instruction decoder and execution controller

The design is implemented entirely in synthesizable Verilog and can be simulated using Icarus Verilog. The project includes comprehensive testbenches, waveform viewers, and example programs to help understand CPU operation.

---

## Features

### Hardware Features

- **8-Bit Datapath**: Complete 8-bit internal architecture
- **Harvard Architecture**: 
  - Instruction Memory: 256 × 16-bit (read-only ROM)
  - Data Memory: 256 × 8-bit (read-write RAM)
- **Register File**: 8 × 8-bit registers with dual-port read and single-port write
- **Program Counter**: 8-bit counter with increment and jump capabilities
- **ALU Operations**: 14 operations including:
  - Arithmetic: ADD, SUB
  - Logical: AND, OR, XOR, NOT
  - Shifts: SHL (shift left), SHR (shift right logical), SAR (shift right arithmetic)
  - Comparisons: CMP, LT, LTU, EQ
  - Data Movement: MOV, PASS
- **Status Flags**: Zero, Carry, Overflow, Negative flags updated on ALU operations
- **Control Flow**: Unconditional jumps and conditional branches (JZ, JNZ)

### Software Features

- **Comprehensive Testbench**: Execution trace with register state monitoring
- **Waveform Generation**: VCD file output for detailed timing analysis
- **Multiple Viewers**: Terminal-based and web-based waveform viewers
- **Example Programs**: Pre-loaded demo program demonstrating all instruction types
- **Makefile Build System**: Simplified compilation and simulation workflow

---

## Architecture

### High-Level Block Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ENHANCED 8-BIT CPU                            │
│                                                                       │
│  ┌──────────────────┐                                                │
│  │   Program        │                                                │
│  │   Counter (PC)   │───┐                                            │
│  │   8-bit          │   │                                            │
│  └──────────────────┘   │                                            │
│         ↑                │                                            │
│         │                ↓                                            │
│         │      ┌──────────────────────┐                              │
│         │      │  Instruction Memory  │                              │
│         │      │  256 × 16-bit ROM    │                              │
│         │      └──────────────────────┘                              │
│         │                │                                            │
│         │                ↓                                            │
│         │      ┌──────────────────────┐                              │
│         └─────→│   Control Unit       │                              │
│                │   (State Machine)    │                              │
│                └──────────────────────┘                              │
│                  │ │ │ │ │ │ │ │ │                                  │
│                  ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓                                  │
│         ┌──────────────────────────────┐                            │
│         │     Register File            │                            │
│         │  8 × 8-bit (R0-R7)          │                            │
│         │  Dual-port Read              │                            │
│         │  Single-port Write           │                            │
│         └──────────────────────────────┘                            │
│             │  │          │  │                                       │
│             ↓  ↓          ↓  ↓                                       │
│         ┌──────────────────────────────┐                            │
│         │        ALU                   │                            │
│         │  14 Operations + Flags       │                            │
│         │  Zero, Carry, Overflow,      │                            │
│         │  Negative                    │                            │
│         └──────────────────────────────┘                            │
│                  │                                                   │
│                  ↓                                                   │
│         ┌──────────────────────────────┐                            │
│         │      Data Memory             │                            │
│         │  256 × 8-bit RAM             │                            │
│         │  Read/Write                  │                            │
│         └──────────────────────────────┘                            │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Instruction Execution Pipeline

The CPU uses a simple 3-state execution pipeline:

1. **FETCH State**: Read instruction from instruction memory at PC address
2. **DECODE State**: Decode opcode, extract register addresses and immediate values, set up control signals
3. **EXECUTE State**: Execute instruction (ALU operation, memory access, or control flow)

For most instructions, execution completes in a single cycle after decode. Conditional branches (JZ/JNZ) require an additional execute cycle to evaluate the condition.

### Data Flow

1. **Instruction Fetch**:
   - PC provides address to instruction memory
   - 16-bit instruction is fetched and sent to control unit

2. **Instruction Decode**:
   - Control unit extracts: opcode[15:12], reg1[11:9], reg2[8:6], immediate[5:0]
   - Control signals are generated based on opcode

3. **Register Read**:
   - Register file reads operands from reg1 and reg2 addresses
   - Data available immediately (combinational read)

4. **ALU Operation**:
   - ALU performs operation on operands (register values or immediate)
   - Status flags are updated based on result

5. **Memory Access** (if needed):
   - For LOAD: Read from data memory, store result in register
   - For STORE: Write register value to data memory

6. **Write Back**:
   - ALU result or memory data written to destination register
   - PC incremented or loaded with jump address

---

## Instruction Set

### Instruction Format

All instructions are 16 bits wide with the following encoding:

```
Bits    Field           Description
─────────────────────────────────────────────────
[15:12] opcode         4-bit operation code
[11:9]  reg1           3-bit first register address (source/destination)
[8:6]   reg2           3-bit second register address (source/destination)
[5:0]   immediate      6-bit immediate value or address
```

### Instruction Reference

| Opcode | Hex | Mnemonic | Format | Description | Status Flags |
|--------|-----|----------|--------|-------------|--------------|
| 0000   | 0   | LOADI    | `LOADI Rd, imm` | Load immediate value into register Rd | None |
| 0001   | 1   | ADD      | `ADD Rd, Rs1, Rs2` | Add: Rd = Rs1 + Rs2 | Zero, Carry, Overflow, Negative |
| 0010   | 2   | SUB      | `SUB Rd, Rs1, Rs2` | Subtract: Rd = Rs1 - Rs2 | Zero, Carry, Overflow, Negative |
| 0011   | 3   | AND      | `AND Rd, Rs1, Rs2` | Bitwise AND: Rd = Rs1 & Rs2 | Zero, Negative |
| 0100   | 4   | OR       | `OR Rd, Rs1, Rs2` | Bitwise OR: Rd = Rs1 \| Rs2 | Zero, Negative |
| 0101   | 5   | XOR      | `XOR Rd, Rs1, Rs2` | Bitwise XOR: Rd = Rs1 ^ Rs2 | Zero, Negative |
| 0110   | 6   | STORE    | `STORE Rs, [addr]` | Store register to memory: Mem[addr] = Rs | None |
| 0111   | 7   | LOAD     | `LOAD Rd, [addr]` | Load from memory: Rd = Mem[addr] | None |
| 1000   | 8   | SHL      | `SHL Rd, Rs1, Rs2` | Shift left: Rd = Rs1 << Rs2[2:0] | Zero, Carry, Negative |
| 1001   | 9   | SHR      | `SHR Rd, Rs1, Rs2` | Shift right logical: Rd = Rs1 >> Rs2[2:0] | Zero, Carry, Negative |
| 1010   | A   | MOV      | `MOV Rd, Rs` | Move register: Rd = Rs | Zero, Negative |
| 1011   | B   | CMP      | `CMP Rs1, Rs2` | Compare and set flags: flags = Rs1 - Rs2 (no store) | Zero, Carry, Overflow, Negative |
| 1100   | C   | JUMP     | `JUMP addr` | Unconditional jump: PC = addr | None |
| 1101   | D   | JZ       | `JZ Rs, addr` | Jump if zero: if (Rs == 0) PC = addr | None |
| 1110   | E   | JNZ      | `JNZ Rs, addr` | Jump if non-zero: if (Rs != 0) PC = addr | None |
| 1111   | F   | NOT      | `NOT Rd, Rs` | Bitwise NOT: Rd = ~Rs | Zero, Negative |
| 1111   | F   | HALT     | `HALT` | Halt execution (special: opcode=1111, all other fields=0) | None |

### Status Flags

The ALU maintains four status flags that are updated after arithmetic and logical operations:

- **Zero Flag (Z)**: Set when result equals zero
- **Carry Flag (C)**: Set when addition produces carry or subtraction produces borrow
- **Overflow Flag (V)**: Set when signed arithmetic operation overflows (result exceeds 8-bit signed range)
- **Negative Flag (N)**: Set when result's most significant bit (MSB) is 1 (indicates negative in two's complement)

**Note**: Logical operations (AND, OR, XOR) update Zero and Negative flags. Shifts update Zero, Carry, and Negative flags. CMP only updates flags without storing a result.

### Register Addressing

- **3-bit register addresses**: Supports 8 registers (R0 through R7)
- **Register R0**: Can be used as a general-purpose register (though conventionally it's often treated as zero register)
- **Register conventions** (not enforced by hardware):
  - R0: Often used as zero or accumulator
  - R1-R6: General-purpose registers
  - R7: May be used as stack pointer or general-purpose

### Immediate Values

- **6-bit immediate field**: Supports values 0-63 (unsigned) or -32 to +31 (if sign-extended, though current implementation uses zero-extension)
- **Usage**: 
  - Immediate operands for LOADI
  - Memory addresses for STORE/LOAD instructions
  - Jump target addresses for JUMP/JZ/JNZ instructions

---

## Installation

### System Requirements

- **Operating System**: macOS (Intel or Apple Silicon) or Linux
- **Verilog Simulator**: Icarus Verilog (iverilog, vvp)
- **Python**: Python 3.x (for waveform viewer script)
- **Web Browser**: Any modern browser (for HTML waveform viewer)
- **Make**: Build system (usually pre-installed on Unix systems)

### Installing Icarus Verilog

**macOS (using Homebrew):**
```bash
brew install icarus-verilog
```

**Debian/Ubuntu Linux:**
```bash
sudo apt-get update
sudo apt-get install iverilog
```

**Fedora/RHEL/CentOS:**
```bash
sudo dnf install iverilog
```

**Arch Linux:**
```bash
sudo pacman -S iverilog
```

**From Source:**
If your distribution doesn't have a package, you can compile from source:
```bash
git clone https://github.com/steveicarus/iverilog.git
cd iverilog
./autoconf.sh
./configure
make
sudo make install
```

### Installing Python 3

Python 3 is typically pre-installed on macOS and most Linux distributions. Verify installation:
```bash
python3 --version
```

If not installed:
- **macOS**: `brew install python3`
- **Linux**: Use your distribution's package manager

### Verifying Installation

Check that all tools are available:
```bash
iverilog -v
vvp -v
python3 --version
make --version
```

---

## Quick Start

1. **Clone or download the project:**
   ```bash
   cd simple-cpu-project
   ```

2. **Run the simulation:**
   ```bash
   make simulate
   ```
   This will compile the Verilog code, run the simulation, and generate a VCD waveform file.

3. **View waveforms in your browser (recommended):**
   ```bash
   make web-wave
   ```
   Then drag `cpu_sim.vcd` into the opened HTML page.

4. **Or view waveforms in terminal:**
   ```bash
   make wave
   ```

You should see output similar to:
```
=================================================
    Enhanced 8-bit CPU Simulation
=================================================
Time(ns) | PC | Halt | R0 | R1 | R2 | R3 | R4 | R5 | R6 | R7 | Instruction | Assembly
-------------------------------------------------
  26000 |   0 |   0  |   0 |   0 |   0 |   0 |   0 |   0 |   0 |   0 | 0205      | LOADI R1, 5
  36000 |   1 |   0  |   0 |   5 |   0 |   0 |   0 |   0 |   0 |   0 | 040a      | LOADI R2, 10
  ...
```

---

## Project Structure

```
simple-cpu-project/
│
├── README.md                   # This file - comprehensive documentation
├── Makefile                    # Build system for compilation and simulation
│
├── rtl/                        # Register Transfer Level (RTL) design files
│   ├── cpu.v                   # Top-level CPU module (wires all components)
│   ├── alu.v                   # Arithmetic Logic Unit (14 operations + flags)
│   ├── register_file.v         # 8 × 8-bit register file with dual-port read
│   ├── program_counter.v       # 8-bit program counter with increment/jump
│   ├── instruction_memory.v    # 256 × 16-bit instruction ROM (program storage)
│   ├── data_memory.v           # 256 × 8-bit data RAM (Harvard architecture)
│   └── control_unit.v          # Instruction decoder and state machine controller
│
├── sim/                        # Simulation and testbench files
│   └── cpu_tb.v                # CPU testbench (drives CPU, generates VCD, prints trace)
│
├── tools/                      # Utility scripts and viewers
│   ├── vcd_viewer.py           # Python script for terminal-based waveform viewing
│   └── waveform_viewer.html    # HTML/JavaScript waveform viewer for browsers
│
├── .github/                    # GitHub Actions workflows
│   └── workflows/
│       └── sim.yml             # CI/CD simulation workflow
│
├── cpu_sim.vcd                 # Generated VCD waveform file (after simulation)
├── cpu_sim.vvp                 # Compiled simulation executable (after compilation)
└── sim.png                     # Example waveform screenshot
```

---

## Component Details

### 1. CPU Top-Level Module (`cpu.v`)

**Purpose**: Wires together all CPU components into a complete system.

**Key Responsibilities**:
- Connects program counter, instruction memory, control unit, register file, ALU, and data memory
- Implements data path multiplexing (ALU operand selection, memory address selection, register write data selection)
- Provides debug outputs for all registers and program counter

**Key Signals**:
- `clk`: System clock
- `rst`: Active-high reset signal
- `halt`: Indicates CPU has halted
- `pc_out`, `reg0_out` through `reg7_out`: Debug outputs

**Data Path Multiplexing**:
- ALU operand B: Either register value (`reg_read_b`) or immediate value
- Memory address: Either register value or immediate value
- Register write data: Either ALU result or data memory read output

### 2. Control Unit (`control_unit.v`)

**Purpose**: Decodes instructions and generates control signals for all CPU components.

**Architecture**: 4-state finite state machine:
- `STATE_FETCH`: Instruction is available from memory
- `STATE_DECODE`: Decode instruction fields and prepare execution
- `STATE_EXECUTE`: Execute conditional branches (check flags)
- `STATE_HALT`: CPU is halted

**Key Responsibilities**:
- Instruction decoding (extract opcode, register addresses, immediate values)
- Control signal generation (PC enable/load, register write enable, memory write enable, ALU operation select)
- State machine management
- Flag-based conditional branch evaluation

**Instruction Decoding**:
- Extracts: `opcode = instruction[15:12]`, `reg1 = instruction[11:9]`, `reg2 = instruction[8:6]`, `imm6 = instruction[5:0]`
- Zero-extends immediate to 8 bits for internal use

**Control Signals Generated**:
- `pc_enable`: Increment program counter
- `pc_load`: Load new PC value (for jumps)
- `reg_write_enable`: Write result to register file
- `mem_write_enable`: Write to data memory
- `alu_op`: ALU operation select (4 bits)
- `reg1_addr`, `reg2_addr`, `reg_dest_addr`: Register file addresses
- `immediate`: Immediate value (8 bits)
- `use_immediate`: Select immediate as ALU operand
- `mem_addr_sel`: Select immediate vs register for memory address
- `load_from_mem`: Select memory data vs ALU result for register write

### 3. ALU (`alu.v`)

**Purpose**: Performs arithmetic and logical operations on 8-bit operands.

**Operations Supported** (14 total):

| Operation | Code | Description | Result | Flags Updated |
|-----------|------|-------------|--------|---------------|
| ADD | 0x0 | Addition | `A + B` | Z, C, V, N |
| SUB | 0x1 | Subtraction | `A - B` | Z, C, V, N |
| AND | 0x2 | Bitwise AND | `A & B` | Z, N |
| OR | 0x3 | Bitwise OR | `A \| B` | Z, N |
| XOR | 0x4 | Bitwise XOR | `A ^ B` | Z, N |
| NOT | 0x5 | Bitwise NOT | `~A` | Z, N |
| SHL | 0x6 | Shift left | `A << B[2:0]` | Z, C, N |
| SHR | 0x7 | Shift right logical | `A >> B[2:0]` | Z, C, N |
| SAR | 0x8 | Shift right arithmetic | `$signed(A) >>> B[2:0]` | Z, C, N |
| LT | 0x9 | Less than (signed) | `(A < B) ? 1 : 0` | Z, N |
| LTU | 0xA | Less than (unsigned) | `(A < B) ? 1 : 0` | Z, N |
| EQ | 0xB | Equality | `(A == B) ? 1 : 0` | Z, N |
| PASS | 0xC | Pass operand A | `A` | Z, N |
| PASS_B | 0xD | Pass operand B | `B` | Z, N |

**Status Flags**:
- **Zero (Z)**: `result == 0`
- **Carry (C)**: Overflow from addition/subtraction or bit shifted out from shifts
- **Overflow (V)**: Signed arithmetic overflow (both operands same sign, result different sign)
- **Negative (N)**: `result[7] == 1` (MSB set)

**Implementation Details**:
- Uses 9-bit arithmetic internally for carry/borrow detection
- Shift operations use only lower 3 bits of shift amount (0-7 positions)
- Arithmetic shifts preserve sign bit

### 4. Register File (`register_file.v`)

**Purpose**: Provides 8 general-purpose 8-bit registers with dual-port read and single-port write.

**Architecture**:
- 8 registers, each 8 bits wide
- Two independent read ports (combinational)
- One write port (sequential, clocked)
- Write occurs on positive clock edge when `write_enable` is high

**Read Operations**:
- Combinational: Data available immediately on `read_addr_a` and `read_addr_b`
- No clock required

**Write Operations**:
- Sequential: Write occurs on positive clock edge
- Requires `write_enable == 1` and `write_addr` within valid range
- R0 protection: Conventionally R0 is read-only, but hardware allows writes

**Reset Behavior**: All registers reset to 0 on active reset signal

### 5. Program Counter (`program_counter.v`)

**Purpose**: Maintains the current instruction address and supports incrementing or jumping.

**Functionality**:
- **Reset**: PC resets to 0
- **Increment**: When `enable == 1`, PC increments by 1
- **Jump**: When `load == 1`, PC loads new value from `load_addr`
- **Priority**: Load takes precedence over increment

**Size**: 8 bits (supports addresses 0-255, 256 instructions)

### 6. Instruction Memory (`instruction_memory.v`)

**Purpose**: Stores the program as read-only memory (ROM).

**Specifications**:
- Size: 256 locations × 16 bits
- Address width: 8 bits (from program counter)
- Data width: 16 bits (instruction format)

**Initialization**:
- Contains a demo program in the `initial` block
- All unused locations initialized to 0 (treated as NOP)

**Read Behavior**: Combinational read - instruction available immediately at address

**Program Editing**: Edit the `initial` block to change the program. See [Creating Custom Programs](#creating-custom-programs) section.

### 7. Data Memory (`data_memory.v`)

**Purpose**: Provides separate data storage (Harvard architecture).

**Specifications**:
- Size: 256 locations × 8 bits
- Address width: 8 bits
- Data width: 8 bits

**Operations**:
- **Read**: Combinational - data available immediately at address
- **Write**: Sequential - write occurs on positive clock edge when `write_enable == 1`

**Reset Behavior**: All memory locations reset to 0 on active reset signal

**Usage**: Accessed by STORE and LOAD instructions for memory-mapped data storage

---

## Running Simulations

### Basic Simulation

Run a complete simulation (compile + execute):
```bash
make simulate
```

This performs:
1. Compilation: `iverilog -g2012 -o cpu_sim.vvp rtl/*.v sim/cpu_tb.v`
2. Execution: `vvp cpu_sim.vvp`
3. Generation: Creates `cpu_sim.vcd` waveform file

### Compilation Only

To compile without running:
```bash
make compile
```

### Manual Compilation (Advanced)

If you need more control, compile manually:
```bash
iverilog -g2012 -o cpu_sim.vvp \
    rtl/cpu.v \
    rtl/control_unit.v \
    rtl/alu.v \
    rtl/register_file.v \
    rtl/program_counter.v \
    rtl/instruction_memory.v \
    rtl/data_memory.v \
    sim/cpu_tb.v
```

### Manual Execution

Run the compiled simulation:
```bash
vvp cpu_sim.vvp
```

### Simulation Output

The testbench prints a detailed execution trace:
- Clock cycle timing
- Program counter value
- Halt status
- All register values (R0-R7)
- Current instruction (hex)
- Assembly mnemonic

Example output:
```
=================================================
    Enhanced 8-bit CPU Simulation
=================================================
Time(ns) | PC | Halt | R0 | R1 | R2 | R3 | R4 | R5 | R6 | R7 | Instruction | Assembly
-------------------------------------------------
  26000 |   0 |   0  |   0 |   0 |   0 |   0 |   0 |   0 |   0 |   0 | 0205      | LOADI R1, 5
  36000 |   1 |   0  |   0 |   5 |   0 |   0 |   0 |   0 |   0 |   0 | 040a      | LOADI R2, 10
  66000 |   2 |   0  |   0 |   5 |  10 |   0 |   0 |   0 |   0 |   0 | 1280      | ADD R2, R1, R2
  ...
-------------------------------------------------
CPU HALTED at time 236000 ns
Final Register Values:
  R0 =   0 (hex: 00, binary: 00000000)
  R1 =  10 (hex: 0a, binary: 00001010)
  R2 =  10 (hex: 0a, binary: 00001010)
  ...
```

---

## Viewing Waveforms

Waveforms are essential for debugging and understanding CPU operation. The project provides three viewing options:

### 1. Web Browser Viewer (Recommended)

**Best for**: Interactive exploration, macOS compatibility

```bash
make web-wave
```

This opens `tools/waveform_viewer.html` in your default browser. Then:
1. Drag and drop `cpu_sim.vcd` into the browser window
2. Select signals to display from the signal tree
3. Zoom and pan using mouse controls
4. Search for specific signal names

**Advantages**:
- Works on all platforms
- No additional software needed
- Interactive zoom/pan
- Signal search functionality

### 2. Terminal Viewer (Text-Based)

**Best for**: Quick checks, scripted analysis

```bash
make wave
```

This runs `tools/vcd_viewer.py` which:
- Parses the VCD file
- Displays signal value tables
- Shows ASCII-style waveforms for key signals
- Prints summary statistics

**Advantages**:
- Works in any terminal
- Good for automation
- No GUI required

**Example Output**:
```
Signal: clk
  Time 0: 0
  Time 5: 1
  Time 10: 0
  ...

Signal: pc
  0: 0
  10: 0
  20: 1
  ...

ASCII Waveform:
clk:  _|‾|_|‾|_|‾|_|‾
pc:   __‾‾‾‾‾‾‾‾‾‾
```

### 3. GTKWave (If Installed)

**Best for**: Professional waveform analysis

```bash
make gtkwave
```

**Installation** (if needed):
- **macOS**: `brew install gtkwave` (may have issues on Apple Silicon)
- **Linux**: Usually available in package manager (`sudo apt-get install gtkwave`)

**Advantages**:
- Professional-grade tool
- Advanced filtering and search
- Export capabilities
- Cursor measurements

**Note**: GTKWave can be problematic on Apple Silicon Macs. Use the web viewer instead.

### Recommended Signals to Monitor

When viewing waveforms, these signals are most informative:

**Control Signals**:
- `clk`: System clock
- `rst`: Reset signal
- `halt`: Halt indicator

**Instruction Flow**:
- `pc`: Program counter (instruction address)
- `instruction`: Current 16-bit instruction
- `opcode`: Decoded instruction opcode

**Register File**:
- `reg0_out` through `reg7_out`: All register values

**ALU**:
- `alu_result`: ALU computation result
- `zero_flag`, `carry_flag`, `overflow_flag`, `negative_flag`: Status flags

**Memory**:
- `mem_addr`: Data memory address
- `mem_read_data`: Data read from memory
- `mem_write_enable`: Memory write indicator

**Control Unit State**:
- `state`: Current FSM state (if exposed)

---

## Example Programs

### Default Demo Program

The instruction memory comes pre-loaded with a comprehensive demo program that exercises all instruction types:

```assembly
; Enhanced 8-bit CPU Demo Program
; Demonstrates: Immediate loading, arithmetic, logic, memory ops, control flow

0:  LOADI R1, 5        ; R1 = 5
1:  LOADI R2, 10       ; R2 = 10
2:  ADD R2, R1, R2     ; R2 = R1 + R2 = 5 + 10 = 15
3:  SUB R1, R2, R1     ; R1 = R2 - R1 = 15 - 5 = 10
4:  MOV R3, R1         ; R3 = R1 = 10 (register copy)
5:  CMP R1, R2         ; Compare R1 and R2, set flags (10 - 15 = -5)
6:  LOADI R4, 50       ; R4 = 50 (memory address)
7:  STORE R1, [50]     ; Mem[50] = R1 = 10
8:  LOAD R5, [50]      ; R5 = Mem[50] = 10
9:  AND R2, R1, R2     ; R2 = R1 & R2 = 10 & 15 = 10
10: MOV R6, R2         ; R6 = R2 = 10
11: JUMP 13            ; Unconditional jump to address 13
12: LOADI R7, 99       ; This instruction is skipped
13: LOADI R7, 42       ; R7 = 42
14: HALT               ; Stop execution
```

**Expected Final State**:
- R0 = 0 (never written)
- R1 = 10 (from SUB instruction)
- R2 = 10 (from AND instruction)
- R3 = 10 (from MOV instruction)
- R4 = 50 (memory address, from LOADI)
- R5 = 10 (loaded from memory address 50)
- R6 = 10 (from MOV instruction)
- R7 = 42 (from LOADI at address 13)
- Mem[50] = 10 (stored by STORE instruction)

### Simple Arithmetic Program

A minimal program that adds two numbers:

```assembly
0:  LOADI R1, 15       ; R1 = 15
1:  LOADI R2, 27       ; R2 = 27
2:  ADD R3, R1, R2     ; R3 = R1 + R2 = 42
3:  HALT               ; Stop
```

**Expected Result**: R3 = 42

### Memory Operations Example

Demonstrates storing and loading data:

```assembly
0:  LOADI R1, 100      ; R1 = 100
1:  STORE R1, [32]     ; Mem[32] = 100
2:  LOAD R2, [32]      ; R2 = Mem[32] = 100
3:  ADD R3, R2, R1     ; R3 = R2 + R1 = 200
4:  HALT               ; Stop
```

**Expected Result**: R2 = 100, R3 = 200, Mem[32] = 100

### Control Flow Example

Demonstrates conditional branches:

```assembly
0:  LOADI R1, 0        ; R1 = 0 (zero value)
1:  JZ R1, 4           ; Jump to 4 if R1 == 0 (will jump)
2:  LOADI R2, 99       ; Skipped
3:  JUMP 5             ; Skipped
4:  LOADI R2, 42       ; R2 = 42 (this executes)
5:  HALT               ; Stop
```

**Expected Result**: R2 = 42 (instruction at address 2 is skipped)

---

## Creating Custom Programs

### Editing Instruction Memory

Programs are stored in `rtl/instruction_memory.v` in the `initial` block. To create a custom program:

1. **Open the file**:
   ```bash
   code rtl/instruction_memory.v  # or your preferred editor
   ```

2. **Edit the `initial` block**: Modify or add instruction assignments:
   ```verilog
   memory[0] = {4'b0000, 3'b001, 3'b000, 6'b000101};  // LOADI R1, 5
   memory[1] = {4'b0001, 3'b001, 3'b010, 6'b000000};  // ADD R2, R1, R2
   // ... more instructions
   ```

3. **Instruction Encoding Format**:
   ```verilog
   memory[address] = {opcode[3:0], reg1[2:0], reg2[2:0], immediate[5:0]};
   ```

4. **Clear unused locations**: Ensure all unused memory locations are set to 0 (or HALT):
   ```verilog
   for (i = program_end; i < 256; i = i + 1) begin
       memory[i] = 16'b1111000000000000;  // HALT instruction
   end
   ```

5. **Recompile and simulate**:
   ```bash
   make simulate
   ```

### Instruction Encoding Helper

Use this reference when encoding instructions:

**LOADI Rd, imm**:
```verilog
memory[addr] = {4'b0000, reg_dest[2:0], 3'b000, immediate[5:0]};
// Example: LOADI R1, 5
memory[0] = {4'b0000, 3'b001, 3'b000, 6'b000101};
```

**ADD Rd, Rs1, Rs2**:
```verilog
memory[addr] = {4'b0001, src1[2:0], dest[2:0], 6'b000000};
// Example: ADD R2, R1, R2 (R2 = R1 + R2)
memory[2] = {4'b0001, 3'b001, 3'b010, 6'b000000};
```

**STORE Rs, [addr]**:
```verilog
memory[addr] = {4'b0110, src_reg[2:0], 3'b000, address[5:0]};
// Example: STORE R1, [50]
memory[7] = {4'b0110, 3'b001, 3'b000, 6'b110010};  // 50 = 0b110010
```

**LOAD Rd, [addr]**:
```verilog
memory[addr] = {4'b0111, dest_reg[2:0], 3'b000, address[5:0]};
// Example: LOAD R5, [50]
memory[8] = {4'b0111, 3'b101, 3'b000, 6'b110010};
```

**JUMP addr**:
```verilog
memory[addr] = {4'b1100, 3'b000, 3'b000, target_addr[5:0]};
// Example: JUMP 13
memory[11] = {4'b1100, 3'b000, 3'b000, 6'b001101};  // 13 = 0b001101
```

**HALT**:
```verilog
memory[addr] = {4'b1111, 3'b000, 3'b000, 6'b000000};
// Example: HALT
memory[14] = {4'b1111, 3'b000, 3'b000, 6'b000000};
```

### Assembly to Verilog Converter Script

For convenience, you could create a simple script to convert assembly mnemonics to Verilog encoding. Here's a Python example:

```python
def encode_loadi(reg, imm):
    return f"{{4'b0000, 3'b{reg:03b}, 3'b000, 6'b{imm:06b}}}"

def encode_add(dest, src1, src2):
    return f"{{4'b0001, 3'b{src1:03b}, 3'b{dest:03b}, 6'b000000}}"

# Usage:
print(f"memory[0] = {encode_loadi(1, 5)};  // LOADI R1, 5")
```

### Best Practices

1. **Always include a HALT instruction** at the end of your program
2. **Document your program** with comments explaining what each instruction does
3. **Test incrementally**: Start with simple programs, then add complexity
4. **Check register values** after simulation to verify correctness
5. **Use meaningful addresses** for memory operations (avoid address 0 if possible)

---

## Makefile Reference

The project includes a comprehensive Makefile for building and simulation:

### Available Targets

| Target | Description | Command |
|--------|-------------|---------|
| `all` | Default target (runs `simulate`) | `make` or `make all` |
| `compile` | Compile Verilog files only | `make compile` |
| `simulate` | Compile and run simulation | `make simulate` |
| `wave` | Run simulation and view in terminal | `make wave` |
| `web-wave` | Run simulation and open web viewer | `make web-wave` |
| `gtkwave` | Run simulation and open GTKWave | `make gtkwave` |
| `clean` | Remove generated files | `make clean` |
| `help` | Display help message | `make help` |

### Target Dependencies

```
simulate → compile
wave → simulate
web-wave → simulate
gtkwave → simulate
```

### Customization

You can modify the Makefile to:
- Change compiler flags (`-g2012` enables SystemVerilog-2012 features)
- Add additional RTL files
- Change output file names
- Add new targets (e.g., `lint`, `coverage`)

### Example: Adding a Lint Target

```makefile
lint:
	verilator --lint-only $(RTL_FILES)
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. "iverilog: command not found"

**Problem**: Icarus Verilog is not installed or not in PATH.

**Solution**: 
- Install Icarus Verilog (see [Installation](#installation))
- Verify installation: `which iverilog`
- Check PATH: `echo $PATH`

#### 2. "python3: command not found"

**Problem**: Python 3 is not installed or not in PATH.

**Solution**:
- Install Python 3 (see [Installation](#installation))
- Some systems use `python` instead of `python3` - update Makefile accordingly
- Verify: `python3 --version`

#### 3. Simulation Never Halts

**Problem**: CPU keeps executing without stopping.

**Possible Causes**:
- Program doesn't contain a HALT instruction
- HALT instruction is incorrectly encoded
- Control unit state machine is stuck

**Solution**:
- Verify HALT instruction exists: `memory[N] = {4'b1111, 3'b000, 3'b000, 6'b000000};`
- Check waveform to see if PC keeps incrementing
- Add explicit timeout in testbench if needed

#### 4. "No such file or directory: cpu_sim.vcd"

**Problem**: VCD file wasn't generated.

**Possible Causes**:
- Simulation failed during compilation
- Simulation crashed before completion
- Makefile didn't run simulation

**Solution**:
- Check for compilation errors: `make compile`
- Run simulation manually: `vvp cpu_sim.vvp`
- Check console output for errors
- Verify testbench has `$dumpfile` and `$dumpvars` calls

#### 5. Web Viewer Shows Nothing

**Problem**: Waveform viewer opens but displays blank.

**Solution**:
- **Drag and drop** `cpu_sim.vcd` into the browser window (it's not auto-loaded)
- Ensure VCD file exists: `ls -l cpu_sim.vcd`
- Check browser console for JavaScript errors (F12)
- Try a different browser (Chrome, Firefox, Safari)

#### 6. Register Values Are Wrong

**Problem**: Simulation completes but register values don't match expectations.

**Debugging Steps**:
1. Check instruction encoding in `instruction_memory.v`
2. Verify instruction format matches opcode definitions
3. Review waveform to see register writes
4. Check ALU operations produce correct results
5. Verify control signals are correct for each instruction

**Common Mistakes**:
- Wrong register addresses (remember: 3 bits, 0-7)
- Immediate values too large (>63) or incorrectly encoded
- Destination register wrong for arithmetic operations
- Memory addresses outside valid range (0-255)

#### 7. Compilation Errors

**Common Verilog Errors**:

**"Port width mismatch"**:
- Check signal widths match module port definitions
- Ensure 8-bit signals connect to 8-bit ports

**"Undefined signal"**:
- Check signal names match exactly (case-sensitive)
- Verify signals are declared in correct scope

**"Illegal left-hand side"**:
- Cannot assign to `wire` - must use `reg` or `assign`
- Check if signal should be combinational (`assign`) or sequential (`always @(*)`)

#### 8. GTKWave Issues on macOS

**Problem**: GTKWave doesn't work or crashes on Apple Silicon Macs.

**Solution**:
- Use web viewer instead: `make web-wave`
- Install X11/XQuartz if using Intel Mac
- Consider using alternative viewers or running Linux VM

#### 9. Simulation Runs Too Fast/Slow

**Problem**: Can't see individual cycles in output.

**Solution**:
- Adjust clock period in testbench: `forever #5 clk = ~clk;` (5ns = 100MHz)
- Modify `$display` frequency in testbench
- Use waveform viewer for detailed timing analysis

#### 10. Branch Instructions Not Working

**Problem**: JZ/JNZ always jump or never jump.

**Debugging**:
- Verify zero flag is set correctly by ALU
- Check that CMP or arithmetic instruction executed before branch
- Review control unit state machine for JZ/JNZ handling
- Check immediate field contains correct jump target address

### Getting Help

If you encounter issues not covered here:

1. **Check waveforms**: Often reveals the problem immediately
2. **Add debug prints**: Insert `$display` statements in modules
3. **Simplify program**: Test with minimal 2-3 instruction program
4. **Verify syntax**: Use Verilog linter if available
5. **Review documentation**: Re-read relevant component descriptions

---

## Development Guide

### Code Style Guidelines

1. **Naming Conventions**:
   - Modules: `snake_case` (e.g., `register_file`)
   - Signals: `snake_case` (e.g., `write_enable`)
   - Parameters: `UPPER_CASE` (e.g., `ALU_ADD`)
   - Clock: `clk`, Reset: `rst`

2. **Module Organization**:
   - Port declarations first
   - Internal wire/reg declarations
   - Sub-module instantiations
   - Combinational logic (`always @(*)` or `assign`)
   - Sequential logic (`always @(posedge clk)`)

3. **Comments**:
   - Module header with purpose and key signals
   - Explain complex logic
   - Document instruction encodings
   - Note any design decisions or limitations

4. **Indentation**: Use consistent indentation (spaces or tabs, 2-4 spaces recommended)

### Adding New Instructions

To add a new instruction:

1. **Define opcode** in `control_unit.v`:
   ```verilog
   localparam OP_NEW = 4'bXXXX;
   ```

2. **Add ALU operation** (if needed) in `alu.v`:
   ```verilog
   localparam ALU_NEW = 4'bXXXX;
   // Implement operation in case statement
   ```

3. **Decode instruction** in `control_unit.v`:
   ```verilog
   OP_NEW: begin
       // Set control signals
       reg_dest_addr <= reg2;
       alu_op <= ALU_NEW;
       // ... other signals
       state <= STATE_FETCH;
   end
   ```

4. **Update testbench** to display new instruction mnemonic

5. **Add to instruction memory** demo program to test

6. **Update documentation** (this README)

### Testing New Features

1. **Unit Test**: Test component in isolation if possible
2. **Integration Test**: Test in full CPU context
3. **Waveform Analysis**: Verify timing and signals
4. **Regression Test**: Ensure existing instructions still work

### Version Control

Recommended `.gitignore` entries:
```
*.vcd
*.vvp
*.vcd.lxt
*.log
.DS_Store
```

### Continuous Integration

The project includes a GitHub Actions workflow (`.github/workflows/sim.yml`) that:
- Runs simulation on every push
- Verifies compilation succeeds
- Checks for basic functionality

---

## Future Extensions

### Potential Enhancements

#### Instruction Set Extensions

- **Stack Operations**: PUSH, POP for subroutine support
- **Multiplication/Division**: Hardware multiply/divide instructions
- **Extended Immediate**: 16-bit immediate values for larger constants
- **Memory-Mapped I/O**: Instructions for peripheral access
- **Interrupts**: Hardware interrupt support with interrupt vector table

#### Architecture Improvements

- **Pipeline**: 3-5 stage instruction pipeline for higher throughput
- **Cache**: Instruction and data caches for faster memory access
- **Branch Prediction**: Predict branch outcomes to reduce stalls
- **Register Windows**: Overlapping register sets for fast context switching
- **Floating-Point Unit**: Support for IEEE 754 floating-point operations

#### Memory System

- **Virtual Memory**: Memory management unit (MMU) for address translation
- **Memory Protection**: Read/write/execute permission bits
- **Cache Hierarchy**: L1/L2 cache with coherence protocol

#### Debugging Features

- **Breakpoints**: Hardware breakpoint support
- **Single-Step Mode**: Execute one instruction at a time
- **Register/Memory Inspection**: Debug port for reading internal state
- **Instruction Tracing**: Log of executed instructions

#### Tooling

- **Assembler**: Convert assembly mnemonics to binary instructions
- **Linker**: Combine multiple object files
- **Debugger**: GDB-like interface for CPU debugging
- **Compiler Backend**: LLVM/GCC backend targeting this CPU

#### Hardware Implementation

- **FPGA Synthesis**: Target specific FPGA families (Xilinx, Altera)
- **ASIC Design**: Full custom layout for ASIC implementation
- **Clock Gating**: Reduce power consumption
- **Test Infrastructure**: Built-in self-test (BIST) circuitry

### Educational Projects Based on This CPU

1. **Operating System**: Simple OS with scheduler, memory manager
2. **Compiler**: Write a compiler for a simple language (e.g., C subset)
3. **Virtual Machine**: Implement a VM on top of this CPU
4. **Debugger**: Build a software debugger with breakpoints, watchpoints
5. **Performance Analyzer**: Profile instruction execution, identify bottlenecks

---

## License

This project is provided as-is for educational purposes. Feel free to use, modify, and distribute as needed.

---

## Acknowledgments

This CPU design is based on fundamental computer architecture principles and is intended as an educational tool for understanding:
- Instruction set architecture (ISA) design
- Control unit and datapath implementation
- Memory systems and Harvard vs. von Neumann architectures
- Hardware description languages (Verilog)
- Digital circuit simulation

---

## Contact and Contributions

For questions, suggestions, or contributions:
- Review the code and documentation
- Submit issues for bugs or feature requests
- Fork and submit pull requests for improvements
- Share your own programs and modifications

---

**Happy CPU Designing! 🚀**
