"""RAG engine -- retrieval-augmented generation for /ask, /translate-phrase, and /chat.

Retrieval uses Supabase (keyword via PostgREST, vector via pgvector RPC).
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
    hadrami_head = (entry.get("word_vocalized") or "").strip()
    fus_gloss = (entry.get("fusha_equivalent") or "").strip()
    definition = (entry.get("definition") or "").strip()
    out: list[tuple[str, str]] = []

    raw_examples = entry.get("examples")
    if isinstance(raw_examples, list):
        for ex in raw_examples[:4]:
            if not isinstance(ex, dict):
                continue
            h = (ex.get("h") or "").strip()
            f = (ex.get("f") or "").strip()
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
    """Hadrami→MSA translation prompt: demand grounding in retrieved lexicon only."""
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

    if blocks:
        reference_text = "\n\n".join(blocks)
        intro = (
            "You are a professional translator from Hadrami Arabic to Modern Standard Arabic. "
            "Every content word mapping MUST be licensed by the Hadrami↔MSA pairs below. "
            "Do not invent senses, synonyms, or free paraphrase beyond what these pairs support. "
            "If the sentence cannot be translated faithfully from these pairs alone, output exactly one line:\n"
            "لم يُسترجَع قاموسياً ما يكفي لترجمة هذه الجملة بدقة."
        )
    else:
        reference_text = _context_block(context_entries, definition_max_chars=220)
        intro = (
            "You are a professional translator from Hadrami Arabic to Modern Standard Arabic. "
            "You MUST ground the translation ONLY in the Arabic lexicon excerpt below "
            "(headwords, MSA glosses, definitions, examples). "
            "Do not use general bilingual knowledge to fill gaps. "
            "If the excerpt does not license a faithful full-sentence translation, output exactly:\n"
            "لم يُسترجَع قاموسياً ما يكفي لترجمة هذه الجملة بدقة.\n"
            "Otherwise output only the MSA translation."
        )

    return f"""{intro}

{reference_text}

Translate the following Hadrami text to Modern Standard Arabic. Output only the MSA translation, or the exact refusal sentence above:
{question}"""


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


def _synonyms_from_entry(entry: dict[str, Any]) -> list[str]:
    raw = entry.get("synonyms")
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
        hadrami = str(ex.get("h") or "").strip()
        fusha = str(ex.get("f") or "").strip()
        if hadrami and fusha:
            return hadrami, fusha
    return "", ""


def _context_block(entries: list[dict], definition_max_chars: int = 160) -> str:
    blocks: list[str] = []
    cap = max(80, definition_max_chars)
    for entry in entries[:5]:
        head = str(entry.get("word_vocalized") or "").strip()
        fusha = str(entry.get("fusha_equivalent") or "").strip()
        definition = str(entry.get("definition") or "").strip()
        synonyms = _synonyms_from_entry(entry)[:4]
        ex_h, ex_f = _first_example(entry)

        lines = [f"- الكلمة الحضرمية: {head or 'غير متوفر'}"]
        if synonyms:
            lines.append(f"  المرادفات: {', '.join(synonyms)}")
        if fusha:
            lines.append(f"  المقابل الفصيح: {fusha}")
        if definition:
            lines.append(f"  الشرح القاموسي: {definition[:cap]}")
        if ex_h and ex_f:
            lines.append(f"  مثال قاموسي: {ex_h}")
            lines.append(f"  معنى المثال: {ex_f}")
        blocks.append("\n".join(lines))
    return "\n\n".join(blocks)


def _rag_prompt(question: str, context_entries: list[dict]) -> str:
    context = _context_block(context_entries)
    return f"""أنت مساعد متخصص في اللهجة الحضرمية اليمنية.
