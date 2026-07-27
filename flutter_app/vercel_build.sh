#!/usr/bin/env bash
# Vercel Linux build: install Flutter (stable), then build web with API URL baked in.
set -euo pipefail
cd "$(dirname "$0")"

export PATH="$PATH:$PWD/_flutter/bin"

if [[ ! -f "_flutter/bin/flutter" ]]; then
  rm -rf _flutter
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git _flutter
fi

flutter config --no-analytics >/dev/null
flutter precache --web
flutter pub get
# freezed / json_serializable / riverpod_generator / reactive_forms_generator
# output is gitignored — must regenerate before compiling.
dart run build_runner build --delete-conflicting-outputs
# Set API_BASE_URL in the Vercel project Environment Variables (Production).
flutter build web --release --dart-define=API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
