import { existsSync } from "node:fs";
import { join } from "node:path";
import Device from "@/components/Device";
import {
  IconAR,
  IconBoundary,
  IconWater,
  IconGauge,
  IconTerrain,
  IconWind,
  IconOffline,
  IconLock,
} from "@/components/Icons";

const TESTFLIGHT_URL = "https://testflight.apple.com/join/rwCZwKBC";
const GITHUB_URL = "https://github.com/swperb/marshsight";

// The real AR-over-camera screenshot is shot on-device later. Drop it at
// web/public/screens/ar.png (or .jpg) and this row appears automatically.
function arScreenshot(): string | null {
  for (const name of ["ar.png", "ar.jpg", "ar.jpeg"]) {
    if (existsSync(join(process.cwd(), "public", "screens", name))) {
      return `/screens/${name}`;
    }
  }
  return null;
}

function LogoMark({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 48 48" className={className} aria-hidden fill="none">
      <rect x="1" y="1" width="46" height="46" rx="11" fill="#161d22" />
      <path d="M24 9 L33.5 14.5 L33.5 25.5 L24 31 L14.5 25.5 L14.5 14.5 Z" fill="none" stroke="#f2efe6" strokeWidth="2.2" strokeLinejoin="round" />
      <path d="M24 20 L24 9 M24 20 L14.5 25.5 M24 20 L33.5 25.5" stroke="#f2efe6" strokeWidth="2.2" strokeLinecap="round" />
      <circle cx="24" cy="20" r="2.3" fill="#5cc6dd" />
      <path d="M14 38 C 18 36.5, 23 39.5, 27 38 C 30 37, 32.5 38.5, 34 37.8" fill="none" stroke="#5cc6dd" strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  );
}

const features = [
  { Icon: IconBoundary, title: "Public-land boundaries", body: "Open, restricted, and closed land color-coded from PAD-US, BLM, and state GIS — plus hunting units for 47 states and private parcels with owner names where the state publishes them." },
  { Icon: IconWater, title: "Water, down to the creek", body: "Rivers, sloughs, lakes, and ponds from the USGS National Hydrography Dataset — the full network, not just the big blue lines." },
  { Icon: IconGauge, title: "Live river gauges", body: "Real-time stage and discharge from USGS water gauges, so you know what the water is doing before you launch in the dark." },
  { Icon: IconTerrain, title: "Terrain & slope shading", body: "USGS 3DEP elevation with live slope shading — read ridges, drainages, and benches before you set foot on them." },
  { Icon: IconWind, title: "Wind & scent cone", body: "Current wind from Open-Meteo drives a downwind scent cone on the map, with moon phase computed on device." },
  { Icon: IconOffline, title: "Built to go offline", body: "USGS National Map basemaps render through MapLibre and download into offline packs — public-domain tiles that keep working with no signal." },
  { Icon: IconAR, title: "Augmented reality", body: "Tap “Look Around in AR” to paint your route, boundaries, and hazards onto the live camera view, aligned to true north." },
  { Icon: IconLock, title: "Your spots stay yours", body: "Contributions are private by default and live on your device. No ads, no tracking, no selling your locations." },
];

const useCases = [
  { tag: "Duck boats", headline: "Run murky water before light", body: "Pre-dawn runs through flooded timber and braided sloughs are unforgiving. MarshSight projects channels, depth, and known hazards so you can read water you cannot see.", photo: "/photos/water-dock.jpg" },
  { tag: "Deer hunters", headline: "Know exactly where the line is", body: "Glass a ridge and see the property line, drainages, and access points — with the wind and your scent cone laid over the map.", photo: "/photos/timber-fog.jpg" },
  { tag: "Anglers", headline: "Read the lake and the river", body: "Lake structure, river flow, and live USGS gauge data bring the water into focus before you ever make a cast.", photo: "/photos/lake-still.jpg" },
];

const sources = ["USGS 3DEP", "USGS NHD", "USGS Water Data", "PAD-US", "NOAA ENC", "USFS Trails", "USFWS Refuges", "Open-Meteo"];

function PrimaryCTA({ className = "", children }: { className?: string; children: React.ReactNode }) {
  return (
    <a href={TESTFLIGHT_URL} target="_blank" rel="noopener noreferrer"
      className={`inline-flex items-center justify-center rounded-full bg-pine-700 px-7 py-3.5 text-base font-medium text-paper-50 transition hover:bg-pine-800 ${className}`}>
      {children}
    </a>
  );
}

