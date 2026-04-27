#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Batch experiment script:
- Create p experiment folders:
    /exp/aes/aesv/vsplit/aesv1/aesvX_1 ... aesvX_p
- Copy testX.sv, sim.py, specX.md from the source directory
    /exp/aes/aesv/vsplit/aesvX
  into each experiment folder
- Copy the updated stage4_aesX_p.py into each experiment folder
- Automatically modify DEFAULT_SRC_DIR in sim.py to point to the current folder
- Run stage4_aesX_p.py --x X --rounds q inside each experiment folder
- Count the number of PASS results among the p experiments
"""

import argparse
import json
import shutil
import subprocess
from pathlib import Path
import sys, os

sys.path.append(os.path.dirname(__file__))

from utils import ensure_dir, copy_files, read_text, write_text


def patch_sim_srcdir(sim_path: Path, new_src_dir: Path):
    """Modify DEFAULT_SRC_DIR inside sim.py to new_src_dir"""
    s = read_text(sim_path)
    s = s.replace(
        'DEFAULT_SRC_DIR = ""',
        f'DEFAULT_SRC_DIR = "{str(new_src_dir)}"'
    )
    write_text(sim_path, s)


def main():
    ap = argparse.ArgumentParser(
        description="Batch create p experiment directories and run q LLM repair rounds in each"
    )
    ap.add_argument("--p", type=int, required=True,
                    help="Number of experiment folders")
    ap.add_argument("--q", type=int, required=True,
                    help="Number of LLM repair rounds per folder")
    ap.add_argument("--x", type=int, required=True,
                    help="X value (e.g., 2)")
    ap.add_argument("--source", required=True,
                    help="Source directory, e.g., /exp/aes/aesv/vsplit/aesvX")
    ap.add_argument("--target-root", required=True,
                    help="Target root directory, e.g., /exp/aes/aesv/vsplit/aesv1")
    ap.add_argument("--aes-dir", default="",
                    help="Optional: C++ source directory (passed to child script)")
    ap.add_argument("--vsplit-dir", default="",
                    help="Optional: vsplit root directory (passed to child script)")
    args = ap.parse_args()

    p, q, x = args.p, args.q, args.x
    source = Path(args.source).resolve()
    target_root = Path(args.target_root).resolve()

    # Check required files
    required_files = [f"test{x}.sv", f"spec{x}.md"]
    for name in required_files:
        if not (source / name).exists():
            raise SystemExit(f"[ERROR] Missing required file in source directory: {source / name}")

    # Locate sim.py
    sim_src = source / "sim.py"
    if not sim_src.exists():
        sim_src = Path(__file__).resolve().parent / "sim.py"
        if not sim_src.exists():
            raise SystemExit("[ERROR] sim.py not found")

    # Locate stage4 script
    stage4_src = Path(__file__).resolve().parent / "stage4_aesX_p.py"
    if not stage4_src.exists():
        raise SystemExit("[ERROR] stage4_aesX_p.py not found")

    # Locate utils and llm_utils
    utils_src = Path(__file__).resolve().parent / "utils.py"
    llm_utils_src = Path(__file__).resolve().parent / "llm_utils.py"

    # Create experiment directories
    created_dirs = []
    for i in range(1, p + 1):
        exp_dir = target_root / f"aesvX_{i}"
        ensure_dir(exp_dir)

        # Copy required SV and spec files
        copy_files(source, exp_dir, [f"test{x}.sv", f"spec{x}.md"])

        # Copy and patch sim.py
        shutil.copy2(sim_src, exp_dir / "sim.py")
        patch_sim_srcdir(exp_dir / "sim.py", exp_dir)

        # Copy stage4 script
        shutil.copy2(stage4_src, exp_dir / "stage4_aesX_p.py")

        # Copy utils.py
        if utils_src.exists():
            shutil.copy2(utils_src, exp_dir / "utils.py")

        # Copy config.py
        config_src = Path(__file__).resolve().parent / "config.py"
        if config_src.exists():
            shutil.copy2(config_src, exp_dir / "config.py")

        # Copy llm_utils.py
        if llm_utils_src.exists():
            shutil.copy2(llm_utils_src, exp_dir / "llm_utils.py")

        created_dirs.append(exp_dir)

    # Execute experiments
    pass_count = 0
    results = []

    for i, d in enumerate(created_dirs, 1):
        print(f"================= [RUN {i}/{p}] {d} =================")

        cmd = [
            "python3",
            "stage4_aesX_p.py",
            "--x", str(x),
            "--rounds", str(q)
        ]

        if args.aes_dir:
            cmd.extend(["--aes-dir", str(Path(args.aes_dir).resolve())])

        if args.vsplit_dir:
            cmd.extend(["--vsplit-dir", str(Path(args.vsplit_dir).resolve())])

        rc = subprocess.run(cmd, cwd=str(d), text=True).returncode

        # Read summary.json
        summary_path = d / "summary.json"
        if summary_path.exists():
            summary_data = json.loads(summary_path.read_text(encoding="utf-8"))
            results.append(summary_data)
            if summary_data.get("final_pass"):
                pass_count += 1
        else:
            results.append({
                "dir": str(d),
                "final_pass": False,
                "note": "summary.json not found"
            })

    # Overall summary
    overall = {
        "p": p,
        "q": q,
        "x (No. of Submodule)": x,
        "pass_count": pass_count,
        "results": results,
    }

    out_path = target_root / "overall_summary.json"
    out_path.write_text(
        json.dumps(overall, indent=2, ensure_ascii=False),
        encoding="utf-8"
    )

    print("============= OVERALL SUMMARY =============")
    print(json.dumps(overall, indent=2, ensure_ascii=False))
    print(f"[INFO] Saved to: {out_path}")


if __name__ == "__main__":
    main()