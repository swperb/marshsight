# MarshSight brand assets

The icon, logo, and social cards are generated from code so they stay crisp and
consistent. The mark is the **ARKit isometric cube** (Apple's AR glyph) with a
cyan node, sitting over a water line — flat and modern.

## Files

- `concepts.mjs` — the three icon concepts that were explored. `conceptB` is the chosen mark.
- `finalize.mjs` — renders the chosen icon + social cards to every shipped size.
- `board.mjs` — renders the 3-up concept comparison board (for picking a direction).
- `concept-a/b/c.svg`, `icon-final.svg` — generated SVG sources (kept for reference).

## Regenerate the shipped assets

```sh
cd assets/brand
npm install            # installs sharp (node_modules + *.png are gitignored)
node finalize.mjs      # overwrites the real assets in web/ and MarshSight/
```

`finalize.mjs` writes:

- `MarshSight/Assets.xcassets/AppIcon.appiconset/icon_1024.png` (iOS app icon, opaque square)
- `web/src/app/apple-icon.png` (opaque square)
- `web/public/logo.png`, `web/src/app/icon.png`, `assets/icon.png` (rounded, transparent)
- `web/src/app/opengraph-image.png`, `web/src/app/twitter-image.png`, `assets/social-preview.png`

The favicon is built separately from the rendered PNG:

```sh
magick web/src/app/icon.png -define icon:auto-resize=64,48,32,16 web/src/app/favicon.ico
```

The on-site header/footer mark is an inline SVG (`LogoMark` in `web/src/app/page.tsx`),
kept in sync with this icon by hand.
```
