import os, re, time, json, datetime
from pathlib import Path

from typing import List, Dict, Tuple, Optional

from config import LOG_DIR, MODEL, OPENAI_API_KEY, OPENAI_BASE_URL, STRICT_CODE_ONLY


_client = None


def _get_openai_client():
    """Initialize and cache the OpenAI client."""
    global _client
    if _client is None:
        try:
            from openai import OpenAI
            _client = OpenAI(api_key=OPENAI_API_KEY, base_url=OPENAI_BASE_URL)
        except Exception as e:
            raise RuntimeError(
                "Please install and configure the 'openai' package and OPENAI_API_KEY, "
                "or modify config.py accordingly."
            ) from e
    return _client


def ensure_log_dir():
    LOG_DIR.mkdir(parents=True, exist_ok=True)


def ts() -> str:
    return datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")


def save_io(tag: str, prompt: str, output: str) -> None:
    """Save the prompt and output of an LLM interaction."""
    ensure_log_dir()
    t = ts()
    with open(LOG_DIR / f"{tag}_prompt.txt", "w", encoding="utf-8") as f:
        f.write(prompt)
    with open(LOG_DIR / f"{tag}_output.txt", "w", encoding="utf-8") as f:
        f.write(output)


_CODE_FENCE_RE = re.compile(r"```(?:\w+)?\s*([\s\S]*?)```", re.MULTILINE)


def extract_code_blocks(text: str) -> List[str]:
    """Extract code blocks enclosed in Markdown fences. If none found, return full text."""
    blocks = _CODE_FENCE_RE.findall(text)
    if blocks:
        return [b.strip() for b in blocks if b.strip()]
    return [text.strip()] if text.strip() else []


def call_llm(messages: List[Dict[str, str]],
             model: Optional[str] = None,
             max_tokens: int = 4096) -> str:
    """
    General LLM wrapper.  
    Tries the OpenAI Responses API first, then falls back to ChatCompletions.
    """
    model = model or MODEL
    client = _get_openai_client()

    # Prefer Responses API
    try:
        resp = client.responses.create(
            model=model,
            input=messages,
            max_output_tokens=max_tokens,
        )
        out = resp.output_text
        return out
    except Exception:
        # Fallback: ChatCompletions API
        try:
            chat_msgs = [{"role": m.get("role", "user"), "content": m["content"]} for m in messages]
            cc = client.chat.completions.create(
                model=model,
                messages=chat_msgs,
                temperature=0.2
            )
            return cc.choices[0].message.content
        except Exception as e:
            raise


def strict_code_guard_prefix() -> str:
    if not STRICT_CODE_ONLY:
        return ""
    return (
        "You must output **code only**, with no explanations.\n"
    )
