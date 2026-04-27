"""
- Robust Questa transcript parsing: strictly separates "true errors" from noise.
- Compilation status: determined by Errors > 0 in vlog blocks and (vlog-*) fatal patterns.
- Simulation status: determined by GLOBAL_CHECK in the generated report_{r}.txt.
- Feature: extract_vsim_errors_full() provides complete context for vsim failures 
  (includes vopt-7033, Optimization failed, # Errors: N, etc.)
"""
from pathlib import Path
import re
import shutil
import subprocess
from typing import List

def read_text(p: Path) -> str:
    return Path(p).read_text(encoding="utf-8", errors="ignore")

def write_text(p: Path, s: str) -> None:
    p = Path(p)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding="utf-8")

def copy_files(src_dir: Path, dst_dir: Path, names: List[str]) -> None:
    src_dir = Path(src_dir)
    dst_dir = Path(dst_dir)
    dst_dir.mkdir(parents=True, exist_ok=True)
    for n in names:
        s = src_dir / n
        if not s.exists():
            raise FileNotFoundError(f"Source file not found: {s}")
    for n in names:
        shutil.copy2(src_dir / n, dst_dir / n)

def ensure_dir(d: Path) -> None:
    Path(d).mkdir(parents=True, exist_ok=True)

def run_cmd(cmd: list, cwd: Path = None, env: dict = None) -> int:
    print(">>", " ".join(map(str, cmd)))
    r = subprocess.run(cmd, cwd=str(cwd) if cwd else None, env=env, text=True)
    return r.returncode

# -------- Testbench round adaptation --------
def transform_testbench_for_round(base_sv: Path, out_sv: Path, x: int, round_id: int) -> None:
    """
    Generates testX_{round_id}.sv based on testX.sv:
    - Top module remains topX.
    - Redirects report output: $fopen("report.txt","w") -> $fopen("report_{round_id}.txt","w")
    - Keeps all other content intact.
    """
    s = read_text(base_sv)
    s = re.sub(
        r'(\$fopen\(\s*")report\.txt("\s*,\s*"w"\s*\))',
        rf'\1report_{round_id}.txt\2',
        s
    )
    write_text(out_sv, s)

# -------- LLM output splitting --------
def split_sv_blocks_from_llm_output(raw: str, x: int, round_id: int):
    idx = raw.lower().find(f"module top{x}".lower())
    if idx <= 0:
        return (raw.strip(), "")
    return raw[:idx].strip(), raw[idx:].strip()

# -------- Transcript analysis (robust) --------
# Captures strictly fatal patterns; ignores (vdel-*) and ** Note/** Warning
ERROR_PATTERNS = [
    r"#\s*\*\*\s*Error\b(?!.*\(vdel-\d+\))",  # True ** Error, excluding vdel to suppress cleanup noise
    r"#\s*Error loading design\b",            # vsim load failure (with #)
    r"(^|\s)Error loading design\b",          # vsim load failure (without #)
    r"#\s*Error in macro\b",                  # Tcl macro execution error
    r"\bFatal:\b",                            # Fatal runtime error
]

def _is_note_or_warning(s: str) -> bool:
    return bool(re.search(r"\b\*\*\s*Note\b", s) or re.search(r"\b\*\*\s*Warning\b", s))

