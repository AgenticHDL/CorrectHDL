import os, re, time, json, datetime
from pathlib import Path
from typing import List, Dict, Tuple, Optional
import sys

sys.path.append(str(Path(__file__).resolve().parent.parent))
from config import MODEL, OPENAI_API_KEY, OPENAI_BASE_URL, STRICT_CODE_ONLY

_client = None

def _get_openai_client():
    global _client
    if _client is None:
        try:
            from openai import OpenAI
            _client = OpenAI(api_key=OPENAI_API_KEY, base_url=OPENAI_BASE_URL)
        except Exception as e:
            raise RuntimeError("Please install 'openai' and set OPENAI_API_KEY in config.py.") from e
    return _client

def ts() -> str:
    return datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")

_CODE_FENCE_RE = re.compile(r"```(?:\w+)?\s*([\s\S]*?)```", re.MULTILINE)

def extract_code_blocks(text: str) -> List[str]:
    """Extract code from Markdown fences; returns the whole text if no fences found."""
    blocks = _CODE_FENCE_RE.findall(text)
    if blocks:
        return [b.strip() for b in blocks if b.strip()]
    return [text.strip()] if text.strip() else []

def call_llm(messages: List[Dict[str, str]], model: Optional[str] = None, max_tokens: int = 4096) -> str:
    """Standard LLM call (tries Responses API first, fallbacks to ChatCompletions)."""
    model = model or MODEL
    client = _get_openai_client()

    try:
        # Try modern Responses API
        resp = client.responses.create(
            model=model,
            input=messages,
            max_output_tokens=max_tokens,
        )
        return resp.output_text
    except Exception:
        # Fallback to legacy Chat Completions
        try:
            chat_msgs = [{"role": m.get("role", "user"), "content": m["content"]} for m in messages]
            cc = client.chat.completions.create(model=model, messages=chat_msgs, temperature=0.2)
            return cc.choices[0].message.content
        except Exception as e:
            raise e

def strict_code_guard_prefix() -> str:
    if not STRICT_CODE_ONLY:
        return ""
    return (
        "Output **CODE ONLY**. Do not include explanations, intro text, or Markdown fences. "
        "Just the raw SystemVerilog source code.\n"
    )