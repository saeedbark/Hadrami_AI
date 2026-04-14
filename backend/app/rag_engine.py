"""RAG engine — retrieval-augmented generation for /ask and /translate-phrase.

Retrieval now uses Supabase (keyword via PostgREST, vector via pgvector RPC)
instead of the old in-memory ENTRIES + optional Chroma index.
"""

import os
import re
import time
import unicodedata
from pathlib import Path
from typing import Any, Optional

try:
    from dotenv import load_dotenv

    load_dotenv(Path(__file__).resolve().parent.parent / ".env")
except ImportError:
    pass

from .core.data_store import rpc_match_entries
from .schemas import Entry, ExamplePair
from .services.dictionary_service import search as keyword_search
from .services.dictionary_service import search_expanded, search_phrase_lexicon

MODE = os.getenv("RAG_MODE", "local")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
_GEMINI_FALLBACK_MODELS = [
    "gemini-2.0-flash",
    "gemini-2.5-flash-lite",
    "gemini-1.5-flash-002",
]
_QUERY_CACHE_TTL_SECONDS = max(0, int((os.getenv("RAG_CACHE_TTL_SECONDS") or "90").strip()))
_keyword_cache: dict[tuple[str, int], tuple[float, dict[str, Any]]] = {}
_vector_cache: dict[tuple[str, int], tuple[float, list[dict[str, Any]]]] = {}


def _rag_log(msg: str) -> None:
    if os.getenv("RAG_DEBUG", "1").lower() in ("0", "false", "no", "off"):
        return
    print(msg, flush=True)


def _rag_response_mode_tag() -> str:
    """API ``mode`` for Gemini answers and lexicon-only fallbacks (never ``simple``)."""
    return "local_gemini" if MODE == "local" else "gemini"


def _preview(text: str, max_len: int = 160) -> str:
    t = (text or "").replace("\n", " ")
    return t if len(t) <= max_len else t[: max_len - 3] + "..."


def _cache_get(cache: dict[Any, tuple[float, Any]], key: Any) -> Any | None:
    if _QUERY_CACHE_TTL_SECONDS <= 0:
        return None
    hit = cache.get(key)
    if hit is None:
        return None
    expires_at, value = hit
    if expires_at < time.time():
        cache.pop(key, None)
        return None
    return value


def _cache_put(cache: dict[Any, tuple[float, Any]], key: Any, value: Any) -> Any:
    if _QUERY_CACHE_TTL_SECONDS > 0:
        cache[key] = (time.time() + _QUERY_CACHE_TTL_SECONDS, value)
    return value


def _gemini_api_key() -> str:
    return (os.getenv("GEMINI_API_KEY") or "").strip()


_USAGE_EXAMPLE_PATTERN = re.compile(r"\)\s*:\s*([^()]+?)\s*\(", re.UNICODE)

_TRANSLATION_INTENT_PATTERN = re.compile(
    r"(ترجم|ترجمة|إلى\s*الفصحى|إلى\s*العربية|بالفصحى|بالعربية\s*الفصحى|"
    r"translate|حول\s*إلى\s*الفصحى|عبر\s*إلى\s*الفصحى|فصحى\s*هذه)",
    re.IGNORECASE,
)


def _looks_like_translation_request(question: str) -> bool:
    q = (question or "").strip()
    if not q:
        return False
    return bool(_TRANSLATION_INTENT_PATTERN.search(q))


def _few_shot_pairs_from_entry(entry: dict[str, Any]) -> list[tuple[str, str]]:
    hadrami_head = (entry.get("hadrami_word") or "").strip()
    fus_gloss = (entry.get("arabic_fus7a") or "").strip()
    definition = (entry.get("full_definition") or "").strip()
    out: list[tuple[str, str]] = []

    raw_examples = entry.get("examples")
    if isinstance(raw_examples, list):
        for ex in raw_examples[:4]:
            if not isinstance(ex, dict):
                continue
            h = (ex.get("hadrami") or ex.get("hadrami_sentence") or ex.get("sentence") or "").strip()
            f = (ex.get("fusha") or ex.get("fusha_translation") or ex.get("meaning") or "").strip()
            if h and f:
                out.append((h, f))

    for m in _USAGE_EXAMPLE_PATTERN.finditer(definition):
        snippet = (m.group(1) or "").strip()
        if len(snippet) >= 3:
            gloss = fus_gloss if fus_gloss else definition[:160]
            out.append((snippet, gloss))

    if not out and hadrami_head and fus_gloss:
        out.append((hadrami_head, fus_gloss))

    return out[:2]


