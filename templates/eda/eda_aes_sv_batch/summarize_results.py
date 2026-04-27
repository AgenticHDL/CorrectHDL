#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Standalone summary script: reads overall_summary.json and prints statistics.
"""
import json
from pathlib import Path

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--summary", required=True, help="Path to overall_summary.json")
    args = ap.parse_args()
    
    p = Path(args.summary)
    if not p.exists():
        raise SystemExit(f"[ERROR] File not found: {p}")
        
    # Read and parse JSON summary data
    data = json.loads(p.read_text(encoding="utf-8", errors="ignore"))
    
    # Print the full raw data for detail
    print(json.dumps(data, indent=2, ensure_ascii=False))
    
    # Print a quick summary of trial results
    print(f"Total trials p = {data.get('p')}, rounds q = {data.get('q')}, pass count = {data.get('pass_cnt')}")

if __name__ == "__main__":
    main()