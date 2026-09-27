

#!/usr/bin/env bash
set -e

echo "Iniciando compilacion de Vargas SPA"

if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_PUBLISHABLE_KEY:-}" ]; then
  echo "ERROR: Faltan SUPABASE_URL o SUPABASE_PUBLISHABLE_KEY en Vercel."
  exit 1
fi

if [ ! -x "$HOME/flutter/bin/flutter" ]; then
  git clone https://github.com/flutter/flutter.git \
    --depth 1 \
    --branch stable \
    "$HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get

flutter build web --release \
  --base-href "/" \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY"

echo "Compilacion finalizada"