def _translation_prompt(question: str, context_entries: list[dict]) -> str:
    blocks: list[str] = []
    for e in context_entries[:8]:
        for had, fusha in _few_shot_pairs_from_entry(e):
            if len(blocks) >= 10:
                break
            had_clean = had.replace("\n", " ").strip()
            fusha_clean = fusha.replace("\n", " ").strip()
            if not had_clean or not fusha_clean:
                continue
            blocks.append(
                f"- Hadrami Example: {had_clean}\n  - Fusha Translation: {fusha_clean}"
            )
        if len(blocks) >= 10:
            break

    examples_text = (
        "\n\n".join(blocks)
        if blocks
        else "(No structured examples were retrieved from the dictionary; rely on general Hadrami-to-MSA competence.)"
    )

    system_and_examples = f"""You are a professional translator from Hadrami dialect to Modern Standard Arabic. Use the following examples as a guide for style, grammar, and vocabulary mapping.

{examples_text}"""

    return f"""{system_and_examples}

Now, translate this sentence precisely: {question}"""


def _merge_entries_by_id(*lists: list[dict]) -> list[dict]:
    seen: set[int] = set()
    out: list[dict] = []
    for lst in lists:
        for e in lst:
            eid = e.get("id")
            if eid is None or eid in seen:
                continue
            seen.add(eid)
            out.append(e)
    return out


def _aliases_from_entry(entry: dict[str, Any]) -> list[str]:
    raw = entry.get("aliases")
    if not isinstance(raw, list):
        return []
    return [x.strip() for x in raw if isinstance(x, str) and x.strip()]


def _first_example(entry: dict[str, Any]) -> tuple[str, str]:
    raw_examples = entry.get("examples")
    if not isinstance(raw_examples, list):
        return "", ""
    for ex in raw_examples:
        if not isinstance(ex, dict):
            continue
        hadrami = str(ex.get("hadrami") or ex.get("hadrami_sentence") or ex.get("sentence") or "").strip()
        fusha = str(ex.get("fusha") or ex.get("fusha_translation") or ex.get("meaning") or "").strip()
        if hadrami and fusha:
            return hadrami, fusha
    return "", ""


def _context_block(entries: list[dict]) -> str:
    blocks: list[str] = []
    for entry in entries[:5]:
        head = str(entry.get("hadrami_word") or "").strip()
        fusha = str(entry.get("arabic_fus7a") or "").strip()
        definition = str(entry.get("full_definition") or "").strip()
        aliases = _aliases_from_entry(entry)[:4]
        ex_h, ex_f = _first_example(entry)

        lines = [f"- الكلمة الحضرمية: {head or 'غير متوفر'}"]
        if aliases:
            lines.append(f"  البدائل: {', '.join(aliases)}")
        if fusha:
            lines.append(f"  المقابل الفصيح: {fusha}")
        if definition:
            lines.append(f"  الشرح القاموسي: {definition[:160]}")
        if ex_h and ex_f:
            lines.append(f"  مثال قاموسي: {ex_h}")
            lines.append(f"  معنى المثال: {ex_f}")
        blocks.append("\n".join(lines))
    return "\n\n".join(blocks)


def _rag_prompt(question: str, context_entries: list[dict]) -> str:
    context = _context_block(context_entries)
    return f"""أنت مساعد متخصص في اللهجة الحضرمية اليمنية.
اعتمد فقط على المراجع القاموسية التالية، ولا تخترع معاني أو كلمات غير مدعومة بها.
إذا ذكرت كلمة حضرمية موجودة في المراجع، فاكتبها حرفياً كما وردت في خانة «الكلمة الحضرمية» أو «البدائل».
اجعل الإجابة موجزة وواضحة بهذا الشكل:
- ابدأ باسم الكلمة الحضرمية بين علامتي تنسيق غامق.
- بعده سطر «المعنى: ...» من المقابل الفصيح مباشرة.
- ثم سطر «الشرح: ...» من جملة إلى جملتين قصيرتين تشرحان المقصود والاستعمال اليومي للكلمة بشكل بسيط.
- ثم سطر «مثال: ...» بجملة حضرمية قصيرة جداً ومعناها بالفصحى.
لا تكرر الشرح نفسه بصيغ متعددة، ولا تستخدم ألفاظاً عامة إذا كان للقاموس مقابل أدق.

{context}

السؤال: {question}

الإجابة:"""


