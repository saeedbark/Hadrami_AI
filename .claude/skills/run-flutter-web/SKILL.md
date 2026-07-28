---
name: run-flutter-web
description: This skill should be used when asked to launch, run, or visually verify the Hadrami NLP Flutter app (flutter_app/) — e.g. "run the app", "check this UI change in the browser", "screenshot the search page". Covers starting the web dev server and driving it headlessly with Playwright.
version: 0.1.0
---

# Running the Hadrami NLP Flutter app (web)

The app has no committed web build (`flutter_app/build/` is gitignored,
regenerated on every Vercel deploy — see the root `CLAUDE.md` Deployment
section). To see a change working, run it locally with `flutter run`
against a headless browser.

## 1. Start the dev server

```bash
cd flutter_app
flutter run -d web-server --web-port 8765 --web-hostname 127.0.0.1 \
  > /tmp/flutter_run.log 2>&1 &
```

Poll instead of sleeping — first compile takes 15-30s:

```bash
for i in $(seq 1 60); do
  grep -q "is being served at" /tmp/flutter_run.log && break
  sleep 3
done
```

Stop it when done: `lsof -ti:8765 -sTCP:LISTEN | xargs -r kill`.

This app has no backend dependency for UI verification — the dictionary
data renders from whatever `API_BASE_URL` the app is built with
(see `lib/src/configs/api_config.dart`); the home/search/dictionary
pages hit the real deployed backend by default, no local backend needed
just to look at the UI.

## 2. Drive it with Playwright (not chromium-cli)

`chromium-cli` is not installed in this environment. Use Node + the
`playwright` package instead (install once with
`npm install playwright@1.62.0` in a scratch dir, then
`npx playwright install chromium` — both require network access and
took about a minute combined the first time).

```js
import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
page.on('pageerror', e => console.log('PAGE ERROR', e.message));
await page.goto('http://127.0.0.1:8765', { waitUntil: 'load', timeout: 60000 });
await page.waitForTimeout(5000); // first paint is slow, no reliable DOM signal to wait for
await page.screenshot({ path: 'shot.png' });
await browser.close();
```

## Gotcha: this is a canvas app, not a DOM app

Flutter web (CanvasKit renderer, used here) paints everything to a
`<canvas>`. **Playwright's DOM-based locators don't work** —
`page.getByText(...)`, `page.locator('button:has-text(...)')`, etc. all
time out even though the text is visibly on screen. Interact purely by
coordinates: `page.mouse.click(x, y)`, `page.keyboard.type(...)`,
`page.mouse.wheel(0, dy)` to scroll. Take a screenshot first, read the
pixel coordinates off it, then click.

The right-hand nav rail (app is RTL) at the default 1280×900 viewport,
top nav item first:
`الرئيسية` (home) ≈ (1200, 143), `بحث` (search) ≈ (1200, 186),
`القاموس` (dictionary) ≈ (1200, 230), `المفضلة` (favorites) ≈ (1200, 273),
`اسأل` (ask) ≈ (1200, 317), `عبارات` (phrase) ≈ (1200, 361),
`محادثة` (chat) ≈ (1200, 405). Settings gear icon is in the top-left
corner of the home page (≈ 40, 32) and duplicated near the bottom of the
nav rail on inner pages (≈ 1180, 863) since the top-left corner is
occupied by a page title there instead.

Always check `console --errors`-equivalent (`page.on('pageerror', ...)`)
— a Flutter web page can render its shell fine while a provider/service
call fails silently underneath.
