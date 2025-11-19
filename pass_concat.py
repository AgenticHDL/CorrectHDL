"""
All-in-one script:
- Read overall_summary.json for each submodule from EXP vsplit.
- For each submodule, randomly select one instance with final_sim == "PASS".
- From that instance directory, pick the aesX_M.sv file with the largest M.
- Copy that single file into /path.
- Build an LLM prompt:
    - Interface/spec from /path.
    - C++ reference from /path.
- Ask the LLM to generate aes_concat.sv / test_concat.sv into /path.
- Optional simulation: prefer sim_concat.py in aesv_concat; if not present, fall back to aesh4/aes_concat.
"""

from __future__ import annotations
import os
import re
import sys
import json
import shutil
import random
import subprocess
from pathlib import Path
from typing import List, Dict, Tuple, Optional

ORIGHLS_ROOT = Path("/nas")
EXP_VSPLIT_ROOT = ORIGHLS_ROOT
AESV_CONCAT_DIR = ORIGHLS_ROOT / "aesv_concat"

# Specification and interface directory
VSPLIT_SPEC_DIR = ORIGHLS_ROOT  # contains standard_stream_if.sv, interface_spec.md

# C++ reference directory
# contains aes_concat.cpp, test_concat.cpp
AES_CONCAT_SRC_DIR = Path(
    "/nas"
)

# Data width used in the LLM prompt
DEFAULT_TDATA_WIDTH = 512

# Random seed (optional, for reproducibility)
SELECT_SEED: Optional[int] = None 

# Whether to run simulation after generating SV (only if sim_concat.py is present)
RUN_SIM_IF_PRESENT = True


# Utility functions
def log(msg: str):
    print(msg, flush=True)


def ensure_dir(p: Path):
    p.mkdir(parents=True, exist_ok=True)


def read_text_if_exists(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="ignore") if p.exists() else ""


def list_submodules_from_exp(exp_root: Path) -> List[int]:
    xs: List[int] = []
    log(f"[SCAN] Scanning EXP root directory: {exp_root}")
    for d in exp_root.iterdir():
        if d.is_dir() and d.name.startswith("aesv"):
            tail = d.name[4:]
            if tail.isdigit():
                x = int(tail)
                summary_path = d / f"aesv{x}_runs" / "overall_summary.json"
                if summary_path.exists():
                    log(f"[FOUND] Submodule {x} summary: {summary_path}")
                    xs.append(x)
    xs.sort()
    return xs


# ------- Instance directory resolver -------

def resolve_instance_dir(runs_dir: Path, sub_x: int, i: int) -> Optional[Path]:
    """
    Resolve the directory for instance i of submodule sub_x.

    Tries the following naming patterns in order:
      1) aesv{sub_x}_{i}
      2) aes{sub_x}_{i}
      3) aesvX_{i}
      4) aesX_{i}

    If none match, falls back to:
      - Scan all subdirectories in runs_dir whose names end with _{i}.
      - Prefer a directory containing files named aes{sub_x}_*.sv.
      - If none contain such files, pick the first matching directory.
    """
    candidates = [
        runs_dir / f"aesv{sub_x}_{i}",
        runs_dir / f"aes{sub_x}_{i}",
        runs_dir / f"aesvX_{i}",
        runs_dir / f"aesX_{i}",
    ]
    for c in candidates:
        if c.exists():
            return c

    # Fallback: scan *_i
    tail_pat = re.compile(rf".*_{i}$")
    matched_dirs: List[Path] = [
        p for p in runs_dir.iterdir()
        if p.is_dir() and tail_pat.match(p.name)
    ]
    if not matched_dirs:
        return None

    sig_pat = re.compile(rf"^aes{sub_x}_(\d+)\.sv$", re.IGNORECASE)
    for d in matched_dirs:
        if any(sig_pat.match(f.name) for f in d.iterdir() if f.is_file()):
            return d

    # If none contain aes{sub_x}_*.sv, return the first match
    return matched_dirs[0]