التزم حصراً بالمراجع القاموسية أدناه. لا تذكر معانٍ أو أشكالاً حضرمية أو فصحى لم ترد فيها صراحة.
إذا لم تغطِ المراجعُ السؤال، فقل ذلك في جملة واحدة ولا تكمل بمعرفة عامة أو تخمين.
إذا ذكرت كلمة حضرمية من المراجع، فاكتبها حرفياً كما في «الكلمة الحضرمية» أو «المرادفات».
اجعل الإجابة موجزة بهذا الشكل:
- ابدأ باسم الكلمة الحضرمية بين علامتي تنسيق غامق.
- سطر «المعنى: ...» من المقابل الفصيح من المراجع فقط.
- سطر «الشرح: ...» جملة أو جملتان تلخصان الشرح القاموسي دون إضافة معلومات من خارج المراجع.
- سطر «مثال: ...» فقط إذا وُجد في المراجع مثال حضرمي+فصيح؛ وإلا اكتب «لا يوجد في المراجع مثال جاهز».
لا تكرر الشرح بصيغ متعددة، ولا تستخدم ألفاظاً عامة إذا كان للقاموس مقابل أدق.

{context}

السؤال: {question}

الإجابة:"""


def _rag_prompt_no_hits(question: str) -> str:
    """Safety template only: prefer skipping LLM when retrieval is empty (see get_rag_answer)."""
    return f"""أنت مساعد متخصص في اللهجة الحضرمية اليمنية.
