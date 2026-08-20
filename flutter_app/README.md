# Flutter App — Hadrami NLP

Cross-platform client for the Hadrami dialect dictionary and conversion API.
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

The backend URL defaults to **`http://localhost:8000`**. Override at build time
to point at the deployed API or another backend:

```bash
flutter run --dart-define=API_BASE_URL=https://hadrami-ai.vercel.app  # Deployed backend
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000           # Android emulator → host
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8000        # Physical device on LAN
```

Configured in `lib/src/core/network/api_config.dart`.

---

## Architecture

```
lib/
├── main.dart                  ← Entry point, ProviderScope
└── src/
    ├── app.dart               ← MaterialApp.router, theme binding
    ├── core/                  ← Infrastructure ONLY. Zero domain knowledge — nothing here
    │   │                        knows what a "word" is. This is the portable part: it would
    │   │                        drop into a different app unchanged.
    │   ├── theme/
    │   │   ├── theme.dart             ← M3 light/dark themes (warm Yemeni palette: terracotta + saffron + cream — see docs/flutter_ui_changes.md)
    │   │   ├── theme_provider.dart    ← Theme persistence (shared_preferences)
    │   │   ├── app_colors.dart        ← Color palette
    │   │   └── app_radius.dart        ← Border radii
    │   ├── network/
    │   │   ├── api_service.dart       ← Pure HTTP transport (getJson/postJson) — no domain types
    │   │   ├── api_config.dart        ← Backend URL (compile-time define), timeouts
    │   │   └── api_endpoints.dart     ← Backend route path constants
    │   ├── formatting/
    │   │   └── time_formatting.dart   ← Shared display formatters
    │   ├── routing/
    │   │   ├── router.dart            ← go_router with StatefulShellRoute (composition root)
    │   │   └── app_routes.dart        ← Route path constants
    │   ├── strings/
    │   │   └── app_strings.dart       ← Centralized UI copy, grouped by screen/widget
    │   └── ui/                        ← Generic widget kit (domain-free, used by 2+ modules)
    │       ├── app_scaffold.dart      ← Common page scaffold + AppAppBar
    │       ├── content_shell.dart     ← Responsive max-width wrapper (no-op on mobile, clamps on web/desktop)
    │       ├── animated_appear.dart   ← AnimatedAppear + StaggeredAppear (one-shot fade + slide)
    │       ├── loading_widget.dart    ← Themed spinner + animated SkeletonLine placeholder
    │       ├── empty_state.dart       ← Empty state placeholder
    │       └── text_input.dart        ← AppTextField (standard / pill / compact variants)
    │
    └── modules/               ← Domain + features
        ├── lexicon/           ← FOUNDATION DOMAIN MODULE — owns the word domain.
        │   │                    Every other feature depends on it; it depends on none.
        │   ├── models/        ← word_entry.dart, app_stats.dart, dictionary_labels.dart
        │   ├── providers/     ← favorites_provider.dart (saved words)
        │   ├── services/      ← lexicon_service.dart (/words, /stats, /feedback)
        │   └── widgets/       ← word_card.dart, word_detail_sheet.dart
        ├── landing/           ← Bottom nav (mobile) / rail (desktop) shell
        ├── home/              ← Hero gradient + stats + sections + word of the day
        ├── dictionary/        ← Full word list + letter filter + search
        ├── favorites/         ← Locally saved words
        ├── chat/              ← Unified conversational dispatcher (`/chat`)
        └── settings/          ← Connection test, theme, about
```

The former `search/`, `ask/` and `phrase/` modules were folded into Dictionary
and Chat; `/search`, `/ask` and `/phrase-translate` are GoRouter redirects now,
not real pages.

### Module Pattern

Each feature module follows the same structure:

```
modules/<feature>/
├── pages/          ← Full-screen page widgets
├── providers/      ← Riverpod providers (state + API calls)
├── widgets/        ← Feature-specific widgets (optional)
├── services/       ← Module-scoped API calls wrapping ApiService (optional)
├── models/         ← Models owned by this module alone (optional)
├── utils/          ← Helpers used only by this module (optional)
└── forms/          ← Reactive form models (optional)
```

### The rule that actually matters: dependency direction

Folder names are cosmetic; the dependency graph is not. Three invariants:

1. **`modules → core`, never the reverse.** `core/` is infrastructure with zero
   domain knowledge — if a file in `core/` needs to know what a *word* is, it's
   in the wrong place. The one exception is `core/routing/router.dart`, the
   composition root, which imports every page by definition.
2. **Feature modules never import each other.** They may only depend on
   `modules/lexicon/`, the foundation domain module. This keeps the graph
   acyclic, so any feature can be deleted or rewritten on its own.
3. **Shared by 2+ features → move it up; used by 1 → move it down.** Promote on
   the *second* real consumer, not in anticipation of one. Anticipatory
   promotion is how dead code gets born.

Applied to widgets: domain-free and shared → `core/ui/`; domain-aware and shared
→ `modules/lexicon/widgets/`; used by one feature → that feature's `widgets/`.
There is no top-level `widgets/` folder.

Verify with:

```bash
# any core file importing a module (only router.dart may)
grep -rl "src/modules/" lib/src/core/
```

### Data Flow

1. **User action** triggers a provider method
2. **Provider** calls a module-scoped service (`LexiconService`, `DictionaryService`, …)
3. That service calls `ApiService`, which sends the request to the FastAPI backend
4. **Response** is deserialized into a freezed model (`WordEntry`, `SearchResult`, etc.)
5. **UI** rebuilds reactively via Riverpod `ref.watch()`

### Key Models

Core domain models live in `modules/lexicon/models/word_entry.dart`:

| Model | Purpose |
|-------|---------|
| `WordEntry` | Lexicon entry: `wordVocalized`, `fushaEquivalent`, `synonyms`, `phoneticVariants`, `examples`, `proverbs`, `tags` |
| `ExamplePair` | Usage example pair (`h` = Hadrami, `f` = Fusha) |
| `SearchResult` | Search response with total count + results list |
| `ChatResult` | `/chat` reply + context entries + `hadramiSpans` |
| `HadramiSpan` | Start/end/surface for highlighted Hadrami words |
| `AppStats` | Lexicon statistics — in `modules/lexicon/models/app_stats.dart` |

---

## Screens

| # | Screen | Route | Nav | Description |
|---|--------|-------|-----|-------------|
| 1 | Home | `/` | ✅ | Hero gradient, stats cards, sections, random word, staggered entry animations |
| 2 | Dictionary | `/dictionary` | ✅ | Paginated list + Arabic letter filter chips + search |
| 3 | Favorites | `/favorites` | ✅ | Locally saved words |
| 4 | Chat | `/chat` | ✅ | Unified conversational dispatcher (5 intents, refusal contract) |
| 5 | Settings | `/settings` | — | Backend test, theme selector (light / dark / system), version info |

Navigation has **4 destinations** (Home, Dictionary, Favorites, Chat). `/search`,
`/ask` and `/phrase-translate` redirect to Dictionary/Chat — they are not pages.

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
