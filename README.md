# Simple 4-Bit CPU Project

A small 4‑bit CPU core and testbench, meant as a first hands‑on hardware project. It uses plain Verilog, Icarus Verilog for simulation, and a couple of simple viewers for looking at the waveforms.

---

## Table of Contents

1. Project Overview
2. Quick Start (macOS / Linux)
3. What You’ll Learn
4. Project Layout
5. Installation
6. Running a Simulation
7. Viewing Waveforms
8. Example Output
9. CPU Architecture
10. Instruction Set
11. Editing the Demo Program
12. Makefile Targets
13. Troubleshooting
14. Ideas for Extensions
15. Next Steps

---

## Project Overview

This repo contains a minimal 4‑bit CPU with:

- a tiny instruction memory (ROM)
- a 4‑register file
- a basic ALU
- a simple control unit / state machine
- a testbench that drives everything and writes a VCD file

The goal isn’t to be fancy. It’s just enough logic to see how a CPU fetches, decodes, and executes a short program, and to give you something small you can comfortably read in one sitting.

---

## Quick Start

### Requirements

- macOS (Intel or Apple Silicon) or Linux
- Icarus Verilog (`iverilog`, `vvp`)
- Python 3
- Any modern web browser (for the HTML waveform viewer)

### Install Icarus Verilog

On macOS (Homebrew):

```bash
brew install icarus-verilog
```

On Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install iverilog
```

Check that things are on the path:

```bash
iverilog -v
python3 --version
```

---

## What You’ll Learn

Working through this repo you’ll touch:

- writing small, modular Verilog modules
- basic CPU datapath components (ALU, register file, program counter, control)
- simple finite‑state machines
- running simulations with Icarus Verilog
- reading VCD waveforms and correlating them with the program

It’s a good size project if you’re comfortable with basic logic gates and want to see how they add up to “a CPU”.

---

## Project Layout

```text
simple-cpu-project/
├── Makefile
├── README.md
│
├── rtl/                     # RTL design
│   ├── alu.v
│   ├── register_file.v
│   ├── program_counter.v
│   ├── instruction_memory.v
│   ├── control_unit.v
│   └── cpu.v                # top level
│
├── sim/
│   └── cpu_tb.v             # testbench
│
├── tools/
│   ├── vcd_viewer.py        # text/terminal VCD viewer
│   └── waveform_viewer.html # in‑browser VCD viewer
│
├── cpu_sim.vcd              # VCD written by the testbench (generated)
├── cpu_sim.vvp              # compiled simulation (generated)
└── sim.png                  # example waveform screenshot
```

---

## Installation

Clone or copy the project somewhere convenient, then from the project root:

```bash
cd simple-cpu-project
make help
```

If `make help` runs and prints the targets, your toolchain is probably set up correctly.

---

## Running a Simulation

From the project root:

```bash
make simulate
```

This compiles the RTL and testbench with `iverilog`, runs the simulation with `vvp`, and writes `cpu_sim.vcd`. The testbench also prints a short trace of the program as it executes.

You should see output along these lines (exact numbers may differ if you change the program):

```text
=================================================
    Simple 4-bit CPU Simulation
=================================================
Time(ns) | PC | Halt | R0 | R1 | R2 | R3 | Instruction
-------------------------------------------------
     25 |  0 |   0  |  0 |  0 |  0 |  0 | 00000101
     35 |  1 |   0  |  5 |  0 |  0 |  0 | 00000011
     45 |  2 |   0  |  5 |  3 |  0 |  0 | 00100001
     55 |  3 |   0  |  8 |  3 |  0 |  0 | 00000010
