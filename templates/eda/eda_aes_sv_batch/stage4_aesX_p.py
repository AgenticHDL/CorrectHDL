"""
Automation pipeline for q-round LLM -> SystemVerilog generation + Questa simulation.
- test{x}_{round_id}.sv is derived from test{x}.sv: redirects output to report_{round_id}.txt.
- LLM generates aes{x}_{round_id}.sv only; testbench is NEVER overwritten.
- Compilation PASS: No vlog errors (Errors: 0) and no (vlog-*) fatal patterns in transcript.
- Simulation PASS: Based on GLOBAL_CHECK in report_{r}.txt.
- Final results are logged to report{X}_{q}.txt.
"""
import argparse
import json
import subprocess
from pathlib import Path
import re

from utils import (

    read_text, write_text, transform_testbench_for_round,
    grep_errors_from_transcript, parse_global_result, split_sv_blocks_from_llm_output,
    analyze_transcript, compile_pass_from_transcript, vsim_started_from_transcript
)

# ---- LLM Utility Dependencies ----
try:
    from llm_utils import call_llm, strict_code_guard_prefix, extract_code_blocks
except Exception:
    raise SystemExit("Fatal: Ensure llm_utils.py is available with call_llm, strict_code_guard_prefix, and extract_code_blocks.")

from rag_utils import retrieve_template_block

# Optional: C++ Prototype Parser
try:
    from cpp_utils import parse_prototypes_from_header
except Exception:
    def parse_prototypes_from_header(*_a, **_k): return ""

# ---------------- Error Context Extraction ----------------
def extract_error_context(transcript_path: Path) -> str:
    """Grabs relevant error lines from the transcript to feed back to the LLM."""
    if not transcript_path.exists():
        return "(Transcript log not found)"
    
    lines = read_text(transcript_path).splitlines()
    picked, started = [], False
    for ln in lines:
        s = ln.strip()
        # Start tracking once vlog or vsim begins
        if re.search(r"^\#\s*vlog\s+-lint\b", s) or re.search(r"^\#\s*vsim\s+-c\b", s):
            started = True
        if not started:
            continue
        
        # Filter for actual design errors or compilation messages
        if s.startswith("# -- Compiling "):
            picked.append(ln); continue
        if ("# ** Error:" in s or "# Error:" in s or "Error loading design" in s or "Error in macro" in s):
            picked.append(ln); continue
        
        # Check for non-zero error counts
        m = re.search(r"#\s*Errors:\s*(\d+)", s)
        if m and int(m.group(1)) > 0:
            picked.append(ln); continue
        
        # Include block markers
        if s.startswith("# End time:") or s.startswith("# vsim -c"):
            picked.append(ln); continue
            
    return "\n".join(picked) if picked else "(No critical compile/sim errors detected)"

def extract_vsim_error_context(transcript_path: Path) -> str:
    """Extracts specific vsim runtime/loading errors."""
    if not transcript_path.exists():
        return "(Transcript log not found)"
    
    lines = read_text(transcript_path).splitlines()
    out, in_vsim = [], False
    for ln in lines:
        s = ln
        if re.search(r"^\#\s*vsim\s+-c\b", s):
            in_vsim = True
            out.append(ln)
            continue
        if in_vsim:
            if re.search(r"^\#\s*End time:.*Elapsed time:", s):
                out.append(ln)
                in_vsim = False
                continue
            if ("# ** Error:" in s or "Error loading design" in s
                or "Fatal:" in s or re.search(r"\(vsim-\d+\)", s)):
                out.append(ln); continue
            
            m = re.search(r"#\s*Errors:\s*(\d+)", s)
            if m and int(m.group(1)) > 0:
                out.append(ln); continue
                
    return "\n".join(out) if out else "(No specific vsim errors detected)"

# ---------------- Path Resolution ----------------
def find_ancestor_named(start: Path, name: str) -> Path:
    """Climbs the directory tree to find the vsplit root."""
    start = start.resolve()
    if start.name == name:
        return start
    for p in start.parents:
        if p.name == name:
            return p
    raise SystemExit(f"[ERROR] Could not find '{name}' in parent directories of {start}. Use --vsplit-dir.")

