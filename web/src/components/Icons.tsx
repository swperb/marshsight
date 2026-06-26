// Lightweight line icons (stroke = currentColor) for the feature grid.
type P = { className?: string };
const base = {
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.6,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
};

function Svg({ className, children }: P & { children: React.ReactNode }) {
  return (
    <svg viewBox="0 0 24 24" className={className} {...base} aria-hidden>
      {children}
    </svg>
  );
}

export function IconAR({ className }: P) {
  return (
    <Svg className={className}>
      <path d="M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3" />
      <circle cx="12" cy="12" r="3.2" />
      <circle cx="12" cy="12" r="0.6" fill="currentColor" />
    </Svg>
  );
}

export function IconBoundary({ className }: P) {
  return (
    <Svg className={className}>
      <path d="M4 7l8-3 8 3-8 3-8-3Z" />
      <path d="M4 7v8l8 3 8-3V7" />
      <path d="M12 10v8" />
    </Svg>
  );
}

export function IconWater({ className }: P) {
  return (
    <Svg className={className}>
      <path d="M3 7c2.5 0 2.5 2 5 2s2.5-2 5-2 2.5 2 5 2" />
      <path d="M3 12c2.5 0 2.5 2 5 2s2.5-2 5-2 2.5 2 5 2" />
      <path d="M3 17c2.5 0 2.5 2 5 2s2.5-2 5-2 2.5 2 5 2" />
    </Svg>
  );
}

export function IconGauge({ className }: P) {
  return (
    <Svg className={className}>
      <path d="M4 19a8 8 0 1 1 16 0" />
      <path d="M12 14l4-4" />
      <circle cx="12" cy="14" r="1.2" fill="currentColor" stroke="none" />
    </Svg>
  );
}

export function IconTerrain({ className }: P) {
  return (
    <Svg className={className}>
      <path d="M3 19l5-8 3.2 4.6" />
      <path d="M10 19l4-6 7 6" />
      <path d="M13.5 13.5l1.6-2.4" />
    </Svg>
  );
}

export function IconOffline({ className }: P) {
  return (
    <Svg className={className}>
      <path d="M7 18a4 4 0 0 1-.5-7.97 5.5 5.5 0 0 1 10.6-1.02A3.75 3.75 0 0 1 18 17" />
      <path d="M12 11v6m0 0l-2.5-2.5M12 17l2.5-2.5" />
    </Svg>
  );
}

export function IconWind({ className }: P) {
  return (
    <Svg className={className}>
      <path d="M3 8h10a2.5 2.5 0 1 0-2.5-2.5" />
      <path d="M3 12h14a2.5 2.5 0 1 1-2.5 2.5" />
      <path d="M3 16h7a2 2 0 1 1-2 2" />
    </Svg>
  );
}

export function IconLock({ className }: P) {
  return (
    <Svg className={className}>
      <rect x="5" y="11" width="14" height="9" rx="2" />
      <path d="M8 11V8a4 4 0 0 1 8 0v3" />
      <circle cx="12" cy="15.5" r="1" fill="currentColor" stroke="none" />
    </Svg>
  );
}
