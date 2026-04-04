# Hadrami NLP Project

Backend FastAPI + Frontend Flutter (Riverpod + go_router)

---

## Project Structure

```
hadrami_project/
├── backend/
│   ├── app/
│   │   ├── main.py                ← FastAPI routes
│   │   ├── schemas.py             ← Pydantic models
│   │   ├── rag_engine.py          ← RAG / ask pipeline
│   │   ├── core/
│   │   │   ├── config.py          ← constants + paths
│   │   │   └── data_store.py      ← dataset loading
│   │   └── services/
│   │       ├── dictionary_service.py
│   │       └── phrase_translation_service.py ← phrase + lexicon
│   ├── data/
│   │   ├── hadrami_dataset.json
│   │   └── feedback.json
│   ├── requirements.txt
│   ├── run.sh
│   └── run_api.ps1                ← Windows: venv + uvicorn
│
└── flutter_app/
    ├── lib/
    │   ├── main.dart              ← Entry point (ProviderScope)
    │   └── src/
    │       ├── app.dart           ← MaterialApp.router + theme
    │       ├── configs/
    │       │   ├── api_config.dart
    │       │   ├── phrase_translate_config.dart
    │       │   ├── app_colors.dart
    │       │   └── app_radius.dart
    │       ├── core/
    │       │   ├── models/
    │       │   │   └── word_entry.dart
    │       │   ├── services/
    │       │   │   └── api_service.dart
    │       │   ├── providers/
    │       │   │   └── theme_provider.dart
    │       │   ├── routing/
    │       │   │   └── router.dart
    │       │   └── theme/
    │       │       └── theme.dart
    │       ├── widgets/
    │       │   ├── app_card.dart
    │       │   ├── app_scaffold.dart
    │       │   ├── hadrami_highlighted_text.dart
    │       │   ├── loading_widget.dart
    │       │   ├── error_widget.dart
    │       │   └── empty_state.dart
    │       └── modules/
    │           ├── landing/pages/landing_page.dart
    │           ├── home/
    │           │   ├── pages/home_page.dart
    │           │   ├── providers/home_provider.dart
    │           │   └── widgets/translate_result_card.dart
    │           ├── search/
    │           │   ├── pages/search_page.dart
    │           │   └── providers/search_provider.dart
    │           ├── dictionary/
    │           │   ├── pages/dictionary_page.dart
    │           │   ├── providers/dictionary_provider.dart
    │           │   └── widgets/
    │           │       ├── word_card.dart
    │           │       └── word_detail_sheet.dart
    │           ├── favorites/
    │           │   ├── pages/favorites_page.dart
    │           │   └── providers/favorites_provider.dart
    │           ├── ask/
    │           │   ├── pages/ask_page.dart
    │           │   └── providers/ask_provider.dart
    │           ├── phrase/
    │           │   ├── pages/phrase_translate_page.dart
    │           │   └── providers/
    │           └── settings/pages/settings_page.dart
    └── pubspec.yaml
```

---

## How To Run (Backend + Frontend)

### Requirements

- Python 3.10+
- Flutter SDK 3.x
- Git (optional)

### 1) Run Backend

```bash
cd backend
python -m venv venv
```

Activate virtual environment:

- Windows PowerShell:
```powershell
.\venv\Scripts\Activate.ps1
```
- Linux/macOS:
```bash
source venv/bin/activate
```

Install dependencies and start API:

```bash
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

On Windows, from `backend` with the venv already created and dependencies installed, you can use `.\run_api.ps1` instead of the `uvicorn` line above (same host, port, and reload).

Backend URLs:

- API base: `http://localhost:8000`
- Swagger docs: `http://localhost:8000/docs`
- OpenAPI JSON: `http://localhost:8000/openapi.json`

### 2) Test Backend API Quickly

Use the docs page, or test from terminal.

Examples:

```bash
curl "http://localhost:8000/stats"
curl "http://localhost:8000/translate?q=ويش"
curl "http://localhost:8000/search?q=ويش&limit=5"
curl "http://localhost:8000/words?page=1&size=10"
curl "http://localhost:8000/random"
```

POST phrase translation (MSA ↔ Hadrami; `direction` is `ar_to_hadrami` or `hadrami_to_ar`):

```bash
curl -X POST "http://localhost:8000/translate-phrase" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"مرحبا\",\"direction\":\"ar_to_hadrami\"}"
```

POST feedback example:

```bash
curl -X POST "http://localhost:8000/feedback" \
  -H "Content-Type: application/json" \
  -d "{\"word_id\":1,\"hadrami_word\":\"ويش\",\"suggested_fus7a\":\"ماذا\",\"comment\":\"test\"}"
```

If all responses are valid JSON, backend is ready for frontend.

### 3) Run Frontend (Flutter)

```bash
cd flutter_app
flutter pub get
flutter run
```

### 4) Connect Frontend To Backend API

The API base URL is set in `flutter_app/lib/src/configs/api_config.dart` via compile-time define **`API_BASE_URL`** (default `http://localhost:8000`).

Phrase screen limits and soft-length hints live in `phrase_translate_config.dart` and match the backend caps.

**Web / Windows / macOS desktop (same machine as backend):** default is enough.

**Android emulator** (`localhost` points at the emulator, not your PC):

```bash
cd flutter_app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**Physical phone:** use your computer’s LAN IP and allow the port in the Windows firewall if needed:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
```

**iOS simulator:** usually `http://localhost:8000` works; if not, use your Mac’s IP with `--dart-define`.

After changing the define, do a full restart (not only hot reload).

### 5) End-to-End Test (Backend + Frontend)

1. Start backend and keep it running.
2. Start Flutter app.
3. In app Home screen, translate a word like `ويش`.
4. Open Dictionary and verify list loads.
5. Open Ask screen and send a question.
6. Open Phrases (عبارات) and try a short phrase in both directions.
7. Open Settings and run connection test.

If these pass, integration is working.

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API info |
| GET | `/stats` | Dictionary stats |
| GET | `/translate?q=word` | Translate Hadrami word |
| POST | `/translate-phrase` | Phrase translation (body: `text`, `direction`) |
| GET | `/search?q=word` | Search dictionary |
| GET | `/words?page=1&size=20` | Paginated word list |
| GET | `/word/{id}` | Single word |
| GET | `/random` | Random word |
| POST | `/feedback` | Submit correction |
| GET | `/ask?q=question` | AI-powered Q&A (RAG) |
| POST | `/admin/build-index` | Build vector index |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | FastAPI + Python |
| Frontend | Flutter + Riverpod + go_router |
| State | hooks_riverpod + flutter_hooks |
| Routing | go_router (StatefulShellRoute) |
| Theme | Material 3 + responsive (mobile/tablet/desktop) |
| AI | RAG (Gemini / simple keyword) |

---

## App Screens

1. **Home** - translate + stats + random word of the day
2. **Search** - live search as you type
3. **Dictionary** - full word list with Arabic letter filter
4. **Favorites** - saved words
5. **Ask** - AI Q&A about the Hadrami dialect
6. **Phrases** (عبارات) - phrase-level translation with highlighted Hadrami spans
7. **Settings** - connection test + about info
