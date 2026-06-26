import MarshScene from "@/components/MarshScene";
import { PhoneFrame, ArScreen, MapScreen } from "@/components/Phone";
import {
  IconAR,
  IconBoundary,
  IconWater,
  IconGauge,
  IconTerrain,
  IconOffline,
  IconWind,
  IconLock,
} from "@/components/Icons";

const TESTFLIGHT_URL = "https://testflight.apple.com/join/rwCZwKBC";
const GITHUB_URL = "https://github.com/swperb/marshsight";

const features = [
  {
    Icon: IconAR,
    title: "AR over your camera",
    body: "Waypoints, boundaries, and hazards are drawn onto the live view in front of you — aligned to true north with GPS, compass, and the device IMU. Look up, not down.",
  },
  {
    Icon: IconBoundary,
    title: "Public-land boundaries",
    body: "Open, restricted, and closed land color-coded from PAD-US, BLM, and state GIS. Hunting units for 47 states, plus private parcels with owner names where the state publishes them.",
  },
  {
    Icon: IconWater,
    title: "Water, down to the creek",
    body: "Rivers, sloughs, lakes, and ponds from the USGS National Hydrography Dataset — the full network, not just the big blue lines.",
  },
  {
    Icon: IconGauge,
    title: "Live river gauges",
    body: "Real-time stage and discharge from USGS water gauges, so you know what the water is doing before you launch in the dark.",
  },
  {
    Icon: IconTerrain,
    title: "Terrain & slope shading",
    body: "USGS 3DEP elevation with live slope shading — read ridges, drainages, and benches before you ever set foot on them.",
  },
  {
    Icon: IconWind,
    title: "Wind & scent cone",
    body: "Current wind from Open-Meteo drives a downwind scent cone on the map, plus moon phase computed on device. Hunt the wind, not against it.",
  },
  {
    Icon: IconOffline,
    title: "Built to go offline",
    body: "USGS National Map basemaps render through MapLibre and download into offline packs — public-domain tiles that keep working with no signal.",
  },
  {
    Icon: IconLock,
    title: "Your spots stay yours",
    body: "Contributions are private by default and live on your device. No ads, no tracking, no selling your locations. Ever.",
  },
];

const useCases = [
  {
    tag: "Duck boats",
    headline: "Run murky water before light",
    body: "Pre-dawn runs through flooded timber and braided sloughs are unforgiving. MarshSight projects channels, depth, and known hazards over your camera so you can read water you cannot see.",
    photo: "/photos/water-dock.jpg",
    accent: "read the water",
  },
  {
    tag: "Deer hunters",
    headline: "Know exactly where the line is",
    body: "Glass a ridge and see the property line, drainages, and access points standing in the world in front of you — with the wind and your scent cone laid over the map.",
    photo: "/photos/timber-fog.jpg",
    accent: "hunt the wind",
  },
  {
    tag: "Anglers",
    headline: "Read the lake and the river",
    body: "Lake structure, river flow, and live USGS gauge data bring the water into focus. See where current is moving and where the channel runs before you ever make a cast.",
    photo: "/photos/lake-still.jpg",
    accent: "find the channel",
  },
];

const comparison = [
  {
    feature: "Price",
    ours: "Free, forever",
    note: "No subscription, no paywalled layers. The core app costs nothing to use.",
  },
  {
    feature: "Source & data",
    ours: "Open source, public data",
    note: "The code is public and every map layer is pulled straight from USGS, NOAA, PAD-US, and USFS — datasets you can inspect.",
  },
  {
    feature: "Primary view",
    ours: "AR-first, over your camera",
    note: "Boundaries and water are rendered onto the real world, not just a flat 2D map you stare down at.",
  },
];

const sources = [
  "USGS 3DEP",
  "USGS NHD",
  "USGS Water Data",
  "PAD-US",
  "NOAA ENC",
  "USFS Trails",
  "USFWS Refuges",
  "Open-Meteo",
];

function TestFlightButton({ className = "" }: { className?: string }) {
  return (
    <a
      href={TESTFLIGHT_URL}
      target="_blank"
      rel="noopener noreferrer"
      className={`inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-b from-amber-400 to-ember-600 px-7 py-3.5 text-base font-semibold text-marsh-950 shadow-lg shadow-ember-700/30 transition hover:from-amber-300 hover:to-amber-500 ${className}`}
    >
      Get the beta on TestFlight
    </a>
  );
}

