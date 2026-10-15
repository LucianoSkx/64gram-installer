#!/usr/bin/env bash
# 64Gram (unofficial Telegram Desktop) — instalador universal para Linux
# Funciona em Debian, Ubuntu, Fedora, Arch, CachyOS, openSUSE e derivados.
# Se chamarem com "sh install.sh", "dash install.sh" ou "zsh install.sh",
# re-executa no bash antes de usar construções que só o bash entende.
if [ -z "${BASH_VERSION:-}" ]; then
	exec bash "$0" "$@"
fi

set -euo pipefail

REPO="TDesktop-x64/tdesktop"
# repositório onde este install.sh está publicado (para execução via curl | bash)
SELF_REPO="LucianoSkx/64gram-installer"
# link único para instalar — servido pelo GitHub Pages, é o mesmo install.sh do repo
INSTALL_URL="https://lucianoskx.github.io/64gram-installer/install.sh"
APP_CMD="64gram"
APP_TITLE="64Gram Desktop"
DESKTOP_ID="io.github.tdesktop_x64.TDesktop.desktop"
ICON_NAME="64gram"
ICON_URL_BASE="https://raw.githubusercontent.com/$REPO/dev/Telegram/Resources/art"
ICON_SIZES="16 32 48 64 128 256 512"
PREFIX_SYSTEM="/opt/64gram"
# instalação do usuário fica em ~/.local/opt para não se confundir com os dados
# do app, que são em ~/.local/share/64Gram (com G maiúsculo, definido pelo 64Gram)
PREFIX_USER="$HOME/.local/opt/64gram"
DATA_USER="${XDG_DATA_HOME:-$HOME/.local/share}/64Gram"

ORIG_ARGS=("$@")
VERSION=""
LOCAL=""
USER_MODE=0
UNINSTALL=0
ASSUME_YES=0
info() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> ATENÇÃO:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mErro:\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- detecção
# Reconhece a distro para usar o gerenciador e os nomes de pacote certos.
SYS_NAME="sistema desconhecido"
SYS_FAMILY="desconhecida"
SYS_PM=""          # comando completo para instalar pacotes
SYS_ROOT=0         # 1 se estiver instalado como root

detect_system() {
	SYS_ROOT=0
	[ "$(id -u)" = "0" ] && SYS_ROOT=1

	if [ ! -r /etc/os-release ]; then
		warn "sem /etc/os-release: não dá para identificar a distro"
		return 0
	fi

	local id="" like="" pretty=""
	# shellcheck disable=SC1091
	. /etc/os-release
	id="${ID:-}"; like="${ID_LIKE:-}"; pretty="${PRETTY_NAME:-$id}"
	SYS_NAME="${pretty:-$id}"
	[ -n "$SYS_NAME" ] || SYS_NAME="sistema desconhecido"

	case " ${like:-} ${id:-} " in
		*" arch "*|*" cachyos "*|*" manjaro "*|*" endeavouros "*|*" garuda "*|*" artix "*)
			SYS_FAMILY="arch"; SYS_PM="pacman -S --needed --noconfirm" ;;
		*" debian "*|*" ubuntu "*|*" mint "*|*" pop "*|*" raspbian "*)
			SYS_FAMILY="debian"; SYS_PM="apt-get install -y" ;;
		*" fedora "*|*" rhel "*|*" centos "*|*" rocky "*|*" almalinux "*|*" ol "*)
			SYS_FAMILY="rpm"; SYS_PM="dnf install -y" ;;
		*" opensuse "*|*" suse "*|*" sle "*)
			SYS_FAMILY="suse"; SYS_PM="zypper --non-interactive install" ;;
		*" void "*) SYS_FAMILY="void"; SYS_PM="xbps-install -y" ;;
		*" alpine "*) SYS_FAMILY="alpine"; SYS_PM="apk add" ;;
		*) SYS_FAMILY="desconhecida" ;;
	esac
}

