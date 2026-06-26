import sharp from "sharp";
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { squareIcon, roundedIcon, ogCard } from "./art.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, "..", "..");
const buf = (svg) => Buffer.from(svg);

async function png(svg, w, h, out) {
  await sharp(buf(svg), { density: 384 })
    .resize(w, h, { fit: "fill" })
    .png()
    .toFile(out);
  console.log("wrote", out);
}

// Keep SVG sources around for future edits.
writeFileSync(join(here, "icon-app.svg"), squareIcon());
writeFileSync(join(here, "logo-mark.svg"), roundedIcon());
writeFileSync(join(here, "og.svg"), ogCard());

const sq = squareIcon();
const round = roundedIcon();
const og = ogCard();

// Local previews to eyeball.
await png(round, 512, 512, join(here, "preview-logo.png"));
await png(sq, 512, 512, join(here, "preview-icon.png"));
await png(og, 1200, 630, join(here, "preview-og.png"));

// ---- Ship to real locations (only when PUBLISH=1) ----
if (process.env.PUBLISH === "1") {
  // iOS app icon — square, full-bleed, no alpha.
  await sharp(buf(sq), { density: 384 })
    .resize(1024, 1024, { fit: "fill" })
    .flatten({ background: "#07140f" })
    .png()
    .toFile(join(repo, "MarshSight/Assets.xcassets/AppIcon.appiconset/icon_1024.png"));

  // README / repo icon — rounded.
  await png(round, 512, 512, join(repo, "assets/icon.png"));

  // Web logo + favicon + apple icon.
  await png(round, 256, 256, join(repo, "web/public/logo.png"));
  await png(round, 512, 512, join(repo, "web/src/app/icon.png"));
  await sharp(buf(sq), { density: 384 })
    .resize(180, 180, { fit: "fill" })
    .flatten({ background: "#07140f" })
    .png()
    .toFile(join(repo, "web/src/app/apple-icon.png"));

  // Open Graph + Twitter + social preview.
  await png(og, 1200, 630, join(repo, "web/src/app/opengraph-image.png"));
  await png(og, 1200, 630, join(repo, "web/src/app/twitter-image.png"));
  await png(og, 1200, 630, join(repo, "assets/social-preview.png"));

  console.log("published all brand assets");
}
