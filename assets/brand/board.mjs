import sharp from "sharp";
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { conceptA, conceptB, conceptC } from "./concepts.mjs";

const here = dirname(fileURLToPath(import.meta.url));

const tiles = [
  { svg: conceptA(), label: "A · Viewfinder + Pin" },
  { svg: conceptB(), label: "B · ARKit Cube + Water" },
  { svg: conceptC(), label: "C · Reticle + River Bend" },
];

// Render each concept to a rounded 320px PNG buffer.
const size = 320,
  radius = 72;
const mask = Buffer.from(
  `<svg width="${size}" height="${size}"><rect width="${size}" height="${size}" rx="${radius}" ry="${radius}"/></svg>`
);

const pngs = await Promise.all(
  tiles.map(async (t) => {
    const base = await sharp(Buffer.from(t.svg), { density: 200 })
      .resize(size, size)
      .composite([{ input: mask, blend: "dest-in" }])
      .png()
      .toBuffer();
    return base;
  })
);

// Compose a board: stone background, 3 icons in a row with labels.
const gap = 64,
  pad = 70,
  labelH = 64;
const boardW = pad * 2 + size * 3 + gap * 2;
const boardH = pad * 2 + size + labelH;

const labelSvg = `<svg width="${boardW}" height="${boardH}">
  <style>.t{font-family:Georgia,'Times New Roman',serif;font-size:26px;fill:#2b2a26;}</style>
  ${tiles
    .map((t, i) => {
      const x = pad + i * (size + gap) + size / 2;
      const y = pad + size + 42;
      return `<text class="t" x="${x}" y="${y}" text-anchor="middle">${t.label}</text>`;
    })
    .join("")}
</svg>`;

let board = sharp({
  create: { width: boardW, height: boardH, channels: 3, background: "#efece3" },
});

const composites = pngs.map((buf, i) => ({
  input: buf,
  left: pad + i * (size + gap),
  top: pad,
}));
composites.push({ input: Buffer.from(labelSvg), top: 0, left: 0 });

await board.composite(composites).png().toFile(join(here, "concept-board.png"));
console.log("wrote concept-board.png");

// Also write individual SVGs so the chosen one can be finalized.
writeFileSync(join(here, "concept-a.svg"), conceptA());
writeFileSync(join(here, "concept-b.svg"), conceptB());
writeFileSync(join(here, "concept-c.svg"), conceptC());