def _rag_prompt_no_hits(question: str) -> str:
    return f"""أنت مساعد متخصص في اللهجة الحضرمية اليمنية.
لم يُعثر في القاموس الحضرمي على مدخل يطابق سؤالك بوضوح.
إذا كان سؤالك عن كلمة أو عبارة، يرجى التأكد من كتابتها كما تُنطق محلياً، مع أو بدون «ال» التعريف، أو مع إضافة الهمزة إن وُجدت (مثلاً «بَعْل» بدلاً من «بل»).
إذا كان سؤالك عن معنىً عام، فمن الأفضل إعادة صياغة السؤال بشكل أوضح.

السؤال: {question}

الإجابة:"""


def _prompt_for_gemini(question: str, context_entries: list[dict]) -> str:
    if context_entries:
        return _rag_prompt(question, context_entries)
    return _rag_prompt_no_hits(question)


def _normalize_match_char(ch: str) -> str:
    if ch in {"أ", "إ", "آ", "ٱ"}:
        return "ا"
    if ch == "ى":
        return "ي"
    if ch == "ـ":
        return ""
    if unicodedata.combining(ch):
        return ""
    return ch


def _normalized_text_with_positions(text: str) -> tuple[str, list[int]]:
    chars: list[str] = []
    positions: list[int] = []
    for idx, ch in enumerate(text):
        norm = _normalize_match_char(ch)
        if not norm:
            continue
        chars.append(norm)
        positions.append(idx)
    return "".join(chars), positions


def _collect_highlight_surfaces(entries: list[dict]) -> list[str]:
    seen: set[str] = set()
    surfaces: list[str] = []
    for entry in entries:
        for raw in [
            entry.get("hadrami_word"),
            entry.get("search_key"),
            *(_aliases_from_entry(entry)),
        ]:
            text = str(raw or "").strip()
            if len(text) < 2 or text in seen:
                continue
            seen.add(text)
            surfaces.append(text)
    surfaces.sort(key=len, reverse=True)
    return surfaces


def _find_hadrami_spans(text: str, surfaces: list[str]) -> list[dict[str, Any]]:
    if not text or not surfaces:
        return []

    normalized_text, positions = _normalized_text_with_positions(text)
    if not normalized_text:
        return []

    intervals: list[tuple[int, int]] = []
    for surface in surfaces:
        normalized_surface, _ = _normalized_text_with_positions(surface)
        if len(normalized_surface) < 2:
            continue
        start_at = 0
        while True:
            idx = normalized_text.find(normalized_surface, start_at)
            if idx < 0:
                break
            orig_start = positions[idx]
            orig_end = positions[idx + len(normalized_surface) - 1] + 1
            intervals.append((orig_start, orig_end))
            start_at = idx + 1

    if not intervals:
        return []

    intervals.sort()
    merged: list[list[int]] = [[intervals[0][0], intervals[0][1]]]
    for start, end in intervals[1:]:
        last = merged[-1]
        if start <= last[1]:
            if end > last[1]:
                last[1] = end
            continue
        merged.append([start, end])

    return [
        {"start": start, "end": end, "surface": text[start:end]}
        for start, end in merged
        if start < end
    ]


def _entries_to_response(entries: list[dict]) -> list[Entry]:
    out: list[Entry] = []
    for entry in entries:
        examples = None
        raw_examples = entry.get("examples")
        if isinstance(raw_examples, list):
            examples = [
                ExamplePair(
                    hadrami=str(ex.get("hadrami", "")),
                    fusha=str(ex.get("fusha", "")),
                )
                for ex in raw_examples
                if isinstance(ex, dict)
            ]
        out.append(
            Entry(
                id=int(entry.get("id", 0)),
                hadrami_word=str(entry.get("hadrami_word", "")),
                arabic_fus7a=str(entry.get("arabic_fus7a", "")),
                full_definition=str(entry.get("full_definition", "")),
                search_key=entry.get("search_key"),
                part_of_speech=entry.get("part_of_speech"),
                thematic_category=entry.get("thematic_category"),
                is_archaic=bool(entry.get("is_archaic", False)),
                cultural_note=entry.get("cultural_note"),
                proverb_record=entry.get("proverb_record"),
                aliases=entry.get("aliases"),
                examples=examples,
            )
        )
    return out


