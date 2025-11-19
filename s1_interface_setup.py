# -*- coding: utf-8 -*-
import re, sys
from pathlib import Path
from typing import List
from config import ROOT, VSPLIT_DIR, TEMPLATES_DIR, DEFAULT_TDATA_WIDTH, aes_dir, aesv_dir
from llm_utils import call_llm, save_io, extract_code_blocks

def discover_modules() -> List[int]:
    """Discover all module directories named aesX that contain aesX.h"""
    ids = []
    for p in ROOT.iterdir():
        if p.is_dir():
            m = re.fullmatch(r"aes(\d+)", p.name)
            if m and (p / f"aes{m.group(1)}.h").exists():
                ids.append(int(m.group(1)))
    ids.sort()
    return ids

def make_s4_script(x: int):
    """Instantiate the s 4 script for module X using the template."""
    tpl = (TEMPLATES_DIR / "s4_template.py").read_text(encoding="utf-8")
    body = tpl.replace("{{X}}", str(x))
    (VSPLIT_DIR / f"s4_aes{x}.py").write_text(body, encoding="utf-8")

def build_llm_prompt(mod_ids: List[int]) -> str:
    """Construct the LLM prompt based on module decomposition and module sources."""
    decomp_path = ROOT / "csplit" / "module_decomposition.txt"
    decomp_text = (
        decomp_path.read_text(encoding="utf-8", errors="ignore")
        if decomp_path.exists()
        else ""
    )

    parts = []
    parts += [
        "Define a unified minimal interface with fixed signals: clk, tvalid, tready, tdata.",
        f"The default WIDTH for tdata is {DEFAULT_TDATA_WIDTH}. Output exactly two code blocks:",
        "1. systemverilog: standard_stream_if.sv (only the interface and its two modports: master/slave)",
        "2. markdown: interface_spec.md (concise rules: handshake behavior, packing by declaration order, base width, multi-cycle sequencing if WIDTH is insufficient; also provide a minimal mapping table for each function).",
        "No extra text, comments, or filenames are allowed."
    ]

    parts.append("[module_decomposition.txt]")
    parts.append(decomp_text)

    for x in mod_ids:
        for ext in ("h", "cpp"):
            p = aes_dir(x) / f"aes{x}.{ext}"
            parts.append(f"[/aesh4/aes{x}/aes{x}.{ext}]")
            parts.append(
                p.read_text(encoding="utf-8", errors="ignore") if p.exists() else ""
            )

    return "\n".join(parts)

def extract_two_outputs(raw: str):
    """
    Extract the two output blocks: SystemVerilog and Markdown.
    Fallback heuristics are used if code blocks are not detected properly.
    """
    blocks = extract_code_blocks(raw)
    if len(blocks) >= 2:
        return blocks[0], blocks[1]

    import re
    m = re.search(
        r"(interface\s+standard_stream_if[\s\S]*?endinterface)",
        raw,
        flags=re.IGNORECASE,
    )
    if m:
        return m.group(1), raw.replace(m.group(1), "").strip()

    # Final fallback: minimal valid interface
    sv = f"""interface standard_stream_if #(parameter int WIDTH = {DEFAULT_TDATA_WIDTH}) (input logic clk);
  logic tvalid; logic tready; logic [WIDTH-1:0] tdata;
  modport master (input clk, output tvalid, input tready, output tdata);
  modport slave  (input clk, input tvalid, output tready, input tdata);
endinterface
"""
    return sv, raw

def main():
    VSPLIT_DIR.mkdir(parents=True, exist_ok=True)

    mod_ids = discover_modules()
    if not mod_ids:
        print("No /aesh4/aesX modules found.", file=sys.stderr)
        sys.exit(2)

    for x in mod_ids:
        aesv_dir(x).mkdir(parents=True, exist_ok=True)

    prompt = build_llm_prompt(mod_ids)
    output = call_llm([{"role": "user", "content": prompt}], max_tokens=32768)

    save_io("s1_interface", prompt, output)

    sv, md = extract_two_outputs(output)

    (VSPLIT_DIR / "standard_stream_if.sv").write_text(sv.strip() + "\n", encoding="utf-8")
    (VSPLIT_DIR / "interface_spec.md").write_text(md.strip() + "\n", encoding="utf-8")

    for x in mod_ids:
        make_s4_script(x)

    print(f"s 1 simplification completed: {mod_ids}")

if __name__ == "__main__":
    main()