def detect_root_from_vsplit(vsplit_dir: Path) -> Path:
    """Heuristic to find the project root based on aesc/aesv structure."""
    for p in [vsplit_dir] + list(vsplit_dir.parents):
        if (p / "aesc").exists() and (p / "aesv").exists():
            return p
    return vsplit_dir.parent.parent

# ---------------- Prompt Engineering ----------------
def build_prompt(x: int, aes_dir: Path, aesv_dir: Path, vsplit_dir: Path) -> str:
    """Assembles the initial prompt using C++ sources and the SV spec."""
    h = read_text(aes_dir / f"aes{x}.h") if (aes_dir / f"aes{x}.h").exists() else ""
    cpp = read_text(aes_dir / f"aes{x}.cpp") if (aes_dir / f"aes{x}.cpp").exists() else ""
    testcpp = read_text(aes_dir / f"test{x}.cpp") if (aes_dir / f"test{x}.cpp").exists() else ""
    spec = read_text(aesv_dir / f"spec{x}.md") if (aesv_dir / f"spec{x}.md").exists() else ""
    
    funs = ""
    hdr = aes_dir / f"aes{x}.h"
    if hdr.exists():
        try:
            funs = parse_prototypes_from_header(hdr)
        except Exception:
            funs = ""
            
    base_tb = read_text(aesv_dir / f"test{x}.sv") if (aesv_dir / f"test{x}.sv").exists() else ""

    return f"""
You are a hardware design expert. Return **RAW CODE ONLY** according to these rules:
1) Generate one file: /aesh4/vsplit/aesv{x}/aes{x}.sv
2) Adhere to spec{x}.md specifications and the following port format:
module XXX (
    standard_stream_if.slave  s_in,
    standard_stream_if.master s_out,
    ...);
3) No explanations. Pure SystemVerilog only. Use ```systemverilog``` blocks if returning multiple segments.

Target C++ source files for conversion:
[aes{x}.h]
{h}

[aes{x}.cpp]
{cpp}

[test{x}.cpp]
{testcpp}

Reference Testbench (Top: top{x}, Report Output: report_q.txt):
[test{x}.sv]
{base_tb}

Function Prototypes (Auto-parsed):
{funs}
"""

def build_fix_context(x: int, round_id: int, aesv_dir: Path,
                      prev_compile_pass: bool, prev_sim_status: str,
                      include_aes_code: bool = True) -> str:
    """Constructs the feedback loop context for the LLM based on previous failures."""
    transcript = aesv_dir / "logs" / f"transcript_{round_id}.log"
    report = aesv_dir / f"report_{round_id}.txt"
    aes_prev = aesv_dir / f"aes{x}_{round_id}.sv"

    rep_text = read_text(report) if report.exists() else "(Report not generated)"
    err_excerpt_all = extract_error_context(transcript)
    err_excerpt_vsim = extract_vsim_error_context(transcript)

    parts = []
    parts.append(f"【Previous Round Status】Compile: {'PASS' if prev_compile_pass else 'FAIL'} | Sim: {prev_sim_status or 'UNKNOWN'}")

    if not prev_compile_pass:
        rag_block, rag_id, rag_method = retrieve_template_block(err_excerpt_all)
        parts += [
            f"[Questa Compile/Sim Errors: transcript_{round_id}.log]",
            err_excerpt_all,
        ]
        if rag_block:
            parts += [
                rag_block,
                "Use the retrieved template guidance to repair the SystemVerilog so it compiles with **vlog -sv** in QuestaSim."
            ]
        else:
            parts += [
                "Please fix syntax, port mismatches, or type declarations so the design compiles in Questa."
            ]
    else:
        sim_stat = (prev_sim_status or '').upper()
        if sim_stat == 'FAIL':
            parts += [
                f"[Functional Report: report_{round_id}.txt]",
                rep_text,
                f"[vsim Error Excerpt: transcript_{round_id}.log]",
                err_excerpt_vsim,
                "Note: Compile passed but Simulation failed. Fix logic and protocol issues to align with the C++ golden reference."
            ]
        elif sim_stat == 'UNKNOWN':
            parts += [
                f"[vsim Error Excerpt: transcript_{round_id}.log]",
                err_excerpt_vsim,
                "Errors occurred during simulation. Fix the design to ensure report_q.txt is generated."
            ]

    if include_aes_code and aes_prev.exists():
        aes_code = read_text(aes_prev)
        parts += [
            f"[Previous SystemVerilog Source: aes{x}_{round_id}.sv]",
            "```systemverilog",
            aes_code,
            "```"
        ]
    return "\n".join(parts)

