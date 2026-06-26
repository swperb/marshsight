#!/bin/bash
# frame.sh IN OUT  -> screen centered on a black 1320x2868 canvas (black border)
IN="$1"; OUT="$2"
magick "$IN" -resize 1180x2563 -background black -gravity center -extent 1320x2868 "$OUT"