لم يُسترجَع أي مدخل قاموسي يدعم إجابةً موثوقة عن السؤال.
يجب أن ترد بجملة واحدة فقط تطلب من المستخدم إعادة الصياغة أو البحث في القاموس، دون ذكر معانٍ أو ترجمات من عندك.

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
            entry.get("word_vocalized"),
            entry.get("word_clean"),
            *(_synonyms_from_entry(entry)),
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
                    h=str(ex.get("h", "")),
                    f=str(ex.get("f", "")),
                )
                for ex in raw_examples
                if isinstance(ex, dict)
            ]
        out.append(
            Entry(
                id=int(entry.get("id", 0)),
                word_vocalized=str(entry.get("word_vocalized", "")),
                word_clean=entry.get("word_clean"),
                root=entry.get("root"),
                pos=entry.get("pos"),
                fusha_equivalent=str(entry.get("fusha_equivalent", "")),
                definition=str(entry.get("definition", "")),
                region=entry.get("region", "General"),
                synonyms=entry.get("synonyms"),
                phonetic_variants=entry.get("phonetic_variants"),
                note=entry.get("note"),
                source=entry.get("source"),
                proverbs=entry.get("proverbs"),
                tags=entry.get("tags"),
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


def _gemini_generate(
    prompt: str,
    api_key: str,
    generation_config: Any | None = None,
) -> str:
    if not api_key:
        _rag_log("Gemini: no API key (GEMINI_API_KEY empty)")
        return "Gemini not available: set GEMINI_API_KEY"
    _rag_log(
        f"Gemini model={GEMINI_MODEL!r} chars={len(prompt)} | prompt: {_preview(prompt, 200)}"
    )
    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)

        order: list[str] = []
        for m in [GEMINI_MODEL, *_GEMINI_FALLBACK_MODELS]:
            if m and m not in order:
                order.append(m)

        gen_kwargs: dict[str, Any] = {}
        if generation_config is not None:
            gen_kwargs["generation_config"] = generation_config

        last_err: Exception | None = None
        for mname in order:
            try:
                model = genai.GenerativeModel(mname)
                response = model.generate_content(prompt, **gen_kwargs)
                text = (response.text or "").strip()
                if mname != GEMINI_MODEL:
                    _rag_log(f"Gemini used fallback model={mname!r}")
                _rag_log(f"Gemini answer_chars={len(text)} preview: {_preview(text)}")
                return text
            except Exception as e:
                last_err = e
                _rag_log(f"Gemini model {mname!r} failed: {e!r}")

        if last_err:
            return f"Gemini not available: {last_err}"
        return "Gemini not available: unknown error"
    except ImportError:
        _rag_log("Gemini: google-generativeai not installed")
        return "Gemini not available: google-generativeai not installed"


# ---------------------------------------------------------------------------
# Vector retrieval helpers (pgvector via Supabase RPC)
# ---------------------------------------------------------------------------

def _vector_context(query: str, top_k: int = 6) -> list[dict]:
    cache_key = (query.strip(), top_k)
    cached = _cache_get(_vector_cache, cache_key)
    if cached is not None:
        _rag_log(f"vector_context cache hit q={query!r} -> {len(cached)} hits")
        return cached

    from .services.embedding_service import embed_text

    embedding = embed_text(query)
    if embedding is None:
        _rag_log("vector_context: embedding unavailable -- skipping vector search")
        return []

    rows = rpc_match_entries(embedding, match_threshold=0.25, match_count=top_k)
    labels = [f"{r.get('word_vocalized', '?')}->{r.get('fusha_equivalent', '')} ({r.get('similarity', 0):.2f})" for r in rows[:5]]
    _rag_log(f"vector_context q={query!r} -> {len(rows)} hits: {labels}")
    return _cache_put(_vector_cache, cache_key, rows)


def _keyword_context(query: str, top_k: int = 5) -> list[dict]:
    result = keyword_search(query, limit=top_k)
    rows = result["results"]
    labels = [f"{r.get('word_vocalized', '?')}->{r.get('fusha_equivalent', '')}" for r in rows[:5]]
    _rag_log(f"keyword_search q={query!r} top_k={top_k} -> {len(rows)} hits: {labels}")
    return rows


def _expanded_keyword_context(query: str, top_k: int = 8) -> dict[str, Any]:
    cache_key = (query.strip(), top_k)
    cached = _cache_get(_keyword_cache, cache_key)
    if cached is not None:
        _rag_log(
            f"search_expanded cache hit q={query!r} top_k={top_k} -> {len(cached.get('results', []))} hits"
        )
        return cached

    payload = search_expanded(query, limit=top_k)
    rows = payload["results"]
    labels = [f"{r.get('word_vocalized', '?')}->{r.get('fusha_equivalent', '')}" for r in rows[:5]]
    _rag_log(
        f"search_expanded q={query!r} top_k={top_k} "
        f"score={payload.get('top_score', 0)} -> {len(rows)} hits: {labels}"
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
        _rag_log(f"exact keyword hit for q={query!r} -- skipping vector search")
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
        fb = merged[0].get("fusha_equivalent", "غير موجود") if merged else "غير موجود"
        tag = _rag_response_mode_tag()
        _rag_log(f"translation Gemini failed -> fallback mode={tag} answer_preview={_preview(fb)}")
        return _finalize_ask_payload(fb, tag, ctx_for_api)

    mode_tag = _rag_response_mode_tag()
    _rag_log(f"get_translation_answer END mode={mode_tag} answer_preview={_preview(answer)}")
    return _finalize_ask_payload(answer, mode_tag, ctx_for_api)


def get_rag_answer(question: str) -> dict:
    q = (question or "").strip()

    if _looks_like_translation_request(q):
        return get_translation_answer(q)

    merged, ctx_for_api = retrieve_rag_context(q)
    prompt = _prompt_for_gemini(q, merged)
    answer = _gemini_generate(prompt, _gemini_api_key())

    if answer.startswith("Gemini not available:"):
        fb = merged[0].get("fusha_equivalent", "غير موجود") if merged else "غير موجود"
        tag = _rag_response_mode_tag()
        _rag_log(f"Gemini failed -> fallback lexicon mode={tag} answer_preview={_preview(fb)}")
        return _finalize_ask_payload(fb, tag, ctx_for_api)

    mode_tag = _rag_response_mode_tag()
    _rag_log(f"get_rag_answer END mode={mode_tag} answer_preview={_preview(answer)}")
    return _finalize_ask_payload(answer, mode_tag, ctx_for_api)


# ---------------------------------------------------------------------------
# Chat (multi-turn conversation with RAG)
# ---------------------------------------------------------------------------

def _chat_prompt(
    user_message: str,
    history: list[dict[str, str]],
    context_entries: list[dict],
) -> str:
    context = _context_block(context_entries, definition_max_chars=320)
    history_block = ""
    if history:
        turns: list[str] = []
        for msg in history[-10:]:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            label = "المستخدم" if role == "user" else "المساعد"
            turns.append(f"{label}: {content}")
        history_block = "\n".join(turns)

    return f"""أنت مساعد ذكي ومتخصص في اللهجة الحضرمية اليمنية. تتحدث بأسلوب ودود وواضح.
اعتمد على المراجع القاموسية عندما تكون صلة السؤال بها واضحة؛ لا تلصق معنى مدخل قاموسي لا يطابق سؤال المستخدم الحالي.
إذا لم يكن أي مرجع يطابق السؤال، قل ذلك صراحة ثم يمكنك اقتراح معنى محتمل بلهجة حضرمية مع تنبيه أنه ليس من القاموس.

مهم جداً: لا تكتفي بكلمة أو بعبارة قصيرة جداً كإجابة كاملة. يجب أن يشرح ردك المعنى والسياق.

للإجابة عن معنى كلمة أو عبارة حضرمية، التزم بهذا التنسيق (بعناوين واضحة):
- **الكلمة أو العبارة:** (الشكل الحضرمي المناسب من المراجع إن وُجد)
- **المعنى بالفصحى:** (مقابل مباشر)
- **الشرح:** فقرتان على الأكثر تشرحان الاستعمال اليومي، الندرة، أو الفرق عن الفصحى إن لزم.
- **مثال:** جملة حضرمية قصيرة جداً ثم معناها بالفصحى (من المراجع إن وُجد، وإلا اذكر أن المثال تقريبي).

إذا كان السؤال ترجمة جملة (مثلاً «قال لي رح وديه»)، فسّر العبارة سطراً بسطراً ضمن **الشرح** ولا تكتف بذكر موضوع غير مرتبط من القاموس.

مراجع من القاموس:
{context if context else "(لا توجد مطابقات قاموسية واضحة)"}

{"سجل المحادثة السابقة (للسياق فقط؛ ركّز على آخر سؤال):" + chr(10) + history_block if history_block else ""}

المستخدم: {user_message}

المساعد:"""


def _chat_fallback_reply(entries: list[dict]) -> str:
    """Structured offline reply when Gemini is unavailable (not a single MSA gloss)."""
    if not entries:
        return (
            "تعذّر الاتصال بنموذج الإجابة الآن، ولم تُسترجَع مطابقة قاموسية واضحة لهذا السؤال. "
            "جرّب إعادة صياغة الكلمة كما تُنطق محلياً، أو استخدم صفحة ترجمة العبارات إن كان السؤال جملة."
        )
    parts: list[str] = []
    for entry in entries[:3]:
        head = str(entry.get("word_vocalized") or "").strip() or "—"
        fusha = str(entry.get("fusha_equivalent") or "").strip() or "—"
        definition = str(entry.get("definition") or "").strip()
        ex_h, ex_f = _first_example(entry)
        block = f"**{head}**\n\nالمعنى بالفصحى: {fusha}"
        if definition:
            block += f"\n\nالشرح (من القاموس): {definition[:500]}"
        if ex_h and ex_f:
            block += f"\n\nمثال: {ex_h} — {ex_f}"
        parts.append(block)
    tail = "\n\n_(إجابة مبسّطة من القاموس فقط؛ لتفسير أغنى فعّل نموذج Gemini.)_"
    return "\n\n---\n\n".join(parts) + tail


def get_chat_answer(
    message: str,
    history: list[dict[str, str]],
) -> dict[str, Any]:
    """Process a chat message with RAG context and conversation history."""
    q = (message or "").strip()
    merged, ctx_for_api = retrieve_rag_context(q)
    prompt = _chat_prompt(q, history, merged)
    chat_gen_cfg: Any | None = None
    try:
        import google.generativeai as genai

        chat_gen_cfg = genai.types.GenerationConfig(
            max_output_tokens=1536,
            temperature=0.35,
        )
    except ImportError:
        pass

    answer = _gemini_generate(prompt, _gemini_api_key(), chat_gen_cfg)

    if answer.startswith("Gemini not available:"):
        _rag_log("Chat Gemini failed -> fallback")
        answer = _chat_fallback_reply(merged)

    highlight_surfaces = _collect_highlight_surfaces(merged)
    return {
        "reply": answer,
        "context": _entries_to_response(ctx_for_api),
        "hadrami_spans": _find_hadrami_spans(answer, highlight_surfaces),
        "highlight_surfaces": highlight_surfaces,
    }


if __name__ == "__main__":
    import sys

    query = sys.argv[1] if len(sys.argv) > 1 else "ما معنى كلمة ويش؟"
    print(f"Query: {query}")
    print(f"Mode: {MODE}")
    result = get_rag_answer(query)
    print(f"Answer: {result['answer']}")
    print(f"Context ({len(result['context'])} entries):")
    for e in result["context"]:
        print(f"  - {e.word_vocalized} -> {e.fusha_equivalent}")
