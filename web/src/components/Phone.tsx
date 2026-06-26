// Faithful in-browser mockups of the MarshSight iOS app. The AR HUD and the 2D
// map mirror the real app's layers and colors (see HUDOverlay.swift and
// RegionStyle.swift) so the screenshots are honest, not invented.

import type { ReactNode } from "react";

const SANS = "ui-sans-serif, system-ui, -apple-system, sans-serif";
const MONO = "ui-monospace, SFMono-Regular, Menlo, monospace";

export function PhoneFrame({
  children,
  className = "",
  float = false,
}: {
  children: ReactNode;
  className?: string;
  float?: boolean;
}) {
  return (
    <div
      className={`relative ${className}`}
      style={float ? { animation: "float-y 7s ease-in-out infinite" } : undefined}
    >
      <div className="rounded-[2.6rem] border border-marsh-600/70 bg-[#05100b] p-2.5 shadow-2xl shadow-black/60 ring-1 ring-white/5">
        <div className="relative overflow-hidden rounded-[2.1rem] bg-black">
          {/* Dynamic Island */}
          <div className="absolute left-1/2 top-2 z-10 h-5 w-24 -translate-x-1/2 rounded-full bg-black" />
          {children}
        </div>
      </div>
    </div>
  );
}

/* ----------------------------- AR HUD screen ----------------------------- */

export function ArScreen() {
  return (
    <svg viewBox="0 0 320 692" className="block w-full" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="ar-sky" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#13241d" />
          <stop offset="0.5" stopColor="#26392b" />
          <stop offset="0.74" stopColor="#7a6738" />
          <stop offset="0.82" stopColor="#caa85a" />
          <stop offset="1" stopColor="#2c3a33" />
        </linearGradient>
        <linearGradient id="ar-water" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#b88a45" stopOpacity="0.7" />
          <stop offset="0.3" stopColor="#34453c" />
          <stop offset="1" stopColor="#0c1812" />
        </linearGradient>
      </defs>

      {/* camera feed: dawn marsh */}
      <rect width="320" height="692" fill="url(#ar-sky)" />
      <ellipse cx="160" cy="430" rx="150" ry="70" fill="#ffce80" opacity="0.5" />
      <path d="M0 410 q40 -16 80 -6 q44 -22 96 -6 q50 -20 104 -4 q30 -10 40 -4 V470 H0Z" fill="#16271e" />
      <rect y="430" width="320" height="262" fill="url(#ar-water)" />
      <g stroke="#ffd28a" strokeLinecap="round" opacity="0.45">
        <path d="M120 470 H210" strokeWidth="2" />
        <path d="M104 498 H224" strokeWidth="2" opacity="0.7" />
        <path d="M96 528 H236" strokeWidth="2" opacity="0.5" />
      </g>
      {/* foreground reeds */}
      <g stroke="#0a1812" strokeWidth="3" strokeLinecap="round" fill="none">
        <path d="M22 692 C 18 600, 26 560, 20 520" />
        <path d="M40 692 C 38 610, 44 580, 40 540" />
        <path d="M300 692 C 304 590, 296 556, 302 512" />
        <path d="M282 692 C 280 612, 286 584, 282 548" />
      </g>

      {/* ---- HUD ---- */}
      {/* top pills */}
      <g fontFamily={SANS} fontWeight={600} fontSize="11">
        <g>
          <rect x="12" y="50" width="78" height="26" rx="13" fill="#000" opacity="0.5" />
          <text x="26" y="67" fill="#fff">⚡ 4.2 mph</text>
        </g>
        <g>
          <rect x="96" y="50" width="96" height="26" rx="13" fill="#000" opacity="0.5" />
          <text x="108" y="67" fill="#7cc593">▣ Bayou DeView</text>
        </g>
        <g>
          <rect x="240" y="50" width="68" height="26" rx="13" fill="#000" opacity="0.5" />
          <text x="251" y="67" fill="#34C759">◉ GPS 6m</text>
        </g>
      </g>

      {/* public land banner */}
      <g>
        <rect x="12" y="84" width="296" height="44" rx="12" fill="#000" opacity="0.6" />
        <rect x="12" y="84" width="296" height="44" rx="12" fill="none" stroke="#34C759" strokeWidth="1.5" />
        <circle cx="28" cy="106" r="5" fill="#34C759" />
        <text x="42" y="103" fill="#fff" fontFamily={SANS} fontWeight={700} fontSize="13">
          Dale Bumpers White River NWR
        </text>
        <text x="42" y="119" fill="#ffffff" opacity="0.82" fontFamily={SANS} fontSize="10.5">
          Open Access · U.S. Fish &amp; Wildlife Service
        </text>
      </g>

      {/* river stage banner (teal) */}
      <g>
        <rect x="12" y="134" width="296" height="44" rx="12" fill="#2fa6c2" opacity="0.9" />
        <text x="26" y="153" fill="#fff" fontFamily={SANS} fontSize="13">⌗</text>
        <text x="42" y="151" fill="#fff" fontFamily={SANS} fontWeight={600} fontSize="10.5">
          White River at Clarendon
        </text>
        <text x="42" y="169" fill="#fff" fontFamily={MONO} fontWeight={700} fontSize="13">
          Stage 4.21 ft     320 cfs
        </text>
      </g>

      {/* floating AR waypoint billboards */}
      <Billboard x={206} y={300} label="Channel Bend" sub="210 yd" color="#22D3EE" />
      <Billboard x={70} y={360} label="Decoy Spread" sub="95 yd" color="#22C55E" />
      <Billboard x={150} y={250} label="Launch" sub="540 yd" color="#FFD60A" />

      {/* hazard alert capsule */}
      <g>
        <rect x="60" y="486" width="200" height="30" rx="15" fill="#FF3B30" opacity="0.9" />
        <text x="78" y="505" fill="#fff" fontFamily={SANS} fontWeight={600} fontSize="12">
          ⚠ Submerged stump
        </text>
        <text x="218" y="505" fill="#fff" fontFamily={MONO} fontWeight={700} fontSize="12">
          80 yd
        </text>
      </g>

      {/* steering card */}
      <g>
        <rect x="12" y="540" width="296" height="86" rx="18" fill="#000" opacity="0.55" />
        <g transform="translate(56 583)">
          <circle r="30" fill="#000" opacity="0.4" />
          <circle r="30" fill="none" stroke="#fff" strokeWidth="1" opacity="0.3" />
          <path
            d="M0 -16 L9 10 L0 4 L-9 10 Z"
            fill="#22D3EE"
            transform="rotate(28)"
          />
        </g>
        <text x="100" y="572" fill="#fff" fontFamily={SANS} fontWeight={700} fontSize="16">
          Channel Bend
        </text>
        <text x="100" y="592" fill="#fff" opacity="0.85" fontFamily={MONO} fontSize="13">
          210 yd ahead
        </text>
        <text x="100" y="610" fill="#FFD60A" fontFamily={MONO} fontSize="11">
          Launch 540 yd
        </text>
      </g>
    </svg>
  );
}

