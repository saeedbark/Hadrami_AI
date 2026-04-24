from contextlib import asynccontextmanager
from pathlib import Path

from dotenv import load_dotenv

# backend/.env (same directory as app package parent), not dependent on shell cwd
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional

from .core.config import (
    APP_DESCRIPTION,
    APP_TITLE,
    APP_VERSION,
    ASK_MAX_CHARS,
    DEFAULT_PAGE_SIZE,
    MAX_PAGE_SIZE,
)
from .core.data_store import count_rows
from .schemas import (
    AskRequest,
    AskResponse,
    ChatRequest,
    ChatResponse,
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


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        total = count_rows()
        print(f"Supabase connected — {total} entries in DB")
    except Exception as exc:
        print(f"Supabase connection check failed: {exc}")
    yield


app = FastAPI(
    title=APP_TITLE,
    description=APP_DESCRIPTION,
    version=APP_VERSION,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1|192\.168\.\d{1,3}\.\d{1,3})(:\d+)?",
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    total = count_rows()
    return {
        "message": "Hadrami NLP API",
        "version": APP_VERSION,
        "total_words": total,
        "endpoints": [
            "/translate",
            "/translate-phrase",
            "/search",
            "/semantic-search",
            "/word/{id}",
            "/stats",
            "/sections",
            "/feedback",
            "/ask",
            "/chat",
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


@app.get("/semantic-search", response_model=SearchResult)
def semantic_search(
    q: str = Query(..., description="Natural-language query for vector search"),
    limit: int = Query(10, ge=1, le=MAX_PAGE_SIZE),
    threshold: float = Query(0.3, ge=0.0, le=1.0),
):
    """Semantic / vector similarity search using pgvector embeddings."""
    from .services.embedding_service import embed_text

    query_embedding = embed_text(q)
    if query_embedding is None:
        raise HTTPException(status_code=503, detail="Embedding service unavailable")
    results = dictionary_service.semantic_search(query_embedding, threshold, limit)
    return SearchResult(total=len(results), results=results)


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
    pos: Optional[str] = Query(None, description="Filter by pos (Noun, Verb, Adjective, Expression)"),
    region: Optional[str] = Query(None, description="Filter by region"),
    tag: Optional[str] = Query(None, description="Filter by tag"),
):
    payload = dictionary_service.list_words(
        page=page, size=size, letter=letter, pos=pos, region=region, tag=tag,
    )
    return SearchResult(total=payload["total"], results=payload["results"])


@app.post("/feedback")
def submit_feedback(fb: FeedbackRequest):
    payload: dict = {
        "word_id": fb.word_id,
        "word_vocalized": fb.word_vocalized,
        "suggested_fusha": fb.suggested_fusha,
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


def _run_ask(q: str) -> AskResponse:
    from .rag_engine import _preview, _rag_log, get_rag_answer

    result = get_rag_answer(q)
    ctx_snip = [
        f"{e.word_vocalized}->{e.fusha_equivalent}" for e in result["context"][:3]
    ]
    _rag_log(
        f"/ask q={q!r} -> mode={result['mode']!r} | context={ctx_snip} | answer={_preview(result['answer'])}"
    )
    return AskResponse(
        question=q,
        answer=result["answer"],
        mode=result["mode"],
        hadrami_spans=result.get("hadrami_spans", []),
        highlight_surfaces=result.get("highlight_surfaces", []),
        context=result["context"],
    )


@app.get("/ask", response_model=AskResponse)
def ask_get(
    q: str = Query(
        ...,
        min_length=1,
        max_length=ASK_MAX_CHARS,
        description="Ask anything about Hadrami dialect",
    ),
):
    return _run_ask(q)


@app.post("/ask", response_model=AskResponse)
def ask_post(body: AskRequest):
    """Same as GET /ask but accepts the question in the JSON body."""
    return _run_ask(body.q)


@app.post("/chat", response_model=ChatResponse)
def chat(body: ChatRequest):
    """Conversational chat with RAG context and message history."""
    from .rag_engine import get_chat_answer

    history = [{"role": m.role.value, "content": m.content} for m in body.history]
    result = get_chat_answer(body.message, history)
    return ChatResponse(
        reply=result["reply"],
        context=result.get("context", []),
        hadrami_spans=result.get("hadrami_spans", []),
        highlight_surfaces=result.get("highlight_surfaces", []),
    )
