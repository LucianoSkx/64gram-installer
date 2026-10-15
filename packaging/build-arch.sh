#!/usr/bin/env bash
# Gera o pacote Arch (.pkg.tar.zst) do 64Gram.
# Usa o PKGBUILD deste repositório, com versão e checksums reais.
#
# Uso: packaging/build-arch.sh <versão> [zip] [saída]
#   zip omitted  -> baixa do release oficial
#   saída        -> pasta onde o .pkg.tar.zst é depositado (padrão: dist)
set -euo pipefail

VERSION="${1:-}"
ZIP="${2:-}"
OUT="${3:-dist}"

[ -n "$VERSION" ] || { echo "Uso: $0 <versão> [zip] [saída]" >&2; exit 1; }
command -v makepkg >/dev/null 2>&1 || { echo "makepkg é necessário" >&2; exit 1; }

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="TDesktop-x64/tdesktop"
ICON_SIZES="16 32 48 64 128 256 512"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- fontes ---------------------------------------------------------------
if [ -z "$ZIP" ]; then
	ZIP="$WORK/64Gram_${VERSION}_linux.zip"
	curl -fsSL --retry 3 --retry-all-errors -o "$ZIP" \
		"https://github.com/$REPO/releases/download/v$VERSION/64Gram_${VERSION}_linux.zip"
fi
[ -f "$ZIP" ] || { echo "zip não encontrado: $ZIP" >&2; exit 1; }
ZIP_SHA="$(sha256sum "$ZIP" | cut -d' ' -f1)"

for size in $ICON_SIZES; do
	curl -fsSL --retry 3 --retry-all-errors -o "$WORK/icon${size}.png" \
		"https://raw.githubusercontent.com/$REPO/dev/Telegram/Resources/art/icon${size}.png"
done

cp "$HERE/shared/io.github.tdesktop_x64.TDesktop.desktop" "$WORK/"
cp "$HERE/64gram.install" "$WORK/"
# o PKGBUILD referencia o zip pelo nome canônico do release
if [ "$ZIP" != "$WORK/64Gram_${VERSION}_linux.zip" ]; then
	cp "$ZIP" "$WORK/64Gram_${VERSION}_linux.zip"
fi

sum_lines="	'$ZIP_SHA'"
for size in $ICON_SIZES; do
	sum_lines="$sum_lines
	'$(sha256sum "$WORK/icon${size}.png" | cut -d' ' -f1)'"
done

# --- PKGBUILD -------------------------------------------------------------
cat > "$WORK/PKGBUILD" <<PKG
# gerado por packaging/build-arch.sh — não editar à mão
pkgname=64gram
pkgver=$VERSION
pkgrel=1
pkgdesc="Unofficial desktop version of Telegram messaging app"
arch=('x86_64')
url="https://github.com/LucianoSkx/64gram-installer"
license=('GPL-3.0-only')
depends=(cairo desktop-file-utils fontconfig freetype2 glib2 harfbuzz hicolor-icon-theme libdbus libx11 libxcb libxext libxrender pango systemd-libs)
optdepends=('ttf-opensans: default Open Sans font family')
provides=('64gram-desktop')
conflicts=('64gram-desktop' '64gram-desktop-bin')
install='64gram.install'
source=(
	"64Gram_${VERSION}_linux.zip"
	"icon16.png"
	"icon32.png"
	"icon48.png"
	"icon64.png"
	"icon128.png"
	"icon256.png"
	"icon512.png"
	"io.github.tdesktop_x64.TDesktop.desktop"
)
sha256sums=(
$sum_lines
	'$(sha256sum "$WORK/io.github.tdesktop_x64.TDesktop.desktop" | cut -d' ' -f1)'
)

package() {
	install -dm755 "\$pkgdir/opt/64gram"
	install -Dm755 "Telegram" "\$pkgdir/opt/64gram/Telegram"
	install -Dm755 "Updater" "\$pkgdir/opt/64gram/Updater"

	install -dm755 "\$pkgdir/opt/64gram/externalupdater.d"
	printf '%s\n' "/opt/64gram/Telegram" \\
		> "\$pkgdir/opt/64gram/externalupdater.d/telegram-desktop.conf"

	install -dm755 "\$pkgdir/usr/bin"
	ln -s /opt/64gram/Telegram "\$pkgdir/usr/bin/64gram"

	install -dm755 "\$pkgdir/usr/share/applications"
	install -Dm644 "io.github.tdesktop_x64.TDesktop.desktop" \\
		"\$pkgdir/usr/share/applications/io.github.tdesktop_x64.TDesktop.desktop"

	local size
	for size in $ICON_SIZES; do
		install -dm755 "\$pkgdir/usr/share/icons/hicolor/\${size}x\${size}/apps"
		install -Dm644 "icon\${size}.png" \\
			"\$pkgdir/usr/share/icons/hicolor/\${size}x\${size}/apps/64gram.png"
	done
}
PKG

# --- empacota -------------------------------------------------------------
echo "==> makepkg (64gram $VERSION)"
( cd "$WORK" && makepkg -f --noconfirm --nodeps >/dev/null )

# o makepkg também gera o pacote -debug quando a distro pede: não é nosso
rm -f "$WORK"/64gram-debug-*.pkg.tar.zst

mkdir -p "$OUT"
rm -f "$OUT"/64gram-debug-*.pkg.tar.zst
pkg="$(cd "$WORK" && ls 64gram-*.pkg.tar.zst | head -1)"
cp "$WORK/$pkg" "$OUT/"
echo "$OUT/$pkg"