export default function Home() {
  return (
    <div className="flex min-h-full flex-col bg-marsh-900 text-foreground">
      {/* Header */}
      <header className="sticky top-0 z-30 border-b border-marsh-700/60 bg-marsh-900/80 backdrop-blur-md">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-5 py-3.5">
          <a href="#top" className="flex items-center gap-2.5">
            <img
              src="/logo.png"
              alt="MarshSight logo"
              width={34}
              height={34}
              className="h-9 w-9 rounded-lg ring-1 ring-marsh-600/60"
            />
            <span className="font-slab text-xl font-bold tracking-tight">
              MarshSight
            </span>
          </a>
          <nav className="hidden items-center gap-8 text-sm text-foreground/70 md:flex">
            <a href="#features" className="transition hover:text-amber-400">
              Features
            </a>
            <a href="#app" className="transition hover:text-amber-400">
              The app
            </a>
            <a href="#why" className="transition hover:text-amber-400">
              Why open
            </a>
            <a href={GITHUB_URL} className="transition hover:text-amber-400">
              GitHub
            </a>
          </nav>
          <a
            href={TESTFLIGHT_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-lg bg-gradient-to-b from-amber-400 to-ember-600 px-4 py-2 text-sm font-semibold text-marsh-950 transition hover:from-amber-300 hover:to-amber-500"
          >
            Join the beta
          </a>
        </div>
      </header>

      <main id="top" className="flex-1">
        {/* Hero */}
        <section className="relative overflow-hidden">
          <MarshScene className="pointer-events-none absolute inset-0 h-full w-full opacity-90" />
          <div
            aria-hidden
            className="pointer-events-none absolute inset-0 bg-gradient-to-b from-marsh-900/70 via-marsh-900/40 to-marsh-900"
          />
          <div className="relative mx-auto grid max-w-6xl items-center gap-12 px-5 pb-24 pt-16 sm:pt-24 lg:grid-cols-[1.1fr_0.9fr] lg:pb-32">
            <div className="reveal">
              <span className="inline-flex items-center gap-2 rounded-full border border-amber-500/40 bg-marsh-950/60 px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.18em] text-amber-400 backdrop-blur">
                Free · Open source · iOS beta
              </span>
              <h1 className="mt-6 font-slab text-5xl font-bold leading-[1.04] tracking-tight sm:text-6xl lg:text-[4.4rem]">
                Find your line
                <span className="block font-hand text-4xl font-bold text-amber-400 sm:text-5xl">
                  before first light.
                </span>
              </h1>
              <p className="mt-6 max-w-xl text-lg leading-relaxed text-foreground/85">
                MarshSight overlays public-land boundaries, river channels, live
                water levels, and hazards onto your live camera view — built on
                open government data, not a closed subscription.
              </p>
              <div className="mt-9 flex flex-col gap-3 sm:flex-row sm:items-center">
                <TestFlightButton className="w-full sm:w-auto" />
                <a
                  href="#app"
                  className="inline-flex w-full items-center justify-center rounded-xl border border-marsh-600 bg-marsh-900/40 px-7 py-3.5 text-base font-semibold text-foreground/90 backdrop-blur transition hover:border-amber-500/60 hover:text-foreground sm:w-auto"
                >
                  See how it works
                </a>
              </div>
              <p className="mt-6 text-sm text-foreground/55">
                Built on USGS · NOAA · PAD-US public data · No account required
              </p>
            </div>

            <div className="reveal mx-auto w-full max-w-[300px] lg:ml-auto" style={{ animationDelay: "0.15s" }}>
              <PhoneFrame float>
                <ArScreen />
              </PhoneFrame>
            </div>
          </div>
        </section>

        {/* Data sources strip */}
        <section className="border-y border-marsh-700/50 bg-marsh-950/60">
          <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-center gap-x-8 gap-y-3 px-5 py-6 text-sm font-medium text-foreground/45">
            <span className="font-slab uppercase tracking-wider text-foreground/35">
              Built on public data
            </span>
            {sources.map((s) => (
              <span key={s} className="text-foreground/55">
                {s}
              </span>
            ))}
          </div>
        </section>

        {/* Features */}
        <section id="features" className="grain relative">
          <div className="mx-auto max-w-6xl px-5 py-20 sm:py-28">
            <div className="max-w-2xl">
              <p className="font-hand text-2xl text-amber-400">everything in one app</p>
              <h2 className="mt-1 font-slab text-3xl font-bold tracking-tight sm:text-5xl">
                The map, the water, and the line.
              </h2>
              <p className="mt-4 text-lg text-foreground/70">
                One open app, tuned for the realities of the marsh, the timber,
                and the river — and honest about where every layer comes from.
              </p>
            </div>

            <div className="mt-14 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {features.map(({ Icon, title, body }) => (
                <div
                  key={title}
                  className="group rounded-2xl border border-marsh-700/70 bg-marsh-850/60 p-6 transition hover:-translate-y-1 hover:border-amber-500/50 hover:bg-marsh-800/60"
                >
                  <span className="inline-flex h-11 w-11 items-center justify-center rounded-xl bg-marsh-700/60 text-amber-400 transition group-hover:bg-amber-500/15">
                    <Icon className="h-6 w-6" />
                  </span>
                  <h3 className="mt-4 font-slab text-lg font-semibold">{title}</h3>
                  <p className="mt-2 text-sm leading-relaxed text-foreground/65">
                    {body}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* App showcase */}
        <section
          id="app"
          className="relative overflow-hidden border-y border-marsh-700/50 bg-marsh-950/50"
        >
          <img
            src="/photos/marsh-dawn.jpg"
            alt=""
            aria-hidden
            className="pointer-events-none absolute inset-0 h-full w-full object-cover opacity-[0.12]"
          />
          <div
            aria-hidden
            className="pointer-events-none absolute inset-0 bg-gradient-to-b from-marsh-950 via-marsh-950/70 to-marsh-950"
          />
          <div className="relative mx-auto max-w-6xl px-5 py-20 sm:py-28">
            <div className="mx-auto max-w-2xl text-center">
              <p className="font-hand text-2xl text-amber-400">two views, one truth</p>
              <h2 className="mt-1 font-slab text-3xl font-bold tracking-tight sm:text-5xl">
                Heads-up in AR. Heads-down on the map.
              </h2>
              <p className="mt-4 text-lg text-foreground/70">
                The same boundaries, water, and gauges in both views — the 2D map
                stays the source of truth while the AR HUD puts it in front of
                you.
              </p>
            </div>

            <div className="mt-16 grid items-end gap-12 sm:grid-cols-2 sm:gap-8 lg:gap-16">
              <figure className="flex flex-col items-center">
                <PhoneFrame className="w-full max-w-[280px]">
                  <ArScreen />
                </PhoneFrame>
                <figcaption className="mt-6 max-w-xs text-center">
                  <span className="font-slab text-lg font-semibold text-amber-400">
                    Augmented reality
                  </span>
                  <p className="mt-1 text-sm text-foreground/65">
                    Steering arrow, hazard alerts, live river stage, and waypoint
                    billboards over the live camera.
                  </p>
                </figcaption>
              </figure>
              <figure className="flex flex-col items-center">
                <PhoneFrame className="w-full max-w-[280px]">
                  <MapScreen />
                </PhoneFrame>
                <figcaption className="mt-6 max-w-xs text-center">
                  <span className="font-slab text-lg font-semibold text-water-400">
                    The 2D map
                  </span>
                  <p className="mt-1 text-sm text-foreground/65">
                    Color-coded land access, hunting units, hydrography, your
                    track, and the route — on USGS basemaps.
                  </p>
                </figcaption>
              </figure>
            </div>
          </div>
        </section>

        {/* Use cases */}
        <section className="mx-auto max-w-6xl px-5 py-20 sm:py-28">
          <div className="max-w-2xl">
            <p className="font-hand text-2xl text-amber-400">however you get out</p>
            <h2 className="mt-1 font-slab text-3xl font-bold tracking-tight sm:text-5xl">
              Built for the way you hunt and fish.
            </h2>
          </div>
          <div className="mt-14 grid gap-6 lg:grid-cols-3">
            {useCases.map((card) => (
              <article
                key={card.tag}
                className="group overflow-hidden rounded-3xl border border-marsh-700/70 bg-marsh-850/60"
              >
                <div className="relative h-44 overflow-hidden">
                  <img
                    src={card.photo}
                    alt=""
                    className="h-full w-full object-cover transition duration-700 group-hover:scale-105"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-marsh-850 via-marsh-850/30 to-transparent" />
                  <span className="absolute left-4 top-4 rounded-lg bg-marsh-950/80 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-amber-400 backdrop-blur">
                    {card.tag}
                  </span>
                  <span className="absolute bottom-3 right-4 font-hand text-2xl text-water-300/90">
                    {card.accent}
                  </span>
                </div>
                <div className="p-6">
                  <h3 className="font-slab text-xl font-semibold">{card.headline}</h3>
                  <p className="mt-3 text-sm leading-relaxed text-foreground/70">
                    {card.body}
                  </p>
                </div>
              </article>
            ))}
          </div>
        </section>

        {/* Why open / comparison */}
        <section id="why" className="border-t border-marsh-700/50 bg-marsh-950/50">
          <div className="mx-auto max-w-6xl px-5 py-20 sm:py-28">
            <div className="max-w-2xl">
              <p className="font-hand text-2xl text-amber-400">why open</p>
              <h2 className="mt-1 font-slab text-3xl font-bold tracking-tight sm:text-5xl">
                The open answer to closed mapping.
              </h2>
              <p className="mt-4 text-lg text-foreground/70">
                Most outdoor mapping apps, like onX, are paid subscriptions built
                on closed data and a flat 2D map. MarshSight takes a different
                line — here is what that means for you.
              </p>
            </div>

            <div className="mt-12 grid gap-5 md:grid-cols-3">
              {comparison.map((item) => (
                <div
                  key={item.feature}
                  className="rounded-2xl border border-marsh-700/70 bg-marsh-850/60 p-7"
                >
                  <p className="text-xs font-semibold uppercase tracking-wider text-foreground/45">
                    {item.feature}
                  </p>
                  <p className="mt-2 font-slab text-2xl font-bold text-amber-400">
                    {item.ours}
                  </p>
                  <p className="mt-3 text-sm leading-relaxed text-foreground/65">
                    {item.note}
                  </p>
                </div>
              ))}
            </div>

            <p className="mt-6 max-w-3xl text-xs leading-relaxed text-foreground/40">
              Comparison reflects our own approach. MarshSight is an independent,
              community project and is not affiliated with, endorsed by, or
              derived from onX. It uses no onX data, tiles, or endpoints — every
              layer is sourced directly from its government publisher.
            </p>
          </div>
        </section>

        {/* Beta CTA */}
        <section id="beta" className="relative overflow-hidden">
          <MarshScene className="pointer-events-none absolute inset-0 h-full w-full opacity-60" />
          <div
            aria-hidden
            className="pointer-events-none absolute inset-0 bg-gradient-to-b from-marsh-900 via-marsh-900/85 to-marsh-900"
          />
          <div className="relative mx-auto max-w-2xl px-5 py-24 text-center sm:py-32">
            <h2 className="font-slab text-4xl font-bold tracking-tight sm:text-5xl">
              Get out before the others wake up.
            </h2>
            <p className="mx-auto mt-5 max-w-xl text-lg text-foreground/75">
              MarshSight is live in open beta on iOS through TestFlight. Install
              TestFlight, then tap below to put it on your iPhone.
            </p>
            <div className="mt-9 flex justify-center">
              <TestFlightButton />
            </div>
            <p className="mt-4 text-sm text-foreground/55">
              Requires an iPhone and the free TestFlight app from Apple.
            </p>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-marsh-700/50 bg-marsh-950">
        <div className="mx-auto flex max-w-6xl flex-col gap-8 px-5 py-12 sm:flex-row sm:items-start sm:justify-between">
          <div className="max-w-sm">
            <span className="flex items-center gap-2.5">
              <img
                src="/logo.png"
                alt="MarshSight logo"
                width={28}
                height={28}
                className="h-7 w-7 rounded-lg ring-1 ring-marsh-600/60"
              />
              <span className="font-slab text-lg font-bold">MarshSight</span>
            </span>
            <p className="mt-3 text-sm leading-relaxed text-foreground/55">
              Free, open-source AR navigation for hunters and anglers. Built on
              public data from USGS, NOAA, PAD-US, and USFS. Not affiliated with
              onX.
            </p>
          </div>
          <nav className="flex flex-wrap gap-x-8 gap-y-2 text-sm text-foreground/70">
            <a href={GITHUB_URL} className="transition hover:text-amber-400">
              GitHub
            </a>
            <a href={`${GITHUB_URL}/issues`} className="transition hover:text-amber-400">
              Report an issue
            </a>
            <a href="/privacy" className="transition hover:text-amber-400">
              Privacy
            </a>
            <a
              href={TESTFLIGHT_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="transition hover:text-amber-400"
            >
              TestFlight beta
            </a>
          </nav>
        </div>
        <div className="border-t border-marsh-800/60">
          <p className="mx-auto max-w-6xl px-5 py-5 text-xs text-foreground/35">
            © {new Date().getFullYear()} MarshSight · A navigation aid, not a
            survey instrument — always carry a backup and check local
            regulations.
          </p>
        </div>
      </footer>
    </div>
  );
}