```

---

## Viewing Waveforms

There are a few options for looking at the VCD.

### 1. Web Viewer (HTML)

Opens a small in‑browser viewer from the `tools` directory:

```bash
make web-wave
```

Your default browser should open `tools/waveform_viewer.html`. Once it’s open:

- drag `cpu_sim.vcd` into the page
- select signals you care about (e.g. `clk`, `pc`, `halt`, register outputs)
- zoom and pan around the timeline

### 2. Terminal Viewer (Python)

For a quick text‑based summary:

```bash
make wave
```

This runs `tools/vcd_viewer.py` on `cpu_sim.vcd` and prints signal tables and a couple of simple ASCII “waveforms” directly in the terminal.

### 3. Other Tools

If you already have GTKWave or another VCD viewer installed, you can of course use that as well. The Makefile has a `gtkwave` target for convenience:

```bash
make gtkwave
```

On Apple Silicon, GTKWave can be finicky; the web viewer tends to be the least painful option.

---

## Example Waveform (sim.png)

The file `sim.png` was captured from a run of this testbench and shows one of the example programs executing. It’s roughly what you should see if you load `cpu_sim.vcd` into a waveform viewer right after cloning the repo and running `make simulate` once.

In short:

- the clock toggles throughout the run
- the program counter steps through addresses 0–7
- register `R0` walks through a few values as the arithmetic instructions execute
- the `halt` signal goes high on the HALT instruction and stays there

You can use this screenshot as a sanity check if your own waveforms look very different.

![Example CPU simulation waveform](sim.png)

---

## CPU Architecture (High Level)

The CPU is intentionally simple:

- 4‑bit datapath (all registers and the ALU are 4 bits wide)
- 4 general‑purpose registers (`R0`–`R3`)
- 16‑entry instruction memory, 8 bits per instruction
- a program counter that either increments or jumps to a given address
- a small ALU (ADD, SUB, AND, OR, XOR, pass‑through)
- a control unit implemented as a finite‑state machine

A very rough block diagram looks like this:

```text
┌─────────────────────────────────────────┐
│              4-BIT CPU                 │
│                                         │
│  ┌──────────┐                           │
│  │ Program  │                           │
│  │ Counter  │────┐                      │
│  └──────────┘    │                      │
│       ↑          ↓                      │
│       │   ┌─────────────┐              │
│       │   │Instruction  │              │
│       │   │   Memory    │              │
│       │   └─────────────┘              │
│       │          │                      │
│       │          ↓                      │
│       │   ┌─────────────┐              │
│       └───│   Control   │              │
│           │    Unit     │              │
│           └─────────────┘              │
│              │        │                 │
│      ┌───────┘        └────────┐       │
│      ↓                         ↓       │
│  ┌─────────┐             ┌─────────┐  │
│  │Register │────────────→│   ALU   │  │
│  │  File   │             └─────────┘  │
│  └─────────┘                  │        │
│      ↑                        │        │
│      └────────────────────────┘        │
└─────────────────────────────────────────┘
```

---

## Instruction Set

Each instruction is 8 bits: the upper 4 bits are the opcode, the lower 4 bits are an operand (immediate) or an address.

### Encoding

```text
[7:4] opcode
[3:0] operand/address
```

### Implemented Instructions

| Opcode | Mnemonic | Description                           | Example           |
|--------|----------|---------------------------------------|-------------------|
| 0000   | LOAD     | Load 4‑bit immediate into `R0`       | `0000_0101`       |
| 0010   | ADD      | `R0 ← R0 + R1`                       | `0010_0001`       |
| 0011   | SUB      | `R0 ← R0 - R1`                       | `0011_0010`       |
| 0100   | AND      | `R0 ← R0 & R1`                       | `0100_0001`       |
| 0101   | OR       | `R0 ← R0 | R1`                       | `0101_0001`       |
| 0110   | JUMP     | `PC ← address` (unconditional)       | `0110_0011`       |
| 0111   | HALT     | Stop execution                       | `0111_0000`       |
| 1000   | JZ       | Jump if last result was zero         | `1000_0111`       |
| 1001   | JNZ      | Jump if last result was non‑zero     | `1001_0111`       |

The control unit keeps a small latched copy of the ALU’s zero flag so that `JZ` / `JNZ` can make decisions based on the most recent arithmetic/logic instruction.

---

## The Demo Program

`rtl/instruction_memory.v` comes preloaded with a small program that hits arithmetic, a couple of branches, and HALT. In table form:

```text
Address | Binary       | Assembly        | Effect
--------|--------------|-----------------|-------------------------------
   0    | 0000_0000    | LOAD R0, 0      | R0 = 0
   1    | 0000_0001    | LOAD R1, 1      | R1 = 1
   2    | 0010_0001    | ADD  R0, R1     | R0 = 1, last_zero = 0
   3    | 1000_0111    | JZ   7          | not taken (last_zero = 0)
   4    | 0011_0001    | SUB  R0, R1     | R0 = 0, last_zero = 1
   5    | 1001_0111    | JNZ  7          | not taken (last_zero = 1)
   6    | 1000_1000    | JZ   8          | taken   (last_zero = 1)
   7    | 0000_0011    | LOAD R0, 3      | skipped
   8    | 0111_0000    | HALT            | stop