function Billboard({
  x,
  y,
  label,
  sub,
  color,
}: {
  x: number;
  y: number;
  label: string;
  sub: string;
  color: string;
}) {
  const w = label.length * 6.4 + 24;
  return (
    <g fontFamily={SANS}>
      {/* pulse */}
      <circle cx={x} cy={y} r="7" fill={color} opacity="0.25">
        <animate attributeName="r" values="7;16;7" dur="2.4s" repeatCount="indefinite" />
        <animate attributeName="opacity" values="0.35;0;0.35" dur="2.4s" repeatCount="indefinite" />
      </circle>
      <circle cx={x} cy={y} r="5.5" fill={color} stroke="#fff" strokeWidth="1.5" />
      <line x1={x} y1={y} x2={x} y2={y - 18} stroke={color} strokeWidth="1.5" opacity="0.8" />
      <g transform={`translate(${x - w / 2} ${y - 40})`}>
        <rect width={w} height="20" rx="10" fill="#000" opacity="0.6" />
        <rect width={w} height="20" rx="10" fill="none" stroke={color} strokeWidth="1" opacity="0.7" />
        <text x={w / 2} y="14" textAnchor="middle" fill="#fff" fontWeight={600} fontSize="10">
          {label} · {sub}
        </text>
      </g>
    </g>
  );
}

/* ------------------------------ 2D map screen ------------------------------ */

