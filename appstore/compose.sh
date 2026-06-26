#!/bin/bash
# compose.sh IN HEADLINE SUBTITLE OUT  -> branded MarshSight marketing screenshot
# Requires /tmp/bg2.png and /tmp/_wordmark.png (generated once).
IN="$1"; HEAD="$2"; SUB="$3"; OUT="$4"
IMP="/System/Library/Fonts/Supplemental/Impact.ttf"
ARB="/System/Library/Fonts/Supplemental/Arial Bold.ttf"
MAXW=1180
W=940; H=$(magick "$IN" -resize ${W}x -format %h info:)
magick "$IN" -resize ${W}x \( -size ${W}x${H} xc:none -fill white -draw "roundrectangle 0,0 $((W-1)),$((H-1)) 46,46" \) -alpha set -compose DstIn -composite /tmp/_dev.png
magick /tmp/_dev.png \( +clone -background black -shadow 60x30+0+18 \) +swap -background none -layers merge +repage /tmp/_devs.png
magick -background none -fill "#F5F2EB" -font "$IMP" -pointsize 150 label:"$HEAD" -trim +repage /tmp/_h.png
[ "$(magick /tmp/_h.png -format %w info:)" -gt $MAXW ] && magick /tmp/_h.png -resize ${MAXW}x /tmp/_h.png
magick -background none -fill "#A6C6C9" -font "$ARB" -pointsize 46 label:"$SUB" -trim +repage /tmp/_s.png
[ "$(magick /tmp/_s.png -format %w info:)" -gt $MAXW ] && magick /tmp/_s.png -resize ${MAXW}x /tmp/_s.png
magick /tmp/bg2.png \
  /tmp/_wordmark.png -gravity North -geometry +0+85 -composite \
  /tmp/_h.png -gravity North -geometry +0+235 -composite \
  \( -size 130x9 xc:"#5BC4E0" \) -gravity North -geometry +0+405 -composite \
  /tmp/_s.png -gravity North -geometry +0+445 -composite \
  /tmp/_devs.png -gravity North -geometry +0+650 -composite "$OUT"
