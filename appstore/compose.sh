#!/bin/bash
# compose.sh IN HEADLINE SUBTITLE OUT  -> onX-style marketing screenshot
IN="$1"; HEAD="$2"; SUB="$3"; OUT="$4"
IMP="/System/Library/Fonts/Supplemental/Impact.ttf"
ARB="/System/Library/Fonts/Supplemental/Arial Bold.ttf"
MAXW=1180
# Device: rounded corners + soft shadow
W=940; H=$(magick "$IN" -resize ${W}x -format "%h" info:)
magick "$IN" -resize ${W}x \( -size ${W}x${H} xc:none -fill white -draw "roundrectangle 0,0 $((W-1)),$((H-1)) 46,46" \) -alpha set -compose DstIn -composite /tmp/_dev.png
magick /tmp/_dev.png \( +clone -background black -shadow 60x30+0+18 \) +swap -background none -layers merge +repage /tmp/_devs.png
# Headline + subtitle as auto-fit layers (scale down if wider than MAXW)
magick -background none -fill white -font "$IMP" -pointsize 150 label:"$HEAD" -trim +repage /tmp/_h.png
hw=$(magick /tmp/_h.png -format "%w" info:); [ "$hw" -gt "$MAXW" ] && magick /tmp/_h.png -resize ${MAXW}x /tmp/_h.png
magick -background none -fill "#AEB4B9" -font "$ARB" -pointsize 46 label:"$SUB" -trim +repage /tmp/_s.png
sw=$(magick /tmp/_s.png -format "%w" info:); [ "$sw" -gt "$MAXW" ] && magick /tmp/_s.png -resize ${MAXW}x /tmp/_s.png
# Compose
magick /tmp/topo_bg.png \
  /tmp/_h.png  -gravity North -geometry +0+170 -composite \
  /tmp/_s.png  -gravity North -geometry +0+360 -composite \
  /tmp/_devs.png -gravity North -geometry +0+560 -composite "$OUT"
