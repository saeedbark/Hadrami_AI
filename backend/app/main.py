from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional

from .core.config import APP_DESCRIPTION, APP_TITLE, APP_VERSION, DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE
from .core.data_store import ENTRIES
from .schemas import (
    Entry,
    FeedbackRequest,
    LexiconSectionsResponse,
    SearchResult,
    TranslatePhraseRequest,
    TranslatePhraseResponse,
    TranslateResponse,
)
from .services import dictionary_service
from .services.phrase_translation_service import translate_phrase as run_translate_phrase

app = FastAPI(title=APP_TITLE, description=APP_DESCRIPTION, version=APP_VERSION)

# Flutter web runs on a random port (e.g. :63094) while the API is on :8000 — browsers require CORS.
# Regex allows any localhost / 127.0.0.1 / LAN IP with a port (typical dev setups).
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1|192\.168\.\d{1,3}\.\d{1,3})(:\d+)?",
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

print(f"Loaded {len(ENTRIES)} entries")


@app.get("/")
def root():
    return {
        "message": "Hadrami NLP API",
        "version": APP_VERSION,
        "total_words": len(ENTRIES),
        "endpoints": [
            "/translate",
            "/translate-phrase",
            "/search",
            "/word/{id}",
            "/stats",
            "/sections",
            "/feedback",
            "/ask",
        ],
    }


@app.get("/stats")
def get_stats():
    return dictionary_service.get_stats()


@app.get("/sections", response_model=LexiconSectionsResponse)
def list_sections():
    return dictionary_service.get_sections()


@app.get("/translate", response_model=TranslateResponse)
def translate(q: str = Query(..., description="Hadrami word to translate")):
    return dictionary_service.translate(q)


@app.post("/translate-phrase", response_model=TranslatePhraseResponse)
def translate_phrase(body: TranslatePhraseRequest):
    return run_translate_phrase(body.text, body.direction.value)


@app.get("/search", response_model=SearchResult)
def search(
    q: str = Query(..., description="Search query"),
    limit: int = Query(DEFAULT_PAGE_SIZE, ge=1, le=MAX_PAGE_SIZE),
):
    payload = dictionary_service.search(q, limit)
    return SearchResult(total=payload["total"], results=payload["results"])


@app.get("/word/{word_id}", response_model=Entry)
def get_word(word_id: int):
    entry = dictionary_service.get_word(word_id)
    if entry:
        return entry
    raise HTTPException(status_code=404, detail="Word not found")


@app.get("/words", response_model=SearchResult)
def list_words(
    page: int = Query(1, ge=1),
    size: int = Query(DEFAULT_PAGE_SIZE, ge=1, le=MAX_PAGE_SIZE),
    letter: Optional[str] = None,
):
    payload = dictionary_service.list_words(page=page, size=size, letter=letter)
    return SearchResult(total=payload["total"], results=payload["results"])


@app.post("/feedback")
def submit_feedback(fb: FeedbackRequest):
    payload: dict = {
        "word_id": fb.word_id,
        "hadrami_word": fb.hadrami_word,
        "suggested_fus7a": fb.suggested_fus7a,
        "comment": fb.comment,
        "feedback_type": fb.feedback_type.value,
        "consent": fb.consent,
    }
    if fb.spelling_variants:
        payload["spelling_variants"] = fb.spelling_variants
    if fb.sentence_pair_hadrami:
        payload["sentence_pair_hadrami"] = fb.sentence_pair_hadrami
    if fb.sentence_pair_fusha:
        payload["sentence_pair_fusha"] = fb.sentence_pair_fusha
    dictionary_service.save_feedback(payload)
    return {"status": "success", "message": "شكراً على مساهمتك!"}


@app.get("/random")
def random_word():
    entry = dictionary_service.random_word()
    if not entry:
        raise HTTPException(status_code=404, detail="No entries")
    return entry


@app.get("/ask")
def ask(q: str = Query(..., description="Ask anything about Hadrami dialect")):
    from .rag_engine import _preview, _rag_log, get_rag_answer

    result = get_rag_answer(q)
    ctx_snip = [
        f"{e.get('hadrami_word', '?')}→{e.get('arabic_fus7a', '')}" for e in result["context"][:3]
    ]
    _rag_log(
        f"🌐 /ask q={q!r} → mode={result['mode']!r} | context={ctx_snip} | answer={_preview(result['answer'])}"
    )
    return {
        "question": q,
        "answer": result["answer"],
        "mode": result["mode"],
        "context": result["context"][:3],
    }


@app.post("/admin/build-index")
def build_index():
    from .rag_engine import LocalRAG

    rag = LocalRAG()
    success = rag.build_index()
    return {"success": success, "total_entries": len(ENTRIES)}
