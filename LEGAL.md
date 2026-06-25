# Legal, Licensing, and Data Rights

This is the legal posture for MarshSight. It is not legal advice; have an
attorney review the data pipeline before shipping parcel data in any release.

## Licensing

Current state of the repository:

- **iOS app:** MPL-2.0 (`LICENSE`).
- **Platform server:** AGPL-3.0 (`platform/api/LICENSE`), so hosted forks stay open.
- **Standalone pipeline tooling:** MIT (when added).
- **Aggregated / contributed map data:** intended for ODbL (open data).

> Why MPL-2.0 for the app rather than the handoff's GPL-3.0: GPL conflicts with
> App Store distribution (Apple's terms impose usage restrictions that clash with
> GPL's "no further restrictions" clause; GPL apps have been removed from the App
> Store over this). MPL-2.0 keeps file-level copyleft, so a competitor cannot
> take the core and close it, while remaining App Store compatible and easy to
> build on. AGPL on the server matches the handoff's intent that hosted forks
> stay open.

## Data rights

Every map layer is sourced from public-domain government data or free, openly
licensed sources, documented in `DATA_SOURCES.md` with source, license, and
processing. No layer is derived from onX or any commercial product.

The one layer that is not cleanly free at national scale is private-parcel data.
MarshSight uses free statewide state GIS where it exists (no national vendor
license), and there is no national parcel layer. We never aggregate parcels from
a competitor's output.

## Competitor and DMCA policy

These rules are binding on all contributors:

1. No onX (or competitor) data, tiles, API responses, or screenshots are ever
   ingested, cached, scraped, or reverse-engineered. Their aggregated dataset is
   a protectable compilation even though the underlying records are public.
2. No cloning of a competitor's UI layout, color scheme, icon system, or
   interaction patterns (trade dress).
3. Parcel pipelines are built only from raw government sources, never from any
   commercial product's output.
4. Contributors with a competitor account must not inspect its network traffic
   or reproduce any of its data. Tainted knowledge taints the codebase.
5. No "import from a competitor" feature that reproduces their data.

onX has used DMCA aggressively against FOSS competitors (the Open Beta / Mountain
Project matter). These rules exist so there is nothing legitimate to challenge.

## Privacy by design

- No account is required for any core feature; GPS, maps, waypoints, and reports
  work fully on device.
- Contributions default to private and never leave the device unless the user
  explicitly shares them (honey-hole protection).
- No advertising or third-party analytics SDKs in the app.
- The server holds no precise user location history by design, so a subpoena to
  the server produces nothing useful.
