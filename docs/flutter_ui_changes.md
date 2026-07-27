# Flutter UI pass — animations, responsive layout, dead-code sweep

> **Compiled:** 2026-05-03 &middot; companion to
> `docs/hadrami_rag_paper.html`, `docs/search.md`, `docs/chat_unified_changes.md`.
> Mirrors the live code in `flutter_app/lib/`. Update this file when the
> shared widgets in `lib/src/widgets/` change.

## Goal

Polish the Flutter client without rewriting it: add tasteful entry/exit
animations, clamp content width on web/desktop so the app stops sprawling
across wide monitors, swap the dead `app_card.dart` for what's actually
used, and pick up a handful of `prefer_const` perf wins. Keep the existing
M3 light + dark themes, the bottom-nav-on-mobile / rail-on-desktop layout,
the RTL handling, and the Riverpod + go_router architecture untouched.

Constraint: the work was done from a CLI without a running device, so the
edits are deliberately surgical — every change is reviewable, revertible,
and validated by `flutter analyze`. Visual confirmation is the user's job
(`flutter run -d chrome` for web, `flutter run` for a connected device).

## Scope

| Layer | Action |
|---|---|
| Theme (`theme.dart`, `app_colors.dart`) | **Untouched.** Both M3 schemes were already solid. |
| Routing (`router.dart`) | **Untouched.** `StatefulShellRoute` topology preserved. |
| Shared widgets | One added (`content_shell.dart`), one added (`animated_appear.dart`), one upgraded (`loading_widget.dart`), one deleted (`app_card.dart`, unused). |
| Pages | Polish + responsive max-width on `chat_page`, `home_page`, `landing_page`, `ask_page`, `phrase_translate_page`, `settings_page`. |
| Modules not touched | `dictionary`, `favorites`, `search` (already in good shape and out of the immediate path of the pass). |
| Dependencies | **No new packages.** Animations use native Flutter primitives only; `pubspec.yaml` is unchanged. |

## What changed

### New files

- **`lib/src/widgets/content_shell.dart`** — `ContentShell(maxWidth: 880, child: ...)`.
  No-op on mobile (returns the child or a padded child); on tablet/desktop it
  centres the child inside an `Align + ConstrainedBox`. Replaces the per-page
  pattern that would otherwise have been duplicated five times.

- **`lib/src/widgets/animated_appear.dart`** — two reusable primitives:
  - `AnimatedAppear` — wraps a child in a one-shot fade + slide on mount,
    with configurable `duration`, `delay`, `slideOffset`, and `curve`. Used
    by chat bubbles (per-bubble entry) and the chat empty-state body.
  - `StaggeredAppear` — column of `AnimatedAppear` children with a
    configurable `stagger` between item starts. Used by the home page so
    section cards cascade in instead of appearing all at once.

### Edited files

- **`lib/src/widgets/loading_widget.dart`** — `LoadingWidget` now uses an
  explicit themed `CircularProgressIndicator` (primary colour, 2.4-px
  stroke) instead of the bare `CircularProgressIndicator.adaptive`. New
  `SkeletonLine` widget added for skeleton placeholders, with a 1.1-second
  breathing animation (`AnimationController.repeat(reverse: true)`).

- **`lib/src/modules/chat/widgets/chat_bubble.dart`** — wrapped in
  `AnimatedAppear` with directional slide (user bubbles slide in from the
  right, assistant from the left). Replaced the styling-via-`Container`
  width clamp with a `ConstrainedBox` (semantically correct for a bound,
  not a styled box). Inlined the `_formatTime` helper as a `static`.

- **`lib/src/modules/chat/widgets/chat_input.dart`** — replaced the no-op
  `AnimatedContainer` (it wrapped a non-animatable `IconButton.filled` so
  it never animated anything) with a real `AnimatedScale` (button scales
  to 0.92 when disabled, 1.0 when enabled) and an `AnimatedSwitcher` on
  the icon (smooth swap between the send arrow and the loading spinner).

- **`lib/src/modules/chat/pages/chat_page.dart`** — wrapped the body in
  `ContentShell(maxWidth: 880)` so on web/desktop the chat column stops
  at a readable width. Empty-state icon now elastic-bounces in via
  `TweenAnimationBuilder<double>(curve: Curves.elasticOut)`. Typing
  indicator replaced with three phase-staggered pulsing dots
  (`AnimationController.repeat()` shared across all three) instead of
  the static spinner. Removed the dead `colorScheme` plumbing through
  `_SuggestionChip` — it now reads from `Theme.of` directly.

