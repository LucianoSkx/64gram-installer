#!/bin/sh
# não falha a instalação se as ferramentas de desktop não existirem
set -e

if command -v update-desktop-database >/dev/null 2>&1; then
	update-desktop-database -q /usr/share/applications 2>/dev/null || true
fi
if command -v gtk-update-icon-theme >/dev/null 2>&1; then
	gtk-update-icon-theme -q -t hicolor /usr/share/icons/hicolor 2>/dev/null || true
fi
if command -v xdg-mime >/dev/null 2>&1; then
	xdg-mime default io.github.tdesktop_x64.TDesktop.desktop x-scheme-handler/tg >/dev/null 2>&1 || true
fi

exit 0