def _finalize_ask_payload(answer: str, mode: str, entries: list[dict]) -> dict[str, Any]:
    highlight_surfaces = _collect_highlight_surfaces(entries)
    return {
        "answer": answer,
        "mode": mode,
        "context": _entries_to_response(entries),
        "highlight_surfaces": highlight_surfaces,
        "hadrami_spans": _find_hadrami_spans(answer, highlight_surfaces),
    }


def _gemini_generate(prompt: str, api_key: str) -> str:
    if not api_key:
        _rag_log("❌ Gemini: no API key (GEMINI_API_KEY empty)")
        return "Gemini not available: set GEMINI_API_KEY"
    _rag_log(
        f"🤖 Gemini model={GEMINI_MODEL!r} chars={len(prompt)} | prompt: {_preview(prompt, 200)}"
    )
    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)

        order: list[str] = []
        for m in [GEMINI_MODEL, *_GEMINI_FALLBACK_MODELS]:
            if m and m not in order:
                order.append(m)

        last_err: Exception | None = None
        for mname in order:
            try:
                model = genai.GenerativeModel(mname)
                response = model.generate_content(prompt)
                text = (response.text or "").strip()
                if mname != GEMINI_MODEL:
                    _rag_log(f"✅ Gemini used fallback model={mname!r}")
                _rag_log(f"✅ Gemini ← answer_chars={len(text)} preview: {_preview(text)}")
                return text
            except Exception as e:
                last_err = e
                _rag_log(f"⚠️ Gemini model {mname!r} failed: {e!r}")

        if last_err:
            return f"Gemini not available: {last_err}"
        return "Gemini not available: unknown error"
    except ImportError:
        _rag_log("❌ Gemini: google-generativeai not installed — run: pip install -r requirements.txt")
        return "Gemini not available: google-generativeai not installed"


# ---------------------------------------------------------------------------
# Vector retrieval helpers (pgvector via Supabase RPC)
# ---------------------------------------------------------------------------

def _vector_context(query: str, top_k: int = 6) -> list[dict]:
    """Embed the query and call match_entries RPC for semantic retrieval."""
    cache_key = (query.strip(), top_k)
    cached = _cache_get(_vector_cache, cache_key)
    if cached is not None:
        _rag_log(f"📚 vector_context cache hit q={query!r} → {len(cached)} hits")
        return cached

    from .services.embedding_service import embed_text

    embedding = embed_text(query)
    if embedding is None:
        _rag_log("📚 vector_context: embedding unavailable — skipping vector search")
        return []

    rows = rpc_match_entries(embedding, match_threshold=0.25, match_count=top_k)
    labels = [f"{r.get('hadrami_word', '?')}→{r.get('arabic_fus7a', '')} ({r.get('similarity', 0):.2f})" for r in rows[:5]]
    _rag_log(f"📚 vector_context q={query!r} → {len(rows)} hits: {labels}")
    return _cache_put(_vector_cache, cache_key, rows)


def _keyword_context(query: str, top_k: int = 5) -> list[dict]:
    result = keyword_search(query, limit=top_k)
    rows = result["results"]
    labels = [f"{r.get('hadrami_word', '?')}→{r.get('arabic_fus7a', '')}" for r in rows[:5]]
    _rag_log(f"🔎 keyword_search q={query!r} top_k={top_k} → {len(rows)} hits: {labels}")
    return rows


def _expanded_keyword_context(query: str, top_k: int = 8) -> dict[str, Any]:
    cache_key = (query.strip(), top_k)
    cached = _cache_get(_keyword_cache, cache_key)
    if cached is not None:
        _rag_log(
            f"🔎 search_expanded cache hit q={query!r} top_k={top_k} → {len(cached.get('results', []))} hits"
        )
        return cached

    payload = search_expanded(query, limit=top_k)
    rows = payload["results"]
    labels = [f"{r.get('hadrami_word', '?')}→{r.get('arabic_fus7a', '')}" for r in rows[:5]]
    _rag_log(
        f"🔎 search_expanded q={query!r} top_k={top_k} "
        f"score={payload.get('top_score', 0)} → {len(rows)} hits: {labels}"
    )
    return _cache_put(_keyword_cache, cache_key, payload)


