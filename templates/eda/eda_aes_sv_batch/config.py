
import os
from pathlib import Path

MODEL = os.getenv("LLM_MODEL", "gpt-5")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_BASE_URL = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
STRICT_CODE_ONLY = True
DEFAULT_TDATA_WIDTH = 512
PREFER_QUESTA = True
TIMEOUT_SEC = int(os.getenv("VSPLIT_TIMEOUT_SEC", "1800"))