export function MapScreen() {
  return (
    <svg viewBox="0 0 320 692" className="block w-full" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="map-bg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#e7e2cf" />
          <stop offset="1" stopColor="#d2d8c2" />
        </linearGradient>
      </defs>

      {/* USGS topo-style basemap */}
      <rect width="320" height="692" fill="url(#map-bg)" />
      {/* contour lines */}
      <g fill="none" stroke="#b9a06f" strokeWidth="1" opacity="0.5">
        <path d="M-10 120 C 80 90, 160 150, 330 110" />
        <path d="M-10 150 C 80 122, 160 182, 330 142" />
        <path d="M-10 182 C 80 156, 160 214, 330 176" />
        <path d="M-10 560 C 90 600, 200 540, 330 590" />
        <path d="M-10 600 C 90 640, 200 582, 330 628" />
      </g>

      {/* lake (blue fill) */}
      <path
        d="M40 250 C 80 220, 150 230, 170 270 C 188 306, 150 350, 96 348 C 50 346, 18 300, 40 250 Z"
        fill="#3B82F6"
        opacity="0.3"
      />
      <path
        d="M40 250 C 80 220, 150 230, 170 270 C 188 306, 150 350, 96 348 C 50 346, 18 300, 40 250 Z"
        fill="none"
        stroke="#3B82F6"
        strokeWidth="1.5"
      />
      {/* river */}
      <path
        d="M170 270 C 220 300, 230 380, 280 430 C 300 452, 300 520, 268 560"
        fill="none"
        stroke="#3B82F6"
        strokeWidth="2.5"
        opacity="0.75"
      />

      {/* public land: open access (green) */}
      <path
        d="M150 120 H300 V330 C 250 360, 200 330, 150 350 Z"
        fill="#34C759"
        opacity="0.22"
      />
      <path
        d="M150 120 H300 V330 C 250 360, 200 330, 150 350 Z"
        fill="none"
        stroke="#34C759"
        strokeWidth="1.6"
      />
      {/* closed area (red) */}
      <path d="M232 150 h54 v54 h-54 Z" fill="#FF3B30" opacity="0.2" />
      <path d="M232 150 h54 v54 h-54 Z" fill="none" stroke="#FF3B30" strokeWidth="1.6" />

      {/* hunting unit boundary (purple dashed) */}
      <path
        d="M20 100 H300 V470 H20 Z"
        fill="none"
        stroke="#A855F7"
        strokeWidth="2.2"
        strokeDasharray="6 4"
        opacity="0.85"
      />

      {/* trail (orange dashed) */}
      <path
        d="M60 470 C 110 430, 130 360, 200 330"
        fill="none"
        stroke="#E0903C"
        strokeWidth="2"
        strokeDasharray="3 3"
      />

      {/* recorded track (yellow) */}
      <path
        d="M150 600 C 120 540, 180 500, 160 440 C 150 410, 190 380, 200 360"
        fill="none"
        stroke="#FFD60A"
        strokeWidth="2.6"
      />

      {/* nav line (blue) to destination */}
      <path
        d="M150 600 C 200 560, 230 470, 268 440"
        fill="none"
        stroke="#0A84FF"
        strokeWidth="4"
        strokeLinecap="round"
        opacity="0.95"
      />
      {/* destination */}
      <circle cx="268" cy="440" r="7" fill="#0A84FF" stroke="#fff" strokeWidth="2.5" />

      {/* markers */}
      <Marker x={120} y={300} color="#30B0C7" />
      <Marker x={210} y={250} color="#22C55E" />
      <Marker x={250} y={300} color="#FF3B30" />
      <Marker x={90} y={420} color="#AF52DE" />

      {/* user location */}
      <g>
        <circle cx="150" cy="600" r="14" fill="#0A84FF" opacity="0.2" />
        <circle cx="150" cy="600" r="6" fill="#0A84FF" stroke="#fff" strokeWidth="2.5" />
      </g>

      {/* top basemap chips */}
      <g fontFamily={SANS} fontWeight={600} fontSize="10.5">
        <rect x="12" y="50" width="92" height="26" rx="13" fill="#0b1e16" />
        <text x="24" y="67" fill="#7cc593">◧ Sat + Topo</text>
        <rect x="110" y="50" width="58" height="26" rx="13" fill="#fff" opacity="0.85" />
        <text x="124" y="67" fill="#11201a">Topo</text>
        <rect x="174" y="50" width="74" height="26" rx="13" fill="#fff" opacity="0.85" />
        <text x="186" y="67" fill="#11201a">Terrain</text>
        <rect x="280" y="50" width="28" height="26" rx="13" fill="#0b1e16" />
        <text x="289" y="68" fill="#f4b860" fontSize="13">≣</text>
      </g>

      {/* gauge readout card */}
      <g fontFamily={SANS}>
        <rect x="12" y="612" width="296" height="64" rx="16" fill="#0b1e16" opacity="0.96" />
        <circle cx="36" cy="644" r="13" fill="#2fa6c2" opacity="0.25" />
        <text x="36" y="649" textAnchor="middle" fill="#5cc6dd" fontSize="14">⌗</text>
        <text x="58" y="636" fill="#eef3ec" fontWeight={700} fontSize="12">
          White River · Clarendon gauge
        </text>
        <text x="58" y="654" fill="#9fb6a8" fontFamily={MONO} fontSize="11">
          Stage 4.21 ft
        </text>
        <text x="150" y="654" fill="#9fb6a8" fontFamily={MONO} fontSize="11">
          320 cfs
        </text>
        <text x="58" y="670" fill="#7cc593" fontSize="9.5">
          ▲ rising · updated 12 min ago
        </text>
      </g>
    </svg>
  );
}

function Marker({ x, y, color }: { x: number; y: number; color: string }) {
  return <circle cx={x} cy={y} r="5" fill={color} stroke="#fff" strokeWidth="1.5" />;
}
