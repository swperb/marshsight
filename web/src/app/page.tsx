const TESTFLIGHT_URL = "https://testflight.apple.com/join/rwCZwKBC";

const useCases = [
  {
    title: "Duck boats",
    headline: "Run murky water with confidence",
    body: "Pre-dawn runs through flooded timber and braided sloughs are unforgiving. MarshSight projects river channels, depth contours, and known hazards directly over your camera view so you can read water you cannot see.",
  },
  {
    title: "Deer hunters",
    headline: "Know exactly where the line is",
    body: "Public-land boundaries, terrain shading, and elevation are overlaid on the world in front of you. Glass a ridge and see the property line, drainages, and access points without looking down at a 2D map.",
  },
  {
    title: "Anglers",
    headline: "Read the lake and the river",
    body: "Lake structure, river flow, and live gauge data from USGS bring the water into focus. See where current is moving and where the channel runs before you ever make a cast.",
  },
];

const comparison = [
  {
    feature: "Price",
    ours: "Free, forever",
    note: "No subscription. The core app costs nothing to use.",
  },
  {
    feature: "Source and data",
    ours: "Open source, community data",
    note: "Code is public and the maps are built on open public datasets you can inspect and improve.",
  },
  {
    feature: "Primary view",
    ours: "AR-first, over your camera",
    note: "Boundaries and water are rendered onto the real world, not just a flat map.",
  },
];