def parse_overall_summary(summary_path: Path, sub_x: int) -> List[int]:
    """
    Parse overall_summary.json and return the 1-based indices of instances
    with final_sim == "PASS". Each candidate is checked via resolve_instance_dir.
    """
    log(f"[PARSE] Reading {summary_path}")
    data = json.loads(summary_path.read_text(encoding="utf-8"))
    results = data.get("results", [])
    passing_idx: List[int] = []
    runs_dir = summary_path.parent
    for i, item in enumerate(results, start=1):
        simres = str(item.get("final_sim", "")).upper()
        inst_dir = resolve_instance_dir(runs_dir, sub_x, i)
        log(
            f"  - Instance {i}: final_sim={simres}, resolved_dir="
            f"{inst_dir if inst_dir else '<NOT FOUND>'}"
        )
        if simres == "PASS" and inst_dir is not None and inst_dir.exists():
            passing_idx.append(i)
    log(f"[OK] Submodule {sub_x} has {len(passing_idx)} PASS instances: {passing_idx}")
    return passing_idx


def find_latest_sv_in_instance(inst_dir: Path, sub_x: int) -> Path:
    """
    In a given instance directory, find the aes{sub_x}_*.sv file
    with the largest numeric suffix.
    """
    log(f"[SEARCH] Looking for aes{sub_x}_*.sv in {inst_dir}")
    pat = re.compile(rf"^aes{sub_x}_(\d+)\.sv$", re.IGNORECASE)
    candidates: List[Tuple[int, Path]] = []
    for f in inst_dir.iterdir():
        if f.is_file():
            m = pat.match(f.name)
            if m:
                idx = int(m.group(1))
                log(f"  - Candidate file: {f} (index {idx})")
                candidates.append((idx, f))
    if not candidates:
        raise FileNotFoundError(f"[ERROR] No aes{sub_x}_*.sv found in {inst_dir}")
    candidates.sort(key=lambda x: x[0])
    latest = candidates[-1][1]
    log(f"[SELECT] Picked highest-index file: {latest}")
    return latest


def copy_single_to_concat(exp_src: Path, concat_dir: Path) -> Path:
    """
    Copy a single file into the target concatenation directory.
    """
    ensure_dir(concat_dir)
    dst = concat_dir / exp_src.name
    shutil.copy(exp_src, dst)
    log(f"[COPY] {exp_src} -> {dst}")
    return dst


def choose_random(lst: List[int]) -> int:
    if SELECT_SEED is not None:
        random.seed(SELECT_SEED)
    return random.choice(lst)


# ================================
# LLM-related: prompt building and call
# ================================

