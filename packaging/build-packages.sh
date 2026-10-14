#!/usr/bin/env bash
# Baixa o release oficial do 64Gram e constrói .deb, .rpm e AppImage em dist/.
#
# Uso: packaging/build-packages.sh [--version X.Y.Z] [--out DIR]
# Requer: curl, unzip, mksquashfs, jq, nfpm (em PATH) e o runtime do AppImage em
# /tmp/runtime-x86_64 (ou NFPM_RUNTIME).
set -euo pipefail

REPO="TDesktop-x64/tdesktop"
VERSION=""
LOCAL=""
OUTDIR="dist"

while [ $# -gt 0 ]; do
	case "$1" in
		--version) shift; VERSION="${1:-}" ;;
		--local) shift; LOCAL="${1:-}" ;;
		--out) shift; OUTDIR="${1:-}" ;;
		-h|--help)
			printf 'Uso: %s [--version X.Y.Z] [--local zip] [--out DIR]\n' "$0"
			exit 0
			;;
		*) echo "opção desconhecida: $1" >&2; exit 1 ;;
	esac
	shift
done

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
RUNTIME="${NFPM_RUNTIME:-/tmp/runtime-x86_64}"

die() { echo "erro: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "comando necessário: $1"; }

need curl
need unzip
need mksquashfs
need jq
need nfpm

# ------------------------------------------------------------ resolver release
if [ -n "$VERSION" ]; then
	URL="https://github.com/$REPO/releases/download/v$VERSION/64Gram_${VERSION}_linux.zip"
	DIGEST=""
else
	json="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")"
	VERSION="$(printf '%s' "$json" | jq -r '.tag_name' | sed 's/^v//')"
	[ "$VERSION" != "null" ] && [ -n "$VERSION" ] || die "não achei a última versão"
	URL="$(printf '%s' "$json" | jq -r '.assets[] | select(.name | endswith("_linux.zip")) | .browser_download_url')"
	DIGEST="$(printf '%s' "$json" | jq -r '.assets[] | select(.name | endswith("_linux.zip")) | .digest')"
fi
[ -n "$URL" ] && [ "$URL" != "null" ] || die "não achei o pacote linux da versão $VERSION"
echo "==> versão: $VERSION"

# ------------------------------------------------------------ baixar e verificar
WORK="$(mktemp -d)"
STAGE="$HERE/stage"
CONFIG="$HERE/nfpm.release.yaml"
trap 'rm -rf "$WORK" "$STAGE" "$CONFIG"' EXIT

if [ -n "$LOCAL" ]; then
	[ -f "$LOCAL" ] || die "arquivo não encontrado: $LOCAL"
	ZIP="$LOCAL"
else
	ZIP="$WORK/64Gram_${VERSION}_linux.zip"
	echo "==> baixando: $URL"
	curl -fsSL --retry 3 --retry-all-errors -o "$ZIP" "$URL"
fi

if [ -n "$DIGEST" ]; then
	actual="sha256:$(sha256sum "$ZIP" | cut -d' ' -f1)"
	[ "$actual" = "$DIGEST" ] || die "checksum não confere: esperado $DIGEST, obtido $actual"
	echo "==> checksum verificado"
fi

# ------------------------------------------------------------ montar staging
# tudo dentro de packaging/ para que os caminhos relativos do nfpm.yaml funcionem
rm -rf "$STAGE"
mkdir -p "$STAGE/usr/share/applications" "$STAGE/externalupdater.d"

unzip -qo "$ZIP" -d "$STAGE"
[ -f "$STAGE/Telegram" ] || die "binário 'Telegram' ausente no zip"

cp "$HERE/shared/io.github.tdesktop_x64.TDesktop.desktop" \
	"$STAGE/usr/share/applications/io.github.tdesktop_x64.TDesktop.desktop"

printf '%s\n' "/opt/64gram/Telegram" > "$STAGE/externalupdater.d/telegram-desktop.conf"

for size in 16 32 48 64 128 256 512; do
	dir="$STAGE/usr/share/icons/hicolor/${size}x${size}/apps"
	mkdir -p "$dir"
	curl -fsSL --retry 3 --retry-all-errors -o "$dir/64gram.png" \
		"https://raw.githubusercontent.com/$REPO/dev/Telegram/Resources/art/icon${size}.png"
done

# ------------------------------------------------------------ deb + rpm (nfpm)
# nfpm resolve caminhos relativos a partir do diretório atual
sed "s|^version:.*|version: \"$VERSION\"|" "$HERE/nfpm.yaml" > "$CONFIG"

mkdir -p "$ROOT/$OUTDIR"
( cd "$HERE" && nfpm package --config "$CONFIG" --packager deb \
	--target "$ROOT/$OUTDIR/64gram_${VERSION}_amd64.deb" >/dev/null ) || die "nfpm deb falhou"
( cd "$HERE" && nfpm package --config "$CONFIG" --packager rpm \
	--target "$ROOT/$OUTDIR/64gram-${VERSION}-1.x86_64.rpm" >/dev/null ) || die "nfpm rpm falhou"

# ------------------------------------------------------------ AppImage
echo "==> appimage"
"$HERE/appimage/build.sh" "$VERSION" "$ZIP" \
	"$OUTDIR/64gram-${VERSION}-x86_64.AppImage" "$RUNTIME" >/dev/null

# ------------------------------------------------------------ checksums
(cd "$ROOT/$OUTDIR" && sha256sum -- * > SHA256SUMS)
echo "$VERSION" > "$ROOT/$OUTDIR/VERSION"

echo "==> pronto em $OUTDIR:"
ls -1 "$ROOT/$OUTDIR"
