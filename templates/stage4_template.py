# -*- coding: utf-8 -*-
import os, sys, subprocess
from pathlib import Path

from config import VSPLIT_DIR, DEFAULT_TDATA_WIDTH
from llm_utils import call_llm, save_io, strict_code_guard_prefix, extract_code_blocks
from cpp_utils import parse_prototypes_from_header

# Filled by template engine
X = {{X}}

ROOT = Path("/nas").resolve()
AES_DIR = ROOT / f"aes{X}"
AESV_DIR = VSPLIT_DIR / f"aesv{X}"


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="ignore")


def write(p: Path, s: str):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding="utf-8")


def build_prompt() -> str:
    h = read(AES_DIR / f"aes{X}.h")
    cpp = read(AES_DIR / f"aes{X}.cpp")
    testcpp = read(AES_DIR / f"test{X}.cpp")
    spec = read(AESV_DIR / f"spec{X}.md")
    iface_spec = read(VSPLIT_DIR / "interface_spec.md")
    iface_sv = read(VSPLIT_DIR / "standard_stream_if.sv")
    funs = parse_prototypes_from_header(AES_DIR / f"aes{X}.h")

    return f"""
You are an expert hardware designer. Your task is to translate the given C/C++ submodule and test code into **synthesizable Verilog**, and to produce an accompanying testbench, while strictly following the design and formatting constraints below.

==================== AVAILABLE CONTEXT ====================
[Functional specification: spec{X}.md]
{spec}

[Interface specification: interface_spec.md]
{iface_spec}

[Standard interface implementation: standard_stream_if.sv]
{iface_sv}

These artifacts define the expected behavior and interface protocol of aes{X}. You must keep the generated HDL behaviorally equivalent to the C/C++ code and aligned with these specifications.

==================== OVERALL GOAL ====================
Generate the Verilog implementation and testbench for submodule aes{X}.

You MUST generate **exactly two Verilog files**:

1. /aesh4/vsplit/aesv{X}/aes{X}.sv
   - Synthesizable RTL implementation of the aes{X} submodule, functionally equivalent to aes{X}.cpp and aes{X}.h.
   - Must comply with the interface and protocol defined in interface_spec.md and standard_stream_if.sv.

2. /aesh4/vsplit/aesv{X}/test{X}.sv
   - Self-checking Verilog testbench.
   - Top-level testbench module name MUST be: top{X}.
   - It must drive the DUT using stimulus sequences consistent with test{X}.cpp and verify that the observed outputs match the C++ golden behavior.

==================== DESIGN CONSTRAINTS (HDL QUALITY) ====================
To guide the design toward high-quality, effective HDL, you MUST follow these rules:

1) **Separate control logic from datapath**
   - Clearly separate control and datapath in the RTL.
   - Use:
     - `always_ff` blocks for sequential state and pipeline registers.
     - `always_comb` blocks for combinational control / datapath logic.
   - Avoid mixing unrelated control and datapath logic in the same block whenever possible.

2) **Clocking and synchronous reset conventions**
   - Use the clock and reset signals as defined by the provided interface / standard_stream_if.sv.
   - Treat reset as **synchronous**:
     - All state updates must be guarded inside `always_ff @(posedge clk)` blocks.
     - Reset handling must be inside those `always_ff` blocks (no asynchronous reset sensitivity list).
   - When adding new registers (for example, for pipelining), always use the same clock and synchronous reset convention.

3) **Optimization strategies / pipelining**
   - You may insert pipeline stages or registers to improve timing as long as:
     - The externally observable behavior (including ordering of transactions and protocol timing) remains consistent with the C++ semantics and the spec.
   - Preserve functional equivalence: the testbench that mirrors test{X}.cpp must still PASS when run against the generated HDL.

==================== TESTBENCH & REPORT.TXT REQUIREMENTS ====================
The testbench file test{X}.sv must:

1) Instantiate the DUT corresponding to aes{X}.sv and drive it with **5 deterministic test cases** derived from test{X}.cpp (these correspond to LOCAL_CHECK1..5).

2) Top-level testbench module:
   - Name: **top{X}**

3) Result logging:
   - The testbench must create and write to a file named **report.txt** in the simulation working directory.
   - report.txt must contain **exactly 6 lines**:

     Line 1:
       GLOBAL_CHECK: PASS
     or
       GLOBAL_CHECK: FALSE
       (Write PASS only if ALL 5 local checks pass; otherwise write FALSE.)

     Line 2-6:
       LOCAL_CHECK1..LOCAL_CHECK5 in the following strict format:

       LOCAL_CHECKi: PASS|FAIL, Input: ..., Actual Output: ..., Golden Output: ...

   - The string formatting for each local line must follow this exact pattern:

     local_lines[t] = $sformatf(
         "LOCAL_CHECK%0d: %s, Input: %s, Actual Output: %s, Golden Output: %s",
         t+1,
         (pass ? "PASS" : "FAIL"),
         sin,
         sact,
         sgold
     );

   - **Important**: In the format string, `LOCAL_CHECK%0d` MUST use `%0d`, NOT `%d`.

4) The testbench must be fully self-checking:
   - Compute the actual output from the DUT.
   - Compute or embed the corresponding golden output consistent with test{X}.cpp.
   - Decide PASS/FAIL for each of the 5 test cases.
   - Derive GLOBAL_CHECK from the conjunction of all local results.

==================== FORMATTING CONSTRAINTS (LLM OUTPUT) ====================
To make it easy to extract HDL from your output via script, you MUST:

1) Output **only Verilog code**, no explanations, no comments and no prose outside of code fences.

2) Produce **exactly two Markdown code blocks**, in this order:

   (A) First code block: contents of aes{X}.sv  
       - Begin with: ```verilog  
       - End with: ```  

   (B) Second code block: contents of test{X}.sv  
       - Begin with: ```verilog  
       - End with: ```  

3) Do NOT include filenames, banners, or textual labels outside the code fences.
   - The caller will map the **first** code block to aes{X}.sv and the **second** code block to test{X}.sv.

==================== SOURCE C/C++ TO BE TRANSLATED ====================
The Verilog design and testbench must be functionally equivalent to the following C/C++ code:

[aes{X}.h]
{h}

[aes{X}.cpp]
{cpp}

[test{X}.cpp]
{testcpp}

[Parsed function prototypes]
{funs}

Respect the function interfaces and the behavior implied by these sources, the specification, and the interface definition. When Verilog syntax rules conflict with C++ structure, you MUST obey Verilog rules (e.g., declarations must appear at the beginning of a block).
""".strip()


