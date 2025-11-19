#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Round 2: Generate C++ submodule files based on module decomposition.
Input: CSPLIT_DIR/module_decomposition.txt + AES_BASE/aes.cpp
Output: Create aes1, aes2, ... subfolders under AES_BASE and write generated source code.
Also save round2_prompt.txt and round2_output.txt.
"""
# -*- coding: utf-8 -*-
import os, re, json, argparse, subprocess, shutil, sys
from datetime import datetime

# ---------------------- Path configurations (modify as needed) ----------------------
CSPLIT_DIR = "/nas"
AES_BASE   = "/nas"

# Round output: saves round{N}_prompt.txt and round{N}_output.txt under CSPLIT_DIR
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

# ---------------------- LLM call wrapper ----------------------
# Default: OpenAI Chat Completions API
# Temperature and timeout use default settings.
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
                raise RuntimeError("Missing environment variable: OPENAI_API_KEY.")
            headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
            payload = {"model": model, "messages": messages}
            url = api_base.rstrip("/") + "/v1/chat/completions"
            r = requests.post(url, headers=headers, json=payload)
            r.raise_for_status()
            data = r.json()
            return data["choices"][0]["message"]["content"]
        except Exception as e2:
            print("[ERROR] LLM call failed:", e2)
            raise

# ---------------------- LLM output parsing ----------------------
# Force LLM to use this file-block format:
# <FILE:aes1/aes1.h>
# ... file content ...
# </FILE>
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
    print(f"[{timestamp()}] Saved round{round_id} prompt and output to {CSPLIT_DIR}.")

def build_prompt(mod_json, aes_cpp, root_top_name):
    system = {
        "role":"system",
        "content":"You are a senior C++/HLS engineer. Based on a module decomposition plan, extract/refactor standalone compilable C++ submodules from the original aes.cpp. Each module must contain a unique Catapult HLS top function with pragma."
    }

    user = {
        "role":"user",
        "content": f"""
You will generate several C++ submodules based on the following module decomposition JSON and the original aes.cpp.  
Each module must be placed in a separate folder: aes{{id}}/aes{{id}}.h and aes{{id}}/aes{{id}}.cpp.

**Strict output format (per file):**
<FILE:aes{{id}}/aes{{id}}.h>
(file content)
</FILE>
<FILE:aes{{id}}/aes{{id}}.cpp>
(file content)
</FILE>

**Hard requirements:**
- Every module must define a **unique top wrapper** function `aes{{id}}_top(...)`;
- The signature must match JSON field top_function.signature if provided, otherwise follow the main function of that module;
- In `aes{{id}}.cpp`, place `#pragma hls_design top` **exactly one line above** the `aes{{id}}_top` definition;
- **Forbidden** in all modules: declaring/defining/calling `{root_top_name}`;
- Declare `aes{{id}}_top(...)` in the corresponding header;
- Header must have include guards, C++11-compatible, includes based on JSON field `headers`;
- Declare prototypes for all functions in JSON "functions"; internal helpers may be static or placed in the .cpp;
- Any constants, lookup tables or inline helpers must be kept **inside the module**;
- Any inter-module dependency must be passed explicitly via parameters/returns, no global shared state;
- Combined modules must match the functionality of the original aes.cpp;
- Provide complete compilable implementations — no omissions, no pseudo code.

Below is the module decomposition JSON:
===== module_decomposition.json BEGIN =====
{mod_json}
===== module_decomposition.json END =====

Below is the original aes.cpp:
===== aes.cpp BEGIN =====
{aes_cpp}
===== aes.cpp END =====
""".strip()
    }
    return [system, user]

def main():
    ensure_dirs()
    decomp_path = os.path.join(CSPLIT_DIR, "module_decomposition.txt")
    aes_cpp_path = os.path.join(AES_BASE, "aes.cpp")
    if not os.path.exists(decomp_path) or not os.path.exists(aes_cpp_path):
        print(f"[ERROR] Missing {decomp_path} or {aes_cpp_path}")
        sys.exit(1)

    mod_json = read_file(decomp_path)
    aes_cpp  = read_file(aes_cpp_path)

    root_top_name = "aes256_encrypt_ecb"
    try:
        data = json.loads(mod_json)
        if isinstance(data, dict) and data.get("root_top_function"):
            root_top_name = data["root_top_function"].get("name", root_top_name)
    except Exception:
        pass

    messages = build_prompt(mod_json, aes_cpp, root_top_name)
    prompt_txt = "\n\n".join([m["content"] for m in messages if m["role"] != "system"])
    output = call_llm_chat(messages)
    save_round_io(2, prompt_txt, output)

    blocks = parse_file_blocks(output)
    if not blocks:
        print("[ERROR] No <FILE:...> blocks parsed. Check LLM output.")
        sys.exit(2)

    forbidden = [root_top_name]
    for rel_path, body in blocks:
        for sym in forbidden:
            if re.search(rf"\\b{re.escape(sym)}\\b", body):
                print(f"[ERROR] Forbidden symbol '{sym}' appeared in {rel_path}.")
                sys.exit(3)

    write_blocks_to_disk(blocks, AES_BASE)
    print(f"[{timestamp()}] Generated submodule source files have been written to {AES_BASE}.")

if __name__ == "__main__":
    main()