# nome do pacote que fornece uma biblioteca, por família de distro
pkg_for_lib() {
	case "$SYS_FAMILY:$1" in
	debian:libX11.so.*)        echo libx11-6 ;;
	debian:libGL.so.*)         echo libgl1 ;;
	debian:libGLX.so.*)        echo libglx0 ;;
	debian:libGLdispatch.so.*) echo libglvnd0 ;;
	debian:libfontconfig.so.*) echo libfontconfig1 ;;
	debian:libfreetype.so.*)   echo libfreetype6 ;;
	debian:libdbus-1.so.*)     echo libdbus-1-3 ;;
	debian:libsystemd.so.*)    echo libsystemd0 ;;
	debian:libxcb.so.*)        echo libxcb1 ;;
	debian:libXext.so.*)       echo libxext6 ;;
	debian:libXrender.so.*)    echo libxrender1 ;;
	debian:libpango-1.0.so.*)  echo libpango-1.0-0 ;;
	debian:libpangocairo-1.0.so.*) echo libpangocairo-1.0-0 ;;
	debian:libcairo.so.*)      echo libcairo2 ;;
	debian:libharfbuzz.so.*)   echo libharfbuzz0b ;;

	arch:libX11.so.*)          echo libx11 ;;
	arch:libGL.so.*)           echo libglvnd ;;
	arch:libGLX.so.*)          echo libglvnd ;;
	arch:libfontconfig.so.*)   echo fontconfig ;;
	arch:libfreetype.so.*)     echo freetype2 ;;
	arch:libdbus-1.so.*)       echo libdbus ;;
	arch:libsystemd.so.*)      echo systemd-libs ;;
	arch:libxcb.so.*)          echo libxcb ;;
	arch:libXext.so.*)         echo libxext ;;
	arch:libXrender.so.*)      echo libxrender ;;
	arch:libpango-1.0.so.*)    echo pango ;;
	arch:libpangocairo-1.0.so.*) echo pango ;;
	arch:libcairo.so.*)        echo cairo ;;
	arch:libharfbuzz.so.*)     echo harfbuzz ;;

	rpm:libX11.so.*)           echo libX11 ;;
	rpm:libGL.so.*)            echo mesa-libGL ;;
	rpm:libGLX.so.*)           echo libglvnd ;;
	rpm:libfontconfig.so.*)    echo fontconfig ;;
	rpm:libfreetype.so.*)      echo freetype ;;
	rpm:libdbus-1.so.*)        echo dbus-libs ;;
	rpm:libsystemd.so.*)       echo systemd-libs ;;
	rpm:libxcb.so.*)           echo libxcb ;;
	rpm:libXext.so.*)          echo libXext ;;
	rpm:libXrender.so.*)       echo libXrender ;;
	rpm:libpango-1.0.so.*)     echo pango ;;
	rpm:libpangocairo-1.0.so.*) echo pango ;;
	rpm:libcairo.so.*)         echo cairo ;;
	rpm:libharfbuzz.so.*)      echo harfbuzz ;;

	suse:libX11.so.*)          echo libX11 ;;
	suse:libGL.so.*)           echo libglvnd ;;
	suse:libfontconfig.so.*)   echo fontconfig ;;
	suse:libfreetype.so.*)     echo freetype2 ;;
	suse:libdbus-1.so.*)       echo dbus-1 ;;
	suse:libsystemd.so.*)      echo libsystemd0 ;;
	suse:libxcb.so.*)          echo libxcb ;;
	suse:libXext.so.*)         echo libXext ;;
	suse:libXrender.so.*)      echo libXrender ;;
	suse:libpango-1.0.so.*)    echo pango ;;
	suse:libcairo.so.*)        echo cairo ;;
	suse:libharfbuzz.so.*)     echo harfbuzz ;;

	alpine:libX11.so.*)        echo libx11 ;;
	alpine:libGL.so.*)         echo libgl ;;
	alpine:libfontconfig.so.*) echo fontconfig ;;
	alpine:libfreetype.so.*)   echo freetype ;;
	alpine:libdbus-1.so.*)     echo dbus ;;
	alpine:libxcb.so.*)        echo libxcb ;;
	alpine:libpango-1.0.so.*)  echo pango ;;
	alpine:libcairo.so.*)      echo cairo ;;
	alpine:libharfbuzz.so.*)   echo harfbuzz ;;
	*) echo "" ;;
	esac
}

