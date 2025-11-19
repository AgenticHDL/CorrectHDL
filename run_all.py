import argparse, subprocess, sys
from pathlib import Path
from config import VSPLIT_DIR
def run_py(path: Path):
    print(f"==> python {path.name}")
    r = subprocess.run([sys.executable, str(path)], cwd=VSPLIT_DIR)
    if r.returncode != 0: sys.exit(r.returncode)
def list_s4():
    return sorted([p for p in VSPLIT_DIR.iterdir() if p.name.startswith("s4_aes") and p.suffix == ".py"],
                  key=lambda p: int(p.stem.split("aes")[1]))
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only-s", type=int, choices=[1,2,3,5])
    ap.add_argument("--round", type=int)
    ap.add_argument("--start-round", type=int)
    ap.add_argument("--end-round", type=int)
    args = ap.parse_args()
    s1 = VSPLIT_DIR / "s1_interface_setup.py"
    s2 = VSPLIT_DIR / "s2_generate_specs.py"
    s3 = VSPLIT_DIR / "s3_prepare_sim.py"
    s5 = VSPLIT_DIR / "s5_concat_and_test.py"
    if args.only_s:
        if args.only_s == 1: run_py(s1)
        elif args.only_s == 2: run_py(s2)
        elif args.only_s == 3: run_py(s3)
        elif args.only_s == 5: run_py(s5)
        return
    run_py(s1); run_py(s2); run_py(s3)
    if args.round:
        k = args.round; target = VSPLIT_DIR / f"s4_aes{k}.py"
        if not target.exists():
            print(f"s4_aes{k}.py 不存在", file=sys.stderr); sys.exit(2)
        run_py(target)
    else:
        s4s = list_s4()
        if args.start_round or args.end_round:
            sr = args.start_round or int(s4s[0].stem.split("aes")[1])
            er = args.end_round or int(s4s[-1].stem.split("aes")[1])
            for x in range(sr, er+1):
                run_py(VSPLIT_DIR / f"s4_aes{x}.py")
        else:
            for p in list_s4(): run_py(p)
    run_py(s5)
if __name__ == "__main__":
    main()
