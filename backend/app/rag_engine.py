import os
from pathlib import Path
from typing import Optional

try:
    from dotenv import load_dotenv

    load_dotenv(Path(__file__).resolve().parent.parent / ".env")
except ImportError:
    pass

from .core.data_store import ENTRIES
from .services.dictionary_service import search as keyword_search
from .services.dictionary_service import search_expanded

MODE = os.getenv("RAG_MODE", "local")
# Gemini: set GEMINI_API_KEY and optional GEMINI_MODEL.
# Default gemini-2.5-flash matches current AI Studio free-tier naming; 2.0-flash often hits separate quotas first.
# Fallbacks are tried in order on quota / NotFound (see logs). Invalid preview IDs are omitted.
# Heavy Chroma/HF is off until RAG_USE_CHROMA=1 after POST /admin/build-index.
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
_GEMINI_FALLBACK_MODELS = [
    "gemini-2.0-flash",
    "gemini-2.5-flash-lite",
    "gemini-1.5-flash-002",
]


def _use_chroma() -> bool:
    return os.getenv("RAG_USE_CHROMA", "0").lower() in ("1", "true", "yes")


def _rag_log(msg: str) -> None:
    if os.getenv("RAG_DEBUG", "1").lower() in ("0", "false", "no", "off"):
        return
    print(msg, flush=True)


def _preview(text: str, max_len: int = 160) -> str:
    t = (text or "").replace("\n", " ")
    return t if len(t) <= max_len else t[: max_len - 3] + "..."


def _gemini_api_key() -> str:
    return (os.getenv("GEMINI_API_KEY") or "").strip()


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


def _rag_prompt(question: str, context_entries: list[dict]) -> str:
    context = "\n".join(
        [
            f"- الكلمة: {e['hadrami_word']} | الفصحى: {e.get('arabic_fus7a', '')} | الشرح: {e.get('full_definition', '')[:100]}"
            for e in context_entries
        ]
    )
    return f"""أنت مساعد متخصص في اللهجة الحضرمية اليمنية.
استخدم المعلومات التالية من القاموس فقط كأساس للشرح، ووسّع الإجابة بجملة أو جملتين واضحتين بالعربية الفصحى.
بعد الشرح مباشرة، أضف فقرة قصيرة بعنوان «مثال» تتضمن جملة حضرمية بسيطة تستخدم الكلمة أو تعبيراً قريباً منها، ثم اشرح معنى الجملة بالفصحى (يجب أن يبقى المثال متسقاً مع القاموس أعلاه ولا تخترع معانٍ جديدة).

{context}

السؤال: {question}

الإجابة (شرح ثم مثال):"""


def _rag_prompt_no_hits(question: str) -> str:
    return f"""أنت مساعد متخصص في اللهجة الحضرمية اليمنية.
لم يُعثر في القاموس الحضرمي على مدخل يطابق السؤال بوضوح.
أجب باختصار بالعربية الفصحى: اعتذر وأوضح أن الكلمة أو العبارة غير موجودة في قاموسنا حالياً، واقترح على المستخدم إعادة الصياغة (مثلاً كتابة الكلمة كما تُقال محلياً، مع أو بدون «ال»، أو إضافة الهمزة إن وُجدت).
لا تخترع معنىً لكلمة حضرمية محددة ولا تقدّم ترجمة وكأنها من القاموس.
في نهاية الإجابة أضف سطراً بعنوان «مثال» يوضّح كيف يمكن صياغة سؤال أفضل للبحث (دون اختراع معنى للكلمة المذكورة في السؤال).

السؤال: {question}

الإجابة:"""


def _prompt_for_gemini(question: str, context_entries: list[dict]) -> str:
    if context_entries:
        return _rag_prompt(question, context_entries)
    return _rag_prompt_no_hits(question)


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


def _keyword_context(query: str, top_k: int = 5) -> list[dict]:
    result = keyword_search(query, limit=top_k)
    rows = result["results"]
    labels = [f"{r.get('hadrami_word', '?')}→{r.get('arabic_fus7a', '')}" for r in rows[:5]]
    _rag_log(f"🔎 keyword_search q={query!r} top_k={top_k} → {len(rows)} hits: {labels}")
    return rows


def _expanded_keyword_context(query: str, top_k: int = 8) -> list[dict]:
    rows = search_expanded(query, limit=top_k)["results"]
    labels = [f"{r.get('hadrami_word', '?')}→{r.get('arabic_fus7a', '')}" for r in rows[:5]]
    _rag_log(f"🔎 search_expanded q={query!r} top_k={top_k} → {len(rows)} hits: {labels}")
    return rows