def grep_errors_from_transcript(transcript_path: Path) -> str:
    """
    Line-level: Captures specific failure info to determine if compile/sim failed.
    Rules:
      - Start counting only after vlog/vsim headers (skips preceding setup/vdel noise).
      - Ignore ** Note / ** Warning.
      - Ignore (vdel-XX).
      - Include '# Errors: N' only if N > 0.
    """
    if not Path(transcript_path).exists():
        return ""

    lines = read_text(transcript_path).splitlines()
    picked = []
    started = False  # Set to True once vlog/vsim phase starts

    for ln in lines:
        s = ln.strip()

        # Mark analysis start
        if (re.search(r"^\#\s*vlog\s+-lint\b", s)
            or re.search(r"^\#\s*vsim\s+-c\b", s)
            or re.search(r"^\#\s*QuestaSim-.*\s+vlog", s)):
            started = True

        if not started:
            continue

        if _is_note_or_warning(s):
            continue

        if re.search(r"\(vdel-\d+\)", s):
            continue

        # Log '# Errors: N' as an error only if N > 0
        m = re.search(r"#\s*Errors:\s*(\d+)", s)
        if m:
            if int(m.group(1)) > 0:
                picked.append(ln)
            continue

        # Catch true error lines (allows "Error (suppressible)" etc.)
        if any(re.search(p, s) for p in ERROR_PATTERNS):
            picked.append(ln)

        # Include critical vopt errors (e.g., (vopt-2064)) for debugging
        if re.search(r"\(vopt-\d+\)", s) and re.search(r"\b\*\*\s*Error\b", s):
            picked.append(ln)

    return "\n".join(picked)

def extract_blocks(transcript_path: Path) -> dict:
    """
    Block-level: Extracts full text of compilation and simulation blocks.
    Returns:
    {
      "vlog_blocks": [ {"cmd": "vlog -lint ...", "text": "...full block..."}, ... ],
      "vsim_blocks": [ {"cmd": "vsim -c ...", "text": "...full block..."} ],
      "from_ifc_anchor": "Text from interface compilation anchor to EOF."
    }
    """
    res = {"vlog_blocks": [], "vsim_blocks": [], "from_ifc_anchor": ""}
    if not Path(transcript_path).exists():
        return res
    text = read_text(transcript_path)
    lines = text.splitlines()

    # 1) vlog blocks
    i = 0
    n = len(lines)
    while i < n:
        if re.search(r"^\#\s*vlog\s+-lint\b", lines[i]):
            start = i
            cmd_line = lines[i]
            i += 1
            while i < n and not re.search(r"^\#\s*End time:.*Elapsed time:.*", lines[i]):
                if re.search(r"^\#\s*vlog\s+-lint\b", lines[i]) or re.search(r"^\#\s*vsim\s+-c\b", lines[i]):
                    break
                i += 1
            if i < n and re.search(r"^\#\s*End time:.*Elapsed time:.*", lines[i]):
                i += 1
                if i < n and re.search(r"^\#\s*Errors:\s*\d+,\s*Warnings:\s*\d+", lines[i]):
                    i += 1
            block = "\n".join(lines[start:i])
            res["vlog_blocks"].append({"cmd": cmd_line.strip(), "text": block})
        else:
            i += 1

    # 2) vsim blocks
    i = 0
    while i < n:
        if re.search(r"^\#\s*vsim\s+-c\b", lines[i]):
            start = i
            cmd_line = lines[i]
            i += 1
            while i < n and not re.search(r"^\#\s*End time:.*Elapsed time:.*", lines[i]):
                i += 1
            if i < n and re.search(r"^\#\s*End time:.*Elapsed time:.*", lines[i]):
                i += 1
                if i < n and re.search(r"^\#\s*Errors:\s*\d+,\s*Warnings:\s*\d+", lines[i]):
                    i += 1
            block = "\n".join(lines[start:i])
            res["vsim_blocks"].append({"cmd": cmd_line.strip(), "text": block})
        else:
            i += 1

    # 3) Interface anchor
    anchor_idx = None
    for idx, ln in enumerate(lines):
        if "# -- Compiling interface standard_stream_if" in ln:
            anchor_idx = idx
            break
    if anchor_idx is not None:
        res["from_ifc_anchor"] = "\n".join(lines[anchor_idx:])

    return res

