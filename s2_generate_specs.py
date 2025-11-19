# -*- coding: utf-8 -*-
import sys
from pathlib import Path
from typing import List
from config import ROOT, VSPLIT_DIR, aes_dir, aesv_dir
from llm_utils import call_llm, save_io, extract_code_blocks

def discover_modules() -> List[int]:
    """Discover submodule directories named aesX under ROOT."""
    xs = []
    for p in ROOT.iterdir():
        if p.is_dir() and p.name.startswith("aes"):
            try:
                xs.append(int(p.name[3:]))
            except:
                pass
    xs.sort()
    return xs

def build_prompt(x: int, iface_sv: str, iface_md: str, h: str, cpp: str) -> str:
    """Build the LLM prompt for generating spec{x}.md."""
    return f"""
Based on the following inputs, please construct a Verilog specification `spec{x}.md`
for C++ submodule aes{x}. This specification will serve as the prompt for the next
LLM round that generates Verilog code. The specification must be concise, clear,
logically consistent, and accurate.

It must include:

- **Interface constraints**: Extract the corresponding description of this submodule
  from `standard_stream_if.sv`, and strictly follow it.
- **tdata mapping**: Extract the corresponding description of this submodule from
  `interface_spec.md`, and strictly follow it.
- **Top-level naming**:
    - Design top module name: `aes{x}`
    - Testbench top module name: `top{x}`

[standard_stream_if.sv]
{iface_sv}

[interface_spec.md]
{iface_md}

[/aesh4/aes{x}/aes{x}.h]
{h}

[/aesh4/aes{x}/aes{x}.cpp]
{cpp}
"""

def main():
    xs = discover_modules()
    if not xs:
        print("No /aesh4/aesX found.", file=sys.stderr)
        sys.exit(2)

    iface_sv = (VSPLIT_DIR / "standard_stream_if.sv").read_text(encoding="utf-8")
    iface_md = (VSPLIT_DIR / "interface_spec.md").read_text(encoding="utf-8")

    for x in xs:
        h_path = aes_dir(x) / f"aes{x}.h"
        cpp_path = aes_dir(x) / f"aes{x}.cpp"

        h = h_path.read_text(encoding="utf-8", errors="ignore") if h_path.exists() else ""
        cpp = cpp_path.read_text(encoding="utf-8", errors="ignore") if cpp_path.exists() else ""

        prompt = build_prompt(x, iface_sv, iface_md, h, cpp)
        out = call_llm([{"role": "user", "content": prompt}], max_tokens=16384)

        save_io(f"s2_spec{x}", prompt, out)

        blocks = extract_code_blocks(out)
        code = blocks[0] if blocks else out

        (aesv_dir(x) / f"spec{x}.md").write_text(code.strip() + "\n", encoding="utf-8")

    print(f"s2 (LLM) completed: {xs}")

if __name__ == "__main__":
    main()
