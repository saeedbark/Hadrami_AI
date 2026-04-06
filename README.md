# Hadrami NLP Project

A bilingual dictionary and translation tool for the **Hadrami dialect** of Yemeni Arabic.
Combines a curated 1 000+ entry lexicon with RAG (Retrieval-Augmented Generation) powered by Gemini
to provide word-level translation, phrase translation, and AI-powered Q&A.

**Backend:** FastAPI (Python) &nbsp;|&nbsp; **Frontend:** Flutter (Riverpod + go_router)

---

## Project Structure

```
hadrami_project/
├── backend/                     ← FastAPI REST API
│   ├── app/
│   │   ├── main.py              ← Routes & middleware
│   │   ├── schemas.py           ← Pydantic request/response models
│   │   ├── rag_engine.py        ← RAG + Gemini pipeline (/ask, /translate-phrase)
│   │   ├── core/
│   │   │   ├── config.py        ← Constants, paths, limits
│   │   │   └── data_store.py    ← Dataset loading at startup
│   │   └── services/
│   │       ├── dictionary_service.py        ← Search, translate, feedback
│   │       └── phrase_translation_service.py ← Chunked phrase translation
│   ├── data/
│   │   ├── hadrami_dataset.json ← Main lexicon (1 026 entries, v1.1.0)
│   │   └── eval_pairs.json      ← Held-out evaluation pairs
│   ├── scripts/                 ← Data quality & maintenance scripts
│   ├── tests/                   ← Pytest API smoke tests
│   ├── requirements.txt
│   ├── run.ps1                  ← Windows: install deps + start server
│   └── run.sh                   ← Linux/macOS: install deps + start server
│
├── flutter_app/                 ← Flutter mobile/web/desktop client
│   ├── lib/
│   │   ├── main.dart            ← Entry point (ProviderScope)
│   │   └── src/
│   │       ├── app.dart         ← MaterialApp.router + theme
│   │       ├── configs/         ← API URL, colors, radii, phrase limits
│   │       ├── core/            ← Models, services, providers, routing, theme
│   │       ├── widgets/         ← Shared UI components
│   │       └── modules/         ← Feature modules (home, search, dictionary, ...)
│   └── pubspec.yaml
│
├── docs/
│   └── methods_evaluation.md    ← System architecture & evaluation protocol
│
└── ROADMAP.md                   ← Future improvement ideas
```

---

## Quick Start

### Prerequisites

- **Python 3.10+** with pip
- **Flutter SDK 3.x** ([install guide](https://docs.flutter.dev/get-started/install))
- A **Gemini API key** (for AI features — set in `backend/.env`)

### 1. Start the Backend

```bash
cd backend
python -m venv venv
```

Activate the virtual environment:

```powershell
# Windows PowerShell
.\venv\Scripts\Activate.ps1
```
```bash
# Linux / macOS
source venv/bin/activate
```

Install dependencies and launch:

```bash
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Or use the helper script: `.\run.ps1` (Windows) / `./run.sh` (Linux/macOS).

Verify at:
- API root: http://localhost:8000
- Swagger docs: http://localhost:8000/docs

### 2. Run Tests

```bash
cd backend
python -m pytest tests/ -v
```

### 3. Start the Frontend

```bash
cd flutter_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### 4. Connect Frontend to Backend

The API URL defaults to `http://localhost:8000`. Override with `--dart-define`:

| Platform | Command |
|----------|---------|
| Web / Desktop (same machine) | `flutter run` (default works) |
| Android emulator | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000` |
| Physical phone | `flutter run --dart-define=API_BASE_URL=http://<your-lan-ip>:8000` |

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API info + version |
| GET | `/stats` | Dictionary statistics |
| GET | `/translate?q=word` | Translate a Hadrami word |
| POST | `/translate-phrase` | Phrase translation (body: `text`, `direction`) |
| GET | `/search?q=word&limit=20` | Search the dictionary |
| GET | `/words?page=1&size=20` | Paginated word list (optional `letter` filter) |
| GET | `/word/{id}` | Single word by ID |
| GET | `/random` | Random word |
| POST | `/feedback` | Submit a correction or new word |
| GET | `/ask?q=question` | AI-powered Q&A (RAG) |
| POST | `/admin/build-index` | Rebuild vector index |

---

## Dataset (v1.1.0)

The lexicon lives in `backend/data/hadrami_dataset.json` with **1 026 entries**.

Each entry has:

| Field | Type | Description |
|-------|------|-------------|
| `id` | int | Unique identifier |
| `hadrami_word` | string | Hadrami dialect word |
| `arabic_fus7a` | string | Modern Standard Arabic equivalent |
| `full_definition` | string | Detailed definition with context |
| `fus7a_short` | string? | Concise 1-3 word MSA gloss |
| `aliases` | string[]? | Variant spellings or forms |
| `examples` | ExamplePair[]? | Usage examples (`hadrami` + `fusha` fields) |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | FastAPI, Pydantic, Uvicorn |
| AI / RAG | Google Gemini via `google-generativeai` |
| Frontend | Flutter 3.x, Riverpod, go_router |
| Forms | reactive_forms + code generation |
| Models | freezed + json_serializable |
| Theme | Material 3, responsive layout |
| Testing | pytest (backend), flutter_test (frontend) |

---

## App Screens

1. **Home** — translate a word, view stats, word of the day
2. **Search** — live debounced search with result count
3. **Dictionary** — full word list with Arabic letter filter
4. **Favorites** — locally saved words
5. **Ask** — AI Q&A about the Hadrami dialect
6. **Phrases** — phrase-level MSA ↔ Hadrami translation with highlighted spans
7. **Settings** — connection test, theme toggle, about info

---

## Contributing

See [ROADMAP.md](ROADMAP.md) for planned improvements. Contributions welcome.
