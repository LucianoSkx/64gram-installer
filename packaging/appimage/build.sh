#!/usr/bin/env bash
# Constrói a AppImage do 64Gram a partir do zip do release oficial.
# Método: AppDir + mksquashfs + runtime do AppImageKit (não precisa de FUSE).
#
# Uso: packaging/appimage/build.sh <versão> <zip-do-release> <arquivo-de-saida> [runtime]
set -euo pipefail

VERSION="$1"
ZIP="$2"
OUT="$3"
RUNTIME="${4:-/tmp/runtime-x86_64}"
ARCH="x86_64"
NAME="64gram-${VERSION}-${ARCH}.AppImage"
DESKTOP_ID="io.github.tdesktop_x64.TDesktop.desktop"
SHARED="$(cd "$(dirname "$0")/../shared" && pwd)"
ICON_BASE="https://raw.githubusercontent.com/TDesktop-x64/tdesktop/dev/Telegram/Resources/art"

[ -f "$ZIP" ] || { echo "zip não encontrado: $ZIP" >&2; exit 1; }
[ -f "$RUNTIME" ] || { echo "runtime do AppImage não encontrado: $RUNTIME" >&2; exit 1; }
command -v mksquashfs >/dev/null 2>&1 || { echo "mksquashfs é necessário (squashfs-tools)" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

APPDIR="$WORK/AppDir"
mkdir -p "$APPDIR"
unzip -qo "$ZIP" -d "$APPDIR"
[ -f "$APPDIR/Telegram" ] || { echo "binário 'Telegram' ausente no zip" >&2; exit 1; }
chmod 755 "$APPDIR/Telegram" "$APPDIR/Updater"

cp "$(dirname "$0")/AppRun" "$APPDIR/AppRun"
chmod 755 "$APPDIR/AppRun"

# desktop entry: Exec aponta para o próprio AppImage (como o appimagetool faria)
sed -e '/^TryExec=/d' \
    -e "s|^Exec=.*|Exec=$NAME -- %u|" \
    "$SHARED/$DESKTOP_ID" > "$APPDIR/64gram.desktop"

# ícone na raiz do AppDir (256px; desktop entries usam o nome sem caminho)
curl -fsSL --retry 3 --retry-all-errors -o "$APPDIR/64gram.png" "$ICON_BASE/icon256.png"

mksquashfs "$APPDIR" "$WORK/payload.squashfs" -root-owned -noappend -quiet

cat "$RUNTIME" "$WORK/payload.squashfs" > "$WORK/$NAME"
chmod 755 "$WORK/$NAME"
mkdir -p "$(dirname "$OUT")"
mv "$WORK/$NAME" "$OUT"

echo "$OUT"
