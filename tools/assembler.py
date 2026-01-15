#!/usr/bin/env python3
"""
Assembler for Enhanced 8-Bit CPU
Converts assembly mnemonics to binary instruction format
"""

import sys
import re
from typing import Dict, List, Tuple, Optional

# Instruction opcodes
OPCODES = {
    'LOADI': 0x0,
    'ADD': 0x1,
    'SUB': 0x2,
    'AND': 0x3,
    'OR': 0x4,
    'XOR': 0x5,
    'STORE': 0x6,
    'LOAD': 0x7,
    'SHL': 0x8,
    'SHR': 0x9,
    'MOV': 0xA,
    'CMP': 0xB,
    'JUMP': 0xC,
    'JZ': 0xD,
    'JNZ': 0xE,
    'NOT': 0xF,
    'HALT': 0xF,
    'PUSH': 0xE,
    'POP': 0xE,
    'MUL': 0xD,
    'DIV': 0xD,
    'IN': 0xE,
    'OUT': 0xE,
    'RETI': 0xF,
}

# Register names
REGISTERS = {
    'R0': 0, 'R1': 1, 'R2': 2, 'R3': 3,
    'R4': 4, 'R5': 5, 'R6': 6, 'R7': 7,
}

class Assembler:
    def __init__(self):
        self.labels: Dict[str, int] = {}
        self.instructions: List[Tuple[str, List[str]]] = []
        self.address = 0
        
    def parse_register(self, reg_str: str) -> int:
        """Parse register name to number"""
        reg_str = reg_str.strip().upper()
        if reg_str in REGISTERS:
            return REGISTERS[reg_str]
        raise ValueError(f"Invalid register: {reg_str}")
    
    def parse_immediate(self, imm_str: str) -> int:
        """Parse immediate value (hex, decimal, or binary)"""
        imm_str = imm_str.strip()
        
        # Remove brackets if present (for memory addresses)
        if imm_str.startswith('[') and imm_str.endswith(']'):
            imm_str = imm_str[1:-1]
        
        # Hex
        if imm_str.startswith('0x') or imm_str.startswith('0X'):
            return int(imm_str, 16)
        # Binary
        elif imm_str.startswith('0b') or imm_str.startswith('0B'):
            return int(imm_str, 2)
        # Decimal
        else:
            return int(imm_str)
    
    def encode_instruction(self, mnemonic: str, operands: List[str]) -> int:
        """Encode instruction to 16-bit binary format"""
        mnemonic = mnemonic.upper()
        opcode = OPCODES.get(mnemonic)
        
        if opcode is None:
            raise ValueError(f"Unknown instruction: {mnemonic}")
        
        # Instruction format: {opcode[3:0], reg1[2:0], reg2[2:0], immediate[5:0]}
        
        if mnemonic == 'LOADI':
            # LOADI Rd, imm
            rd = self.parse_register(operands[0])
            imm = self.parse_immediate(operands[1])
            if imm > 63:
                raise ValueError(f"Immediate value {imm} exceeds 6-bit range (0-63)")
            return (opcode << 12) | (rd << 9) | (0 << 6) | imm
        
        elif mnemonic == 'ADD':
            # ADD Rd, Rs1, Rs2
            rd = self.parse_register(operands[0])
            rs1 = self.parse_register(operands[1])
            rs2 = self.parse_register(operands[2])
            return (opcode << 12) | (rs1 << 9) | (rd << 6) | 0
        
        elif mnemonic == 'SUB':
            # SUB Rd, Rs1, Rs2
            rd = self.parse_register(operands[0])
            rs1 = self.parse_register(operands[1])
            rs2 = self.parse_register(operands[2])
            return (opcode << 12) | (rs1 << 9) | (rd << 6) | 0
        
        elif mnemonic == 'STORE':
            # STORE Rs, [addr]
            rs = self.parse_register(operands[0])
            addr = self.parse_immediate(operands[1])
            if addr > 63:
                raise ValueError(f"Address {addr} exceeds 6-bit range (0-63)")
            return (opcode << 12) | (rs << 9) | (0 << 6) | addr
        
        elif mnemonic == 'LOAD':
            # LOAD Rd, [addr]
            rd = self.parse_register(operands[0])
            addr = self.parse_immediate(operands[1])
            if addr > 63:
                raise ValueError(f"Address {addr} exceeds 6-bit range (0-63)")
            return (opcode << 12) | (rd << 9) | (0 << 6) | addr
        
        elif mnemonic == 'JUMP':
            # JUMP addr
            addr = self.parse_immediate(operands[0])
            if addr > 63:
                raise ValueError(f"Jump address {addr} exceeds 6-bit range (0-63)")
            return (opcode << 12) | (0 << 9) | (0 << 6) | addr
        
        elif mnemonic == 'JZ':
            # JZ Rs, addr
            rs = self.parse_register(operands[0])
            addr = self.parse_immediate(operands[1])
            if addr > 63:
                raise ValueError(f"Jump address {addr} exceeds 6-bit range (0-63)")
            return (opcode << 12) | (rs << 9) | (0 << 6) | addr
        
        elif mnemonic == 'JNZ':
            # JNZ Rs, addr
            rs = self.parse_register(operands[0])
            addr = self.parse_immediate(operands[1])
            if addr > 63:
                raise ValueError(f"Jump address {addr} exceeds 6-bit range (0-63)")
            return (opcode << 12) | (rs << 9) | (0 << 6) | addr
        
        elif mnemonic == 'PUSH':
            # PUSH Rs (opcode=1110, reg2=000)
            rs = self.parse_register(operands[0])
            return (0xE << 12) | (rs << 9) | (0 << 6) | 0
        
        elif mnemonic == 'POP':
            # POP Rd (opcode=1110, reg2=001)
            rd = self.parse_register(operands[0])
            return (0xE << 12) | (rd << 9) | (1 << 6) | 0
        
        elif mnemonic == 'MUL':
            # MUL Rd, Rs1, Rs2 (opcode=1101, reg2=000)
            rd = self.parse_register(operands[0])
            rs1 = self.parse_register(operands[1])
            rs2 = self.parse_register(operands[2])
            return (0xD << 12) | (rs1 << 9) | (rd << 6) | 0
        
        elif mnemonic == 'HALT':
            # HALT (opcode=1111, all zeros)
            return 0xF000
        
        elif mnemonic == 'RETI':
            # RETI (opcode=1111, imm=1)
            return 0xF001
        
        else:
            raise ValueError(f"Instruction encoding not implemented: {mnemonic}")
    
    def assemble_line(self, line: str) -> Optional[Tuple[str, List[str], Optional[int]]]:
        """Parse a single line of assembly"""
        # Remove comments
        line = line.split(';')[0].strip()
        if not line:
            return None
        
        # Check for label
        label = None
        if ':' in line:
            parts = line.split(':', 1)
            label = parts[0].strip()
            line = parts[1].strip()
            if not line:
                return ('LABEL', [label], None)
        
        # Parse instruction
        parts = re.split(r'[,\s]+', line)
        mnemonic = parts[0].upper()
        operands = [p.strip() for p in parts[1:] if p.strip()]
        
        return (mnemonic, operands, label)
    
    def assemble(self, source: str) -> List[Tuple[int, int]]:
        """Assemble source code to binary instructions"""
        lines = source.split('\n')
        
        # First pass: collect labels
        address = 0
        for line in lines:
            parsed = self.assemble_line(line)
            if parsed is None:
                continue
            mnemonic, operands, label = parsed
            
            if label:
                self.labels[label] = address
            
            if mnemonic != 'LABEL':
                address += 1
        
        # Second pass: encode instructions
        address = 0
        instructions = []
        for line in lines:
            parsed = self.assemble_line(line)
            if parsed is None:
                continue
            mnemonic, operands, label = parsed
            
            if mnemonic == 'LABEL':
                continue
            
            # Replace labels with addresses
            for i, op in enumerate(operands):
                if op in self.labels:
                    operands[i] = str(self.labels[op])
            
            try:
                instruction = self.encode_instruction(mnemonic, operands)
                instructions.append((address, instruction))
                address += 1
            except Exception as e:
                raise ValueError(f"Error at address {address}: {e}")
        
        return instructions
    
    def format_verilog(self, instructions: List[Tuple[int, int]]) -> str:
        """Format instructions as Verilog initial block"""
        lines = ["    // Initialize all memory to 0"]
        lines.append("    for (i = 0; i < 256; i = i + 1) begin")
        lines.append("        memory[i] = 16'b0000000000000000;")
        lines.append("    end")
        lines.append("")
        lines.append("    // Program instructions")
        
        for addr, inst in instructions:
            lines.append(f"    memory[{addr}] = 16'h{inst:04X};")
        
        return '\n'.join(lines)

def main():
    if len(sys.argv) < 2:
        print("Usage: assembler.py <input.asm> [output.v]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    try:
        with open(input_file, 'r') as f:
            source = f.read()
        
        assembler = Assembler()
        instructions = assembler.assemble(source)
        
        # Output
        if output_file:
            verilog_code = assembler.format_verilog(instructions)
            with open(output_file, 'w') as f:
                f.write(verilog_code)
            print(f"Assembled {len(instructions)} instructions to {output_file}")
        else:
            print("Assembled instructions:")
            for addr, inst in instructions:
                print(f"  {addr:3d}: 0x{inst:04X} ({inst:016b})")
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
