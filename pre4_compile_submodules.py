"""
Round 4: Copy and modify compileh.py into each aesX directory, then execute
them sequentially to perform submodule testing.

Inputs:
    AES_BASE/compileh.py + each aesX/aesX.h|.cpp + testX.cpp
Outputs:
    The copied and patched compileh.py inside each aesX directory,
    and the serialized execution of its test flow.

(No LLM invocation in this round, so we do NOT generate
 round4_prompt.txt / round4_output.txt.)
"""
# -*- coding: utf-8 -*-

import os, re, json, argparse, subprocess, shutil, sys
from datetime import datetime

# ---------------------- Path Configuration (modify if needed) ----------------------
CSPLIT_DIR = "/nas"
AES_BASE   = "/nas"

# Round outputs: will save round{N}_prompt.txt and round{N}_output.txt under CSPLIT_DIR
def ensure_dirs():
    os.makedirs(CSPLIT_DIR, exist_ok=True)
    os.makedirs(AES_BASE, exist_ok=True)

def read_file(path):
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        return f.read()

def write_text(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def timestamp():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# ---------------------- LLM Call Wrapper ----------------------
# Uses OpenAI Chat Completions API with model "gpt-5-mini".
# Does not explicitly set temperature or timeout.
def call_llm_chat(messages, model="gpt-5-mini"):
    try:
        # Try official SDK first
        from openai import OpenAI
        client = OpenAI()
        resp = client.chat.completions.create(model=model, messages=messages)
        return resp.choices[0].message.content
    except Exception as e:
        # Fallback to HTTP
        try:
            import requests
            api_base = os.environ.get("OPENAI_BASE_URL", "https://api.openai.com")
            api_key  = os.environ.get("OPENAI_API_KEY", "")
            if not api_key:
                raise RuntimeError("Missing OPENAI_API_KEY environment variable.")
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            }
            payload = {"model": model, "messages": messages}
            url = api_base.rstrip("/") + "/v1/chat/completions"
            r = requests.post(url, headers=headers, json=payload)
            r.raise_for_status()
            data = r.json()
            return data["choices"][0]["message"]["content"]
        except Exception as e2:
            print("[ERROR] LLM invocation failed:", e2)
            raise

FILE_BLOCK_PATTERN = re.compile(
    r"<FILE:(?P<path>[^>]+)>\n(?P<body>.*?)\n</FILE>",
    re.DOTALL
)

def parse_file_blocks(text):
    files = []
    for m in FILE_BLOCK_PATTERN.finditer(text):
        rel_path = m.group("path").strip()
        body     = m.group("body")
        files.append((rel_path, body))
    return files

def write_blocks_to_disk(blocks, root_dir):
    for rel_path, body in blocks:
        dest = os.path.join(root_dir, rel_path)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, "w", encoding="utf-8") as f:
            f.write(body)

def save_round_io(round_id, prompt, output):
    ensure_dirs()
    write_text(os.path.join(CSPLIT_DIR, f"round{round_id}_prompt.txt"), prompt)
    write_text(os.path.join(CSPLIT_DIR, f"round{round_id}_output.txt"), output)
    print(f"[{timestamp()}] Saved round{round_id} prompt and output to {CSPLIT_DIR}.")

# ---------------------- AES Module Discovery ----------------------
def collect_module_folders():
    mods = []
    for name in sorted(os.listdir(AES_BASE)):
        m = re.match(r"aes(\d+)$", name)
        if m and os.path.isdir(os.path.join(AES_BASE, name)):
            mods.append((int(m.group(1)), os.path.join(AES_BASE, name)))
    return mods

# ---------------------- compileh.py Rewriting ----------------------
def patch_compileh(src_text, mid):
    repl = src_text
    repl = repl.replace("aes.h",   f"aes{mid}.h")
    repl = repl.replace("aes.cpp", f"aes{mid}.cpp")
    repl = repl.replace("test.cpp", f"test{mid}.cpp")
    return repl

def ensure_top_pragma(mid, cpp_path):
    txt = read_file(cpp_path)
    if "#pragma hls_design top" in txt:
        return

    pattern = re.compile(rf"(^|\n)([^\n]*\b)aes{mid}_top\s*\(", re.MULTILINE)
    m = pattern.search(txt)

    if not m:
        print(f"[WARN] aes{mid}_top definition not found; cannot auto-insert pragma. Please check: {cpp_path}")
        return

    start = m.start(2)
    new_txt = txt[:start] + "#pragma hls_design top\n" + txt[start:]
    write_text(cpp_path, new_txt)

    print(f"[INFO] Auto-inserted '#pragma hls_design top' into aes{mid}.cpp.")

# ---------------------- Main Flow ----------------------
def main():
    ensure_dirs()

    compile_src_path = os.path.join(AES_BASE, "compileh.py")
    if not os.path.exists(compile_src_path):
        print(f"[ERROR] {compile_src_path} not found.")
        sys.exit(1)

    src = read_file(compile_src_path)

    mods = collect_module_folders()
    if not mods:
        print("[ERROR] No aesX directories found.")
        sys.exit(2)

    # Patch and write compileh.py for each AES module
    for mid, folder in mods:
        dst = os.path.join(folder, "compileh.py")
        patched = patch_compileh(src, mid)
        write_text(dst, patched)

        cpp_path = os.path.join(folder, f"aes{mid}.cpp")
        if os.path.exists(cpp_path):
            ensure_top_pragma(mid, cpp_path)

        print(f"[{timestamp()}] Written and updated: {dst}")

    # Sequential execution of submodule tests
    for mid, folder in mods:
        print(f"[{timestamp()}] Running {folder}/compileh.py ...")
        try:
            subprocess.run([sys.executable, "compileh.py"], cwd=folder, check=True)
        except subprocess.CalledProcessError as e:
            print(f"[WARN] Submodule aes{mid} test script returned non-zero: {e.returncode}. Check logs before continuing.")
        print(f"[{timestamp()}] Finished aes{mid}.")

if __name__ == "__main__":
    main()
