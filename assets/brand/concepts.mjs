// Three flat, modern app-icon concepts built around Apple's ARKit / AR
// viewfinder language. Rendered to a single comparison board for the user to
// pick from. No contour duck, no cartoon.

const W = 1024;

// ---- shared helpers ----
const hexPts = (cx, cy, r) =>
  [90, 150, 210, 270, 330, 30].map((a) => {
    const rad = (a * Math.PI) / 180;
    return [cx + r * Math.cos(rad), cy - r * Math.sin(rad)];
  });

// ARKit-style isometric cube glyph (hexagon outline + central triradiate Y).
function arCube(cx, cy, r, stroke, sw, accent) {
  const p = hexPts(cx, cy, r);
  const hex = `M ${p.map((q) => q.join(",")).join(" L ")} Z`;
  const top = p[0],
    bl = p[2],
    br = p[4];
  return `
    <path d="${hex}" fill="none" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>
    <path d="M ${cx} ${cy} L ${top[0]} ${top[1]} M ${cx} ${cy} L ${bl[0]} ${bl[1]} M ${cx} ${cy} L ${br[0]} ${br[1]}"
          stroke="${stroke}" stroke-width="${sw}" stroke-linecap="round"/>
    <circle cx="${cx}" cy="${cy}" r="${sw * 1.5}" fill="${accent}"/>`;
}

// AR viewfinder corner brackets framing a region.
function brackets(cx, cy, s, len, stroke, sw) {
  const c = [
    [cx - s, cy - s, 1, 1],
    [cx + s, cy - s, -1, 1],
    [cx - s, cy + s, 1, -1],
    [cx + s, cy + s, -1, -1],
  ];
  return c
    .map(
      ([x, y, dx, dy]) =>
        `<path d="M ${x + dx * len} ${y} L ${x} ${y} L ${x} ${y + dy * len}"
           fill="none" stroke="${stroke}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"/>`
    )
    .join("\n");
}

// A simple map pin (teardrop) with a hole.
function pin(cx, cy, r, fill, dot) {
  return `
    <path d="M ${cx} ${cy + r * 2.2}
             C ${cx - r * 1.1} ${cy + r * 0.8}, ${cx - r} ${cy - r * 0.2}, ${cx} ${cy - r}
             C ${cx + r} ${cy - r * 0.2}, ${cx + r * 1.1} ${cy + r * 0.8}, ${cx} ${cy + r * 2.2} Z"
          fill="${fill}"/>
    <circle cx="${cx}" cy="${cy + r * 0.1}" r="${r * 0.42}" fill="${dot}"/>`;
}

function frame(bg, inner, ring = "#ffffff14") {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${W}" viewBox="0 0 ${W} ${W}">
    <defs>${bg.defs || ""}</defs>
    <rect width="${W}" height="${W}" fill="${bg.fill}"/>
    ${bg.overlay || ""}
    ${inner}
    <rect x="3" y="3" width="${W - 6}" height="${W - 6}" rx="0" fill="none" stroke="${ring}" stroke-width="2"/>
  </svg>`;
}

// ---- Concept A: AR viewfinder + location pin ----
export function conceptA() {
  const bg = {
    defs: `<linearGradient id="ga" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1f4034"/><stop offset="1" stop-color="#15302700"/></linearGradient>
    <linearGradient id="ga2" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#22433a"/><stop offset="1" stop-color="#15302a"/></linearGradient>`,
    fill: "url(#ga2)",
  };
  const inner = `
    ${brackets(512, 500, 250, 120, "#f2efe6", 26)}
    ${pin(512, 470, 92, "#e7c46a", "#15302a")}`;
  return frame(bg, inner);
}

// ---- Concept B: ARKit cube + horizon/water line ----
export function conceptB() {
  const bg = {
    defs: `<linearGradient id="gb" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1b2229"/><stop offset="1" stop-color="#11161b"/></linearGradient>`,
    fill: "url(#gb)",
  };
  const inner = `
    ${arCube(512, 452, 230, "#f2efe6", 30, "#5cc6dd")}
    <path d="M 232 760 C 360 730, 480 786, 560 754 C 660 712, 760 760, 792 742"
          fill="none" stroke="#5cc6dd" stroke-width="20" stroke-linecap="round" opacity="0.9"/>
    <path d="M 286 814 C 400 792, 540 828, 740 800"
          fill="none" stroke="#3a6f59" stroke-width="16" stroke-linecap="round" opacity="0.8"/>`;
  return frame(bg, inner);
}

// ---- Concept C: AR reticle over a river bend ----
export function conceptC() {
  const bg = {
    defs: `<linearGradient id="gc" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#27483b"/><stop offset="1" stop-color="#172e26"/></linearGradient>`,
    fill: "url(#gc)",
  };
  const inner = `
    <!-- river bend -->
    <path d="M 250 230 C 470 360, 300 520, 520 620 C 700 700, 560 840, 760 880"
          fill="none" stroke="#5cc6dd" stroke-width="46" stroke-linecap="round" opacity="0.85"/>
    <path d="M 250 230 C 470 360, 300 520, 520 620 C 700 700, 560 840, 760 880"
          fill="none" stroke="#0e221c" stroke-width="10" stroke-linecap="round" stroke-dasharray="2 34" opacity="0.5"/>
    <!-- reticle -->
    <circle cx="512" cy="500" r="120" fill="none" stroke="#f2efe6" stroke-width="24"/>
    <circle cx="512" cy="500" r="34" fill="#e7c46a"/>
    <g stroke="#f2efe6" stroke-width="24" stroke-linecap="round">
      <line x1="512" y1="318" x2="512" y2="380"/>
      <line x1="512" y1="620" x2="512" y2="682"/>
      <line x1="330" y1="500" x2="392" y2="500"/>
      <line x1="632" y1="500" x2="694" y2="500"/>
    </g>`;
  return frame(bg, inner);
}