# ---------------------------------------------------------------------------
# Retrieval orchestration
# ---------------------------------------------------------------------------

def retrieve_rag_context(query: str) -> tuple[list[dict], list[dict]]:
    """Return (entries_for_prompt, entries_for_api_response)."""
    if MODE == "simple":
        context = _keyword_context(query, top_k=3)
        return context[:5], context[:5]

    kw_payload = _expanded_keyword_context(query, top_k=8)
    kw_ctx = kw_payload["results"]
    top_score = int(kw_payload.get("top_score") or 0)
    if top_score >= 100:
        _rag_log(f"⚡ exact keyword hit for q={query!r} — skipping vector search")
        merged = kw_ctx[:5]
        return merged, merged[:5]

    vec_ctx = _vector_context(query, top_k=4)

    merged = _merge_entries_by_id(kw_ctx, vec_ctx)[:5]
    return merged, merged[:5]


def retrieve_phrase_context(query: str) -> tuple[list[dict], list[dict]]:
    """Retrieval for /translate-phrase: stricter lexicon matching."""
    if MODE == "simple":
        rows = search_phrase_lexicon(query, 8)["results"]
        return rows[:5], rows[:5]

    kw_ctx = search_phrase_lexicon(query, 10)["results"]
    vec_ctx = _vector_context(query, top_k=4)

    merged = _merge_entries_by_id(kw_ctx, vec_ctx)[:5]
    return merged, merged[:5]


def get_translation_answer(question: str) -> dict:
    merged, ctx_for_api = retrieve_phrase_context(question)
    prompt = _translation_prompt(question, merged)
    answer = _gemini_generate(prompt, _gemini_api_key())

    if answer.startswith("Gemini not available:"):
        fb = merged[0].get("arabic_fus7a", "غير موجود") if merged else "غير موجود"
        tag = _rag_response_mode_tag()
        _rag_log(f"🔁 translation Gemini failed → fallback mode={tag} answer_preview={_preview(fb)}")
        return _finalize_ask_payload(fb, tag, ctx_for_api)

    mode_tag = _rag_response_mode_tag()
    _rag_log(f"⬅️ get_translation_answer END mode={mode_tag} answer_preview={_preview(answer)}")
    return _finalize_ask_payload(answer, mode_tag, ctx_for_api)


def get_rag_answer(question: str) -> dict:
    q = (question or "").strip()

    if _looks_like_translation_request(q):
        return get_translation_answer(q)

    merged, ctx_for_api = retrieve_rag_context(q)
    prompt = _prompt_for_gemini(q, merged)
    answer = _gemini_generate(prompt, _gemini_api_key())

    if MODE == "simple" and answer.startswith("Gemini not available:"):
        fb = merged[0].get("arabic_fus7a", "غير موجود") if merged else "غير موجود"
        tag = _rag_response_mode_tag()
        _rag_log(f"📌 branch=RAG_MODE=simple retrieval (Gemini failed) mode={tag} answer_preview={_preview(fb)}")
        return _finalize_ask_payload(fb, tag, ctx_for_api)

    if answer.startswith("Gemini not available:"):
        fb = merged[0].get("arabic_fus7a", "غير موجود") if merged else "غير موجود"
        tag = _rag_response_mode_tag()
        _rag_log(f"🔁 Gemini failed → fallback lexicon mode={tag} answer_preview={_preview(fb)}")
        return _finalize_ask_payload(fb, tag, ctx_for_api)

    mode_tag = _rag_response_mode_tag()
    _rag_log(f"⬅️ get_rag_answer END mode={mode_tag} answer_preview={_preview(answer)}")
    return _finalize_ask_payload(answer, mode_tag, ctx_for_api)


if __name__ == "__main__":
    import sys

    query = sys.argv[1] if len(sys.argv) > 1 else "ما معنى كلمة ويش؟"
    print(f"Query: {query}")
    print(f"Mode: {MODE}")
    result = get_rag_answer(query)
    print(f"Answer: {result['answer']}")
    print(f"Context ({len(result['context'])} entries):")
    for e in result["context"]:
        print(f"  - {e['hadrami_word']} -> {e.get('arabic_fus7a', '')}")
