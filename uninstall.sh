#!/usr/bin/env bash
# Atalho de desinstalação: delega para o install.sh com --uninstall.
# Uso: curl -fsSL https://lucianoskx.github.io/64gram-installer/uninstall.sh | bash
#
# INSTALL_SH_URL existe para teste (apontar para outro lugar).
set -euo pipefail

INSTALL_SH_URL="${INSTALL_SH_URL:-https://lucianoskx.github.io/64gram-installer/install.sh}"

curl -fsSL --retry 3 --retry-all-errors "$INSTALL_SH_URL" | bash -s -- --uninstall "$@"
