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
│   │   ├── core/
│   │   │   ├── config.py          ← constants + paths
│   │   │   └── data_store.py      ← dataset loading
│   │   └── services/
│   │       └── dictionary_service.py ← business logic
│   ├── data/
│   │   ├── hadrami_dataset.json
│   │   └── feedback.json
│   ├── requirements.txt
│   └── run.sh
│
└── flutter_app/
    ├── lib/
    │   ├── main.dart              ← Entry point (ProviderScope)
    │   └── src/
    │       ├── app.dart           ← MaterialApp.router + theme
    │       ├── configs/
    │       │   ├── api_config.dart
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

Frontend reads API URL from:

- `flutter_app/lib/src/configs/api_config.dart`

Default:

```dart
static const String baseUrl = 'http://localhost:8000';
```

Use the correct host per platform:

- Android emulator: `http://10.0.2.2:8000`
- iOS simulator: `http://localhost:8000`
- Real phone/device: `http://YOUR_COMPUTER_IP:8000`

After changing `baseUrl`, restart Flutter app.

### 5) End-to-End Test (Backend + Frontend)

1. Start backend and keep it running.
2. Start Flutter app.
3. In app Home screen, translate a word like `ويش`.
4. Open Dictionary and verify list loads.
5. Open Ask screen and send a question.
6. Open Settings and run connection test.

If these pass, integration is working.

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API info |
| GET | `/stats` | Dictionary stats |
| GET | `/translate?q=word` | Translate Hadrami word |
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
| AI | RAG (Gemini / Ollama / simple keyword) |

---

## App Screens

1. **Home** - translate + stats + random word of the day
2. **Search** - live search as you type
3. **Dictionary** - full word list with Arabic letter filter
4. **Favorites** - saved words
5. **Ask** - AI Q&A about the Hadrami dialect
6. **Settings** - connection test + about info