usage() {
	cat <<EOF
Uso: $0 [opções]

  --user            instala só para o usuário (~/.local), sem root
  --version <ver>   instala uma versão específica (ex: 1.2.10)
  --local <zip>     instala a partir de um pacote já baixado (offline)
  --uninstall       remove TUDO: app, atalho, ícones e as conversas
  -y, --yes         não pergunta confirmação ao remover
  -h, --help        mostra esta ajuda

Padrão: baixa o pacote nativo da distro (pkg.tar.zst no Arch/CachyOS, .deb no
Debian/Ubuntu, .rpm no Fedora/openSUSE) e deixa o gerenciador resolver as
dependências. Sem pacote disponível, cai no instalador genérico (zip + /opt).
Com --user, usa sempre o modo genérico, só na sua conta.

Em qualquer shell (fish, zsh, bash, dash, sh):
  curl -fsSL $INSTALL_URL | bash
  curl -fsSL $INSTALL_URL | bash -s -- --user

Sem curl no sistema:
  wget -qO- $INSTALL_URL | bash
EOF
	exit "${1:-0}"
}

while [ $# -gt 0 ]; do
	case "$1" in
		--user) USER_MODE=1 ;;
		--uninstall) UNINSTALL=1 ;;
		-y|--yes) ASSUME_YES=1 ;;
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

# executado via "curl ... | bash" (bash, zsh, fish, dash, sh, tcsh): $0 não é
# um arquivo real, então re-executa a si mesmo a partir de um arquivo de verdade.
# a forma "bash <(curl ...)" (só bash/zsh) cai no mesmo caminho.
if [ ! -f "$0" ] || [ "${0#/dev/fd/}" != "$0" ]; then
	info "obtendo o instalador (execução via pipe)"
	SELF="$TMPD/install.sh"
	download "https://raw.githubusercontent.com/$SELF_REPO/main/install.sh" "$SELF"
	export UPDATE_HINT="curl -fsSL $INSTALL_URL | bash"
	exec bash "$SELF" ${ORIG_ARGS[@]+"${ORIG_ARGS[@]}"}
