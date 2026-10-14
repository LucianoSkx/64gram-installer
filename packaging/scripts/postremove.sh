#!/bin/sh
# conversas em ~/.local/share/64Gram nunca são apagadas pelo pacote
set -e

if command -v update-desktop-database >/dev/null 2>&1; then
	update-desktop-database -q /usr/share/applications 2>/dev/null || true
fi

exit 0