# ---------------- LLM Interaction & File Output ----------------
def llm_once(prompt: str, out_dir: Path, round_id: int, x: int) -> str:
    """Logs the prompt/output and invokes the LLM."""
    llm_dir = out_dir / "llm_log"
    llm_dir.mkdir(parents=True, exist_ok=True)
    full_prompt = strict_code_guard_prefix() + prompt
    out = call_llm([{"role":"user","content": full_prompt}], max_tokens=32768)
    (llm_dir / f"prompt_{round_id}.txt").write_text(full_prompt, encoding="utf-8")
    (llm_dir / f"output_{round_id}.txt").write_text(out, encoding="utf-8")
    return out

def write_aes_from_llm_output(raw: str, aes_path: Path, x: int, round_id: int) -> None:
    """Writes the generated AES code while filtering out extra testbench segments."""
    try:
        blocks = extract_code_blocks(raw)
        if len(blocks) == 0:
            aes_v, _ = split_sv_blocks_from_llm_output(raw, x, round_id)
        elif len(blocks) == 1:
            aes_v, _ = split_sv_blocks_from_llm_output(blocks[0], x, round_id)
        else:
            # Prioritize the block containing the aes{x} module
            cand = None
            for b in blocks:
                if re.search(rf'\bmodule\s+aes{x}\b', b):
                    cand = b; break
            aes_v = cand if cand is not None else blocks[0]
    except Exception:
        aes_v, _ = split_sv_blocks_from_llm_output(raw, x, round_id)
    write_text(aes_path, (aes_v or "").strip() + "\n")

# ---------------- Questa Execution ----------------
def run_sim(sim_py: Path, src_dir: Path, x: int, round_id: int) -> int:
    """Invokes sim.py to trigger the Questa simulation flow."""
    top = f"top{x}"
    aes = f"aes{x}_{round_id}.sv"
    tb  = f"test{x}_{round_id}.sv"
    log_file = Path(src_dir) / "logs" / f"transcript_{round_id}.log"
    cmd = ["python3", str(sim_py), "--src-dir", str(src_dir), "--top", top,
           "--aes", aes, "--tb", tb, "--log-file", str(log_file)]
    print(">>", " ".join(cmd))
    rc = subprocess.run(cmd, cwd=str(src_dir), text=True).returncode
    return rc