fi
SELF_PATH="$0"
case "$SELF_PATH" in
	/*) ;;
	*) SELF_PATH="$PWD/$SELF_PATH" ;;
esac
: "${UPDATE_HINT:=$SELF_PATH}"

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
# Remove o que estiver REALMENTE instalado (modo usuário e/ou sistema), sem
# depender da flag: instalar e desinstalar podem ser chamados em modos diferentes.
uninstall() {
	local home="$HOME"
	if [ -n "${SUDO_USER:-}" ]; then
		local h
		h="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
		[ -n "$h" ] && home="$h"
	fi

	local prefix_u="$home/.local/opt/64gram"          # instalação do usuário
	local prefix_s="/opt/64gram"                    # instalação do sistema
	local dados_u="$home/.local/share/64Gram"       # conversas e conta
	local s found=0

	[ -e "$prefix_u" ] && found=1
	[ -e "$prefix_s" ] && found=1
	[ "$found" = 0 ] && warn "nenhuma instalação encontrada — nada a remover"

	if [ -d "$dados_u" ]; then
		if [ "$ASSUME_YES" = 0 ] && [ -t 0 ]; then
			printf '\nIsto apaga TUDO do 64Gram, incluindo as conversas em:\n  %s\n\nContinuar? [s/N] ' "$dados_u" >&2
			read -r resposta || resposta=""
			case "$resposta" in
				s|S|y|Y|sim|SIM) ;;
				*) info "cancelado — nada foi removido"; return 0 ;;
			esac
		else
			warn "removendo as conversas: $dados_u"
		fi
	fi

	# remove pelo gerenciador se for um pacote nativo (o resto é do gerenciador)
	local nativo=0
	case "$SYS_FAMILY" in
		arch)   pacman -Qq 64gram >/dev/null 2>&1 && nativo=1 ;;
		debian) dpkg-query -W 64gram >/dev/null 2>&1 && nativo=1 ;;
		rpm|suse) rpm -q 64gram >/dev/null 2>&1 && nativo=1 ;;
	esac
	if [ "$nativo" = 1 ]; then
		info "removendo o pacote pelo gerenciador do sistema"
		case "$SYS_FAMILY" in
			arch)   pacman -Rns --noconfirm 64gram ;;
			debian) apt-get remove -y 64gram ;;
			rpm|suse) rpm -e 64gram ;;
		esac
	fi

	# cada instalação remove só o que ela criou
	if [ -e "$prefix_u" ]; then
		info "removendo instalação do usuário"
		rm -f "$home/.local/bin/$APP_CMD"
		rm -f "$home/.local/share/applications/$DESKTOP_ID"
		for s in $ICON_SIZES; do
			rm -f "$home/.local/share/icons/hicolor/${s}x${s}/apps/$ICON_NAME.png"
		done
		rm -rf "$prefix_u"
		command -v update-desktop-database >/dev/null 2>&1 && \
			update-desktop-database "$home/.local/share/applications" >/dev/null 2>&1 || true
	fi

	if [ -e "$prefix_s" ]; then
		info "removendo instalação do sistema"
		rm -f "$BIN_DIR/$APP_CMD"
		rm -f "$DATA_HOME/applications/$DESKTOP_ID"
		for s in $ICON_SIZES; do
			rm -f "$DATA_HOME/icons/hicolor/${s}x${s}/apps/$ICON_NAME.png"
		done
		rm -rf "$prefix_s"
		command -v update-desktop-database >/dev/null 2>&1 && \
			update-desktop-database "$DATA_HOME/applications" >/dev/null 2>&1 || true
	fi

	rm -rf "$dados_u"
	info "64Gram removido (app e conversas)."
}

if [ "$UNINSTALL" = 1 ]; then
	uninstall
	exit 0
fi

# ---------------------------------------------------------- sistema + nativo
# Reconhece a distro e prefere o pacote nativo: o gerenciador do sistema resolve
# as dependências (no Arch/CachyOS é o pacote do AUR, como manda a tradição).
detect_system
info "sistema: $SYS_NAME ($SYS_FAMILY)"

try_native() {
	local v helper
	case "$SYS_FAMILY" in
		arch)
			for helper in paru yay pikaur; do
				command -v "$helper" >/dev/null 2>&1 || continue
				info "instalando pelo AUR com $helper (64gram-desktop-bin)"
				"$helper" -S --needed --noconfirm 64gram-desktop-bin && return 0
				warn "$helper não conseguiu instalar"
			done
			return 1 ;;
		debian|rpm|suse) ;;
		*) return 1 ;;
	esac

	download "https://api.github.com/repos/$SELF_REPO/releases/latest" "$TMPD/rel.json" || return 1
	v="$(awk -F'"' '/"tag_name"/ { print $4; exit }' "$TMPD/rel.json" | sed 's/^v//')"
	[ -n "$v" ] && [ "$v" != "null" ] || return 1
	install_native "$v"
}

if [ "$USER_MODE" = 0 ] && [ -z "$LOCAL" ] && [ -z "$VERSION" ]; then
	if try_native; then
		info "64Gram instalado pelo gerenciador do sistema."
		printf 'Execute: 64gram\nRemover: %s --uninstall\n' "${UPDATE_HINT:-$SELF_PATH}"
		exit 0
	fi
	info "sem pacote nativo disponível — seguindo com o instalador genérico"
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

# ------------------------------------------------------- pacote nativo
# Se existir pacote pronto para a distro, usa o gerenciador do sistema:
# ele resolve as dependências sozinho (mesma ideia do AUR para Arch).
pkg_name_for() { # família -> nome do arquivo no release
	case "$1" in
	arch)   echo "64gram-$2-1-x86_64.pkg.tar.zst" ;;
	debian) echo "64gram_${2}_amd64.deb" ;;
	rpm)    echo "64gram-$2-1.x86_64.rpm" ;;
	suse)   echo "64gram-$2-1.x86_64.rpm" ;;
	*)      echo "" ;;
	esac
}

install_native() { # $1 = versão; usa o gerenciador do sistema
	local pkg url pm helper

	# Arch/CachyOS: o 64Gram é distribuído como pacote do AUR, como manda a tradição
	if [ "$SYS_FAMILY" = "arch" ]; then
		for helper in paru yay pikaur; do
			command -v "$helper" >/dev/null 2>&1 || continue
			info "instalando pelo AUR com $helper (64gram-desktop-bin)"
			if "$helper" -S --needed --noconfirm 64gram-desktop-bin; then
				return 0
			fi
			warn "$helper não conseguiu instalar"
		done
		warn "sem helper de AUR (paru/yay/pikaur) — usando o instalador genérico"
		return 1
	fi

	pkg="$(pkg_name_for "$SYS_FAMILY" "$1")"
	[ -n "$pkg" ] || return 1

	url="https://github.com/$SELF_REPO/releases/download/v$1/$pkg"
	info "baixando $pkg"
	if ! download "$url" "$TMPD/$pkg"; then
		warn "pacote não encontrado ($url)"
		return 1
	fi

	case "$SYS_FAMILY" in
		arch)   pm="pacman -U --noconfirm" ;;
		debian) pm="apt-get install -y" ;;
		rpm)    pm="dnf install -y" ;;
		suse)   pm="zypper --non-interactive install" ;;
	esac

	info "instalando com: $pm"
	# shellcheck disable=SC2086
	if ! $pm "$TMPD/$pkg"; then
		die "o gerenciador recusou o pacote $pkg"
	fi

	if command -v update-desktop-database >/dev/null 2>&1; then
		update-desktop-database "$DATA_HOME/applications" >/dev/null 2>&1 || true
	fi
	return 0
}

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
BIN_PATH="$PREFIX/Telegram"

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
check_deps() {
	command -v ldd >/dev/null 2>&1 || return 0

	local missing
	missing="$(ldd "$BIN_PATH" 2>/dev/null | awk '/not found/ {print $1}' | sort -u)" || true
	[ -n "$missing" ] || return 0

	local lib pacotes=""
	for lib in $missing; do
		local p
		p="$(pkg_for_lib "$lib")"
		[ -n "$p" ] && pacotes="$pacotes $p"
		printf '    %s%s\n' "$lib" "${p:+  →  $p}" >&2
	done
	warn "bibliotecas ausentes (veja acima)"

	case " $pacotes " in *"  "*) ;; *) die "pacote desconhecido para estas bibliotecas: $pacotes" ;; esac
	pacotes="${pacotes# }"

	if [ -z "$SYS_PM" ]; then
		warn "gerenciador de pacotes não reconhecido — instale manualmente: $pacotes"
		return 0
	fi

	if [ "$SYS_ROOT" = 1 ]; then
		info "instalando dependências: $SYS_PM $pacotes"
		# shellcheck disable=SC2086
		$SYS_PM $pacotes || warn "algum pacote não pôde ser instalado — confira acima"
	else
		warn "rode com sudo para instalar as dependências, ou:"
		warn "  sudo $SYS_PM $pacotes"
	fi
}

check_deps

cat <<EOF

✔ 64Gram $VERSION instalado.
  binário:  $BIN_DIR/$APP_CMD
  app:      $PREFIX/Telegram

Execute:        $APP_CMD
Atualizar:      ${UPDATE_HINT:-$SELF_PATH}
Remover:        ${UPDATE_HINT:-$SELF_PATH} --uninstall
EOF

if [ "$USER_MODE" = 1 ]; then
	case ":$PATH:" in
		*":$BIN_DIR:"*) ;;
		*) warn "adicione $BIN_DIR ao PATH: echo 'export PATH=\$PATH:$BIN_DIR' >> ~/.bashrc" ;;
	esac
fi
