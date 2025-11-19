"""
Round 3: Generate test{i}.cpp for each module, and output a 6-line verification report txt.
Input: Under AES_BASE, each aes{i}/aes{i}.h, aes{i}.cpp
Output: Add test{i}.cpp to each subdirectory. After running, it must output report.txt containing 6 lines:
  Line 1: GLOBAL_CHECK: PASS/FAIL
  Line 2-6: LOCAL_CHECK1..5: PASS/FAIL; followed by Input: ..., Actual Output: ..., Golden Output: ...
Also save round3_prompt.txt and round3_output.txt
"""
# -*- coding: utf-8 -*-

import os, re, json, argparse, subprocess, shutil, sys
from datetime import datetime

# ---------------------- Path Configuration (modify if needed) ----------------------
CSPLIT_DIR = "/nas"
AES_BASE   = "/nas"

# Round output: store round{N}_prompt.txt and round{N}_output.txt under CSPLIT_DIR
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

# ---------------------- LLM Invocation Wrapper ----------------------
def call_llm_chat(messages, model="gpt"):
    try:
        from openai import OpenAI
        client = OpenAI()
        resp = client.chat.completions.create(model=model, messages=messages)
        return resp.choices[0].message.content
    except Exception as e:
        try:
            import requests
            api_base = os.environ.get("OPENAI_BASE_URL", "https://api.openai.com")
            api_key  = os.environ.get("OPENAI_API_KEY", "")
            if not api_key:
                raise RuntimeError("Missing OPENAI_API_KEY environment variable.")
            headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
            payload = {"model": model, "messages": messages}
            url = api_base.rstrip("/") + "/v1/chat/completions"
            r = requests.post(url, headers=headers, json=payload)
            r.raise_for_status()
            data = r.json()
            return data["choices"][0]["message"]["content"]
        except Exception as e2:
            print("[ERROR] LLM invocation failed:", e2)
            raise

# ---------------------- LLM Output Parsing ----------------------
FILE_BLOCK_PATTERN = re.compile(r"<FILE:(?P<path>[^>]+)>\n(?P<body>.*?)\n</FILE>", re.DOTALL)

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
    print(f"[{timestamp()}] Saved prompt and output for round{round_id} to {CSPLIT_DIR}.")

def collect_module_sources():
    mods = []
    for name in sorted(os.listdir(AES_BASE)):
        m = re.match(r"aes(\d+)$", name)
        if m:
            mid = int(m.group(1))
            folder = os.path.join(AES_BASE, name)
            h = os.path.join(folder, f"aes{mid}.h")
            c = os.path.join(folder, f"aes{mid}.cpp")
            if os.path.exists(h) and os.path.exists(c):
                mods.append((mid, folder, h, c))
    return mods

def build_prompt(mods):
    system = {
        "role":"system",
        "content":"You are a senior C++ and algorithm verification engineer. For each module, generate a self-contained testbench that must call aes{id}_top()."
    }

    parts = []
    for mid, folder, h, c in mods:
        parts.append(
            f"===== MODULE {mid} BEGIN =====\n"
            f"// PATH: {folder}\n"
            f"// HEADER: {h}\n{read_file(h)}\n\n"
            f"// SOURCE: {c}\n{read_file(c)}\n"
            f"===== MODULE {mid} END ====="
        )
    modules_blob = "\n\n".join(parts)

    user = {
        "role":"user",
        "content": f"""
Please generate a testbench for each module. The output filename must be aes{{id}}/test{{id}}.cpp.
**Strictly use the following multi-file marking format**:
<FILE:aes{{id}}/test{{id}}.cpp>
// C++11 single-file compilable testbench
// Requirements:
// 1) Include the local aes{{id}}.h (or declare needed prototypes). Do NOT include aes{{id}}.cpp, since the compiler will compile it separately.
// 2) **Call the entry function aes{{id}}_top(...)** to run 5 deterministic test cases (LOCAL_CHECK1..5).
// 3) Compute actual output vs golden output.
// 4) Write into "report.txt" exactly 6 lines:
//    Line 1: GLOBAL_CHECK: PASS or FAIL
//    Line 2-6: LOCAL_CHECKk: PASS/FAIL, Input: ..., Actual Output: ..., Golden Output: ...
// 5) main() must return 0.
</FILE>

Notes:
// - Provide a **fully compilable** implementation, not pseudocode.
// - Output filenames and relative paths must strictly match.
// - All testbench output must be written to "report.txt".

Below are the module sources:
{modules_blob}
""".strip()
    }
    return [system, user]

def main():
    ensure_dirs()
    mods = collect_module_sources()
    if not mods:
        print("[ERROR] No aesX submodule sources found. Please run Round 2 first.")
        sys.exit(1)

    messages = build_prompt(mods)
    prompt_txt = "\n\n".join([m["content"] for m in messages if m["role"] != "system"])
    output = call_llm_chat(messages)
    save_round_io(3, prompt_txt, output)

    blocks = parse_file_blocks(output)
    if not blocks:
        print("[ERROR] No <FILE:...> blocks parsed. Please check the LLM output.")
        sys.exit(2)

    write_blocks_to_disk(blocks, AES_BASE)
    print(f"[{timestamp()}] Testbenches generated by LLM have been written to {AES_BASE}.")

if __name__ == "__main__":
    main()
