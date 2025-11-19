import os
import re
import subprocess
import sys
import argparse 

def generate_dc_tcl_script(rtl_file, top_module_name):
    """
    Generates a Design Compiler TCL script to synthesize a specific module.
    The script is saved as "design_compiler.tcl" in the current working directory.

    Args:
        rtl_file (str): The name of the Verilog RTL file.
        top_module_name (str): The name of the top-level module to synthesize.
    """
    tcl_path = os.path.join(os.getcwd(), "design_compiler.tcl")
    with open(tcl_path, "w") as f:
        f.write("# === Synthesis Script for Design Compiler ===\n\n")
        f.write("set target_library /nas/.../NangateOpenCellLibrary_typical.db\n")
        f.write("set link_library /nas/.../NangateOpenCellLibrary_typical.db\n\n")
        f.write(f"read_sverilog {rtl_file}\n") 
        f.write(f"current_design {top_module_name}\n") 
        f.write("suppress_message UID-401\n")
        f.write("check_design\n")
        f.write("link\n\n")
        f.write("set timing_enable_through_paths true\n")
        f.write("set timing_through_path_max_segments 10\n")
        f.write("create_clock clk -period n\n\n")
        f.write("compile_ultra\n")
        f.write("write -f verilog -hierarchy -output netlist.v\n\n")
        f.write("report_area -hier -nosplit\n")
        f.write("report_timing -max_paths 10\n")
        f.write("report_area\n")
        f.write("report_timing -delay max\n")
        f.write("report_power\n\n")
        
        f.write("quit\n")
        
    print(f"TCL script generated at: {tcl_path}")
    return tcl_path

def parse_design_compiler_report(report_file):
    try:
        with open(report_file, 'r') as f:
            report = f.read()
    except Exception as e:
        print(f"Error reading Design Compiler report: {e}")
        return

    def match_text(start_str, end_str, text):
        pattern = re.compile(re.escape(start_str) + r'(.*?)' + re.escape(end_str), re.DOTALL)
        all_matches = pattern.findall(text)
        return all_matches[-1].strip() if all_matches else "N/A"

    total_cell_area = match_text("Total cell area:", "\n", report)
    data_arrival_time = match_text("data arrival time", "\n", report)
    total_dynamic_power = match_text("Total Dynamic Power", "\n", report)
    
    print("\n=== Design Compiler Report Summary ===")
    print(f"Total Cell Area:      {total_cell_area}")
    print(f"Data Arrival Time:    {data_arrival_time}")
    print(f"Total Dynamic Power:  {total_dynamic_power}")
    print("========================================\n")

def run_synthesis(circuit_dir, rtl_filename, top_module_name):
    # --- Step 1: Navigate to the circuit's directory ---
    print(f"Changing working directory to: {circuit_dir}")
    try:
        os.chdir(circuit_dir)
    except FileNotFoundError:
        print(f"Error: Directory not found at {circuit_dir}")
        sys.exit(1)
        
    # --- Step 2: Generate the TCL script ---
    tcl_script = generate_dc_tcl_script(rtl_filename, top_module_name)
    
    # --- Step 3: Run Design Compiler ---
    report_file = "dc_report.txt"
    
    dc_shell_path = '/usr/local/tools/synopsys/syn/.../dc_shell'
    dc_cmd = f'{dc_shell_path} -f {tcl_script} | tee {report_file}'
    
    print("\nRunning Design Compiler synthesis with command:")
    print(f"  {dc_cmd}\n")
    
    os.system(dc_cmd)
    
    # --- Step 4: Parse the report ---
    print("Synthesis finished. Parsing report...")
    parse_design_compiler_report(report_file)

def main():
    """
    Parses command-line arguments and initiates the synthesis process.
    """
    parser = argparse.ArgumentParser(
        description="Run Synopsys Design Compiler synthesis for a specific Verilog module."
    )
    parser.add_argument(
        "circuit_dir", 
        help="The path to the directory containing the circuit's RTL file."
    )
    parser.add_argument(
        "rtl_filename", 
        help="The name of the RTL Verilog file (e.g., 'rtl.sv')."
    )
    parser.add_argument(
        "top_module_name", 
        help="The name of the top-level module to be synthesized."
    )
    args = parser.parse_args()

    full_rtl_path = os.path.join(args.circuit_dir, args.rtl_filename)
    if not os.path.exists(full_rtl_path):
        print(f"Error: V file not found at: {full_rtl_path}")
        sys.exit(1)
        
    run_synthesis(args.circuit_dir, args.rtl_filename, args.top_module_name)

if __name__ == "__main__":
    main()