def run_sim():
    r = subprocess.run([sys.executable, "sim.py"], cwd=AESV_DIR)
    return r.returncode


def main():
    # strict_code_guard_prefix() is assumed to enforce "pure code" output,
    # typically in Markdown code fences, which matches our formatting constraints.
    prompt = strict_code_guard_prefix() + build_prompt()
    out = call_llm([{"role": "user", "content": prompt}], max_tokens=32768)
    save_io(f"stage4_aes{X}", prompt, out)

    blocks = extract_code_blocks(out)

    # We expect exactly two code blocks: [0] = aes{X}.sv, [1] = test{X}.sv
    if len(blocks) == 2:
        aes_v, tb_v = blocks
    else:
        # Fallback: split at "module top{X}" if code block extraction fails.
        all_code = out
        idx = all_code.lower().find(f"module top{X}".lower())
        if idx <= 0:
            aes_v, tb_v = (all_code, "")
        else:
            aes_v, tb_v = all_code[:idx], all_code[idx:]

    write(AESV_DIR / f"aes{X}.sv", aes_v.strip() + "\n")
    write(AESV_DIR / f"test{X}.sv", tb_v.strip() + "\n")

    rc = run_sim()
    if rc != 0:
        sys.exit(rc)


if __name__ == "__main__":
    main()
