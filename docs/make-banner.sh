#!/usr/bin/env bash
# Gera docs/assets/banner.png (cabeçalho do README).
# Precisa de ImageMagick (magick) e do ícone em docs/assets/icon256.png.
#
# Uso: bash docs/make-banner.sh
set -euo pipefail

A="$(cd "$(dirname "$0")/assets" && pwd)"
FONT_B=/usr/share/fonts/noto/NotoSans-Bold.ttf
FONT_R=/usr/share/fonts/noto/NotoSans-Regular.ttf
W=1280
H=480

magick -size ${W}x${H} xc:'#0e1621' /tmp/64gram-banner.png
magick -size 1280x1280 radial-gradient:'#2AABEE28-#2AABEE00' \
	-gravity center -crop ${W}x${H}+0+0 +repage /tmp/64gram-glow.png
magick /tmp/64gram-banner.png /tmp/64gram-glow.png \
	-compose over -composite /tmp/64gram-banner.png

magick "$A/icon256.png" -resize 210x210 \
	\( +clone -background '#000000' -shadow 70x10+0+12 \) \
	+swap -background none -layers merge +repage /tmp/64gram-icon.png
magick /tmp/64gram-banner.png /tmp/64gram-icon.png \
	-gravity west -geometry +115+110 -composite /tmp/64gram-banner.png

magick /tmp/64gram-banner.png \
	-fill white -font "$FONT_B" -pointsize 104 -gravity northwest \
	-annotate +352+95 '64Gram' \
	-fill '#8ab4f8' -font "$FONT_R" -pointsize 34 -gravity northwest \
	-annotate +358+190 'Telegram Desktop não-oficial · instalador para Linux' \
	/tmp/64gram-banner.png

x=358
y=272
for label in .deb .rpm AppImage; do
	len=${#label}
	w=$(( len * 20 + 54 ))
	magick /tmp/64gram-banner.png \
		-fill '#16212e' -stroke '#2AABEE' -strokewidth 2 \
		-draw "roundrectangle ${x},${y},$((x+w)),$((y+62)) 14,14" \
		-fill '#dbeafe' -font "$FONT_R" -pointsize 30 -gravity northwest \
		-annotate +$((x+26))+$((y+14)) "$label" /tmp/64gram-banner.png
	x=$(( x + w + 20 ))
done

cp /tmp/64gram-banner.png "$A/banner.png"
rm -f /tmp/64gram-banner.png /tmp/64gram-glow.png /tmp/64gram-icon.png
echo "$A/banner.png"
