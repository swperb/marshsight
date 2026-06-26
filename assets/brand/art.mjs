// Shared MarshSight brand artwork, authored once and rendered to every PNG size.
// Concept: a left-facing duck head drawn as topographic contour lines, with the
// eye replaced by a glowing AR waypoint (reticle + dot) — "find your line."

// Left-facing mallard head + upper neck, designed in the 1024 icon space.
export const DUCK_PATH = `
M 215 548
C 245 505, 300 484, 362 470
C 432 432, 470 298, 578 258
C 672 270, 752 312, 776 400
C 800 492, 792 600, 756 690
C 730 752, 686 778, 628 772
C 548 766, 470 740, 430 686
C 405 652, 372 612, 330 590
C 300 574, 255 566, 215 558
Z`;

// Gentle wavy "contour" lines that fill the head, suggesting an elevation map.
function contourLines() {
  const lines = [];
  let i = 0;
  for (let y = 312; y <= 742; y += 60) {
    const amp = 14 + (i % 2) * 10;
    const dir = i % 2 === 0 ? 1 : -1;
    const d = `M 180 ${y} C 360 ${y - amp * dir}, 560 ${y + amp * dir}, 860 ${
      y - amp * dir
    }`;
    lines.push(
      `<path d="${d}" fill="none" stroke="url(#contour)" stroke-width="7" stroke-linecap="round" opacity="0.9"/>`
    );
    i++;
  }
  return lines.join("\n");
}

// Faint topographic rings in the background for depth.
function bgRings() {
  const rings = [];
  for (let r = 150; r <= 720; r += 95) {
    rings.push(
      `<circle cx="600" cy="470" r="${r}" fill="none" stroke="#1b3d2f" stroke-width="3" opacity="0.5"/>`
    );
  }
  return rings.join("\n");
}

// The AR waypoint that sits where the duck's eye would be.
function waypoint(cx, cy, scale = 1) {
  const s = (n) => n * scale;
  return `
  <g filter="url(#glow)">
    <circle cx="${cx}" cy="${cy}" r="${s(78)}" fill="none" stroke="#f4b860" stroke-width="${s(3)}" opacity="0.30"/>
    <circle cx="${cx}" cy="${cy}" r="${s(50)}" fill="none" stroke="#f4b860" stroke-width="${s(5)}"/>
    <line x1="${cx}" y1="${cy - s(66)}" x2="${cx}" y2="${cy - s(40)}" stroke="#ffd28a" stroke-width="${s(5)}" stroke-linecap="round"/>
    <line x1="${cx}" y1="${cy + s(40)}" x2="${cx}" y2="${cy + s(66)}" stroke="#ffd28a" stroke-width="${s(5)}" stroke-linecap="round"/>
    <line x1="${cx - s(66)}" y1="${cy}" x2="${cx - s(40)}" y2="${cy}" stroke="#ffd28a" stroke-width="${s(5)}" stroke-linecap="round"/>
    <line x1="${cx + s(40)}" y1="${cy}" x2="${cx + s(66)}" y2="${cy}" stroke="#ffd28a" stroke-width="${s(5)}" stroke-linecap="round"/>
    <circle cx="${cx}" cy="${cy}" r="${s(24)}" fill="url(#dot)"/>
    <circle cx="${cx - s(7)}" cy="${cy - s(7)}" r="${s(7)}" fill="#fff6e4" opacity="0.85"/>
  </g>`;
}

const DEFS = `
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#15413a"/>
    <stop offset="0.45" stop-color="#0d2820"/>
    <stop offset="1" stop-color="#07140f"/>
  </linearGradient>
  <radialGradient id="sun" cx="0.5" cy="0.16" r="0.7">
    <stop offset="0" stop-color="#e89a3c" stop-opacity="0.55"/>
    <stop offset="0.5" stop-color="#c66a26" stop-opacity="0.12"/>
    <stop offset="1" stop-color="#c66a26" stop-opacity="0"/>
  </radialGradient>
  <linearGradient id="head" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#15392d"/>
    <stop offset="1" stop-color="#0a1f18"/>
  </linearGradient>
  <linearGradient id="contour" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#7cc593"/>
    <stop offset="0.55" stop-color="#5fa777"/>
    <stop offset="1" stop-color="#2fa6c2"/>
  </linearGradient>
  <radialGradient id="dot" cx="0.4" cy="0.35" r="0.8">
    <stop offset="0" stop-color="#ffe6b8"/>
    <stop offset="0.5" stop-color="#f4b860"/>
    <stop offset="1" stop-color="#e3892f"/>
  </radialGradient>
  <filter id="glow" x="-60%" y="-60%" width="220%" height="220%">
    <feGaussianBlur stdDeviation="9" result="b"/>
    <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
  <clipPath id="headClip"><path d="${DUCK_PATH}"/></clipPath>
</defs>`;

