// A layered, animated dawn-marsh scene used behind the hero. Pure SVG + CSS so
// it stays crisp, themeable, and cheap. Motion respects prefers-reduced-motion
// via the global stylesheet.

function Reeds({ x, scale = 1, delay = 0 }: { x: number; scale?: number; delay?: number }) {
  const stalks = [-26, -12, 0, 14, 28];
  return (
    <g
      transform={`translate(${x} 760) scale(${scale})`}
      style={{
        transformOrigin: `${x}px 760px`,
        animation: `sway 6s ease-in-out ${delay}s infinite`,
      }}
    >
      {stalks.map((dx, i) => {
        const h = 150 + (i % 3) * 34;
        return (
          <g key={i}>
            <path
              d={`M ${dx} 0 C ${dx - 6} ${-h / 2}, ${dx + 4} ${-h * 0.8}, ${dx} ${-h}`}
              fill="none"
              stroke="#06120d"
              strokeWidth={5}
              strokeLinecap="round"
            />
            {/* cattail head */}
            <rect x={dx - 5} y={-h - 34} width={10} height={34} rx={5} fill="#0a1812" />
            <path
              d={`M ${dx} ${-h - 34} l 0 -16`}
              stroke="#06120d"
              strokeWidth={3}
              strokeLinecap="round"
            />
          </g>
        );
      })}
    </g>
  );
}

function Flock() {
  // A small skein of ducks drifting across the sky, wings flapping.
  const birds = [
    { x: 0, y: 0, s: 1 },
    { x: 46, y: 26, s: 0.86 },
    { x: 90, y: 50, s: 0.74 },
    { x: -44, y: 30, s: 0.84 },
    { x: -88, y: 56, s: 0.7 },
  ];
  return (
    <g style={{ animation: "drift 38s linear infinite" }} opacity={0.78}>
      <g transform="translate(0 150)">
        {birds.map((b, i) => (
          <g
            key={i}
            transform={`translate(${b.x} ${b.y}) scale(${b.s})`}
            style={{
              transformOrigin: "center",
              animation: `flap ${0.7 + i * 0.06}s ease-in-out infinite`,
            }}
          >
            <path
              d="M -16 0 C -8 -9, -3 -9, 0 -2 C 3 -9, 8 -9, 16 0"
              fill="none"
              stroke="#10231a"
              strokeWidth={3.4}
              strokeLinecap="round"
            />
          </g>
        ))}
      </g>
    </g>
  );
}

export default function MarshScene({ className = "" }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 1440 900"
      preserveAspectRatio="xMidYMid slice"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden
    >
      <defs>
        <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#0a1c17" />
          <stop offset="0.45" stopColor="#123029" />
          <stop offset="0.7" stopColor="#3a5a44" />
          <stop offset="0.86" stopColor="#b8763a" />
          <stop offset="1" stopColor="#e3a14a" />
        </linearGradient>
        <radialGradient id="sun" cx="0.5" cy="0.92" r="0.55">
          <stop offset="0" stopColor="#ffd28a" stopOpacity="0.95" />
          <stop offset="0.4" stopColor="#e89a3c" stopOpacity="0.5" />
          <stop offset="1" stopColor="#e89a3c" stopOpacity="0" />
        </radialGradient>
        <linearGradient id="water" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#c8843f" stopOpacity="0.55" />
          <stop offset="0.18" stopColor="#3a5a52" stopOpacity="0.6" />
          <stop offset="1" stopColor="#07140f" />
        </linearGradient>
        <linearGradient id="fog" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#cfe0d6" stopOpacity="0" />
          <stop offset="0.5" stopColor="#cfe0d6" stopOpacity="0.16" />
          <stop offset="1" stopColor="#cfe0d6" stopOpacity="0" />
        </linearGradient>
      </defs>

      {/* sky + rising sun */}
      <rect width="1440" height="640" fill="url(#sky)" />
      <ellipse cx="720" cy="600" rx="900" ry="320" fill="url(#sun)" />

      {/* distant tree line */}
      <path
        d="M0 560 q60 -34 120 -14 q40 -40 96 -20 q50 -44 120 -16 q70 -50 150 -10 q60 -36 140 -18 q70 -44 150 -10 q60 -34 140 -16 q80 -40 160 -8 q60 -30 114 -14 V640 H0 Z"
        fill="#0c1f18"
        opacity="0.92"
      />

      {/* drifting fog bands */}
      <g style={{ animation: "var(--animate-fog)" }}>
        <rect x="-100" y="470" width="1640" height="120" fill="url(#fog)" />
      </g>
      <g style={{ animation: "var(--animate-fog-slow)" }}>
        <rect x="-100" y="540" width="1640" height="150" fill="url(#fog)" />
      </g>

      <Flock />

      {/* water */}
      <rect y="600" width="1440" height="300" fill="url(#water)" />
      {/* sun reflection + ripples */}
      <g opacity="0.5">
        <path d="M620 660 H820" stroke="#ffd28a" strokeWidth="3" strokeLinecap="round" opacity="0.6" />
        <path d="M580 700 H860" stroke="#f4b860" strokeWidth="3" strokeLinecap="round" opacity="0.4" />
        <path d="M540 742 H900" stroke="#e89a3c" strokeWidth="3" strokeLinecap="round" opacity="0.3" />
      </g>
      <g opacity="0.4" stroke="#5cc6dd" strokeWidth="2" strokeLinecap="round">
        <path d="M120 720 H360" />
        <path d="M1020 700 H1280" />
        <path d="M200 778 H520" />
        <path d="M980 770 H1240" />
      </g>

      {/* foreground reeds */}
      <Reeds x={120} scale={1.15} delay={0} />
      <Reeds x={1320} scale={1.25} delay={1.2} />
      <Reeds x={1180} scale={0.95} delay={0.6} />
      <Reeds x={300} scale={0.8} delay={1.8} />
    </svg>
  );
}
