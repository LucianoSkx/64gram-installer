#!/usr/bin/env bash
# 64Gram (unofficial Telegram Desktop) — instalador universal para Linux
# Funciona em Debian, Ubuntu, Fedora, Arch, CachyOS, openSUSE e derivados.
set -euo pipefail

REPO="TDesktop-x64/tdesktop"
# repositório onde este install.sh está publicado (para execução via curl | bash)
SELF_REPO="LucianoSkx/64gram-installer"
APP_CMD="64gram"
APP_TITLE="64Gram Desktop"
DESKTOP_ID="io.github.tdesktop_x64.TDesktop.desktop"
ICON_NAME="64gram"
ICON_URL_BASE="https://raw.githubusercontent.com/$REPO/dev/Telegram/Resources/art"
ICON_SIZES="16 32 48 64 128 256 512"
PREFIX_SYSTEM="/opt/64gram"
PREFIX_USER="${XDG_DATA_HOME:-$HOME/.local/share}/64gram"
DATA_USER="${XDG_DATA_HOME:-$HOME/.local/share}/64Gram"

ORIG_ARGS=("$@")
VERSION=""
LOCAL=""
USER_MODE=0
UNINSTALL=0

info() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> ATENÇÃO:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mErro:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
	cat <<EOF
Uso: $0 [opções]

  --user            instala só para o usuário atual (~/.local)
  --version <ver>   instala uma versão específica (ex: 1.2.10)
  --local <zip>     instala a partir de um pacote já baixado (offline)
  --uninstall       remove a instalação
  -h, --help        mostra esta ajuda

Sem --user, instala no sistema (requer root; usa sudo automaticamente).
EOF
	exit "${1:-0}"
}

while [ $# -gt 0 ]; do
	case "$1" in
		--user) USER_MODE=1 ;;
		--uninstall) UNINSTALL=1 ;;
		--version) shift; VERSION="${1:-}" ;;
		--local) shift; LOCAL="${1:-}" ;;
		-h|--help) usage ;;
		*) die "opção desconhecida: $1" ;;
	esac
	shift
done

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT

download() { # url destino
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --retry 3 --retry-all-errors -o "$2" "$1"
	elif command -v wget >/dev/null 2>&1; then
		wget -q -O "$2" "$1"
	else
		die "curl ou wget são necessários"
	fi
}

# quando executado via "curl ... | bash" ou "bash <(curl ...)", $0 não é um arquivo real
if [ ! -f "$0" ] || [ "${0#/dev/fd/}" != "$0" ]; then
	info "obtendo o instalador (execução via pipe)"
	SELF="$TMPD/install.sh"
	download "https://raw.githubusercontent.com/$SELF_REPO/main/install.sh" "$SELF"
	exec bash "$SELF" "$@"
