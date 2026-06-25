# Contributing to MarshSight

MarshSight is a free, open-source AR navigation app for hunters and anglers, and
an open data platform. The goal is to give the outdoor community a tool it owns,
built on public data, instead of a closed subscription.

## Repository layout

- `MarshSight/` - the iOS app (SwiftUI + ARKit/RealityKit). MPL-2.0.
- `platform/api/` - the data + contribution platform API (Node + TypeScript).
  AGPL-3.0, so hosted forks stay open.
- `web/` - the marketing and waitlist site (Next.js).
- `PLATFORM.md` - the architecture and roadmap.
- `DATA_SOURCES.md` - data provenance and the rules that keep us legally clean.

## Ground rules

1. **Only public and properly licensed data.** Never add onX data, tiles, API
   responses, or screenshots, and never scrape another app's service. Every
   layer must come from its original public publisher. See `DATA_SOURCES.md`.
2. **Safety first.** This is a navigation aid, not an authority. Do not remove or
   weaken safety disclaimers, and do not overstate accuracy in copy or UI.
3. **Honey-hole privacy.** User contributions default to private. Never change a
   default to expose someone's spots without explicit opt-in.
4. **No AI-attribution trailers in commits.**

## How to contribute

1. Open an issue describing the change before large work, so we can agree on it.
2. Fork, branch, and keep pull requests focused.
3. Match the surrounding code style. The app is Swift; the API and site are
   TypeScript.
4. For the app: `xcodegen generate` then build in Xcode. For the API:
   `cd platform/api && npm install && npm run dev`. For the site:
   `cd web && npm install && npm run dev`.
5. Verify your change builds before opening the PR.

## What we especially want help with

- Additional public data layers (state WMA/GMU services, NOAA ENC charts,
  USFS MVUM roads, weather).
- The contribution backend (accounts, moderation, a real PostGIS store).
- ML models on the open data (waterfowl, deer, fish activity forecasts).
- Field testing and bug reports from real hunts and outings.

By contributing, you agree your code is licensed under the repository's license
(MPL-2.0 for the app, AGPL-3.0 for the server) and that contributed
map data may be published under an open data license (ODbL).
