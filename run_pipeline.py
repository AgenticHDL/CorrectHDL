
"""
Top-level script: execute pipeline pre 1–5 either sequentially or selectively.

Examples:
  python3 run_pipeline.py                 # run pre 1..5
  python3 run_pipeline.py --pre 2       # only pre 2
  python3 run_pipeline.py --pre 2 3     # run pre 2 and 3
  python3 run_pipeline.py --from 3        # run pre 3..5
  python3 run_pipeline.py --to 4          # run pre 1..4
"""
import os, sys, subprocess, argparse

SCRIPTS = {
    1: "step1_decompose.py",
    2: "step2_generate_modules.py",
    3: "step3_tb_veri.py",
    4: "step4_compile_submodules.py",
    5: "step5_concat_and_test.py",
}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--pre",
        nargs="*",
        type=int,
        help="Run only these pre (empty means using --from/--to)"
    )
    parser.add_argument(
        "--from",
        dest="from_step",
        type=int,
        default=1,
        help="Start pre (default 1)"
    )
    parser.add_argument(
        "--to",
        dest="to_step",
        type=int,
        default=5,
        help="End pre (default 5)"
    )
    args = parser.parse_args()

    if args.pre:
        pre = sorted(set(args.pre))
    else:
        pre = list(range(args.from_step, args.to_step + 1))

    here = os.path.dirname(os.path.abspath(__file__))

    for s in pre:
        script = SCRIPTS.get(s)
        if not script:
            print(f"[WARN] Skip unknown pre {s}")
            continue
        path = os.path.join(here, script)
        if not os.path.exists(path):
            print(f"[ERROR] Script not found: {path}")
            sys.exit(1)
        print(f"\n=== Running pre {s}: {script} ===\n")
        code = subprocess.call([sys.executable, path])
        if code != 0:
            print(f"[WARN] pre {s} returned exit code: {code} (you may fix and retry)")

if __name__ == "__main__":
    main()
