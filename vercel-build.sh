#!/bin/bash
# Script de build automático para Vercel
set -e

echo "=== Verificando Flutter SDK ==="
if [ ! -d "flutter" ]; then
  echo "Clonando Flutter SDK (stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Flutter SDK já presente em cache."
fi

export PATH="$PATH:`pwd`/flutter/bin"

echo "Versão do Flutter:"
flutter --version

echo "Instalando dependências..."
flutter pub get

echo "Compilando para a Web..."
flutter build web --release

echo "=== Build concluído com sucesso! ==="