export default function Home() {
  return (
    <div className="flex min-h-full flex-col bg-marsh-900 text-foreground">
      {/* Header */}
      <header className="sticky top-0 z-20 border-b border-marsh-800/80 bg-marsh-900/80 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-5 py-4">
          <span className="flex items-center gap-2 text-lg font-bold tracking-tight">
            <img src="/logo.png" alt="MarshSight logo" width={28} height={28} className="h-7 w-7 rounded-md" />
            MarshSight
          </span>
          <nav className="hidden items-center gap-7 text-sm text-foreground/70 sm:flex">
            <a href="#approach" className="transition hover:text-foreground">
              Our approach
            </a>
            <a href="#use-cases" className="transition hover:text-foreground">
              Use cases
            </a>
            <a href="#beta" className="transition hover:text-foreground">
              Beta
            </a>
          </nav>
          <a
            href={TESTFLIGHT_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-lg bg-moss-500 px-4 py-2 text-sm font-semibold text-marsh-950 transition hover:bg-moss-400"
          >
            Join the beta
          </a>
        </div>
      </header>

      <main className="flex-1">
        {/* Hero */}
        <section className="relative overflow-hidden">
          <div
            aria-hidden
            className="pointer-events-none absolute inset-0 bg-[radial-gradient(70%_60%_at_50%_0%,rgba(95,167,119,0.18),transparent_70%)]"
          />
          <div className="relative mx-auto max-w-6xl px-5 py-24 sm:py-32">
            <div className="mx-auto max-w-3xl text-center">
              <span className="inline-block rounded-full border border-marsh-700 bg-marsh-800/60 px-4 py-1.5 text-xs font-medium uppercase tracking-wide text-moss-400">
                Free and open source
              </span>
              <h1 className="mt-6 text-4xl font-bold leading-tight tracking-tight sm:text-6xl">
                Your hunt and your water, in augmented reality.
              </h1>
              <p className="mt-6 text-lg text-foreground/80 sm:text-xl">
                MarshSight overlays public-land boundaries, river channels, live
                water levels, and hazards onto your live camera view. The open
                alternative to closed, subscription mapping.
              </p>
              <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
                <a
                  href={TESTFLIGHT_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full rounded-xl bg-moss-500 px-7 py-3.5 text-center text-base font-semibold text-marsh-950 transition hover:bg-moss-400 sm:w-auto"
                >
                  Get the beta on TestFlight
                </a>
                <a
                  href="#approach"
                  className="w-full rounded-xl border border-marsh-700 px-7 py-3.5 text-center text-base font-semibold text-foreground/90 transition hover:border-moss-500 hover:text-foreground sm:w-auto"
                >
                  See our approach
                </a>
              </div>
            </div>
          </div>
        </section>

        {/* Approach / comparison */}
        <section
          id="approach"
          className="border-t border-marsh-800/80 bg-marsh-950/40"
        >
          <div className="mx-auto max-w-6xl px-5 py-20 sm:py-24">
            <div className="max-w-2xl">
              <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
                Why MarshSight
              </h2>
              <p className="mt-4 text-foreground/75">
                Most outdoor mapping apps, such as onX, are paid subscriptions
                built on closed data and a 2D map. MarshSight takes a different
                approach. Here is what that means for you.
              </p>
            </div>

            <div className="mt-12 grid gap-5 sm:grid-cols-3">
              {comparison.map((item) => (
                <div
                  key={item.feature}
                  className="rounded-2xl border border-marsh-700 bg-marsh-800/40 p-6"
                >
                  <p className="text-sm font-medium uppercase tracking-wide text-foreground/50">
                    {item.feature}
                  </p>
                  <p className="mt-2 text-xl font-semibold text-moss-400">
                    {item.ours}
                  </p>
                  <p className="mt-3 text-sm leading-relaxed text-foreground/70">
                    {item.note}
                  </p>
                </div>
              ))}
            </div>

            <p className="mt-6 text-xs text-foreground/40">
              Comparison reflects our own approach. MarshSight is an independent
              project and is not affiliated with or endorsed by onX.
            </p>
          </div>
        </section>

        {/* Use cases */}
        <section
          id="use-cases"
          className="border-t border-marsh-800/80"
        >
          <div className="mx-auto max-w-6xl px-5 py-20 sm:py-24">
            <div className="max-w-2xl">
              <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
                Built for the way you get out
              </h2>
              <p className="mt-4 text-foreground/75">
                One app, tuned for the realities of the marsh, the timber, and
                the water.
              </p>
            </div>

            <div className="mt-12 grid gap-6 md:grid-cols-3">
              {useCases.map((card) => (
                <article
                  key={card.title}
                  className="group rounded-2xl border border-marsh-700 bg-marsh-800/40 p-7 transition hover:border-moss-500/60"
                >
                  <span className="inline-block rounded-lg bg-marsh-700/60 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-water-400">
                    {card.title}
                  </span>
                  <h3 className="mt-4 text-xl font-semibold">
                    {card.headline}
                  </h3>
                  <p className="mt-3 text-sm leading-relaxed text-foreground/70">
                    {card.body}
                  </p>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* Beta */}
        <section id="beta" className="border-t border-marsh-800/80 bg-marsh-950/40">
          <div className="mx-auto max-w-3xl px-5 py-20 text-center sm:py-24">
            <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
              Join the beta
            </h2>
            <p className="mt-4 text-foreground/75">
              MarshSight is live in open beta on iOS through TestFlight. Install
              the TestFlight app, then tap below to get MarshSight on your iPhone.
            </p>
            <a
              href={TESTFLIGHT_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="mt-8 inline-block rounded-xl bg-moss-500 px-7 py-3.5 text-base font-semibold text-marsh-950 transition hover:bg-moss-400"
            >
              Get the beta on TestFlight
            </a>
            <p className="mt-4 text-sm text-foreground/55">
              Requires an iPhone and the free TestFlight app from Apple.
            </p>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-marsh-800/80 bg-marsh-950">
        <div className="mx-auto flex max-w-6xl flex-col gap-6 px-5 py-12 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <span className="flex items-center gap-2 text-base font-bold">
              <img src="/logo.png" alt="MarshSight logo" width={24} height={24} className="h-6 w-6 rounded-md" />
              MarshSight
            </span>
            <p className="mt-3 max-w-md text-sm leading-relaxed text-foreground/55">
              Open source. Built on public data (USGS, NOAA, PAD-US). Not
              affiliated with onX.
            </p>
          </div>
          <nav className="flex flex-wrap gap-x-6 gap-y-2 text-sm text-foreground/70">
            {/* TODO: point these at the real GitHub org/repo once published. */}
            <a
              href="https://github.com/swperb/marshsight"
              className="transition hover:text-foreground"
            >
              GitHub
            </a>
            <a
              href="https://github.com/swperb/marshsight"
              className="transition hover:text-foreground"
            >
              Source code
            </a>
            <a
              href="https://github.com/swperb/marshsight/issues"
              className="transition hover:text-foreground"
            >
              Report an issue
            </a>
          </nav>
        </div>
      </footer>
    </div>
  );
}
