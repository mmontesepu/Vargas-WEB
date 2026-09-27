#!/usr/bin/env bash
set -e

echo "Iniciando compilacion de Vargas SPA"

git clone https://github.com/flutter/flutter.git --depth 1 --branch stable "$HOME/flutter"

export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release --base-href "/"

echo "Compilacion finalizada"