class LocalRAG:
    def __init__(self):
        self._collection = None
        self._client = None

    def _get_collection(self):
        if self._collection is not None:
            return self._collection
        try:
            import chromadb
            from chromadb.utils import embedding_functions

            self._client = chromadb.PersistentClient(path="./hadrami_chroma_db")
            emb_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
                model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
            )
            self._collection = self._client.get_or_create_collection(
                name="hadrami_words",
                embedding_function=emb_fn,
                metadata={"hnsw:space": "cosine"},
            )
            return self._collection
        except ImportError:
            return None

    def build_index(self) -> bool:
        collection = self._get_collection()
        if collection is None:
            return False

        if collection.count() >= len(ENTRIES):
            return True

        batch_size = 100
        for i in range(0, len(ENTRIES), batch_size):
            batch = ENTRIES[i : i + batch_size]
            ids = [str(e["id"]) for e in batch]
            docs = [
                f"{e['hadrami_word']} {e.get('arabic_fus7a', '')} {e.get('full_definition', '')}"
                for e in batch
            ]
            metas = [
                {
                    "hadrami_word": e["hadrami_word"],
                    "arabic_fus7a": e.get("arabic_fus7a", ""),
                    "word_id": e["id"],
                }
                for e in batch
            ]
            collection.upsert(ids=ids, documents=docs, metadatas=metas)

        return True

    def chroma_search(self, query: str, top_k: int = 5) -> Optional[list[dict]]:
        """Vector search only; returns None if Chroma is missing or empty (avoid duplicate keyword pass)."""
        collection = self._get_collection()
        if collection is None or collection.count() == 0:
            return None

        results = collection.query(query_texts=[query], n_results=top_k)

        found = []
        for meta in results["metadatas"][0] if results["metadatas"] else []:
            word_id = meta.get("word_id")
            entry = next((e for e in ENTRIES if e["id"] == word_id), None)
            if entry:
                found.append(entry)
        labels = [f"{e.get('hadrami_word', '?')}→{e.get('arabic_fus7a', '')}" for e in found[:5]]
        _rag_log(f"📚 chroma_search q={query!r} n={len(found)} → {labels}")
        return found

    def vector_search(self, query: str, top_k: int = 5) -> list[dict]:
        chroma_hits = self.chroma_search(query, top_k)
        if chroma_hits is not None:
            return chroma_hits
        _rag_log(f"📚 vector_search: no Chroma index → fallback keyword for q={query!r}")
        return _keyword_context(query, top_k)


_local_rag = None


def get_rag_answer(question: str) -> dict:
    global _local_rag

    if MODE == "simple":
        context = _keyword_context(question, top_k=3)
        if not context:
            answer = "غير موجود"
            _rag_log(f"📌 branch=simple (no hits) answer_preview={_preview(answer)}")
            return {"answer": answer, "context": context, "mode": "simple"}
        answer = context[0].get("arabic_fus7a", "غير موجود")
        _rag_log(f"📌 branch=simple mode=simple answer_preview={_preview(answer)}")
        return {"answer": answer, "context": context, "mode": "simple"}

    kw_ctx = _expanded_keyword_context(question, top_k=8)
    chroma_ctx: list[dict] = []
    if MODE == "local" and _use_chroma():
        if _local_rag is None:
            _local_rag = LocalRAG()
        ch = _local_rag.chroma_search(question, top_k=6)
        if ch is not None:
            chroma_ctx = ch
    elif MODE == "local":
        _rag_log(
            "📚 Chroma/HF skipped (RAG_USE_CHROMA is off). Keyword RAG + Gemini only. "
            "After POST /admin/build-index set RAG_USE_CHROMA=1 for vector search."
        )

    merged = _merge_entries_by_id(kw_ctx, chroma_ctx)[:5]
    ctx_for_api = merged[:3]
    prompt = _prompt_for_gemini(question, merged)
    answer = _gemini_generate(prompt, _gemini_api_key())

    if answer.startswith("Gemini not available:"):
        fb = merged[0].get("arabic_fus7a", "غير موجود") if merged else "غير موجود"
        _rag_log(f"🔁 Gemini failed → fallback simple answer_preview={_preview(fb)}")
        return {"answer": fb, "context": ctx_for_api, "mode": "simple"}

    mode_tag = "local_gemini" if MODE == "local" else "gemini"
    _rag_log(f"⬅️ get_rag_answer END mode={mode_tag} answer_preview={_preview(answer)}")
    return {"answer": answer, "context": ctx_for_api, "mode": mode_tag}


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
