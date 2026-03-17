from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import json
import os
import re
from pathlib import Path

app = FastAPI(
    title="Hadrami Dialect NLP API",
    description="API for Hadrami Arabic dialect translation and search",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Load dataset ────────────────────────────────────────────────────────────
DATA_FILE = Path(__file__).parent.parent / "data" / "hadrami_dataset.json"

def load_data():
    if DATA_FILE.exists():
        with open(DATA_FILE, encoding="utf-8") as f:
            return json.load(f)["entries"]
    return []

ENTRIES = load_data()
print(f"✅ Loaded {len(ENTRIES)} entries")

# ── Models ──────────────────────────────────────────────────────────────────
class Entry(BaseModel):
    id: int
    hadrami_word: str
    arabic_fus7a: str
    full_definition: str

class TranslateResponse(BaseModel):
    found: bool
    hadrami_word: str
    arabic_fus7a: str
    full_definition: str
    confidence: str  # "exact" | "partial" | "not_found"

class FeedbackRequest(BaseModel):
    word_id: int
    hadrami_word: str
    suggested_fus7a: str
    comment: Optional[str] = None

class SearchResult(BaseModel):
    total: int
    results: List[Entry]

# ── Routes ───────────────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {
        "message": "Hadrami NLP API",
        "version": "1.0.0",
        "total_words": len(ENTRIES),
        "endpoints": ["/translate", "/search", "/word/{id}", "/stats", "/feedback"]
    }

@app.get("/stats")
def get_stats():
    total = len(ENTRIES)
    with_fus7a = sum(1 for e in ENTRIES if e.get("arabic_fus7a", "").strip())
    return {
        "total_words": total,
        "translated": with_fus7a,
        "pending": total - with_fus7a,
        "completion_percent": round(with_fus7a / total * 100, 1) if total else 0
    }

@app.get("/translate", response_model=TranslateResponse)
def translate(q: str = Query(..., description="Hadrami word to translate")):
    q_clean = q.strip()
    
    # 1. Exact match
    for e in ENTRIES:
        if e["hadrami_word"].strip() == q_clean:
            return TranslateResponse(
                found=True,
                hadrami_word=e["hadrami_word"],
                arabic_fus7a=e["arabic_fus7a"],
                full_definition=e["full_definition"],
                confidence="exact"
            )
    
    # 2. Partial match (word contained in entry or vice versa)
    for e in ENTRIES:
        word = e["hadrami_word"].strip()
        if q_clean in word or word in q_clean:
            return TranslateResponse(
                found=True,
                hadrami_word=e["hadrami_word"],
                arabic_fus7a=e["arabic_fus7a"],
                full_definition=e["full_definition"],
                confidence="partial"
            )
    
    # 3. Search in definitions
    for e in ENTRIES:
        if q_clean in e.get("full_definition", ""):
            return TranslateResponse(
                found=True,
                hadrami_word=e["hadrami_word"],
                arabic_fus7a=e["arabic_fus7a"],
                full_definition=e["full_definition"],
                confidence="partial"
            )
    
    return TranslateResponse(
        found=False,
        hadrami_word=q_clean,
        arabic_fus7a="",
        full_definition="الكلمة غير موجودة في القاموس",
        confidence="not_found"
    )

@app.get("/search", response_model=SearchResult)
def search(
    q: str = Query(..., description="Search query"),
    limit: int = Query(20, ge=1, le=100)
):
    q_lower = q.strip()
    results = []
    
    for e in ENTRIES:
        score = 0
        word = e["hadrami_word"]
        fus7a = e.get("arabic_fus7a", "")
        defn = e.get("full_definition", "")
        
        if word == q_lower:
            score = 100
        elif q_lower in word:
            score = 80
        elif word in q_lower:
            score = 70
        elif q_lower in fus7a:
            score = 60
        elif q_lower in defn:
            score = 40
        
        if score > 0:
            results.append((score, e))
    
    results.sort(key=lambda x: -x[0])
    top = [r[1] for r in results[:limit]]
    
    return SearchResult(total=len(results), results=top)

@app.get("/word/{word_id}", response_model=Entry)
def get_word(word_id: int):
    for e in ENTRIES:
        if e["id"] == word_id:
            return e
    raise HTTPException(status_code=404, detail="Word not found")

@app.get("/words", response_model=SearchResult)
def list_words(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    letter: Optional[str] = None
):
    filtered = ENTRIES
    if letter:
        filtered = [e for e in ENTRIES if e["hadrami_word"].strip().startswith(letter)]
    
    total = len(filtered)
    start = (page - 1) * size
    end = start + size
    
    return SearchResult(total=total, results=filtered[start:end])

@app.post("/feedback")
def submit_feedback(fb: FeedbackRequest):
    # Save feedback to file
    feedback_file = Path(__file__).parent.parent / "data" / "feedback.json"
    feedbacks = []
    if feedback_file.exists():
        with open(feedback_file, encoding="utf-8") as f:
            feedbacks = json.load(f)
    
    feedbacks.append({
        "word_id": fb.word_id,
        "hadrami_word": fb.hadrami_word,
        "suggested_fus7a": fb.suggested_fus7a,
        "comment": fb.comment
    })
    
    with open(feedback_file, "w", encoding="utf-8") as f:
        json.dump(feedbacks, f, ensure_ascii=False, indent=2)
    
    return {"status": "success", "message": "شكراً على مساهمتك!"}

@app.get("/random")
def random_word():
    import random
    if not ENTRIES:
        raise HTTPException(status_code=404, detail="No entries")
    return random.choice(ENTRIES)

# ── RAG endpoint (AI-powered) ────────────────────────────────────────────────
@app.get("/ask")
def ask(q: str = Query(..., description="Ask anything about Hadrami dialect")):
    """
    AI-powered Q&A using RAG.
    Uses simple keyword search by default.
    Set RAG_MODE=local for Ollama, RAG_MODE=prod for Gemini.
    """
    from .rag_engine import get_rag_answer
    result = get_rag_answer(q)
    return {
        "question": q,
        "answer": result["answer"],
        "mode": result["mode"],
        "context": result["context"][:3],
    }

# ── Build RAG index ──────────────────────────────────────────────────────────
@app.post("/admin/build-index")
def build_index():
    """Build ChromaDB vector index (LOCAL mode only). Run once."""
    from .rag_engine import LocalRAG
    rag = LocalRAG()
    success = rag.build_index()
    return {"success": success, "total_entries": len(ENTRIES)}
