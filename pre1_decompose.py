"""
Input: aes.h and aes.cpp under AES_BASE
Output: CSPLIT_DIR/module_decomposition.txt (JSON format)
Also saves round1_prompt.txt and round1_output.txt
"""
import os, re, json, argparse, subprocess, shutil, sys
from datetime import datetime

# ---------------------- Path Configuration (modify as needed) ----------------------
CSPLIT_DIR = "/Path"
AES_BASE   = "/Path"

# Each round output: will save round{N}_prompt.txt and round{N}_output.txt under CSPLIT_DIR
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

# ---------------------- LLM Wrapper ----------------------
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
            print("[ERROR] LLM call failed:", e2)
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
    print(f"[{timestamp()}] Saved prompt and output for round {round_id} into {CSPLIT_DIR}.")

def build_prompt(aes_h, aes_cpp):
    system = {
        "role": "system",
        "content": (
            "You are a senior hardware and HLS expert. You are familiar with the AES algorithm "
            "and with mapping software into modular hardware through C/C++ restructuring. "
            "You extract synthesizable modules cleanly from C++ implementations."
        )
    }
    user = {
        "role": "user",
        "content": f"""
Please read the following C++ header and source files and perform a *module-level decomposition*.
The goal is to split the original aes.cpp into four core submodules:

1) SubBytes
2) ShiftRows
3) MixColumns
4) AddRoundKey

Other helper functions must be assigned to one of the above submodules based on call dependencies and semantic cohesion.

The decomposition must follow these strict rules:
(1) Function-Level Granularity: Decomposition is performed strictly along function boundaries. Do not split a single function body across multiple submodules.
(2) Explicit I/O Definition: Each submodule exposes a single top-level function that uses only fixed-width scalar types or statically sized arrays as its interface (for example, int8_t state[16] or uint8_t roundKey[16]), with all bit widths explicitly specified.
(3) Single and Clear Semantics: Each submodule implements one clearly defined stage of the algorithm (for example, in AES, SubBytes() performs only SBox substitution), and must avoid mixing unrelated responsibilities.

Additional constraints:
- Identify the root top-level function that is tagged with `#pragma hls_design top` in the original aes.cpp. Ensure it appears only in the final integration stage and never inside any submodule.
- The combined functionality of all submodules must exactly match the original aes.cpp (no logic may be dropped or weakened).
- Each module should be cohesive and have a clean, minimal interface so that downstream HLS tools can map it into a standalone hardware unit.
- Each module must define one and only one top-level wrapper function (with a fixed name pattern `aes{{id}}_top`) whose signature matches or wraps the main functionality of that module. Declare this function in the corresponding .h file.
- In each module's .cpp file, place `#pragma hls_design top` immediately above that top wrapper function.
- In every C/C++ file, ALL variable declarations MUST appear at the top of each function before any executable statements.

{{
  "modules": [
    {{
      "id": 1,
      "name": "SubBytes",
      "functions": [
        {{"signature": "void SubBytes(uint8_t state[16]);"}}
      ],
      "top_function": {{
        "name": "aes1_top",
        "signature": "void aes1_top(uint8_t state[16]);",
        "notes": "Include extra parameters if necessary (e.g., constant tables)."
      }},
      "headers": ["<cstdint>"],
      "notes": "Brief reasoning for this module's boundaries/dependencies"
    }},
    {{
      "id": 2,
      "name": "ShiftRows",
      "functions": [],
      "top_function": {{
        "name": "aes2_top",
        "signature": "void aes2_top(uint8_t state[16]);",
        "notes": ""
      }},
      "headers": [],
      "notes": ""
    }},
    {{
      "id": 3,
      "name": "MixColumns",
      "functions": [],
      "top_function": {{
        "name": "aes3_top",
        "signature": "void aes3_top(uint8_t state[16]);",
        "notes": ""
      }},
      "headers": [],
      "notes": ""
    }},
    {{
      "id": 4,
      "name": "AddRoundKey",
      "functions": [],
      "top_function": {{
        "name": "aes4_top",
        "signature": "void aes4_top(uint8_t state[16], const uint8_t roundKey[16]);",
        "notes": ""
      }},
      "headers": [],
      "notes": ""
    }}
  ],
  "splitting_strategy": "Short description of the global splitting strategy"
}}

Below is aes.h:
===== aes.h BEGIN =====
{aes_h}
===== aes.h END =====

Below is aes.cpp:
===== aes.cpp BEGIN =====
{aes_cpp}
===== aes.cpp END =====
""".strip()
    }
    return [system, user]

def main():
    ensure_dirs()
    aes_h_path = os.path.join(AES_BASE, "aes.h")
    aes_cpp_path = os.path.join(AES_BASE, "aes.cpp")

    if not os.path.exists(aes_h_path) or not os.path.exists(aes_cpp_path):
        print(f"[ERROR] {aes_h_path} or {aes_cpp_path} not found.")
        sys.exit(1)

    aes_h = read_file(aes_h_path)
    aes_cpp = read_file(aes_cpp_path)

    messages = build_prompt(aes_h, aes_cpp)
    prompt_txt = "\n\n".join([m["content"] for m in messages if m["role"] != "system"])
    output = call_llm_chat(messages)

    save_round_io(1, prompt_txt, output)

    try:
        data = json.loads(output)
    except Exception:
        print("[WARN] LLM output is not valid JSON; saving raw text to module_decomposition.txt")
        data = None

    out_path = os.path.join(CSPLIT_DIR, "module_decomposition.txt")
    if data is not None:
        write_text(out_path, json.dumps(data, ensure_ascii=False, indent=2))
    else:
        write_text(out_path, output)

    print(f"[{timestamp()}] Module decomposition written to: {out_path}")

if __name__ == "__main__":
    main()
