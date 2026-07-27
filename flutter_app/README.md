# Flutter App — Hadrami NLP

Cross-platform client for the Hadrami dialect dictionary and translation API.
Built with **Flutter 3.x**, **Riverpod** for state management, and **go_router** for navigation.

---

## Setup

```bash
cd flutter_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Code Generation

This project uses code generation for models and providers:

- **freezed** + **json_serializable** for immutable data classes (`*.freezed.dart`, `*.g.dart`)
- **reactive_forms_generator** for form models (`*.gform.dart`)
- **riverpod_generator** for providers (`*.g.dart`)

After modifying any annotated class, regenerate with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### API Configuration

The backend URL defaults to the **deployed API** (`https://hadrami-ai.vercel.app/`).
Override at build time to use a local or different backend:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000          # Local backend
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000           # Android emulator → host
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8000        # Physical device on LAN
```

Configured in `lib/src/configs/api_config.dart`.

---

## Architecture

```
lib/
├── main.dart                  ← Entry point, ProviderScope
└── src/
    ├── app.dart               ← MaterialApp.router, theme binding
    ├── configs/               ← App-wide constants
    │   ├── api_config.dart    ← Backend URL (compile-time define)
    │   ├── phrase_translate_config.dart  ← Phrase limits
    │   ├── app_colors.dart    ← Color palette
    │   └── app_radius.dart    ← Border radii
    │
    ├── core/                  ← Shared infrastructure
    │   ├── models/
    │   │   ├── word_entry.dart        ← All data models (freezed)
    │   │   └── lexicon_section.dart   ← Letter section model
    │   ├── services/
    │   │   └── api_service.dart       ← HTTP client for all API calls
    │   ├── providers/
    │   │   └── theme_provider.dart    ← Theme persistence (shared_preferences)
    │   ├── routing/
    │   │   └── router.dart            ← go_router with StatefulShellRoute
    │   ├── theme/
    │   │   └── theme.dart             ← M3 light/dark themes (warm Yemeni palette: terracotta + saffron + cream — see docs/flutter_ui_changes.md)
    │   └── utils/
    │       └── hadrami_lexicon_spans.dart  ← Highlighted span utilities
    │
    ├── widgets/               ← Shared UI components
    │   ├── app_scaffold.dart          ← Common page scaffold + AppAppBar
    │   ├── content_shell.dart         ← Responsive max-width wrapper (no-op on mobile, clamps on web/desktop)
    │   ├── animated_appear.dart       ← AnimatedAppear + StaggeredAppear (one-shot fade + slide)
    │   ├── loading_widget.dart        ← Themed spinner + animated SkeletonLine placeholder
    │   ├── error_widget.dart          ← Error display
    │   ├── empty_state.dart           ← Empty state placeholder
    │   └── hadrami_highlighted_text.dart  ← Highlighted span text
    │
    └── modules/               ← Feature modules
        ├── landing/           ← Bottom nav (mobile) / rail (desktop) shell
        ├── home/              ← Hero gradient + stats + sections + word of the day
        ├── search/            ← Live debounced search
        ├── dictionary/        ← Full word list + letter filter
        ├── favorites/         ← Locally saved words
        ├── ask/               ← AI Q&A (`/ask`)
        ├── phrase/            ← Phrase translation with spans (`/translate-phrase`)
        ├── chat/              ← Unified conversational dispatcher (`/chat`)
        └── settings/          ← Connection test, theme, about
```

### Module Pattern

Each feature module follows the same structure:

```
modules/<feature>/
├── pages/          ← Full-screen page widgets
├── providers/      ← Riverpod providers (state + API calls)
├── widgets/        ← Feature-specific widgets (optional)
└── forms/          ← Reactive form models (optional)
```

### Data Flow

1. **User action** triggers a provider method
2. **Provider** calls `ApiService` to make an HTTP request
3. **ApiService** sends the request to the FastAPI backend
4. **Response** is deserialized into a freezed model (`WordEntry`, `SearchResult`, etc.)
5. **UI** rebuilds reactively via Riverpod `ref.watch()`

### Key Models

All models are defined in `core/models/word_entry.dart`:

| Model | Purpose |
|-------|---------|
| `WordEntry` | Dictionary entry with optional `fus7aShort`, `aliases`, `examples` |
| `ExamplePair` | Usage example pair (`hadrami` + `fusha`) |
| `TranslateResult` | Single word translation response |
| `SearchResult` | Search response with total count + results list |
| `AskResult` | AI Q&A response with answer + mode + context |
| `PhraseTranslateResult` | Phrase translation with highlighted spans |
| `HadramiSpan` | Start/end/surface for highlighted Hadrami words |
| `AppStats` | Dictionary statistics |

---

## Screens

| # | Screen | Route | Description |
|---|--------|-------|-------------|
| 1 | Home | `/` | Hero gradient, stats cards, sections, random word, staggered entry animations |
| 2 | Search | `/search` | Debounced search with result count |
| 3 | Dictionary | `/dictionary` | Paginated list + Arabic letter filter chips |
| 4 | Favorites | `/favorites` | Locally saved words (shared_preferences) |
| 5 | Ask | `/ask` | AI Q&A with copy button and source mode |
| 6 | Phrases | `/phrase-translate` | Bidirectional phrase translation |
| 7 | Chat | `/chat` | Unified conversational dispatcher (5 intents, refusal contract) |
| 8 | Settings | `/settings` | Backend test, theme selector (light / dark / system), version info |

---

## Platform Support

| Platform | Status |
|----------|--------|
| Android | Tested |
| iOS | Supported |
| Web | Supported |
| Windows | Supported |
| macOS | Supported |
| Linux | Supported |
