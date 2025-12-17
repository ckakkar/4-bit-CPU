#!/usr/bin/env python3
"""Small VCD-to-text helper.

Reads a VCD file (e.g. cpu_sim.vcd) and prints a compact table plus a few
ASCII-style waveforms so you can sanity-check a run from the terminal.
"""

import sys
import re
from collections import defaultdict

def parse_vcd(vcd_file):
    """Parse VCD file and extract signal data"""
    
    signals = {}  # Maps identifier to signal name
    values = defaultdict(list)  # Maps signal name to [(time, value)]
    current_time = 0
    
    with open(vcd_file, 'r') as f:
        in_header = True
        
        for line in f:
            line = line.strip()
            
            # Parse variable definitions
            if line.startswith('$var'):
                parts = line.split()
                if len(parts) >= 5:
                    identifier = parts[3]
                    signal_name = parts[4]
                    signals[identifier] = signal_name
            
            # End of header
            elif line.startswith('$enddefinitions'):
                in_header = False
            
            # Parse time changes
            elif line.startswith('#') and not in_header:
                current_time = int(line[1:])
            
            # Parse value changes
            elif not in_header and line:
                if line[0] in '01xz':
                    # Single bit value
                    value = line[0]
                    identifier = line[1:]
                    if identifier in signals:
                        signal_name = signals[identifier]
                        values[signal_name].append((current_time, value))
                
                elif line[0] == 'b':
                    # Multi-bit value
                    parts = line.split()
                    if len(parts) >= 2:
                        value = parts[0][1:]  # Remove 'b' prefix
                        identifier = parts[1]
                        if identifier in signals:
                            signal_name = signals[identifier]
                            values[signal_name].append((current_time, value))
    
    return values

def format_binary_value(value, width=8):
    """Format binary value for display"""
    if value in ['x', 'z']:
        return value * width
    # Pad with zeros or truncate
    return value.rjust(width, '0')[-width:]

def print_ascii_waveform(values, signal_name, max_time):
    """Print ASCII waveform for a signal"""
    
    if not values:
        return
    
    # Create timeline
    time_points = sorted(set(t for t, _ in values))
    if not time_points:
        return
    
    # For single-bit signals, create ASCII waveform
    if all(v in '01xz' for _, v in values):
        print(f"\n{signal_name}:")
        
        # Create waveform string
        waveform = []
        current_val = '0'
        value_dict = dict(values)
        
        for t in range(0, max_time + 1, 5):  # Sample every 5ns
            if t in value_dict:
                current_val = value_dict[t]
            
            if current_val == '1':
                waveform.append('▄')
            elif current_val == '0':
                waveform.append('_')
            else:
                waveform.append('?')
        
        print('  ' + ''.join(waveform))
        
        # Print time markers
        markers = []
        for t in range(0, max_time + 1, 25):
            markers.append(str(t).ljust(5))
        print('  ' + ''.join(markers))
    
    else:
        # Multi-bit signal - print value changes
        print(f"\n{signal_name} (multi-bit):")
        for time, value in values[:20]:  # Limit to first 20 changes
            try:
                decimal = int(value, 2) if value.replace('x', '').replace('z', '') else None
                if decimal is not None:
                    print(f"  {time:6d}ns: {value:>8s} (decimal: {decimal})")
                else:
                    print(f"  {time:6d}ns: {value:>8s}")
            except:
                print(f"  {time:6d}ns: {value:>8s}")