- **`lib/src/modules/landing/pages/landing_page.dart`** — theme-toggle
  icon (desktop rail) now uses `AnimatedSwitcher` with a combined
  `RotationTransition` + `FadeTransition`. Sun/moon icons rotate and
  fade between states instead of snapping. Keyed by the theme mode so
  the switcher actually fires.

- **`lib/src/modules/home/pages/home_page.dart`** — body wrapped in
  `ContentShell(maxWidth: 880)`. Section cards wrapped in
  `StaggeredAppear` so they cascade in (80 ms stagger, 360 ms per item,
  `Curves.easeOutCubic`). Hero gradient wrapped in `AnimatedContainer`
  so light↔dark theme transitions cross-fade (320 ms). Theme-toggle icon
  upgraded to the same `AnimatedSwitcher` pattern as landing.

- **`lib/src/modules/ask/pages/ask_page.dart`** — body wrapped in
  `ContentShell(maxWidth: 880)`.

- **`lib/src/modules/phrase/pages/phrase_translate_page.dart`** — body
  wrapped in `ContentShell(maxWidth: 880)`.

- **`lib/src/modules/settings/pages/settings_page.dart`** — body wrapped
  in `ContentShell(maxWidth: 720)` — narrower than the chat/home shells
  because settings is form-heavy and reads better at a tighter width.

### Deleted files

- **`lib/src/widgets/app_card.dart`** — `grep -rl "app_card" lib --include="*.dart"`
  returned zero importers. Removed.

### `dart fix --apply` (Phase 3)

Ran across the whole project; landed 6 `prefer_const_constructors`
fixes in 4 files (`api_service.dart`, `home_page.dart` × 3,
`phrase_translate_page.dart`, `settings_page.dart`).

## Analyzer status

| Stage | Issues | Errors | New issues introduced |
|---|---:|---:|---:|
| Baseline (before this pass) | 22 | 0 | — |
| After Phase 1 (animations + polish) | 22 | 0 | 0 |
| After Phase 2 (responsive `ContentShell` wrappers) | 22 | 0 | 0 |
| After Phase 3 (`dart fix` + delete `app_card.dart`) | 15 | 0 | 0 |

The remaining 15 issues are all pre-existing infra noise unrelated to
this pass:

- **9** generated-code warnings on `lib/src/core/models/word_entry.dart`
  (`invalid_annotation_target` from `JsonSerializable.new`). Fixes when
  the codegen is re-run on a current `json_serializable`.
- **6** Riverpod 2 → 3 deprecation infos
  (`'XxxRef' is deprecated, use Ref instead`) in generated provider
  files (`router.g.dart`, `home_provider.g.dart`, `search_provider.g.dart`).
  Fixes by re-running `build_runner` on `riverpod_generator >= 2.4.0` /
  hand-replacing in a Riverpod 3 migration pass.

## Design notes

### Why no `flutter_animate` / `shimmer` / etc.

Adding a dependency for two animation primitives the framework already
ships would be a maintenance liability disproportionate to the value.
`AnimatedAppear` is ~70 lines and uses only `AnimationController`,
`CurvedAnimation`, and `AnimatedBuilder` — i.e. the framework's own
animation machinery. `pubspec.yaml` is unchanged; `pub get` is not
required to consume this pass.

### Why `ContentShell` and not `LayoutBuilder` per page

Two reasons. (1) The breakpoints are project-global
(`AppTheme.tabletBreakPoint = 600`, `AppTheme.desktopBreakPoint = 1200`)
and already exposed via the `ResponsiveContext` extension on
`BuildContext`, so each page using `LayoutBuilder` would re-implement the
same threshold check. (2) The widget makes the *intent* explicit: the
choice "this page should not exceed N pixels of body content" is easier
to grep, audit, and tweak when it lives at the page root than when it
hides inside a `LayoutBuilder` callback.

### Why per-page `maxWidth` differences

- 880 px for chat / home / ask / phrase — long-form bilingual text reads
  comfortably at this width with the IBM Plex Sans Arabic body sizes
  defined in `theme.dart`.
- 720 px for settings — settings is form-heavy with paired label / input
  rows; the narrower clamp keeps related controls visually together.

### Why `RotationTransition` + `FadeTransition` on the theme toggle

A pure `AnimatedSwitcher` cross-fade made the sun↔moon swap feel like a
dissolve transition (cinematic, slow-feeling). Adding the rotation
gives the icon a brief spin that reads as a deliberate state change.
Both transitions are 300 ms — short enough not to feel laggy, long
enough that the user registers the state change before the new icon
settles.

