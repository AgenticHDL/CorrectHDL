"""
RAG utilities for QuestaSim/SystemVerilog syntax repair.

- Loads a JSONL template library (>=50 templates recommended).
- Retrieves the most relevant template for a given error log:
  1) Regex match against known Questa/vlog patterns (high precision)
  2) Similarity search over template text (TF-IDF; optional SentenceTransformer)

This module is intentionally dependency-light: it runs with only the standard
library; if scikit-learn is available it uses TF-IDF; if sentence-transformers
is available it can be enabled via env var RAG_USE_ST=1.
"""
from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
from typing import List, Dict, Optional, Tuple
import json, os, re, hashlib

@dataclass
class RagTemplate:
    id: str
    title: str
    error_patterns: List[str]
    manual_summary: str
    fix_guidance: str
    example_before: str = ""
    example_after: str = ""

    @staticmethod
    def from_dict(d: Dict) -> "RagTemplate":
        return RagTemplate(
            id=str(d.get("id","")),
            title=str(d.get("title","")),
            error_patterns=list(d.get("error_patterns",[]) or []),
            manual_summary=str(d.get("manual_summary","")),
            fix_guidance=str(d.get("fix_guidance","")),
            example_before=str(d.get("example_before","") or ""),
            example_after=str(d.get("example_after","") or ""),
        )

    def to_prompt_block(self) -> str:
        parts = [
            f"[RAG Template {self.id}] {self.title}",
            f"- Rule Summary: {self.manual_summary}".strip(),
            f"- Repair Guidance: {self.fix_guidance}".strip(),
        ]
        if self.example_before.strip() or self.example_after.strip():
            parts += ["- Example:"]
            if self.example_before.strip():
                parts += ["  - Before:", "```systemverilog", self.example_before.strip(), "```"]
            if self.example_after.strip():
                parts += ["  - After:", "```systemverilog", self.example_after.strip(), "```"]
        return "\n".join(parts).strip()

class TemplateLibrary:
    def __init__(self, jsonl_path: Path):
        self.jsonl_path = Path(jsonl_path)
        self.templates: List[RagTemplate] = []
        self._regex_compiled: List[Tuple[RagTemplate, List[re.Pattern]]] = []
        self._sim_engine = None  # lazy
        self._sim_texts: List[str] = []

    def load(self) -> None:
        if not self.jsonl_path.exists():
            raise FileNotFoundError(f"RAG template library not found: {self.jsonl_path}")
        items = []
        for ln in self.jsonl_path.read_text(encoding="utf-8", errors="ignore").splitlines():
            ln = ln.strip()
            if not ln: 
                continue
            try:
                items.append(json.loads(ln))
            except Exception:
                continue
        self.templates = [RagTemplate.from_dict(d) for d in items if isinstance(d, dict)]
        self._regex_compiled = []
        for t in self.templates:
            pats = []
            for p in (t.error_patterns or []):
                try:
                    pats.append(re.compile(p, re.IGNORECASE))
                except re.error:
                    continue
            self._regex_compiled.append((t, pats))

        self._sim_engine = None
        self._sim_texts = [self._template_text(t) for t in self.templates]

    @staticmethod
    def _template_text(t: RagTemplate) -> str:
        return "\n".join([
            t.title or "",
            " ".join(t.error_patterns or []),
            t.manual_summary or "",
            t.fix_guidance or "",
        ]).strip()

    def _build_similarity_engine(self):
        # Prefer sentence-transformers if explicitly enabled and available.
        use_st = os.getenv("RAG_USE_ST", "0").strip() == "1"
        if use_st:
            try:
                from sentence_transformers import SentenceTransformer, util  # type: ignore
                model_name = os.getenv("RAG_ST_MODEL", "all-MiniLM-L6-v2")
                st_model = SentenceTransformer(model_name)
                emb = st_model.encode(self._sim_texts, convert_to_tensor=True, show_progress_bar=False)
                self._sim_engine = ("st", st_model, util, emb)
                return
            except Exception:
                pass

        # Default: TF-IDF cosine (scikit-learn). If sklearn not installed, fallback to keyword scoring.
        try:
            from sklearn.feature_extraction.text import TfidfVectorizer  # type: ignore
            from sklearn.metrics.pairwise import cosine_similarity  # type: ignore
            vec = TfidfVectorizer(stop_words="english", max_features=4000)
            mat = vec.fit_transform(self._sim_texts)
            self._sim_engine = ("tfidf", vec, cosine_similarity, mat)
            return
        except Exception:
            self._sim_engine = ("kw", None, None, None)

    def retrieve(self, error_text: str, topk: int = 1) -> List[Tuple[RagTemplate, float, str]]:
        """
        Returns list of (template, score, method) sorted by best match first.
        method in {"regex","st","tfidf","kw"}.
        """
        if not self.templates:
            self.load()
        et = (error_text or "").strip()
        if not et:
            return []
        # 1) regex direct match
        hits = []
        for t, pats in self._regex_compiled:
            for p in pats:
                if p.search(et):
                    hits.append((t, 1.0, "regex"))
                    break
        if hits:
            # If multiple regex hits, keep deterministic order (first in file)
            return hits[:topk]

        # 2) similarity
        if self._sim_engine is None:
            self._build_similarity_engine()
        kind = self._sim_engine[0]
        if kind == "st":
            _, st_model, util, emb = self._sim_engine
            q = st_model.encode([et], convert_to_tensor=True, show_progress_bar=False)
            scores = util.cos_sim(q, emb)[0].cpu().tolist()
            ranked = sorted(list(enumerate(scores)), key=lambda x: x[1], reverse=True)[:topk]
            return [(self.templates[i], float(s), "st") for i, s in ranked if i < len(self.templates)]
        if kind == "tfidf":
            _, vec, cosine_similarity, mat = self._sim_engine
            qv = vec.transform([et])
            sims = cosine_similarity(qv, mat).flatten().tolist()
            ranked = sorted(list(enumerate(sims)), key=lambda x: x[1], reverse=True)[:topk]
            return [(self.templates[i], float(s), "tfidf") for i, s in ranked if i < len(self.templates)]

        # 3) fallback: keyword overlap
        qwords = set(re.findall(r"[A-Za-z_]\w+", et.lower()))
        scored = []
        for i, t in enumerate(self.templates):
            tw = set(re.findall(r"[A-Za-z_]\w+", self._sim_texts[i].lower()))
            inter = len(qwords & tw)
            union = max(1, len(qwords | tw))
            score = inter / union
            scored.append((i, score))
        ranked = sorted(scored, key=lambda x: x[1], reverse=True)[:topk]
        return [(self.templates[i], float(s), "kw") for i, s in ranked]

def default_library_path() -> Path:
    return Path(__file__).resolve().parent / "rag_library" / "questa_sv_syntax_templates.jsonl"

def retrieve_template_block(error_text: str, library_path: Optional[Path] = None) -> Tuple[str, Optional[str], Optional[str]]:
    """
    Convenience helper:
    returns (prompt_block, template_id, method) or ("", None, None) if not found.
    """
    lib = TemplateLibrary(library_path or default_library_path())
    try:
        hits = lib.retrieve(error_text, topk=1)
    except Exception:
        hits = []
    if not hits:
        return ("", None, None)
    t, score, method = hits[0]
    block = "\n".join([
        "[Retrieved Template]",
        t.to_prompt_block(),
        f"(match_method={method}, score={score:.3f})"
    ])
    return (block, t.id, method)