# ---------------- Main Execution Loop ----------------
def main():
    ap = argparse.ArgumentParser(description="Iterative LLM->SV->Questa repair loop.")
    ap.add_argument("--x", type=int, required=True, help="X value (e.g., 2)")
    ap.add_argument("--rounds", type=int, required=True, help="Number of repair rounds (q)")
    ap.add_argument("--aes-dir", default="", help="C++ source dir (Default: ROOT/aesc/csplit/aescX)")
    ap.add_argument("--vsplit-dir", default="", help="vsplit root dir")
    args = ap.parse_args()

    x = args.x
    q = args.rounds

    aesv_dir = Path(".").resolve()
    if args.vsplit_dir:
        vsplit_dir = Path(args.vsplit_dir).resolve()
    else:
        vsplit_dir = find_ancestor_named(aesv_dir, "vsplit")
    root_dir = detect_root_from_vsplit(vsplit_dir)
    aes_dir = Path(args.aes_dir).resolve() if args.aes_dir else root_dir / "aesc" / "csplit" / f"aesc{x}"

    print(f"[PATH] aesv_dir   = {aesv_dir}")
    print(f"[PATH] vsplit_dir = {vsplit_dir}")
    print(f"[PATH] root_dir   = {root_dir}")
    print(f"[PATH] aes_dir    = {aes_dir}")

    base_tb = aesv_dir / f"test{x}.sv"
    if not base_tb.exists():
        raise SystemExit(f"[ERROR] Missing base testbench: {base_tb}")
    sim_py = aesv_dir / "sim.py"
    if not sim_py.exists():
        raise SystemExit(f"[ERROR] Missing sim.py driver: {sim_py}")

    if not (aes_dir / f"aes{x}.h").exists() or not (aes_dir / f"aes{x}.cpp").exists():
        raise SystemExit(f"[ERROR] Source files missing in {aes_dir}. Verify --aes-dir.")

    last_compile_pass = None
    last_sim_status = None
    final_pass = False
    final_round = 0
    per_round_lines = []

    for r in range(1, q+1):
        # 1) Setup per-round testbench
        tb_r = aesv_dir / f"test{x}_{r}.sv"
        transform_testbench_for_round(base_tb, tb_r, x, r)

        # 2) Construct Prompt
        prompt = build_prompt(x, aes_dir=aes_dir, aesv_dir=aesv_dir, vsplit_dir=vsplit_dir)
        if r > 1:
            prompt += "\n\n" + build_fix_context(
                x, r-1, aesv_dir=aesv_dir,
                prev_compile_pass=bool(last_compile_pass),
                prev_sim_status=last_sim_status or "UNKNOWN",
                include_aes_code=True
            )
            prompt += "\nFix the SystemVerilog based on the feedback above. Prioritize syntax/ports if compile failed; fix logic/protocol if sim failed. **Return the corrected SystemVerilog only**."

        # 3) LLM Inference & File Write
        raw = llm_once(prompt, out_dir=aesv_dir, round_id=r, x=x)
        aes_r = aesv_dir / f"aes{x}_{r}.sv"
        write_aes_from_llm_output(raw, aes_path=aes_r, x=x, round_id=r)

        # 4) Questa Simulation
        rc = run_sim(sim_py=sim_py, src_dir=aesv_dir, x=x, round_id=r)

        # 5) Analyze Results
        transcript_r = aesv_dir / "logs" / f"transcript_{r}.log"
        compile_pass = compile_pass_from_transcript(transcript_r)

        report_r = aesv_dir / f"report_{r}.txt"
        sim_result = parse_global_result(report_r) if compile_pass else "UNKNOWN"
        if compile_pass and sim_result == "UNKNOWN":
            sim_result = "FAIL" # Compile ok, but sim crashed/didn't report

        sim_pass = (sim_result == "PASS")

        # Cache state for next round
        last_compile_pass = compile_pass
        last_sim_status = sim_result
        per_round_lines.append(f"round={r}, compile={'PASS' if compile_pass else 'FAIL'}, sim={sim_result}")

        # Termination condition
        if compile_pass and sim_pass and rc == 0:
            final_pass = True
            final_round = r
            print(f"[ROUND {r}] Status: Compile PASS | Sim PASS")
            break
        else:
            print(f"[ROUND {r}] Status: Compile {'PASS' if compile_pass else 'FAIL'} | Sim {sim_result}")

    # Summary Generation
    summary = {
        "x": x,
        "rounds_planned": q,
        "rounds_run": final_round if final_round else q,
        "final_pass": final_pass,
        "final_round": final_round,
        "final_compile": 'PASS' if (last_compile_pass is True) else 'FAIL',
        "final_sim": last_sim_status or 'UNKNOWN',
    }
    write_text(aesv_dir / "summary.json", json.dumps(summary, indent=2, ensure_ascii=False))

    # Log to final report{X}_{q}.txt
    final_report_name = aesv_dir / f"report{x}_{q}.txt"
    final_lines = per_round_lines + [
        f"ROUNDS_PLANNED: {q}",
        f"ROUNDS_RUN: {summary['rounds_run']}",
        f"FINAL_COMPILE: {summary['final_compile']}",
        f"FINAL_SIM: {summary['final_sim']}",
        f"FINAL_PASS: {'PASS' if final_pass else 'FAIL'}"
    ]
    write_text(final_report_name, "\n".join(final_lines) + "\n")

    print("=== SUMMARY ===")
    print(json.dumps(summary, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()