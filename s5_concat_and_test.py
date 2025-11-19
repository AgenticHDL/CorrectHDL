import os
import sys
import subprocess
import shutil
from pathlib import Path
from typing import List

from config import ROOT, VSPLIT_DIR, DEFAULT_TDATA_WIDTH
from llm_utils import call_llm, save_io, extract_code_blocks

AES_CONCAT_DIR = VSPLIT_DIR / "aes_concat"


def discover_submodules() -> List[int]:
    """Discover all submodule directories named aesvX under VSPLIT_DIR."""
    xs: List[int] = []
    for p in VSPLIT_DIR.iterdir():
        if p.is_dir() and p.name.startswith("aesv"):
            try:
                xs.append(int(p.name[4:]))
            except ValueError:
                pass
    xs.sort()
    return xs

def read(p: Path) -> str:
    """Read file content if the file exists, otherwise return an empty string."""
    return p.read_text(encoding="utf-8", errors="ignore") if p.exists() else ""


def build_prompt(xs: List[int]) -> str:
    """Build the LLM prompt for generating the concatenated Verilog design and testbench."""
    iface_md = read(VSPLIT_DIR / "interface_spec.md")
    std_if_sv = read(VSPLIT_DIR / "standard_stream_if.sv")

    verilog_blobs = []
    for x in xs:
        vpath = VSPLIT_DIR / f"aesv{x}" / f"aes{x}.sv"
        verilog_blobs.append(f"[/aes/vsplit/aesv{x}/aes{x}.sv]\n{read(vpath)}")

    cc = read(ROOT / "aes_concat" / "aes_concat.cpp")
    tc = read(ROOT / "aes_concat" / "test_concat.cpp")

    return f"""
You are a senior hardware architecture and verification expert. Based on the provided artifacts, you will generate high-quality, synthesizable Verilog for a concatenated AES design and its corresponding testbench.

==================== Context: Interface and Functional Specifications ====================
[Interface specification (interface_spec.md)]
{iface_md}

[Standard streaming interface (standard_stream_if.sv)]
{std_if_sv}

==================== Context: Pre-verified Submodules ====================
The following Verilog submodules (from /aesh/vsplit) are assumed to be functionally correct and represent individual AES sub-stages:

{chr(10).join(verilog_blobs)}

==================== Context: C/C++ Top-level Behavior ====================
The concatenated C++ top-level implementation and its C++ testbench are:

[/aes/aes_concat/aes_concat.cpp]
{cc}

[/aes/aes_concat/test_concat.cpp]
{tc}

The C/C++ top-level code, functional specification, interface definition, and the design/formatting constraints below are jointly provided to guide you in generating the HDL design.

==================== Task ====================
You must produce the following two Verilog files:

1) /aes/aes_concat/aes_concat.sv
   - Top module name: aes_concat
   - This module must:
     - Instantiate all submodules (aes1, aes2, ...) and connect them in a streaming pipeline so that the end-to-end behavior matches aes_concat.cpp.
     - Use the streaming interface defined in standard_stream_if.sv, with parameter int WIDTH = {DEFAULT_TDATA_WIDTH} where appropriate.
     - Expose one input stream and one output stream using this interface and obey the valid/ready handshake protocol.

2) /aes/aes_concat/test_concat.sv
   - Testbench top module name: top
   - This testbench must:
     - Instantiate aes_concat as the DUT.
     - Apply stimulus logically equivalent to test_concat.cpp.
     - Check the DUT outputs against the expected (golden) behavior derived from test_concat.cpp.
     - Finish the simulation without deadlock when run in a standard simulator.

==================== Design Constraints (HDL Quality) ====================
To guide you toward effective HDL designs, follow these design constraints:

1) Separate control logic from datapath, and use synchronous reset conventions.
   - Use always_ff for sequential logic (registers, FSM state).
   - Use always_comb for purely combinational logic.
   - Keep control logic (e.g., handshake, FSMs) reasonably separated from datapath (e.g., arithmetic operations).
   - Use a single clock (e.g., clk) and an active-low synchronous reset (rst_n).
   - All registers must be reset to known values when rst_n is asserted.

2) Optimization strategies (e.g., pipelining).
   - You may insert pipeline stages or registers to improve timing, as long as:
     - The valid/ready streaming protocol is preserved.
     - The ordering of transactions and the overall functional behavior remain equivalent to aes_concat.cpp.

3) Streaming interface and handshake conventions.
   - Use the standard_stream_if interface for dataflow between submodules and at the top level.
   - A transfer occurs on a clock cycle when tvalid && tready are both high on the rising edge of clk.
   - Avoid combinational loops between tvalid and tready (use registered backpressure if needed).

==================== Formatting Constraints (LLM Output) ====================
To facilitate automatic HDL extraction by a script, you must follow these formatting constraints:

- Output **exactly two Markdown code blocks**, in this order:

  (A) First code block: full contents of aes_concat.sv
      - Begin with: ```verilog
      - End with: ```

  (B) Second code block: full contents of test_concat.sv
      - Begin with: ```verilog
      - End with: ```

- Do NOT output any additional text before, between, or after these two code blocks:
  - No explanations.
  - No comments outside the code fences.
  - No additional Markdown or prose.

The goal is that a simple script can extract these two Verilog files from your output by parsing the triple backtick code fences.
""".strip()


def write_concat_files(aes_concat_v: str, test_concat_v: str):
    """Write the generated Verilog code into the aes_concat directory."""
    AES_CONCAT_DIR.mkdir(parents=True, exist_ok=True)

    # Copy standard_stream_if.sv for compilation
    std_if_src = VSPLIT_DIR / "standard_stream_if.sv"
    std_if_dst = AES_CONCAT_DIR / "standard_stream_if.sv"
    if std_if_src.exists():
        shutil.copy(std_if_src, std_if_dst)

    # Write DUT and testbench code
    (AES_CONCAT_DIR / "aes_concat.sv").write_text(
        aes_concat_v.strip() + "\n", encoding="utf-8"
    )
    (AES_CONCAT_DIR / "test_concat.sv").write_text(
        test_concat_v.strip() + "\n", encoding="utf-8"
    )


def run_sim() -> int:
    """Run the simulation script sim_concat.py inside the aes_concat directory."""
    r = subprocess.run([sys.executable, "sim_concat.py"], cwd=AES_CONCAT_DIR)
    return r.returncode


def main():
    """Main flow: discover submodules -> build prompt -> call LLM -> write files -> run simulation."""
    xs = discover_submodules()
    if not xs:
        print("Error: No aesvX directories found under VSPLIT_DIR.", file=sys.stderr)
        sys.exit(2)

    prompt = build_prompt(xs)
    out = call_llm([{"role": "user", "content": prompt}], max_tokens=32768)
    save_io("s5_concat", prompt, out)

    blocks = extract_code_blocks(out)
    if len(blocks) >= 2:
        aes_concat_v, test_concat_v = blocks[0], blocks[1]
    else:
        # Fallback: attempt to split by "module top"
        idx = out.lower().find("module top")
        if idx <= 0:
            aes_concat_v, test_concat_v = (out, "")
        else:
            aes_concat_v, test_concat_v = (out[:idx], out[idx:])

    write_concat_files(aes_concat_v, test_concat_v)

    rc = run_sim()
    report_path = AES_CONCAT_DIR / "concat_check.txt"
    if rc == 0:
        report_path.write_text("GLOBAL_CHECK: DONE\n", encoding="utf-8")
    else:
        report_path.write_text(f"SIM_FAIL:{rc}\n", encoding="utf-8")
        sys.exit(rc)


if __name__ == "__main__":
    main()