export default function Home() {
  return (
    <div className="flex min-h-full flex-col bg-paper-100 text-ink-800">
      {/* Header */}
      <header className="sticky top-0 z-30 border-b border-line/80 bg-paper-100/85 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <a href="#top" className="flex items-center gap-2.5">
            <LogoMark className="h-9 w-9" />
            <span className="font-serif text-xl font-medium tracking-tight">MarshSight</span>
          </a>
          <nav className="hidden items-center gap-9 text-sm text-ink-600 md:flex">
            <a href="#app" className="transition hover:text-pine-700">The app</a>
            <a href="#features" className="transition hover:text-pine-700">Features</a>
            <a href="#field" className="transition hover:text-pine-700">In the field</a>
            <a href={GITHUB_URL} className="transition hover:text-pine-700">GitHub</a>
          </nav>
          <a href={TESTFLIGHT_URL} target="_blank" rel="noopener noreferrer"
            className="rounded-full border border-pine-700 px-4 py-2 text-sm font-medium text-pine-700 transition hover:bg-pine-700 hover:text-paper-50">
            Join the beta
          </a>
        </div>
      </header>

      <main id="top" className="flex-1">
        {/* Hero */}
        <section className="relative">
          <div className="mx-auto grid max-w-6xl items-center gap-12 px-6 py-16 sm:py-24 lg:grid-cols-[1.05fr_0.95fr]">
            <div>
              <p className="eyebrow text-clay-600">Free · Open source · iOS beta</p>
              <h1 className="mt-5 font-serif text-5xl font-medium leading-[1.05] tracking-tight text-ink-900 sm:text-6xl">
                A field map that knows the land and the water.
              </h1>
              <p className="mt-6 max-w-xl text-lg leading-relaxed text-ink-600">
                MarshSight maps public-land boundaries, the full water network, live
                river gauges, and terrain — then puts them in front of you in
                augmented reality. Built entirely on open government data.
              </p>
              <div className="mt-9 flex flex-col gap-3 sm:flex-row sm:items-center">
                <PrimaryCTA className="w-full sm:w-auto">Get the beta on TestFlight</PrimaryCTA>
                <a href="#app" className="inline-flex w-full items-center justify-center rounded-full border border-line px-7 py-3.5 text-base font-medium text-ink-800 transition hover:border-ink-400 sm:w-auto">
                  See the app
                </a>
              </div>
              <p className="mt-7 text-sm text-ink-500">
                Built on USGS · NOAA · PAD-US public data · No account required
              </p>
            </div>

            <div className="relative mx-auto w-full max-w-[300px] lg:max-w-[330px] lg:ml-auto">
              <Device src="/screens/map-topo.png" alt="MarshSight topographic map of public land and water near the White River" priority />
            </div>
          </div>
        </section>

        {/* Data sources */}
        <section className="border-y border-line/70 bg-paper-50">
          <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-center gap-x-7 gap-y-2 px-6 py-5">
            <span className="eyebrow text-ink-400">Sourced from</span>
            {sources.map((s) => (
              <span key={s} className="text-sm text-ink-500">{s}</span>
            ))}
          </div>
        </section>

        {/* App — alternating editorial rows */}
        <section id="app" className="mx-auto max-w-6xl px-6 py-20 sm:py-28">
          <div className="max-w-2xl">
            <p className="eyebrow text-clay-600">The app</p>
            <h2 className="mt-3 font-serif text-4xl font-medium tracking-tight text-ink-900 sm:text-5xl">
              Real data, drawn from the source.
            </h2>
            <p className="mt-4 text-lg text-ink-600">
              Every layer comes straight from a government publisher — no aggregator,
              no proprietary compilation. Here is what that looks like on the map.
            </p>
          </div>

          <div className="mt-16 space-y-20 sm:space-y-28">
            {arScreenshot() && (
              <Row
                eyebrow="Augmented reality"
                title="Look up, not down"
                body="Tap “Look Around in AR” to paint your route, boundaries, and hazards onto the live camera view — aligned to true north with GPS, compass, and the device IMU."
                screen={arScreenshot()!}
                alt="MarshSight augmented-reality view overlaying navigation onto the live camera"
              />
            )}
            <Row
              eyebrow="The map"
              title="Topo, satellite, and terrain — your choice"
              body="Switch between USGS imagery, topographic, and shaded-relief basemaps, all public-domain and cacheable. Land access, hunting units, water, and trails draw on top."
              screen="/screens/map-satellite.png"
              alt="MarshSight satellite-topo map with live weather and a river gauge readout"
            />
            <Row
              reverse
              eyebrow="Layers"
              title="Every layer, one open source"
              body="Toggle public land, hunting units, property lines, water, trails, slope angle, the wind scent cone, and weather radar — each pulled from its named USGS, NOAA, or USFS dataset."
              screen="/screens/layers.png"
              alt="MarshSight layer panel listing public land, hunting units, property lines, water, trails, slope, scent cone, and radar"
            />
            <Row
              eyebrow="On launch"
              title="Honest about what it is"
              body="A navigation aid, not a survey instrument — free, offline-capable, and built on public data with no subscription and no account. It tells you so the first time you open it."
              screen="/screens/features.png"
              alt="MarshSight onboarding screen listing what the app gives you"
            />
          </div>
        </section>

        {/* Features grid */}
        <section id="features" className="border-y border-line/70 bg-paper-50">
          <div className="mx-auto max-w-6xl px-6 py-20 sm:py-28">
            <div className="max-w-2xl">
              <p className="eyebrow text-clay-600">What's inside</p>
              <h2 className="mt-3 font-serif text-4xl font-medium tracking-tight text-ink-900 sm:text-5xl">
                Everything you need to read the ground.
              </h2>
            </div>
            <div className="mt-14 grid gap-x-10 gap-y-12 sm:grid-cols-2 lg:grid-cols-4">
              {features.map(({ Icon, title, body }) => (
                <div key={title}>
                  <Icon className="h-6 w-6 text-pine-600" />
                  <h3 className="mt-4 font-serif text-lg font-medium text-ink-900">{title}</h3>
                  <p className="mt-2 text-sm leading-relaxed text-ink-600">{body}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* In the field — use cases */}
        <section id="field" className="mx-auto max-w-6xl px-6 py-20 sm:py-28">
          <div className="max-w-2xl">
            <p className="eyebrow text-clay-600">In the field</p>
            <h2 className="mt-3 font-serif text-4xl font-medium tracking-tight text-ink-900 sm:text-5xl">
              Built for the way you hunt and fish.
            </h2>
          </div>
          <div className="mt-14 grid gap-8 lg:grid-cols-3">
            {useCases.map((card) => (
              <article key={card.tag} className="overflow-hidden rounded-2xl border border-line bg-paper-50">
                <div className="relative aspect-[16/10] overflow-hidden">
                  <img src={card.photo} alt="" className="h-full w-full object-cover" />
                </div>
                <div className="p-6">
                  <p className="eyebrow text-clay-600">{card.tag}</p>
                  <h3 className="mt-2 font-serif text-xl font-medium text-ink-900">{card.headline}</h3>
                  <p className="mt-3 text-sm leading-relaxed text-ink-600">{card.body}</p>
                </div>
              </article>
            ))}
          </div>
        </section>

        {/* Why open */}
        <section className="border-y border-line/70 bg-paper-50">
          <div className="mx-auto max-w-6xl px-6 py-20 sm:py-28">
            <div className="grid gap-12 lg:grid-cols-[0.9fr_1.1fr] lg:items-center">
              <div>
                <p className="eyebrow text-clay-600">Why open</p>
                <h2 className="mt-3 font-serif text-4xl font-medium tracking-tight text-ink-900 sm:text-5xl">
                  The open answer to closed mapping.
                </h2>
                <p className="mt-5 text-lg text-ink-600">
                  Most outdoor apps, like onX, are paid subscriptions on closed data
                  and a flat 2D map. MarshSight takes a different line.
                </p>
              </div>
              <dl className="divide-y divide-line border-y border-line">
                {[
                  ["Price", "Free, forever — no subscription, no paywalled layers."],
                  ["Source & data", "Open source, with every layer pulled from USGS, NOAA, PAD-US, and USFS."],
                  ["Primary view", "AR-first — boundaries and water rendered onto the real world, not just a flat map."],
                ].map(([k, v]) => (
                  <div key={k} className="grid grid-cols-[10rem_1fr] gap-4 py-5">
                    <dt className="font-serif text-base font-medium text-pine-700">{k}</dt>
                    <dd className="text-sm leading-relaxed text-ink-600">{v}</dd>
                  </div>
                ))}
              </dl>
            </div>
            <p className="mt-10 max-w-3xl text-xs leading-relaxed text-ink-400">
              Comparison reflects our own approach. MarshSight is an independent,
              community project and is not affiliated with, endorsed by, or derived
              from onX. It uses no onX data, tiles, or endpoints.
            </p>
          </div>
        </section>

        {/* Beta CTA */}
        <section className="relative overflow-hidden">
          <img src="/photos/marsh-dawn.jpg" alt="" aria-hidden className="absolute inset-0 h-full w-full object-cover" />
          <div aria-hidden className="absolute inset-0 bg-pine-800/80" />
          <div className="relative mx-auto max-w-2xl px-6 py-24 text-center sm:py-32">
            <h2 className="font-serif text-4xl font-medium tracking-tight text-paper-50 sm:text-5xl">
              Get out before the others wake up.
            </h2>
            <p className="mx-auto mt-5 max-w-xl text-lg text-paper-100/85">
              MarshSight is live in open beta on iOS through TestFlight. Install
              TestFlight, then tap below to put it on your iPhone.
            </p>
            <div className="mt-9 flex justify-center">
              <a href={TESTFLIGHT_URL} target="_blank" rel="noopener noreferrer"
                className="inline-flex items-center justify-center rounded-full bg-paper-50 px-7 py-3.5 text-base font-medium text-pine-800 transition hover:bg-white">
                Get the beta on TestFlight
              </a>
            </div>
            <p className="mt-4 text-sm text-paper-100/70">
              Requires an iPhone and the free TestFlight app from Apple.
            </p>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="bg-paper-100">
        <div className="mx-auto flex max-w-6xl flex-col gap-8 px-6 py-12 sm:flex-row sm:items-start sm:justify-between">
          <div className="max-w-sm">
            <span className="flex items-center gap-2.5">
              <LogoMark className="h-7 w-7" />
              <span className="font-serif text-lg font-medium">MarshSight</span>
            </span>
            <p className="mt-3 text-sm leading-relaxed text-ink-500">
              Free, open-source AR navigation for hunters and anglers. Built on public
              data from USGS, NOAA, PAD-US, and USFS. Not affiliated with onX.
            </p>
          </div>
          <nav className="flex flex-wrap gap-x-8 gap-y-2 text-sm text-ink-600">
            <a href={GITHUB_URL} className="transition hover:text-pine-700">GitHub</a>
            <a href={`${GITHUB_URL}/issues`} className="transition hover:text-pine-700">Report an issue</a>
            <a href="/privacy" className="transition hover:text-pine-700">Privacy</a>
            <a href={TESTFLIGHT_URL} target="_blank" rel="noopener noreferrer" className="transition hover:text-pine-700">TestFlight beta</a>
          </nav>
        </div>
        <div className="border-t border-line">
          <p className="mx-auto max-w-6xl px-6 py-5 text-xs text-ink-400">
            © {new Date().getFullYear()} MarshSight · A navigation aid, not a survey
            instrument — always carry a backup and check local regulations.
          </p>
        </div>
      </footer>
    </div>
  );
}

function Row({
  eyebrow,
  title,
  body,
  screen,
  alt,
  reverse = false,
}: {
  eyebrow: string;
  title: string;
  body: string;
  screen: string;
  alt: string;
  reverse?: boolean;
}) {
  return (
    <div className="grid items-center gap-10 lg:grid-cols-2 lg:gap-16">
      <div className={reverse ? "lg:order-2" : ""}>
        <p className="eyebrow text-clay-600">{eyebrow}</p>
        <h3 className="mt-3 font-serif text-2xl font-medium tracking-tight text-ink-900 sm:text-3xl">{title}</h3>
        <p className="mt-4 text-base leading-relaxed text-ink-600">{body}</p>
      </div>
      <div className={`mx-auto w-full max-w-[280px] ${reverse ? "lg:order-1" : ""}`}>
        <Device src={screen} alt={alt} />
      </div>
    </div>
  );
}