### Animation budget

Every new animation is bounded:

| Animation | Lifecycle | Max duration |
|---|---|---|
| `AnimatedAppear` | one-shot on mount | 280 ms (configurable) |
| `StaggeredAppear` (home cards, n = 4) | one-shot on mount | 360 ms × 4 + 80 ms stagger × 3 = 1.68 s total cascade |
| Theme-toggle `AnimatedSwitcher` | one-shot per toggle | 300 ms |
| `AnimatedContainer` on hero gradient | per theme change | 320 ms |
| Send-button `AnimatedScale` + `AnimatedSwitcher` | per state change | 180 ms / 200 ms |
| `_TypingIndicator` dots | infinite (only while loading) | 900 ms cycle |
| `SkeletonLine` breath | infinite (only while skeleton on screen) | 1.1 s cycle |

The two infinite animations both dispose their controllers in `dispose()`,
so they do not leak when the host widget unmounts.

## Reproducing the visual changes

```bash
cd flutter_app

# Web preview
flutter run -d chrome

# Mobile (any connected device)
flutter run

# Static analysis only (the verification used in this pass)
flutter analyze

# Apply the same auto-fixes I applied
dart fix --apply
```

## Palette change (2026-05-03, follow-up pass)

User feedback on the original navy + cold-gold palette: didn't like it.
Replaced with a warm Yemeni-manuscript palette in
`lib/src/configs/app_colors.dart`:

| Role | Old (navy/gold) | New (terracotta/saffron) |
|---|---|---|
| `primaryLight` | `#1B4F72` (deep navy) | `#B5471F` (terracotta) |
| `secondaryLight` | `#C9A227` (cold gold) | `#D49B2A` (saffron) |
| `background` | `#F7F9FC` (cool blue-gray) | `#FAF6EE` (warm cream / parchment) |
| `onSurfaceLight` | `#1A1A1A` (pure near-black) | `#2D241B` (warm dark brown) |
| `outlineLight` | `#C5CED6` (cool gray) | `#B8A98F` (warm tan) |
| `primaryDark` | `#5DADE2` (cool sky blue) | `#E0805A` (lighter terracotta) |
| `backgroundDark` | `#12151A` (cool charcoal) | `#1A140F` (warm charcoal-brown) |
| `gold` (Hadrami highlight) | `#E8C547` (yellow-gold) | `#E8B847` (slightly warmer saffron) |

Surface containers (low → highest) and the matching dark-mode containers
were re-keyed to the same warm hue family so `colorScheme.surface*`
references throughout the app pick up the new palette without any page
edits. The `hadramiLexiconHighlightBackground()` function still applies
gold but with slightly lower alpha (0.42 light / 0.34 dark) so the
text-on-cream stays readable at the new background contrast.

Border radii also nudged up half a step in
`lib/src/configs/app_radius.dart` (sm 6→8, md 10→12, lg 14→16, xl 20→22)
for a marginally softer feel that matches the warmer palette. `full`
unchanged.

`flutter analyze` after the swap: still 15 issues, **zero new** — same
infra noise as before. The swap is structurally clean and revertible by
restoring the two configs files alone.

If the warm-clay direction is wrong, two ready alternatives:

| Alternative | Primary | Secondary | Background | Vibe |
|---|---|---|---|---|
| **Coastal Hadramaut** | `#1E6B7A` (deep teal) | `#D88C5A` (coral) | `#F2F4F1` (sea-mist) | Indian Ocean coast |
| **Modern minimal** | `#2C3E50` (graphite) | `#16A085` (single accent) | `#FCFCFC` (pure off-white) | Quiet, neutral, tech-product |

Either is a 60-second swap of `app_colors.dart`.

## Pointers

- Theme tokens: `lib/src/configs/app_colors.dart`, `lib/src/configs/app_radius.dart`
- Theme builder: `lib/src/core/theme/theme.dart` (light + dark + responsive breakpoints)
- Theme provider: `lib/src/core/providers/theme_provider.dart`
- Routing: `lib/src/core/routing/router.dart`
- Shared animation primitives: `lib/src/widgets/animated_appear.dart`
- Shared responsive shell: `lib/src/widgets/content_shell.dart`
- Shared loading + skeleton: `lib/src/widgets/loading_widget.dart`
- App entry: `lib/main.dart` &rarr; `lib/src/app.dart`
