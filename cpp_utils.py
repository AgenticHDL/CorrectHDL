# -*- coding: utf-8 -*-
import re
from pathlib import Path
from typing import List, Dict, Optional

FUNC_RE = re.compile(
    r"""(?P<ret>[\w:<>\s\*&]+?)\s+
        (?P<name>[A-Za-z_]\w*)\s*
        \(\s*(?P<args>[^)]*)\)\s*;""",
    re.VERBOSE | re.MULTILINE
)

ARG_SPLIT_RE = re.compile(r",(?![^\(<]*[\)>])")
AP_INT_RE = re.compile(r"\bap_int\s*<\s*(\d+)\s*>\s*")
AP_UINT_RE = re.compile(r"\bap_uint\s*<\s*(\d+)\s*>\s*")

def strip_comments(code: str) -> str:
    code = re.sub(r"//.*", "", code)
    code = re.sub(r"/\*[\s\S]*?\*/", "", code)
    return code

def parse_prototypes_from_header(header_path: Path) -> List[Dict]:
    txt = header_path.read_text(encoding="utf-8", errors="ignore")
    txt = strip_comments(txt)
    funs = []
    for m in FUNC_RE.finditer(txt):
        args = m.group("args").strip()
        arg_list = []
        if args:
            parts = ARG_SPLIT_RE.split(args)
            for p in parts:
                p = p.strip()
                if not p:
                    continue
                name_match = re.search(r"([A-Za-z_]\w*)\s*$", p)
                name = name_match.group(1) if name_match else f"arg{len(arg_list)}"
                typ = p[: name_match.start()].strip() if name_match else p
                arg_list.append({"type": typ, "name": name})
        funs.append({
            "ret": m.group("ret").strip(),
            "name": m.group("name").strip(),
            "args": arg_list,
        })
    return funs

def bitwidth_of_ctype(typ: str) -> Optional[int]:
    t = typ.replace("const", "").replace("volatile", "").strip()
    elem_t = t.replace("*", "").replace("&", "").strip()
    M = {
        "bool": 1,
        "char": 8, "signed char": 8, "unsigned char": 8, "uint8_t": 8, "int8_t": 8,
        "short": 16, "short int": 16, "signed short":16, "unsigned short":16,
        "uint16_t":16, "int16_t":16,
        "int": 32, "signed": 32, "unsigned": 32, "unsigned int": 32, "uint32_t": 32, "int32_t": 32,
        "long": 64, "long int": 64, "unsigned long":64, "unsigned long int":64,
        "uint64_t":64, "int64_t":64,
        "float": 32, "double": 64,
    }
    m = re.search(r"\bap_uint\s*<\s*(\d+)\s*>\b", elem_t)
    if m: return int(m.group(1))
    m = re.search(r"\bap_int\s*<\s*(\d+)\s*>\b", elem_t)
    if m: return int(m.group(1))
    return M.get(elem_t)
