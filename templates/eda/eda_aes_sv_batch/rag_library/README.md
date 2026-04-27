

## Files
- `questa_sv_syntax_templates.jsonl`: one JSON object per line (>=50 templates).  
  Each template includes:
  - `error_patterns`: regex patterns for direct matching against vlog transcripts
  - `manual_summary`: short rule summary (from typical Questa/Verilog usage rules)
  - `fix_guidance`: step-by-step repair guidance
  - optional before/after snippets

The repair loop:
1. Parse the **first failing** vlog error excerpt from `transcript_r.log`
2. Retrieve the best matching template:
   - regex match has highest priority
   - otherwise similarity search (TF-IDF or SentenceTransformer if available)
3. Inject the retrieved template into the LLM repair prompt.
