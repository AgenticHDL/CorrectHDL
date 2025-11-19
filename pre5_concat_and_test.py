"""
Round 5: Concatenation Integration + Top-Level Verification
1) Call the LLM to generate aes_concat.cpp and test_concat.cpp 
   (reference original test.cpp, fixed output of 6 report lines)
2) Copy and patch compileh.py into aes_concat, then run top-level testing.
Input: AES_BASE with all aesX submodule sources, original test.cpp
Output: AES_BASE/aes_concat directory containing generated sources and logs;
        also save round5_prompt.txt and round5_output.txt.
"""
import os, re, json, argparse, subprocess, shutil, sys
from datetime import datetime

# ---------------------- PATH CONFIGURATION ----------------------
CSPLIT_DIR = "/nas"
AES_BASE   = "/nas"

# Round output files: stored under CSPLIT_DIR as round{N}_prompt.txt and round{N}_output.txt
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

# ---------------------- LLM CALL WRAPPER ----------------------
# Default: OpenAI chat completions with model "gpt-5-mini"
# No explicit temperature or timeout settings.
def call_llm_chat(messages, model="gpt-5-mini"):
    # Prefer official SDK; fallback to HTTP requests
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
            print("[ERROR] LLM call failed:", e2)
            raise

# ---------------------- LLM OUTPUT PARSING ----------------------
# Force the LLM to emit file blocks like:
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
    print(f"[{timestamp()}] Saved prompt/output for round {round_id} to {CSPLIT_DIR}.")

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

def build_prompt(mods, aes_h, aes_cpp, test_cpp, root_top_name, root_top_sig):
    system = {
        "role":"system",
        "content":"You are a senior C++/HLS and AES expert skilled at integrating functional submodules into synthesizable top modules and producing verification testbenches."
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
Please concatenate all the above AES submodules into a single top-level file: aes_concat.cpp.

**The top-level must contain exactly one entry function `aes_concat_top(...)`,**
and the line immediately above it must contain:
    `#pragma hls_design top`

The top-level interface must follow the same signature as the original AES encryption/decryption entry (encrypt(...), aes(...), etc.).  
However, the function name should be **unified to `aes_concat_top`** while preserving the original signature.

aes_concat.cpp should define the **single** top-level function:
   - Name: {root_top_name}
   - Signature: {root_top_sig}

Place `#pragma hls_design top` exactly one line above its definition.  
Inside the function, sequentially call each AES submodule (SubBytes / ShiftRows / MixColumns / AddRoundKey, etc.) to match the original algorithm behavior.

Also generate aes_concat/test_concat.cpp following the style of the original test.cpp.  
Use the same **five test vectors with golden outputs**, producing 6 report lines into "report.txt" (same format as Round 3).

For compatibility with compileh.py:
- Output **ONLY** the following three files using the exact format:
  <FILE:aes_concat.h> ... </FILE>
  <FILE:aes_concat.cpp> ... </FILE>
  <FILE:test_concat.cpp> ... </FILE>
- Source must be self-contained and compilable; include all required headers.
- Do NOT paste the original aes.cpp into the top-level.
- Hardcode golden outputs inside test_concat.cpp.
- Ensure aes_concat.cpp sequentially invokes each submodule to reproduce the original functionality.

Below are the original header/source files and the test file:
===== aes.h BEGIN =====
{aes_h}
===== aes.h END =====

===== aes.cpp BEGIN =====
{aes_cpp}
===== aes.cpp END =====

===== test.cpp BEGIN =====
{test_cpp}
===== test.cpp END =====

Below are all AES submodule sources:
{modules_blob}
"""
    }
    return [system, user]

def ensure_top_pragma_concat(cpp_path, root_top_name):
    txt = read_file(cpp_path)
    if "#pragma hls_design top" in txt:
        return
    pattern = re.compile(rf"(^|\n)([^\n]*\b){re.escape(root_top_name)}\s*\(", re.MULTILINE)
    m = pattern.search(txt)
    if not m:
        print(f"[WARN] Cannot locate definition for {root_top_name}; pragma not inserted: {cpp_path}")
        return
    start = m.start(2)
    new_txt = txt[:start] + "#pragma hls_design top\n" + txt[start:]
    write_text(cpp_path, new_txt)
    print(f"[INFO] Inserted '#pragma hls_design top' into aes_concat.cpp.")

def main():
    ensure_dirs()
    test_cpp_path = os.path.join(AES_BASE, "test.cpp")
    aes_h_path = os.path.join(AES_BASE, "aes.h")
    aes_cpp_path = os.path.join(AES_BASE, "aes.cpp")
    decomp_path = os.path.join(CSPLIT_DIR, "module_decomposition.txt")

    if not all(os.path.exists(p) for p in [test_cpp_path, aes_h_path, aes_cpp_path]):
        print("[ERROR] Missing original aes.h/aes.cpp/test.cpp")
        sys.exit(1)

    # Default top-level function info
    root_top_name = "aes256_encrypt_ecb"
    root_top_sig  = "void aes256_encrypt_ecb(...)"

    # Optional: override from module_decomposition
    try:
        data = json.loads(read_file(decomp_path))
        rtf = data.get("root_top_function", {})
        root_top_name = rtf.get("name", root_top_name)
        root_top_sig  = rtf.get("signature", root_top_sig)
    except Exception:
        pass

    mods = collect_module_sources()
    if not mods:
        print("[ERROR] No aesX submodules found. Please run Round 2 first.")
        sys.exit(2)

    aes_h = read_file(aes_h_path)
    aes_cpp = read_file(aes_cpp_path)
    test_cpp = read_file(test_cpp_path)

    messages = build_prompt(mods, aes_h, aes_cpp, test_cpp, root_top_name, root_top_sig)
    prompt_txt = "\n\n".join([m["content"] for m in messages if m["role"] != "system"])
    output = call_llm_chat(messages)
    save_round_io(5, prompt_txt, output)

    blocks = parse_file_blocks(output)
    if not blocks:
        print("[ERROR] No <FILE:...> blocks parsed. Check LLM output.")
        sys.exit(3)

    write_blocks_to_disk(blocks, AES_BASE)
    print(f"[{timestamp()}] Generated aes_concat sources.")

    concat_cpp = os.path.join(AES_BASE, "aes_concat", "aes_concat.cpp")
    if os.path.exists(concat_cpp):
        ensure_top_pragma_concat(concat_cpp, root_top_name)

    compile_src_path = os.path.join(AES_BASE, "compileh.py")
    if not os.path.exists(compile_src_path):
        print(f"[ERROR] Missing {compile_src_path}")
        sys.exit(4)

    src = read_file(compile_src_path)
    concat_dir = os.path.join(AES_BASE, "aes_concat")
    os.makedirs(concat_dir, exist_ok=True)

    patched = src.replace("aes.cpp", "aes_concat.cpp").replace("test.cpp", "test_concat.cpp")
    write_text(os.path.join(concat_dir, "compileh.py"), patched)

    print(f"[{timestamp()}] Running aes_concat/compileh.py ...")
    try:
        subprocess.run([sys.executable, "compileh.py"], cwd=concat_dir, check=True)
    except subprocess.CalledProcessError as e:
        print(f"[WARN] Top-level test returned non-zero exit code: {e.returncode}. Check logs.")

    print(f"[{timestamp()}] Top-level concatenation and verification finished.")

if __name__ == "__main__":
    main()
