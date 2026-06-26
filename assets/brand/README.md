# MarshSight brand assets

The icon, logo, and social cards are generated from code so they stay crisp and
consistent. The artwork is a left-facing duck head drawn as topographic contour
lines, with the eye replaced by a glowing AR waypoint — "find your line."

## Files

- `art.mjs` — the artwork, authored once (square icon, rounded logo, OG card).
- `render.mjs` — renders the SVGs to PNG with [`sharp`](https://sharp.pixelplumbing.com/).
- `icon-app.svg`, `logo-mark.svg`, `og.svg` — generated SVG sources (committed for reference).

## Regenerate

```sh
cd assets/brand
npm install            # installs sharp (node_modules is gitignored)
node render.mjs        # writes local preview-*.png to eyeball
PUBLISH=1 node render.mjs   # also writes the real assets in web/ and MarshSight/
```

`PUBLISH=1` overwrites:

- `MarshSight/Assets.xcassets/AppIcon.appiconset/icon_1024.png` (iOS app icon, opaque square)
- `web/public/logo.png`, `web/src/app/icon.png`, `web/src/app/apple-icon.png`
- `web/src/app/opengraph-image.png`, `web/src/app/twitter-image.png`
- `assets/icon.png`, `assets/social-preview.png`

The web favicon is built separately from the rendered PNG:

```sh
magick web/src/app/icon.png -define icon:auto-resize=64,48,32,16 web/src/app/favicon.ico
```