def build_prompt_from_selection(selection: Dict[int, Dict[str, str]]) -> str:
    """
    Build the LLM prompt based on the selected submodules:

    - Interface and functional specification: from VSPLIT_SPEC_DIR.
    - Submodules: from AESV_CONCAT_DIR (aesX_M.sv).
    - C++ top and test: from AES_CONCAT_SRC_DIR.
    """
    iface_md = read_text_if_exists(VSPLIT_SPEC_DIR / "interface_spec.md")
    std_if_sv = read_text_if_exists(VSPLIT_SPEC_DIR / "standard_stream_if.sv")
    test_refer_sv = read_text_if_exists(VSPLIT_SPEC_DIR / "test_concat.sv")

    log(
        f"[PROMPT] Using interface spec: {VSPLIT_SPEC_DIR / 'interface_spec.md'} "
        f"(exists={ (VSPLIT_SPEC_DIR / 'interface_spec.md').exists() })"
    )
    log(
        f"[PROMPT] Using standard interface: {VSPLIT_SPEC_DIR / 'standard_stream_if.sv'} "
        f"(exists={ (VSPLIT_SPEC_DIR / 'standard_stream_if.sv').exists() })"
    )

    # Submodule contents (sorted by numeric index)
    verilog_blobs: List[str] = []
    for x in sorted(selection.keys()):
        sel = selection[x]
        sv_path = Path(sel["dst"])  # aesX_M.sv
        log(f"[PROMPT] Injecting submodule code: {sv_path} (exists={sv_path.exists()})")
        blob = f"[/aesh4/aesv_concat/{sv_path.name}]\n{read_text_if_exists(sv_path)}"
        verilog_blobs.append(blob)

    cc_path = AES_CONCAT_SRC_DIR / "aes_concat.cpp"
    tc_path = AES_CONCAT_SRC_DIR / "test_concat.cpp"
    log(f"[PROMPT] C++ reference: {cc_path} (exists={cc_path.exists()})")
    log(f"[PROMPT] C++ test reference: {tc_path} (exists={tc_path.exists()})")

    cc = read_text_if_exists(cc_path)
    tc = read_text_if_exists(tc_path)

    # Prompt: simplified and fully in English, with explicit design & formatting constraints
    return f"""
You are a senior hardware architecture and verification expert. Based on the provided information, generate high-quality, synthesizable Verilog for a concatenated AES design and its testbench.

==================== Context: Specifications and Interfaces ====================
[Interface specification (interface_spec.md)]
{iface_md}

[Standard streaming interface (standard_stream_if.sv)]
{std_if_sv}

==================== Context: Pre-verified Submodules ====================
The following Verilog submodules (from /aesh4/aesv_concat) have already passed simulation and can be treated as functionally correct. They represent individual AES sub-ss or related components.

{chr(10).join(verilog_blobs)}

==================== Context: C/C++ Top-level Behavior ====================
The concatenated C++ top-level implementation and its C++ testbench are:

[/aesh4/aes_concat/aes_concat.cpp]
{cc}

[/aesh4/aes_concat/test_concat.cpp]
{tc}

For additional reference, you may also look at an existing Verilog testbench (it is not required to copy it verbatim, but the behavior should be compatible):

[Reference Verilog testbench (test_concat.sv)]
{test_refer_sv}

==================== Task ====================
Generate the HDL implementation and testbench for the concatenated AES design.

You must produce **exactly two Verilog files**:

1) /aesh4/aesv_concat/aes_concat.sv  
   - Top module name: `aes_concat`
   - This module must:
     - Instantiate all given submodules (aes1, aes2, ...) to implement the same dataflow and functionality as `aes_concat.cpp`.
     - Use the streaming interface defined in `standard_stream_if.sv` with
       `parameter int WIDTH = {DEFAULT_TDATA_WIDTH}` where appropriate.
     - Connect the submodules via streaming interfaces (e.g., s0, s1, ...) so that
       the overall behavior matches `aes_concat.cpp`.
     - Expose one input stream and one output stream and follow the interface protocol.

2) /aesh4/aesv_concat/test_concat.sv  
   - Testbench top module name: `top`
   - This module must:
     - Instantiate `aes_concat` as the DUT.
     - Apply stimulus equivalent to that in `test_concat.cpp`.
     - Check the DUT outputs against the expected (golden) behavior from `test_concat.cpp`.
     - Terminate the simulation without deadlock when run on a standard simulator (e.g., Questa/ModelSim).

==================== Design Constraints (HDL Quality) ====================
To guide you toward effective HDL designs, follow these rules:

1) Separate control logic from datapath
   - Use `always_ff` for sequential logic (registers, state).
   - Use `always_comb` for purely combinational logic.
   - Where reasonable, keep protocol / handshake / FSM control separate from arithmetic datapath.

2) Use synchronous reset conventions
   - Use a single clock (e.g., `clk`) and an active-low **synchronous** reset signal (e.g., `rst_n`).
   - All sequential state must be reset to known values when reset is asserted.
   - Implement reset behavior inside `always_ff @(posedge clk)` blocks.

3) Allow optimization / pipelining
   - You may insert pipeline ss or registers to improve timing, as long as:
     - The external protocol (valid/ready handshake) is preserved.
     - The ordering of transactions and end-to-end functional behavior remains the same as `aes_concat.cpp`.

4) Streaming interface protocol
   - Use the `standard_stream_if` interface for dataflow between submodules and at the top level.
   - A transaction is transferred on a cycle where `tvalid && tready` on the rising edge of `clk`.
   - Avoid combinational loops between `tvalid` and `tready`; if necessary, use registered backpressure.

==================== Formatting Constraints (LLM Output) ====================
To make HDL extraction easy with a script, you must:

- Output **exactly two Markdown code blocks** in this order:

  (A) First code block: full contents of `aes_concat.sv`  
      - Start with: ```verilog  
      - End with: ```

  (B) Second code block: full contents of `test_concat.sv`  
      - Start with: ```verilog  
      - End with: ```

- Do **not** output any additional text before, between, or after these two code blocks
  (no explanations, no comments outside the code fences).

The C/C++ top-level code, the functional specification, the interface definition, and the above
design and formatting constraints are provided together to guide you to generate a correct and
efficient Verilog implementation of the concatenated AES design.
""".strip()