fi
SELF_PATH="$0"
case "$SELF_PATH" in
	/*) ;;
	*) SELF_PATH="$PWD/$SELF_PATH" ;;
esac

if [ "$USER_MODE" = 1 ]; then
	PREFIX="$PREFIX_USER"
	BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
	DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
else
	PREFIX="$PREFIX_SYSTEM"
	BIN_DIR="/usr/local/bin"
	DATA_HOME="/usr/share"
	if [ "$(id -u)" != "0" ]; then
		command -v sudo >/dev/null 2>&1 || die "execute como root (ou use --user)"
		exec sudo -E bash "$SELF_PATH" ${ORIG_ARGS[@]+"${ORIG_ARGS[@]}"}
	fi
fi

# ---------------------------------------------------------------- desinstalar
uninstall() {
	info "removendo $DESKTOP_ID"
	rm -f "$DATA_HOME/applications/$DESKTOP_ID"
	local s
	for s in $ICON_SIZES; do
		rm -f "$DATA_HOME/icons/hicolor/${s}x${s}/apps/$ICON_NAME.png"
	done
	rm -f "$BIN_DIR/$APP_CMD"
	rm -rf "$PREFIX"
	if command -v update-desktop-database >/dev/null 2>&1; then
		update-desktop-database "$DATA_HOME/applications" >/dev/null 2>&1 || true
	fi
	if [ "$USER_MODE" = 1 ]; then
		info "64Gram removido. Conversas mantidas em $DATA_USER."
	else
		info "64Gram removido. Conversas dos usuários (tdata) foram mantidas."
	fi
}

if [ "$UNINSTALL" = 1 ]; then
	uninstall
	exit 0
fi

# ---------------------------------------------------------------- versão
if [ -n "$LOCAL" ]; then
	[ -f "$LOCAL" ] || die "arquivo não encontrado: $LOCAL"
	ZIP="$LOCAL"
	base="$(basename "$ZIP")"
	case "$base" in
		64Gram_*_linux.zip)
			VERSION="${base#64Gram_}"
			VERSION="${VERSION%_linux.zip}"
			;;
	esac
	[ -n "$VERSION" ] || VERSION="local"
	URL="local: $LOCAL"
	DIGEST=""
elif [ -z "$VERSION" ]; then
	info "consultando última versão em github.com/$REPO"
	download "https://api.github.com/repos/$REPO/releases/latest" "$TMPD/api.json"
	grep -q '"tag_name"' "$TMPD/api.json" || die "falha ao consultar releases: $(head -c 200 "$TMPD/api.json")"
	mapfile -t REL < <(awk '
		/"name"[[:space:]]*:/ {
			name = $0
			sub(/.*"name"[[:space:]]*:[[:space:]]*"/, "", name)
			sub(/".*/, "", name)
		}
		name ~ /_linux\.zip$/ {
			if ($0 ~ /"digest"/) {
				digest = $0
				sub(/.*"digest"[[:space:]]*:[[:space:]]*"/, "", digest)
				sub(/".*/, "", digest)
			}
			if ($0 ~ /"browser_download_url"/) {
				url = $0
				sub(/.*"browser_download_url"[[:space:]]*:[[:space:]]*"/, "", url)
				sub(/".*/, "", url)
			}
		}
		END { print url; print digest }
	' "$TMPD/api.json")
	URL="${REL[0]:-}"
	DIGEST="${REL[1]:-}"
	VERSION="${URL##*/64Gram_}"
	VERSION="${VERSION%_linux.zip}"
else
	URL="https://github.com/$REPO/releases/download/v$VERSION/64Gram_${VERSION}_linux.zip"
	DIGEST=""
fi
[ -n "$VERSION" ] || die "não foi possível determinar a versão"
[ -n "$URL" ] || die "não foi possível achar o pacote linux da versão $VERSION"
info "versão: $VERSION"

# ---------------------------------------------------------------- baixar
if [ -z "$LOCAL" ]; then
	ZIP="$TMPD/64Gram_${VERSION}_linux.zip"
	info "baixando: $URL"
	download "$URL" "$ZIP"
fi

if [ -n "$DIGEST" ]; then
	ACTUAL="sha256:$(sha256sum "$ZIP" | cut -d' ' -f1)"
	[ "$ACTUAL" = "$DIGEST" ] || die "checksum sha256 não confere (esperado $DIGEST, obtido $ACTUAL)"
	info "checksum verificado"
else
	warn "checksum não verificado (pacote local ou versão fixada)"
fi

# ---------------------------------------------------------------- instalar
if command -v unzip >/dev/null 2>&1; then
	extract() { unzip -q "$1" -d "$2"; }
elif command -v bsdtar >/dev/null 2>&1; then
	extract() { bsdtar -xf "$1" -C "$2"; }
elif command -v python3 >/dev/null 2>&1; then
	extract() { python3 -m zipfile -e "$1" "$2"; }
else
	die "precisa de unzip, bsdtar ou python3 para extrair o pacote"
fi

STAGE="$TMPD/stage"
mkdir -p "$STAGE"
extract "$ZIP" "$STAGE"

[ -f "$STAGE/Telegram" ] || die "binário 'Telegram' não encontrado no pacote (mudou o layout do release?)"

info "instalando em $PREFIX"
rm -rf "$PREFIX"
mkdir -p "$PREFIX"
cp -a "$STAGE/." "$PREFIX/"
chmod 755 "$PREFIX/Telegram"

mkdir -p "$BIN_DIR"
ln -sf "$PREFIX/Telegram" "$BIN_DIR/$APP_CMD"

# desativa o atualizador interno do app (quem atualiza é este instalador)
mkdir -p "$PREFIX/externalupdater.d"
printf '%s\n' "$PREFIX/Telegram" > "$PREFIX/externalupdater.d/telegram-desktop.conf"

# ---------------------------------------------------------------- ícones
for s in $ICON_SIZES; do
	dir="$DATA_HOME/icons/hicolor/${s}x${s}/apps"
	mkdir -p "$dir"
	if download "$ICON_URL_BASE/icon${s}.png" "$TMPD/icon${s}.png"; then
		install -m644 "$TMPD/icon${s}.png" "$dir/$ICON_NAME.png"
	else
		warn "não foi possível baixar o ícone ${s}px"
	fi
done

# ---------------------------------------------------------------- desktop entry
mkdir -p "$DATA_HOME/applications"
cat > "$DATA_HOME/applications/$DESKTOP_ID" <<EOF
[Desktop Entry]
Name=$APP_TITLE
Comment=Unofficial desktop version of Telegram messaging app
TryExec=$APP_CMD
Exec=$APP_CMD -- %u
Icon=$ICON_NAME
Terminal=false
StartupWMClass=64Gram
Type=Application
Categories=Chat;Network;InstantMessaging;Qt;
MimeType=x-scheme-handler/tg;
Keywords=tg;chat;im;messaging;messenger;sms;tdesktop;64gram;
Actions=quit;
SingleMainWindow=true
X-GNOME-UsesNotifications=true
X-GNOME-SingleWindow=true

[Desktop Action quit]
Exec=$APP_CMD -quit
Name=Quit Telegram
Icon=application-exit
EOF

if command -v update-desktop-database >/dev/null 2>&1; then
	update-desktop-database "$DATA_HOME/applications" >/dev/null 2>&1 || true
fi
if command -v xdg-mime >/dev/null 2>&1; then
	xdg-mime default "$DESKTOP_ID" x-scheme-handler/tg >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------- checar deps
PM=""
if command -v ldd >/dev/null 2>&1; then
	missing="$(ldd "$PREFIX/Telegram" 2>/dev/null | awk '/not found/ {print $1}' | sort -u)" || true
	if [ -n "$missing" ]; then
		warn "bibliotecas ausentes:"
		for m in $missing; do
			printf '    %s\n' "$m" >&2
		done
		if [ -f /etc/os-release ]; then
			# shellcheck disable=SC1091
			. /etc/os-release
			case "${ID:-}" in
				arch|cachyos|manjaro|endeavouros|garuda) PM="sudo pacman -S --needed" ;;
				debian|ubuntu|linuxmint|pop|devuan|mx) PM="sudo apt-get install -y" ;;
				fedora|rhel|rocky|alma|centos) PM="sudo dnf install -y" ;;
				opensuse*|sles) PM="sudo zypper install" ;;
				void) PM="sudo xbps-install" ;;
				alpine) PM="sudo apk add" ;;
			esac
		fi
		if [ -n "$PM" ]; then
			warn "instale as dependências com: $PM <pacote>"
		else
			warn "instale as dependências pelo gerenciador de pacotes da sua distro"
		fi
	fi
fi

cat <<EOF

✔ 64Gram $VERSION instalado.
  binário:  $BIN_DIR/$APP_CMD
  app:      $PREFIX/Telegram

Execute:        $APP_CMD
Atualizar:      $0
Remover:        $0 --uninstall
EOF

if [ "$USER_MODE" = 1 ]; then
	case ":$PATH:" in
		*":$BIN_DIR:"*) ;;
		*) warn "adicione $BIN_DIR ao PATH: echo 'export PATH=\$PATH:$BIN_DIR' >> ~/.bashrc" ;;
	esac
fi