def compile_pass_from_transcript(transcript_path: Path) -> bool:
    """
    Judge compilation success based solely on vlog blocks:
      - Every vlog block must have 'Errors: 0'.
      - No (vlog-*) patterns marked as ** Error within the block.
    Returns False if no vlog blocks are found.
    """
    if not Path(transcript_path).exists():
        return False
    blocks = extract_blocks(transcript_path).get("vlog_blocks", [])
    if not blocks:
        return False
    for b in blocks:
        txt = b["text"]
        for m in re.finditer(r"#\s*Errors:\s*(\d+)", txt):
            if int(m.group(1)) > 0:
                return False
        for ln in txt.splitlines():
            s = ln.strip()
            if _is_note_or_warning(s) or "(vdel-" in s:
                continue
            if re.search(r"\(vlog-\d+\)", s) and re.search(r"#\s*\*\*\s*Error\b", s):
                return False
    return True

def vsim_started_from_transcript(transcript_path: Path) -> bool:
    if not Path(transcript_path).exists():
        return False
    text = read_text(transcript_path)
    return bool(re.search(r"^\#\s*vsim\s+-c\b", text, flags=re.M) or re.search(r"Loading\s+work\.", text))

def analyze_transcript(transcript_path: Path) -> dict:
    """
    Structural status + Error summary. Strictly validated to prevent false positives.
    Used for debug printing and providing context for the repair loop.
    """
    out = {
        "compile_errors": False,
        "sim_errors": False,
        "error_summary": "",
        "vlog_errors": 0,
        "vsim_errors": 0,
        "blocks": extract_blocks(transcript_path),
    }
    if not Path(transcript_path).exists():
        return out

    comp_pass = compile_pass_from_transcript(transcript_path)
    out["compile_errors"] = (not comp_pass)

    err_lines = grep_errors_from_transcript(transcript_path).splitlines()
    out["error_summary"] = "\n".join(err_lines)

    for blk in out["blocks"]["vlog_blocks"]:
        for m in re.finditer(r"#\s*Errors:\s*(\d+)", blk["text"]):
            n = int(m.group(1))
            if n > 0:
                out["vlog_errors"] += n
    for blk in out["blocks"]["vsim_blocks"]:
        for m in re.finditer(r"#\s*Errors:\s*(\d+)", blk["text"]):
            n = int(m.group(1))
            if n > 0:
                out["vsim_errors"] += n
                out["sim_errors"] = True
    return out

def extract_vsim_errors_full(transcript_path: Path) -> str:
    """
    Extracts high-utility error context from vsim blocks for LLM feedback:
      - Includes the start command: '# vsim -c ...'
      - Includes ** Error, (vopt-XXXX), and 'Optimization failed'.
      - Includes 'Error loading design' variants.
      - Includes non-zero Error/Warning counts.
      - Includes standard vsim markers (e.g., vsim-3812) to preserve context.
      - Ends at '# End time: ...'
    """
    if not Path(transcript_path).exists():
        return "(Transcript log not found)"

    lines = read_text(transcript_path).splitlines()
    out = []
    in_vsim = False

    for ln in lines:
        s = ln

        if re.search(r"^\#\s*vsim\s+-c\b", s):
            in_vsim = True
            out.append(ln)
            continue

        if not in_vsim:
            continue

        if re.search(r"^\#\s*End time:.*Elapsed time:", s):
            out.append(ln)
            break

        if re.search(r"#\s*\*\*\s*Error\b", s):
            out.append(ln)
            continue

        if re.search(r"\(vopt-\d+\)", s):
            out.append(ln)
            continue

        if "Optimization failed" in s:
            out.append(ln)
            continue

        if re.search(r"(^|\s)#?\s*Error loading design\b", s):
            out.append(ln)
            continue

        if re.search(r"\(vsim-\d+\)", s):
            out.append(ln)
            continue

        m = re.search(r"#\s*Errors:\s*(\d+)", s)
        if m and int(m.group(1)) > 0:
            out.append(ln)
            continue

    return "\n".join(out) if out else "(No vsim errors detected)"

def parse_global_result(report_path: Path) -> str:
    if not Path(report_path).exists():
        return "UNKNOWN"
    first = read_text(report_path).splitlines()[0].strip().upper()
    return "PASS" if "PASS" in first else "FAIL" if "FAIL" in first else "UNKNOWN"