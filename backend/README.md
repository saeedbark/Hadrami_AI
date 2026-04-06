# Backend — Hadrami NLP API

FastAPI REST API serving the Hadrami dialect dictionary, word/phrase translation, and AI-powered Q&A.

---

## Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate    # Linux/macOS
# .\venv\Scripts\Activate.ps1  # Windows PowerShell

pip install -r requirements.txt
```

### Environment Variables

Create a `.env` file (never commit it):

```
GEMINI_API_KEY=your-google-gemini-api-key
```

The API key is required for `/ask` and `/translate-phrase`. All other endpoints work without it.

### Run the Server

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Or use the helper scripts: `./run.sh` (Linux/macOS) or `.\run.ps1` (Windows).

Open http://localhost:8000/docs for interactive Swagger documentation.

---

## Code Architecture

```
app/
├── main.py                  ← FastAPI app, all route handlers
├── schemas.py               ← Pydantic models (Entry, FeedbackRequest, etc.)
├── rag_engine.py            ← RAG pipeline: Gemini integration, vector search
├── core/
│   ├── config.py            ← App constants, file paths, translation limits
│   └── data_store.py        ← Loads hadrami_dataset.json into memory at startup
└── services/
    ├── dictionary_service.py         ← Word search, translate, feedback, pagination
    └── phrase_translation_service.py ← Chunked phrase translation via Gemini
```

### Key Design Decisions

- **In-memory dataset**: The entire lexicon (~1 000 entries) is loaded into a Python list at startup via `data_store.py`. This makes search and scoring fast with zero database overhead.
- **Scoring-based search**: `dictionary_service.py` scores matches by exact → substring → definition containment with numeric weights, then sorts by score.
- **RAG for AI features**: `/ask` and `/translate-phrase` use keyword retrieval from the lexicon to build a context prompt sent to Gemini. No external vector DB is required for basic operation.
- **Chunked translation**: Long texts are split on paragraph/sentence boundaries and translated chunk-by-chunk to stay within Gemini's quality sweet spot.

---

## API Reference

### Dictionary

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | API info and version |
| `/stats` | GET | Total words, translated count, completion % |
| `/translate?q=<word>` | GET | Translate a single Hadrami word (exact → partial → definition match) |
| `/search?q=<query>&limit=20` | GET | Scored search across word, fus7a, and definition |
| `/words?page=1&size=20&letter=أ` | GET | Paginated word list with optional letter filter |
| `/word/<id>` | GET | Single entry by ID |
| `/random` | GET | Random dictionary entry |

### AI / Translation

| Endpoint | Method | Body | Description |
|----------|--------|------|-------------|
| `/ask?q=<question>` | GET | — | RAG-powered Q&A about the Hadrami dialect |
| `/translate-phrase` | POST | `{"text": "...", "direction": "ar_to_hadrami"}` | Phrase translation (MSA ↔ Hadrami) |

Direction values: `ar_to_hadrami`, `hadrami_to_ar`

### Feedback

| Endpoint | Method | Body |
|----------|--------|------|
| `/feedback` | POST | `{"hadrami_word": "...", "suggested_fus7a": "...", "feedback_type": "correction"}` |

Feedback types: `correction`, `new_word`, `sentence_pair`, `spelling_variant`

---

## Testing

```bash
python -m pytest tests/ -v
```

The test suite (`tests/test_api.py`) covers all endpoints with 21 smoke tests:
- Root and stats endpoints
- Translate (known word, unknown word, missing query)
- Search (results and empty query)
- Word listing, filtering, single word, not found
- Random word
- Feedback (basic, extended, validation)
- Phrase translation (both directions, invalid direction, empty text, too long)
- Schema validation for optional fields

---

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/validate_dataset.py` | Check dataset integrity: unique IDs, required keys, short fus7a, schema validation |
| `scripts/audit_dataset.py` | Audit arabic_fus7a quality: empty, single-char, truncated glosses |
| `scripts/refactor_dataset.py` | One-time refactoring: fix truncated fus7a, merge duplicates, extract examples, add fields |

Run any script from the `backend/` directory:

```bash
python scripts/validate_dataset.py
python scripts/audit_dataset.py
```

---

## Dataset Format

`data/hadrami_dataset.json` — version 1.1.0, 1 026 entries.

```json
{
  "version": "1.1.0",
  "updated": "2026-04-04",
  "total": 1026,
  "entries": [
    {
      "id": 1,
      "hadrami_word": "أم حبيل",
      "arabic_fus7a": "العنكبوت",
      "full_definition": "العنكبوت.",
      "fus7a_short": null,
      "aliases": null,
      "examples": null
    }
  ]
}
```

Optional fields (`fus7a_short`, `aliases`, `examples`) are omitted when null to keep the file compact.
