# -*- coding: utf-8 -*-
import os
from pathlib import Path
ROOT = Path("/nas/...").resolve()
VSPLIT_DIR = ROOT / "vsplit"
LOG_DIR = VSPLIT_DIR / "logs"
TEMPLATES_DIR = VSPLIT_DIR / "templates"
def aes_dir(x: int) -> Path: return ROOT / f"aes{x}"
def aesv_dir(x: int) -> Path: return VSPLIT_DIR / f"aesv{x}"
MODEL = os.getenv("LLM_MODEL", "gpt")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_BASE_URL = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
STRICT_CODE_ONLY = True
DEFAULT_TDATA_WIDTH = 512
PREFER_QUESTA = True
TIMEOUT_SEC = int(os.getenv("VSPLIT_TIMEOUT_SEC", "1800"))
