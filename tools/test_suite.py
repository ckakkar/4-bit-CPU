#!/usr/bin/env python3
"""
CPU RTL Test Suite
Compiles and runs all Verilog testbenches, parses [PASS]/[FAIL] markers,
and prints a coverage/summary report.

Usage:
    python3 tools/test_suite.py          # run all testbenches
    python3 tools/test_suite.py --unit   # unit tests only
"""

import subprocess
import sys
import os
import re
import json
import argparse
from typing import List, Dict, Tuple

# ---------------------------------------------------------------------------
# Testbench registry
# ---------------------------------------------------------------------------

RTL = "rtl"
SIM = "sim"

UNIT_TESTS = [
    {
        "name": "ALU Unit Tests",
        "id": "alu",
        "tb": f"{SIM}/alu_tb.v",
        "rtl": [f"{RTL}/alu.v"],
        "instructions_covered": [
            "ADD", "SUB", "AND", "OR", "XOR", "NOT",
            "SHL", "SHR", "SAR", "LT", "LTU", "EQ", "MOV(PASS)", "LOADI(PASS_B)",
        ],
    },
    {
        "name": "Register File Unit Tests",
        "id": "register_file",
        "tb": f"{SIM}/register_file_tb.v",
        "rtl": [f"{RTL}/register_file.v"],
        "instructions_covered": [],
    },
    {
        "name": "Program Counter Unit Tests",
        "id": "program_counter",
        "tb": f"{SIM}/program_counter_tb.v",
        "rtl": [f"{RTL}/program_counter.v"],
        "instructions_covered": ["JUMP", "JZ", "JNZ"],
    },
]

INTEGRATION_TESTS = [
    {
        "name": "CPU Instruction Integration Tests",
        "id": "cpu_instr",
        "tb": f"{SIM}/cpu_instr_tb.v",
        "rtl": [
            f"{RTL}/alu.v",
            f"{RTL}/register_file.v",
            f"{RTL}/program_counter.v",
            f"{RTL}/instruction_memory.v",
            f"{RTL}/data_memory.v",
            f"{RTL}/control_unit.v",
            f"{RTL}/cpu.v",
        ],
        "instructions_covered": [
            "LOADI", "ADD", "SUB", "AND", "OR", "XOR",
            "NOT", "MOV", "SHL", "SHR", "STORE", "LOAD",
            "JUMP", "JZ", "JNZ", "HALT",
        ],
    },
]


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

def run_testbench(tb_info: Dict) -> Tuple[int, int, List[str], str]:
    """Compile and run one testbench. Returns (pass, fail, detail_lines, error)."""
    vvp = f"/tmp/_tb_{tb_info['id']}.vvp"
    cmd = ["iverilog", "-g2012", "-o", vvp] + tb_info["rtl"] + [tb_info["tb"]]

    comp = subprocess.run(cmd, capture_output=True, text=True)
    if comp.returncode != 0:
        return 0, 1, [], f"Compilation error:\n{comp.stderr.strip()}"

    try:
        run = subprocess.run(["vvp", vvp], capture_output=True, text=True, timeout=60)
    except subprocess.TimeoutExpired:
        return 0, 1, [], "Simulation timed out (>60 s)"

    stdout = run.stdout
    passed = len(re.findall(r"^\[PASS\]", stdout, re.MULTILINE))
    failed = len(re.findall(r"^\[FAIL\]", stdout, re.MULTILINE))
    details = re.findall(r"^\[(?:PASS|FAIL)\].*$", stdout, re.MULTILINE)
    return passed, failed, details, ""


def run_suite(testbenches: List[Dict]) -> Tuple[int, int, Dict]:
    total_pass = total_fail = 0
    results: Dict[str, Dict] = {}

    for tb in testbenches:
        print(f"\n{'─'*60}")
        print(f"  {tb['name']}")
        print(f"{'─'*60}")
        passed, failed, details, error = run_testbench(tb)

        if error:
            print(f"  ERROR: {error}")
        else:
            for line in details:
                marker = "✓" if line.startswith("[PASS]") else "✗"
                print(f"  {marker} {line[7:]}")

        print(f"\n  Result: {passed} passed, {failed} failed")
        total_pass += passed
        total_fail += failed
        results[tb["id"]] = {
            "name": tb["name"],
            "pass": passed,
            "fail": failed,
            "instructions": tb.get("instructions_covered", []),
        }

    return total_pass, total_fail, results


# ---------------------------------------------------------------------------
# Coverage report
# ---------------------------------------------------------------------------

ISA_INSTRUCTIONS = [
    "LOADI", "ADD", "SUB", "AND", "OR", "XOR",
    "STORE", "LOAD", "SHL", "SHR", "MOV",
    "NOT", "JUMP", "JZ", "JNZ", "HALT",
]


def coverage_report(results: Dict) -> None:
    covered: set = set()
    for r in results.values():
        covered.update(r["instructions"])

    covered_isa = set(ISA_INSTRUCTIONS) & covered
    pct = len(covered_isa) / len(ISA_INSTRUCTIONS) * 100

    print("\n" + "═" * 60)
    print("  INSTRUCTION COVERAGE REPORT")
    print("═" * 60)
    print(f"  ISA instructions tested: {len(covered_isa)}/{len(ISA_INSTRUCTIONS)} ({pct:.0f}%)")

    for instr in ISA_INSTRUCTIONS:
        mark = "✓" if instr in covered_isa else "✗"
        print(f"    {mark}  {instr}")

    passing_modules = sum(1 for r in results.values() if r["fail"] == 0 and r["pass"] > 0)
    print(f"\n  Modules fully passing: {passing_modules}/{len(results)}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="CPU RTL Test Suite")
    parser.add_argument("--unit", action="store_true", help="Run unit tests only")
    args = parser.parse_args()

    # Change to repo root (one level up from tools/)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(os.path.join(script_dir, ".."))

    testbenches = UNIT_TESTS + ([] if args.unit else INTEGRATION_TESTS)

    print("═" * 60)
    print("  CPU RTL Test Suite")
    print("═" * 60)

    total_pass, total_fail, results = run_suite(testbenches)

    total = total_pass + total_fail
    rate = f"{total_pass/total*100:.1f}%" if total else "n/a"

    print("\n" + "═" * 60)
    print(f"  TOTAL  {total_pass} passed / {total_fail} failed  ({rate} pass rate)")
    print("═" * 60)

    coverage_report(results)

    # Save JSON report
    report = {
        "total_pass": total_pass,
        "total_fail": total_fail,
        "pass_rate": rate,
        "suites": results,
    }
    with open("test_report.json", "w") as f:
        json.dump(report, f, indent=2)
    print("\n  Report saved → test_report.json")

    sys.exit(0 if total_fail == 0 else 1)


if __name__ == "__main__":
    main()