def print_table(values, signals_to_show, start_time=0, end_time=None):
    """Print values in a table format"""
    
    # Get all unique time points
    all_times = set()
    for signal in signals_to_show:
        if signal in values:
            all_times.update(t for t, _ in values[signal])
    
    time_points = sorted(all_times)
    
    if end_time:
        time_points = [t for t in time_points if start_time <= t <= end_time]
    else:
        time_points = [t for t in time_points if t >= start_time]
    
    if not time_points:
        print("No data in specified time range")
        return
    
    # Print header
    print("\n" + "="*80)
    print("SIGNAL VALUES TABLE")
    print("="*80)
    header = f"{'Time(ns)':>10} | " + " | ".join(f"{sig:>10}" for sig in signals_to_show)
    print(header)
    print("-"*80)
    
    # Get current value for each signal at each time
    signal_values = {sig: dict(values[sig]) if sig in values else {} for sig in signals_to_show}
    current_values = {sig: '0' for sig in signals_to_show}
    
    for time in time_points[:50]:  # Limit to first 50 time points
        row = f"{time:>10} | "
        
        for signal in signals_to_show:
            if time in signal_values[signal]:
                current_values[signal] = signal_values[signal][time]
            
            val = current_values[signal]
            
            # Try to convert to decimal for display
            try:
                if val in '01':
                    display_val = val
                else:
                    decimal = int(val, 2) if val.replace('x', '').replace('z', '') else None
                    if decimal is not None:
                        display_val = str(decimal)
                    else:
                        display_val = val[:6]
            except:
                display_val = val[:6]
            
            row += f"{display_val:>10} | "
        
        print(row.rstrip(' |'))
    
    if len(time_points) > 50:
        print(f"\n... ({len(time_points) - 50} more time points) ...")

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 vcd_viewer.py <vcd_file>")
        print("\nExample: python3 vcd_viewer.py cpu_sim.vcd")
        sys.exit(1)
    
    vcd_file = sys.argv[1]
    
    print("="*80)
    print("VCD WAVEFORM VIEWER")
    print("="*80)
    print(f"Reading: {vcd_file}\n")
    
    try:
        values = parse_vcd(vcd_file)
    except FileNotFoundError:
        print(f"ERROR: File '{vcd_file}' not found!")
        sys.exit(1)
    except Exception as e:
        print(f"ERROR: Failed to parse VCD file: {e}")
        sys.exit(1)
    
    if not values:
        print("No signals found in VCD file!")
        sys.exit(1)
    
    # Determine max time
    max_time = 0
    for signal_values in values.values():
        if signal_values:
            max_time = max(max_time, max(t for t, _ in signal_values))
    
    print(f"Simulation time: 0 to {max_time} ns")
    print(f"Signals found: {len(values)}\n")
    
    # Key signals to display
    important_signals = [
        'clk',
        'rst', 
        'pc',
        'halt',
        'reg0_out',
        'reg1_out',
        'reg2_out',
        'reg3_out',
        'instruction'
    ]
    
    # Filter to signals that exist
    signals_to_show = [sig for sig in important_signals if any(sig in name for name in values.keys())]
    
    # Find actual signal names (they might have hierarchy prefix)
    actual_signals = []
    for desired_sig in important_signals:
        for actual_sig in values.keys():
            if actual_sig.endswith(desired_sig):
                actual_signals.append(actual_sig)
                break
    
    if actual_signals:
        print_table(values, actual_signals)
    
    # Print ASCII waveforms for single-bit signals
    print("\n" + "="*80)
    print("ASCII WAVEFORMS (Single-bit signals)")
    print("="*80)
    
    single_bit_signals = ['clk', 'rst', 'halt']
    for desired_sig in single_bit_signals:
        for actual_sig in values.keys():
            if actual_sig.endswith(desired_sig):
                print_ascii_waveform(values[actual_sig], actual_sig, min(max_time, 200))
                break
    
    # Print detailed register changes
    print("\n" + "="*80)
    print("REGISTER VALUE CHANGES")
    print("="*80)
    
    reg_signals = ['reg0_out', 'reg1_out', 'reg2_out', 'reg3_out']
    for desired_reg in reg_signals:
        for actual_sig in values.keys():
            if actual_sig.endswith(desired_reg):
                print(f"\n{actual_sig}:")
                reg_values = values[actual_sig]
                for time, value in reg_values[:15]:  # Show first 15 changes
                    try:
                        decimal = int(value, 2)
                        print(f"  {time:6d}ns: {value:>4s} (decimal: {decimal:2d})")
                    except:
                        print(f"  {time:6d}ns: {value:>4s}")
                
                if len(reg_values) > 15:
                    print(f"  ... ({len(reg_values) - 15} more changes)")
                break
    
    print("\n" + "="*80)
    print("TIP: For better visualization, try the web viewer:")
    print("     make web-wave")
    print("="*80)

if __name__ == "__main__":
    main()