```

If you run `make simulate` right after cloning, the printout in the terminal is this program executing. The self‑checking testbench will also assert that the final register state is `R0=0, R1=1, R2=0, R3=0`.

---

## Editing the Program

To change the program, open `rtl/instruction_memory.v` and edit the `initial` block. For example, a very small variant that just does a single add and halts:

```verilog
initial begin
    memory[0]  = 8'b0000_1010;  // LOAD R0, 10
    memory[1]  = 8'b0000_0101;  // LOAD R1, 5
    memory[2]  = 8'b0010_0001;  // ADD R0, R1 (10 + 5 = 15)
    memory[3]  = 8'b0111_0000;  // HALT
    // rest left at 0
end
```

Then re‑run:

```bash
make simulate
make web-wave
```

You should see the new values reflected both in the terminal trace and in your waveforms.

---

## Makefile Targets

The main shortcuts live in the top‑level `Makefile`:

```text
make simulate   # compile and run the testbench, produce cpu_sim.vcd
make wave       # run the Python VCD viewer in the terminal
make web-wave   # open the HTML waveform viewer in your browser
make gtkwave    # (optional) open cpu_sim.vcd in GTKWave, if installed
make clean      # remove generated files
make help       # list available targets
```

If `make` isn’t available on your system, you can run the underlying commands manually:

```bash
iverilog -g2012 -o cpu_sim.vvp rtl/*.v sim/cpu_tb.v
vvp cpu_sim.vvp
python3 tools/vcd_viewer.py cpu_sim.vcd
```

---

## Troubleshooting

A few common things that tend to go wrong:

- **`iverilog: command not found`**: install Icarus Verilog using Homebrew or your distro’s package manager.
- **`python3: command not found`**: install Python 3 from your package manager or from python.org.
- **No `cpu_sim.vcd` after running `make simulate`**: check the console output for earlier compile errors.
- **Simulation never halts**: make sure your program contains a `HALT` instruction (`0111_0000`).
- **Web viewer opens but shows nothing**: drag `cpu_sim.vcd` into the page; the file isn’t loaded automatically.

If you’re really stuck, it’s often helpful to:

- temporarily shorten the program so you can focus on a couple of instructions
- watch `pc`, `instruction`, and `R0` in the waveforms and step through by hand

---

## Ideas for Extensions

Some low‑effort ways to push the design a bit further:

- add a couple more ALU ops (shift left/right, NOT)
- add a `JZ` / `JNZ` style conditional jump using the ALU’s zero flag
- separate data memory from instruction memory
- bump the datapath to 8 bits and resize the registers/ALU

And if you want a larger project:

- build a slightly richer instruction set
- try a tiny RISC‑style core
- port the whole thing to an FPGA dev board and blink some LEDs based on register contents

---

## Next Steps

If you’ve read through the RTL and are comfortable tweaking the instruction memory, you’ve already covered most of what this project is meant to show. From here, you can either grow this design or start something new (UART, FIFO, simple bus, etc.).

In any case, keep the VCDs and waveforms handy—being able to read them comfortably is one of the most useful habits you can build early on.