// Inner artwork (no background), used on top of whatever badge/background.
function artwork() {
  return `
  <g opacity="0.85">${bgRings()}</g>
  <g clip-path="url(#headClip)">
    <path d="${DUCK_PATH}" fill="url(#head)"/>
    ${contourLines()}
  </g>
  <path d="${DUCK_PATH}" fill="none" stroke="#7cc593" stroke-width="6" opacity="0.9"/>
  <!-- bill gape line -->
  <path d="M 232 545 C 270 528, 320 512, 372 498" fill="none" stroke="#7cc593" stroke-width="5" stroke-linecap="round" opacity="0.7"/>
  ${waypoint(470, 452)}
  <!-- waterline -->
  <g opacity="0.8">
    <path d="M 150 838 C 320 818, 520 858, 720 836 C 820 825, 880 838, 920 832" fill="none" stroke="#2fa6c2" stroke-width="7" stroke-linecap="round" opacity="0.55"/>
    <path d="M 220 884 C 360 872, 540 900, 760 880" fill="none" stroke="#2fa6c2" stroke-width="5" stroke-linecap="round" opacity="0.35"/>
  </g>`;
}

// A full square icon (no rounded corners, no alpha) — for the iOS app icon.
export function squareIcon(size = 1024) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 1024 1024">
  ${DEFS}
  <rect width="1024" height="1024" fill="url(#bg)"/>
  <rect width="1024" height="1024" fill="url(#sun)"/>
  ${artwork()}
</svg>`;
}

// A rounded badge with transparency — for the web logo / favicon.
export function roundedIcon(size = 512) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 1024 1024">
  ${DEFS}
  <clipPath id="round"><rect width="1024" height="1024" rx="224" ry="224"/></clipPath>
  <g clip-path="url(#round)">
    <rect width="1024" height="1024" fill="url(#bg)"/>
    <rect width="1024" height="1024" fill="url(#sun)"/>
    ${artwork()}
    <rect x="6" y="6" width="1012" height="1012" rx="220" ry="220" fill="none" stroke="#3a6f59" stroke-width="6" opacity="0.6"/>
  </g>
</svg>`;
}

// Wide Open Graph / social card (1200 x 630).
export function ogCard() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  ${DEFS}
  <linearGradient id="ogbg" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#0c2a22"/>
    <stop offset="1" stop-color="#07140f"/>
  </linearGradient>
  <rect width="1200" height="630" fill="url(#ogbg)"/>
  <rect width="1200" height="630" fill="url(#sun)"/>
  <g opacity="0.5">
    ${Array.from({ length: 7 }, (_, i) => `<circle cx="980" cy="150" r="${90 + i * 78}" fill="none" stroke="#1b3d2f" stroke-width="2.5"/>`).join("\n")}
  </g>
  <!-- mark on the right -->
  <g transform="translate(720, 70) scale(0.46)">
    <g clip-path="url(#headClip)">
      <path d="${DUCK_PATH}" fill="url(#head)"/>
      ${contourLines()}
    </g>
    <path d="${DUCK_PATH}" fill="none" stroke="#7cc593" stroke-width="6" opacity="0.9"/>
    ${waypoint(470, 452)}
  </g>
  <!-- wordmark + tagline on the left -->
  <text x="80" y="250" font-family="'Zilla Slab','Georgia',serif" font-size="92" font-weight="700" fill="#eef3ec">MarshSight</text>
  <text x="84" y="318" font-family="'Zilla Slab',serif" font-size="34" font-weight="500" fill="#f4b860" letter-spacing="2">FREE · OPEN-SOURCE · AR NAVIGATION</text>
  <text x="80" y="392" font-family="'Geist','Helvetica',sans-serif" font-size="30" fill="#c7d4cb">Public-land boundaries, river channels, and live</text>
  <text x="80" y="432" font-family="'Geist','Helvetica',sans-serif" font-size="30" fill="#c7d4cb">water levels — over your live camera view.</text>
  <text x="80" y="540" font-family="'Geist',sans-serif" font-size="24" fill="#7cc593">Built on USGS · NOAA · PAD-US public data</text>
</svg>`;
}