def _messages_to_input(messages: List[Dict]) -> str:
    """Flatten chat messages into a single text prompt for responses.create."""
    parts = []
    role_name = {"system": "System", "user": "User", "assistant": "Assistant"}
    for m in messages:
        r = role_name.get(m.get("role", "user"), "User")
        c = m.get("content", "")
        parts.append(f"{r}:\n{c}")
    parts.append("Assistant:\n")
    return "\n\n".join(parts)


def _extract_text_from_responses(resp) -> str:
    """Best-effort extraction of text from responses.create, compatible with different SDK structures."""
    text = getattr(resp, "output_text", None)
    if text:
        return text
    out = getattr(resp, "output", None)
    if out:
        buf = []
        for o in out:
            content = getattr(o, "content", None) or (
                isinstance(o, dict) and o.get("content")
            ) or []
            for p in content:
                t = getattr(p, "text", None) or (isinstance(p, dict) and p.get("text"))
                if t:
                    buf.append(t)
        if buf:
            return "".join(buf)
    return str(resp)


def call_llm(messages: List[Dict], max_tokens: int = 32768, model: Optional[str] = None) -> str:
    """
    Unified LLM call:

      1) Prefer responses.create (minimal parameters: model + input).
      2) On failure, fall back to chat.completions (model + messages).
      3) If openai<1.0.0, fall back to legacy ChatCompletion.

    No explicit temperature / max_tokens are passed to keep default behavior,
    except for max_output_tokens on responses.create as requested.
    """
    api_key = os.getenv("OPENAI_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError("Missing OPENAI_API_KEY environment variable; cannot call LLM.")
    if model is None:
        model = os.getenv("OPENAI_MODEL", "gpt-5")

    # New SDK route
    try:
        from openai import OpenAI  # openai>=1.x
        client = OpenAI(api_key=api_key)

        # 1) Try Responses API
        try:
            log("[LLM] responses.create (default parameters)")
            resp = client.responses.create(model=model, input=_messages_to_input(messages))
            return _extract_text_from_responses(resp).strip()
        except Exception as e_resp:
            log(f"[LLM] responses.create failed, falling back to chat.completions: {e_resp}")

        # 2) Fallback Chat Completions
        try:
            log("[LLM] chat.completions.create (default parameters)")
            resp = client.chat.completions.create(model=model, messages=messages)
            return (resp.choices[0].message.content or "").strip()
        except Exception as e_chat:
            raise RuntimeError(f"LLM call failed: responses→{e_resp}; chat.completions→{e_chat}")

    except Exception as e_newsdk:
        # SDK not usable or missing, try legacy openai
        try:
            import importlib.metadata as md
            ver = md.version("openai")
        except Exception:
            ver = "0.0.0"

        def _ver_tuple(s: str):
            nums = []
            for x in s.split("."):
                try:
                    nums.append(int("".join(ch for ch in x if ch.isdigit())))
                except ValueError:
                    nums.append(0)
            while len(nums) < 3:
                nums.append(0)
            return tuple(nums[:3])

        if _ver_tuple(ver) < _ver_tuple("1.0.0"):
            try:
                import openai  # legacy
                openai.api_key = api_key
                log("[LLM] openai.ChatCompletion.create (legacy, default parameters)")
                resp = openai.ChatCompletion.create(model=model, messages=messages)
                return (resp["choices"][0]["message"]["content"] or "").strip()
            except Exception as e_old:
                raise RuntimeError(
                    f"LLM call failed (new SDK error: {e_newsdk}; legacy SDK error: {e_old})"
                )
        else:
            raise RuntimeError(f"LLM call failed (openai=={ver}): {e_newsdk}")


# ================================
# Code block extraction (from LLM output)
# ================================

_CODE_FENCE_RE = re.compile(
    r"```(?:verilog|verilog)?\s*([\s\S]*?)```",
    re.IGNORECASE | re.MULTILINE,
)


def extract_code_blocks(text: str) -> List[str]:
    """
    Extract the two Verilog code blocks from the LLM output.

    Preferred behavior:
      - Extract content between Markdown code fences ```verilog ... ```.
      - Return the first two fenced blocks as [aes_concat.sv, test_concat.sv].

    Fallback:
      - If no fenced blocks are found, fall back to splitting by 'module top'
        or by the second 'module <name>' occurrence.
    """
    t = text.strip()
    if not t:
        return []

    fenced = _CODE_FENCE_RE.findall(t)
    if len(fenced) >= 2:
        return [fenced[0].strip(), fenced[1].strip()]
    elif len(fenced) == 1:
        return [fenced[0].strip()]

    # Fallback: previous heuristic
    idx = t.lower().find("module top")
    if idx > 0:
        return [t[:idx].strip(), t[idx:].strip()]
    mods = list(re.finditer(r"(?im)^\s*module\s+\w+", t))
    if len(mods) >= 2:
        return [t[:mods[1].start()].strip(), t[mods[1].start():].strip()]
    return [t]


def write_concat_files(aes_concat_v: str, test_concat_v: str):
    """
    Write the generated Verilog code to the ORIGHLS aesv_concat directory
    (and copy standard_stream_if.sv for compilation).
    """
    ensure_dir(AESV_CONCAT_DIR)

    # Copy standard_stream_if.sv (for compilation)
    std_if_src = VSPLIT_SPEC_DIR / "standard_stream_if.sv"
    std_if_dst = AESV_CONCAT_DIR / "standard_stream_if.sv"
    log(
        f"[WRITE] Copy interface file: {std_if_src} -> {std_if_dst} "
        f"(exists={std_if_src.exists()})"
    )
    if std_if_src.exists():
        shutil.copy(std_if_src, std_if_dst)

    (AESV_CONCAT_DIR / "aes_concat.sv").write_text(
        aes_concat_v.strip() + "\n", encoding="utf-8"
    )
    (AESV_CONCAT_DIR / "test_concat.sv").write_text(
        test_concat_v.strip() + "\n", encoding="utf-8"
    )
    log(
        f"[OK] Written {AESV_CONCAT_DIR / 'aes_concat.sv'} and "
        f"{AESV_CONCAT_DIR / 'test_concat.sv'}"
    )


def prepare_sim_script() -> Optional[Path]:
    """
    If ORIGHLS_ROOT/sim_concat.py exists, copy it to AESV_CONCAT_DIR
    and return the destination path; otherwise return None.
    """
    src = ORIGHLS_ROOT / "sim_concat.py"
    if not src.exists():
        log(f"[SKIP] No sim_concat.py found in ORIGHLS_ROOT: {src}")
        return None
    ensure_dir(AESV_CONCAT_DIR)
    dst = AESV_CONCAT_DIR / "sim_concat.py"
    shutil.copy(src, dst)
    log(f"[SIM] Copied simulation script: {src} -> {dst}")
    return dst


def run_sim_if_present() -> int:
    """
    If RUN_SIM_IF_PRESENT is True:
      - Try to copy ORIGHLS_ROOT/sim_concat.py into AESV_CONCAT_DIR.
      - If present, run it inside AESV_CONCAT_DIR.
      - Return the process return code.

    If sim_concat.py does not exist, skip simulation and return 0.
    """
    if not RUN_SIM_IF_PRESENT:
        return 0

    sim_dst = prepare_sim_script()
    if sim_dst is None:
        log("[SKIP] sim_concat.py not found, skipping simulation.")
        return 0

    log(f"[SIM] Running: {sim_dst} (cwd={AESV_CONCAT_DIR})")
    r = subprocess.run([sys.executable, sim_dst.name], cwd=AESV_CONCAT_DIR)
    return r.returncode


def save_io(tag: str, prompt: str, out: str):
    """
    Save prompt and LLM output into aesv_concat/log.
    """
    io_dir = AESV_CONCAT_DIR / "log"
    ensure_dir(io_dir)
    (io_dir / f"{tag}_prompt.txt").write_text(prompt, encoding="utf-8")
    (io_dir / f"{tag}_out.txt").write_text(out, encoding="utf-8")
    log(f"[LOG] Saved LLM I/O into {io_dir}")


def s1_select_and_collect() -> Dict[int, Dict[str, str]]:
    """
    s 1: filter, select instances, copy SV files.
    """
    log(f"[s1] EXP_VSPLIT_ROOT={EXP_VSPLIT_ROOT}")
    log(f"[s1] AESV_CONCAT_DIR={AESV_CONCAT_DIR}")
    xs = list_submodules_from_exp(EXP_VSPLIT_ROOT)
    if not xs:
        log("[ERROR] No submodules found.")
        sys.exit(2)

    selection: Dict[int, Dict[str, str]] = {}
    for x in xs:
        summary = EXP_VSPLIT_ROOT / f"aesv{x}" / f"aesv{x}_runs" / "overall_summary.json"
        passing = parse_overall_summary(summary, x)
        if not passing:
            log(f"[ERROR] Submodule {x}: no PASS instances.")
            sys.exit(3)

        i = choose_random(passing)
        log(f"[SELECT] Submodule {x}: randomly selected instance {i}")

        runs_dir = summary.parent
        inst_dir = resolve_instance_dir(runs_dir, x, i)
        if inst_dir is None or not inst_dir.exists():
            log(
                f"[ERROR] Failed to resolve instance directory. "
                f"Tried runs_dir={runs_dir}, sub_x={x}, i={i}"
            )
            sys.exit(3)

        latest_sv = find_latest_sv_in_instance(inst_dir, x)
        dst = copy_single_to_concat(latest_sv, AESV_CONCAT_DIR)

        selection[x] = {"instance": str(i), "src": str(latest_sv), "dst": str(dst)}

    ensure_dir(AESV_CONCAT_DIR)
    selection_path = AESV_CONCAT_DIR / "selection.json"
    selection_path.write_text(
        json.dumps(selection, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    log(f"[OK] Selection list written to: {selection_path}")
    return selection


def s2_build_and_call_llm(selection: Dict[int, Dict[str, str]]):
    """
    s 2: build prompt from selection, call LLM, write files, optionally run simulation.
    """
    prompt = build_prompt_from_selection(selection)

    try:
        out = call_llm([{"role": "user", "content": prompt}], max_tokens=32768)
    except Exception as e:
        log(f"[ERROR] LLM call failed: {e}")
        sys.exit(5)

    save_io("s5_concat", prompt, out)

    blocks = extract_code_blocks(out)
    if len(blocks) >= 2:
        aes_concat_v, test_concat_v = blocks[0], blocks[1]
    else:
        # Very conservative fallback
        idx = out.lower().find("module top")
        if idx <= 0:
            aes_concat_v, test_concat_v = (out, "")
        else:
            aes_concat_v, test_concat_v = (out[:idx], out[idx:])

    write_concat_files(aes_concat_v, test_concat_v)

    rc = run_sim_if_present()
    report_path = AESV_CONCAT_DIR / "concat_check.txt"
    if rc == 0:
        report_path.write_text("GLOBAL_CHECK: DONE\n", encoding="utf-8")
        log(f"[OK] Simulation check passed (or was skipped): {report_path}")
    else:
        report_path.write_text(f"SIM_FAIL:{rc}\n", encoding="utf-8")
        log(f"[ERROR] Simulation failed with return code {rc}, see {report_path}")
        sys.exit(rc)


def main():
    if SELECT_SEED is not None:
        random.seed(SELECT_SEED)

    log("==== s 1: Select instances and copy to ORIGHLS aesv_concat ====")
    selection = s1_select_and_collect()

    log("\n==== s 2: LLM-based concatenation (outputs in ORIGHLS aesv_concat) ====")
    s2_build_and_call_llm(selection)


if __name__ == "__main__":
    main()
