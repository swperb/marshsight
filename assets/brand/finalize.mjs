import sharp from "sharp";
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { conceptB } from "./concepts.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, "..", "..");
const buf = (s) => Buffer.from(s);

const SQUARE = conceptB();
writeFileSync(join(here, "icon-final.svg"), SQUARE);

// Rounded mask for web logo / favicon (transparent corners).
const roundedMask = (size, r) =>
  buf(`<svg width="${size}" height="${size}"><rect width="${size}" height="${size}" rx="${r}" ry="${r}"/></svg>`);

async function squarePng(size, out, bg = "#11161b") {
  await sharp(buf(SQUARE), { density: 384 })
    .resize(size, size, { fit: "fill" })
    .flatten({ background: bg })
    .png()
    .toFile(out);
  console.log("square", out);
}

async function roundedPng(size, out) {
  const r = Math.round(size * 0.22);
  await sharp(buf(SQUARE), { density: 384 })
    .resize(size, size, { fit: "fill" })
    .composite([{ input: roundedMask(size, r), blend: "dest-in" }])
    .png()
    .toFile(out);
  console.log("rounded", out);
}

// Editorial social card (1200 x 630) — stone paper + cube mark.
function ogCard() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <rect width="1200" height="630" fill="#f4f1ea"/>
  <rect x="0" y="0" width="1200" height="8" fill="#2a4536"/>
  <text x="80" y="208" font-family="Georgia,'Times New Roman',serif" font-size="32" letter-spacing="3" fill="#b07a3c">FREE · OPEN-SOURCE · AR</text>
  <text x="76" y="300" font-family="Georgia,'Times New Roman',serif" font-size="92" font-weight="bold" fill="#1b1f1a">MarshSight</text>
  <text x="80" y="372" font-family="Helvetica,Arial,sans-serif" font-size="30" fill="#4c534a">Public-land boundaries, the full water network, live</text>
  <text x="80" y="412" font-family="Helvetica,Arial,sans-serif" font-size="30" fill="#4c534a">river gauges, and terrain — in augmented reality.</text>
  <line x1="80" y1="470" x2="470" y2="470" stroke="#ddd6c6" stroke-width="2"/>
  <text x="80" y="512" font-family="Helvetica,Arial,sans-serif" font-size="24" fill="#6b7268">Built on USGS · NOAA · PAD-US public data</text>
  <g transform="translate(840, 175)"><!-- icon placeholder, composited below --></g>
</svg>`;
}

async function buildOg(out) {
  const card = await sharp(buf(ogCard())).png().toBuffer();
  const icon = await sharp(buf(SQUARE), { density: 384 })
    .resize(280, 280, { fit: "fill" })
    .composite([{ input: roundedMask(280, 62), blend: "dest-in" }])
    .png()
    .toBuffer();
  await sharp(card)
    .composite([{ input: icon, left: 840, top: 175 }])
    .png()
    .toFile(out);
  console.log("og", out);
}

// iOS app icon — opaque square, no rounding.
await squarePng(1024, join(repo, "MarshSight/Assets.xcassets/AppIcon.appiconset/icon_1024.png"));
// Apple touch icon — opaque square (iOS rounds it).
await squarePng(180, join(repo, "web/src/app/apple-icon.png"));

// Rounded web marks.
await roundedPng(256, join(repo, "web/public/logo.png"));
await roundedPng(512, join(repo, "web/src/app/icon.png"));
await roundedPng(512, join(repo, "assets/icon.png"));

// Social cards.
await buildOg(join(repo, "web/src/app/opengraph-image.png"));
await buildOg(join(repo, "web/src/app/twitter-image.png"));
await buildOg(join(repo, "assets/social-preview.png"));

// Local preview of the final icon.
await roundedPng(420, join(here, "final-preview.png"));

console.log("done");
