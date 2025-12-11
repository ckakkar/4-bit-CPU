# Simple 4-Bit CPU Project

**Your First Digital Design Project - Complete All-in-One Guide**

This is a working 4-bit CPU that demonstrates all core concepts of computer architecture. Perfect for beginners learning RTL design, hardware verification, and FPGA development.

> **🍎 Mac M2/M1 Users:** This project works PERFECTLY on Apple Silicon - no GTKWave needed!

---

## 📋 Table of Contents

1. [Project Overview](#-project-overview)
2. [Mac M2 Quick Start](#-mac-m2-quick-start-5-minutes)
3. [What You'll Learn](#-what-youll-learn)
4. [Project Structure](#-project-structure)
5. [Installation](#-installation)
6. [Running Your First Simulation](#-running-your-first-simulation)
7. [Viewing Waveforms](#-viewing-waveforms)
8. [Understanding the Output](#-understanding-the-output)
9. [CPU Architecture](#-cpu-architecture)
10. [Instruction Set](#-instruction-set)
11. [Modifying Programs](#-modifying-programs)
12. [Makefile Commands](#-makefile-commands)
13. [Troubleshooting](#-troubleshooting)
14. [Customization Ideas](#-customization-ideas)
15. [What's Next](#-whats-next)

---

## 📦 Project Overview

### Files Included

```
simple-cpu-project/
├── Makefile                     # Build automation
├── README.md                    # This comprehensive guide
│
├── rtl/                         # Hardware Design (6 files)
│   ├── alu.v                   # Arithmetic Logic Unit
│   ├── register_file.v         # 4 registers (R0-R3)
│   ├── program_counter.v       # Instruction pointer
│   ├── instruction_memory.v    # Program storage
│   ├── control_unit.v          # Control logic & FSM
│   └── cpu.v                   # Top-level integration
│
├── sim/                         # Simulation (1 file)
│   └── cpu_tb.v                # Testbench
│
└── tools/                       # Waveform Viewers (2 files)
    ├── vcd_viewer.py           # Terminal viewer
    └── waveform_viewer.html    # Web viewer ⭐
```

Total: **11 files** - everything you need!

---


## 🍎 Mac M2 Quick Start (5 Minutes)

**Your CPU project is 100% compatible with Apple Silicon!**

This guide gets you running in 5 minutes.

---

## ✅ What You Need (Already Have)

- ✅ Mac M2 (or M1)
- ✅ Terminal (comes with macOS)
- ✅ Safari/Chrome/Firefox (any browser)
- ✅ Python 3 (comes with macOS)

## 📥 What to Install

Only one thing:

```bash
brew install icarus-verilog
```

This gives you `iverilog` and `vvp` for compiling and simulating Verilog.

**That's it!** No GTKWave needed.

---

## 🎬 Run Your First Simulation

### Step 1: Open Terminal

Press `Cmd + Space`, type "Terminal", press Enter

### Step 2: Navigate to Project

```bash
cd ~/Downloads/simple-cpu-project
```

(Adjust path if you saved it elsewhere)

### Step 3: Run It!

```bash
make simulate
```

You'll see your CPU execute a program! Watch the register values change!

---

## 👀 View Waveforms

### Best Option: Web Browser

```bash
make web-wave
```

Your browser opens with a beautiful waveform viewer:
- Drag and drop the `cpu_sim.vcd` file
- See waveforms instantly
- Switch between waveform and table views
- Export data as CSV

**This works PERFECTLY on Mac M2!** No compatibility issues.

### Quick Option: Terminal

```bash
make wave
```

See ASCII waveforms and tables right in your terminal. Super fast!

---

## 🎯 What You Should See

### Terminal Output (make simulate)

```
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

Watch R0 change: 0 → 5 → 8 → 6 ... That's your CPU computing!

### Web Viewer (make web-wave)

Beautiful dark-themed interface showing:
- Visual waveforms
- Signal values
- Time axis
- Interactive controls

### Terminal Viewer (make wave)

Text-based output with:
- Signal value tables
- ASCII waveforms for clock/halt
- Register changes over time

---

## 🛠️ All Commands

```bash
make simulate  # Run simulation, see results
make wave      # Terminal waveforms
make web-wave  # Browser waveforms (recommended!)
make clean     # Remove generated files
make help      # Show all commands
```

---

## 📝 Modify the Program

Want to try something different?

1. **Open the instruction memory:**
   ```bash
   open -a TextEdit rtl/instruction_memory.v
   ```

2. **Find the `initial begin` block** (around line 16)

3. **Change some instructions:**
   ```verilog
   memory[0] = 8'b0000_1010;  // LOAD R0, 10
   memory[1] = 8'b0000_0101;  // LOAD R1, 5
   memory[2] = 8'b0010_0001;  // ADD R0, R1
   memory[3] = 8'b0111_0000;  // HALT
   ```

4. **Save and re-run:**
   ```bash
   make simulate
   ```

See your changes in action!

---

## 🎨 Why This Is Perfect for Mac M2

**Traditional GTKWave:**
- ❌ Often doesn't work on Apple Silicon
- ❌ Requires Rosetta 2
- ❌ Can be unstable

**Our Solution:**
- ✅ Native Python (built into macOS)
- ✅ Modern web standards (works in Safari)
- ✅ No external dependencies
- ✅ Better looking anyway!

---

## 🐛 Troubleshooting

### "iverilog: command not found"
```bash
brew install icarus-verilog
```

### "make: command not found"
Run commands individually:
```bash
iverilog -g2012 -o cpu_sim.vvp rtl/*.v sim/cpu_tb.v
vvp cpu_sim.vvp
python3 tools/vcd_viewer.py cpu_sim.vcd
```

### Browser won't open web viewer?
```bash
open tools/waveform_viewer.html
```
Then drag `cpu_sim.vcd` into it.

### Still stuck?
Check the full docs:
- `docs/GETTING_STARTED.md` - Step-by-step guide
- `docs/WAVEFORM_VIEWING.md` - All about waveforms
- `README.md` - Complete documentation

---

## 🎓 What You're Learning

This project teaches you:
- ✅ **Verilog** - Hardware description language
- ✅ **CPU architecture** - How computers really work
- ✅ **Digital design** - Building with logic gates
- ✅ **Verification** - Testing hardware designs
- ✅ **Waveform analysis** - Debugging at the signal level

**This is exactly what FPGA/ASIC engineers do every day!**

---

## 📚 Next Steps

1. ✅ **Run the simulation** - Done!
2. ✅ **View waveforms** - See what's happening
3. 📖 **Read README.md** - Understand how it works
4. 🎨 **Modify the program** - Experiment!
5. 🔍 **Study the code** - Learn Verilog
6. 🚀 **Build Project #2** - UART or SPI communication

---

## 💪 You're Ready!

You now have:
- ✅ Working CPU simulation
- ✅ Multiple waveform viewers
- ✅ Complete documentation
- ✅ Beginner-friendly tools
- ✅ Everything you need to learn hardware design

**No GTKWave required. No compatibility issues. Just hardware engineering! 🎉**

---

*Pro tip: Keep this terminal window open and refer back to it as you work. Happy coding!* 💻


---


## 🎯 What You'll Learn

This project covers:
- ✅ Writing clean, modular Verilog code
- ✅ Building digital subsystems (ALU, registers, control)
- ✅ Finite State Machines (FSMs)
- ✅ System integration and datapath design
- ✅ Instruction execution and computer architecture
- ✅ Simulation and waveform debugging
- ✅ Hardware verification techniques

**Perfect for FPGA/RTL/ASIC Engineer positions**

---

## 🔧 Installation

### What You Need
- Mac (M1/M2/Intel) or Linux
- Icarus Verilog (iverilog + vvp)
- Python 3 (comes with macOS)

### Install Icarus Verilog

**macOS:**
```bash
brew install icarus-verilog
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install iverilog
```

**Verify:**
```bash
iverilog -v
python3 --version
```

---

## 🚀 Running Your First Simulation

### Step 1: Navigate to Project
```bash
cd simple-cpu-project
```

### Step 2: Run Simulation
```bash
make simulate
```

You'll see:
- Compilation messages
- CPU executing instructions
- Register values changing
- Final results

### Step 3: View Waveforms
```bash
make web-wave    # Browser (recommended for Mac M2)
# OR
make wave        # Terminal
```

---

## 👀 Viewing Waveforms

### Option 1: Web Browser (Recommended for Mac M2) 🌟

```bash
make web-wave
```

**Features:**
- 📊 Visual waveforms
- 📋 Table view
- 💾 Export CSV
- 🎨 Dark theme
- ⚡ Perfect on Apple Silicon

**How:** Browser opens → Drag `cpu_sim.vcd` → See waveforms!

### Option 2: Terminal Viewer

```bash
make wave
```

**Features:**
- ASCII waveforms
- Value tables
- Register tracking
- Works anywhere

### Option 3: GTKWave (Optional)

```bash
make gtkwave
```

**Note:** Can be problematic on Mac M2. Use web viewer instead!

---

## 📊 Understanding the Output

### The Demo Program

```
Address | Binary       | Assembly      | Result
--------|--------------|---------------|------------------
   0    | 0000_0101    | LOAD R0, 5   | R0 = 5
   1    | 0000_0011    | LOAD R1, 3   | R1 = 3
   2    | 0010_0001    | ADD R0, R1   | R0 = 8 (5+3)
   3    | 0000_0010    | LOAD R2, 2   | R2 = 2
   4    | 0011_0010    | SUB R0, R2   | R0 = 6 (8-2)
   5    | 0100_0001    | AND R0, R1   | R0 = 2 (6&3)
   6    | 0101_0001    | OR R0, R1    | R0 = 3 (2|3)
   7    | 0111_0000    | HALT         | Stop
```

Watch R0 change: 0 → 5 → 8 → 6 → 2 → 3 ✨

---

## 🏗️ CPU Architecture

### Block Diagram

```
┌─────────────────────────────────────────┐
│              4-BIT CPU                   │
│                                          │
│  ┌──────────┐                            │
│  │ Program  │                            │
│  │ Counter  │────┐                       │
│  └──────────┘    │                       │
│       ↑          ↓                       │
│       │   ┌─────────────┐               │
│       │   │Instruction  │               │
│       │   │   Memory    │               │
│       │   └─────────────┘               │
│       │          │                       │
│       │          ↓                       │
│       │   ┌─────────────┐               │
│       └───│   Control   │               │
│           │    Unit     │               │
│           └─────────────┘               │
│              │        │                  │
│      ┌───────┘        └────────┐        │
│      ↓                         ↓        │
│  ┌─────────┐             ┌─────────┐   │
│  │Register │────────────→│   ALU   │   │
│  │  File   │             └─────────┘   │
│  └─────────┘                  │         │
│      ↑                        │         │
│      └────────────────────────┘         │
└─────────────────────────────────────────┘
```

### Components

1. **ALU** - Does math (ADD, SUB, AND, OR, XOR)
2. **Register File** - 4 registers storing data
3. **Program Counter** - Tracks current instruction
4. **Instruction Memory** - Stores program
5. **Control Unit** - Decodes & controls everything
6. **CPU** - Connects all modules

---

## 📖 Instruction Set

### Format

```
8-bit Instruction = [4-bit Opcode][4-bit Operand]
```

### Instructions

| Opcode | Name | Operation | Example |
|--------|------|-----------|---------|
| 0000 | LOAD | R0 ← immediate | `0000_0101` = LOAD 5 |
| 0010 | ADD | R0 ← R0 + R1 | `0010_0001` = ADD |
| 0011 | SUB | R0 ← R0 - R1 | `0011_0010` = SUB |
| 0100 | AND | R0 ← R0 & R1 | `0100_0001` = AND |
| 0101 | OR | R0 ← R0 \| R1 | `0101_0001` = OR |
| 0110 | JUMP | PC ← address | `0110_0011` = JUMP 3 |
| 0111 | HALT | Stop | `0111_0000` = HALT |

---

## ✏️ Modifying Programs

Open `rtl/instruction_memory.v` and edit the `initial begin` block:

```verilog
initial begin
    memory[0]  = 8'b0000_1010;  // LOAD R0, 10
    memory[1]  = 8'b0000_0101;  // LOAD R1, 5
    memory[2]  = 8'b0010_0001;  // ADD R0, R1     (10 + 5 = 15)
    memory[3]  = 8'b0111_0000;  // HALT
    // Fill rest with NOPs (0000_0000)
end
```

Then run:
```bash
make simulate
make web-wave
```

### Example Programs

**Count to 10:**
```verilog
memory[0]  = 8'b0000_0000;  // LOAD R0, 0
memory[1]  = 8'b0000_0001;  // LOAD R1, 1
memory[2]  = 8'b0010_0001;  // ADD R0, R1
memory[3]  = 8'b0110_0010;  // JUMP 2 (loop)
```

**Logic Operations:**
```verilog
memory[0]  = 8'b0000_1111;  // LOAD R0, 15
memory[1]  = 8'b0000_0101;  // LOAD R1, 5
memory[2]  = 8'b0100_0001;  // AND R0, R1
memory[3]  = 8'b0111_0000;  // HALT
```

---

## 🛠️ Makefile Commands

| Command | What It Does |
|---------|--------------|
| `make simulate` | Compile and run |
| `make wave` | Terminal viewer |
| `make web-wave` | Browser viewer ⭐ |
| `make clean` | Remove generated files |
| `make help` | Show commands |

### Manual Commands

```bash
# Compile
iverilog -g2012 -o cpu_sim.vvp rtl/*.v sim/cpu_tb.v

# Simulate
vvp cpu_sim.vvp

# View
python3 tools/vcd_viewer.py cpu_sim.vcd        # Terminal
open tools/waveform_viewer.html                # Browser
```

---

## 🐛 Troubleshooting

### Installation

**"iverilog not found"**
```bash
brew install icarus-verilog
```

**"python3 not found"**
```bash
brew install python3
```

### Simulation

**Doesn't halt**
- Add HALT instruction (0111_0000)
- Check PC in waveforms
- Press Ctrl+C to stop

**Wrong results**
- Check instruction binary
- View waveforms
- Verify program order

### Waveform Viewing

**Web viewer won't open**
```bash
open tools/waveform_viewer.html
```

**No waveforms**
- Check `cpu_sim.vcd` exists
- Re-run: `make simulate`

---

## 🎨 Customization Ideas

### Easy
1. Change demo program
2. Add more ALU operations (shift, NOT)
3. Try different instruction sequences

### Intermediate
4. Implement conditional jumps (JZ, JNZ)
5. Add data memory (separate from instruction)
6. Expand to 8-bit CPU

### Advanced
7. Add pipelining
8. Implement interrupts
9. Build a cache
10. Deploy to FPGA!

---

## 🚀 What's Next

### Document & Share
1. Add to GitHub
2. Write blog post
3. Create presentation

### Next Projects
1. **UART Communication** - Serial protocol
2. **FIFO Design** - Clock domain crossing
3. **RISC-V Core** - Real instruction set
4. **FPGA Deployment** - Real hardware!

### Career Path
**This project shows:**
- RTL design skills
- System integration
- Verification knowledge
- Debugging ability

**Resume line:**
"Designed 4-bit CPU in Verilog with ALU, register file, and FSM-based control. Verified through testbench simulation and waveform analysis."

**Companies:**
Intel, AMD, NVIDIA, Qualcomm, Broadcom, Apple, Tesla, SpaceX, and many startups!

---

## 📚 Resources

**Verilog:**
- HDLBits (hdlbits.01xz.net)
- Asic-World tutorials

**Digital Design:**
- "Digital Design and Computer Architecture" by Harris
- NandGame (nandgame.com)
- Ben Eater's videos

**Architecture:**
- "Computer Organization and Design" by Patterson
- Nand2Tetris course

---

## 📝 Quick Reference

### Binary to Decimal
| Binary | Dec | Binary | Dec |
|--------|-----|--------|-----|
| 0000 | 0 | 1000 | 8 |
| 0001 | 1 | 1001 | 9 |
| 0010 | 2 | 1010 | 10 |
| 0011 | 3 | 1011 | 11 |
| 0100 | 4 | 1100 | 12 |
| 0101 | 5 | 1101 | 13 |
| 0110 | 6 | 1110 | 14 |
| 0111 | 7 | 1111 | 15 |

### Key Signals
- `clk` - Clock (toggles)
- `rst` - Reset
- `pc` - Program counter
- `halt` - Stopped?
- `reg0_out` - `reg3_out` - Register values

---

## ✅ Success Checklist

After this project, you should be able to:

- [ ] Compile Verilog with iverilog
- [ ] Run simulations
- [ ] View and analyze waveforms
- [ ] Understand instruction execution
- [ ] Modify programs
- [ ] Debug using waveforms
- [ ] Explain CPU architecture
- [ ] Write Verilog modules
- [ ] Create testbenches

**All checked? You're ready for more! 🎉**

---

## 🎉 Congratulations!

You built a CPU! That's amazing! 🚀

**What you accomplished:**
- ✅ Modular Verilog design
- ✅ Complete digital system
- ✅ Simulation & verification
- ✅ Waveform debugging
- ✅ Hardware-level understanding

**You're now ready for:**
- FPGA/RTL engineering roles
- Complex hardware projects
- Contributing to open-source hardware
- Advanced digital design topics

Keep building! Welcome to hardware engineering! 💪

---

*Made with ❤️ for aspiring hardware engineers*

**Questions?** Re-read sections, check troubleshooting, view waveforms, and experiment!

Remember: Every expert started as a beginner. You've got this! 🌟