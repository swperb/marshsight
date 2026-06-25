# Open Outdoors Platform (working name)

The goal stated by the project owner: out-compete onX with a free, open-source
**data and development platform** built on publicly gathered data, with a large
ML ecosystem. MarshSight is the first client app. This document is the honest
blueprint: what it takes, what is hard, and the order to build it.

## The thesis

onX's moat is a proprietary, closed compilation of public records plus a closed
app. Almost every layer they sell is sourced from public data. The opening is to
do that compilation **in the open**, expose it through the developer API onX
refuses to offer, and let a community improve it. Three pillars:

1. **Open data** - normalized, hosted, versioned public-domain layers.
2. **Open platform** - a public API/SDK and vector tiles anyone can build on.
3. **Open intelligence** - ML models on that data, with open weights.

## The one genuine gap to be honest about

onX's hardest-to-replace layer is **nationwide parcel boundaries with owner
names**. That is the part that is not cleanly public; onX licenses it from
vendors (e.g. Regrid) and aggregates county records. Options, none free:
- License Regrid (paid, clean, fast).
- Aggregate county assessor data ourselves (cheap per county, enormous breadth
  of work, wildly inconsistent formats).
- Ship public-land excellence first and treat private-parcel owner data as a
  paid add-on layer.
Everything else (public land, hydro, terrain, charts, gauges, roads, imagery)
is genuinely public and free.

## Architecture

```
            Public sources                         Community
  USGS NWIS / NHD / 3DEP, NOAA ENC, PAD-US,   user waypoints, hazards,
  BLM, USFS MVUM, state WMA/GMU, NWS weather, observations, harvest/catch
  NAIP imagery, OSM, eBird/iNaturalist          reports, trail conditions
        |                                              |
        v                                              v
  +-------------------- Ingestion / ETL --------------------+
  |  scheduled pullers, normalizers, S-57 (ENC) parser,     |
  |  validation, provenance tagging                         |
  +---------------------------------------------------------+
        |                          |                    |
        v                          v                    v
   PostGIS (vector)        Object store (tiles,    Time-series store
   features, boundaries    rasters: 3DEP, NAIP)    (gauges, weather)
        |                          |                    |
        +-----------+--------------+--------------------+
                    v
        +------------------------------+
        |  Platform services           |
        |  - Vector tiles (MVT)        |
        |  - Feature/Boundary API      |
        |  - Live gauge/weather API    |
        |  - Contribution API + moderation
        |  - ML inference API          |
        +------------------------------+
                    |
        +-----------+-----------+-----------+
        v           v           v           v
   Swift SDK    JS SDK     Python SDK   Web client
        |
   MarshSight (duck/fish/hunt clients)
```

## Components

- **Ingestion / ETL.** Scheduled jobs per source. The app already speaks two of
  these directly ([USGSWaterService](MarshSight/Networking/USGSWaterService.swift),
  [NHDService](MarshSight/Networking/NHDService.swift)); the platform moves that
  server-side, caches it, and adds the rest. Hardest puller: NOAA ENC (S-57
  format) and nationwide imagery volume.
- **Storage.** PostGIS for vector; object storage for tiles and rasters;
  time-series DB for gauge/weather history (enables trends and ML features).
- **Platform services.** Vector tiles via Martin/Tegola; a REST + GraphQL API
  for features, boundaries, gauges; the contribution endpoint; the ML inference
  endpoint. This API is the product onX does not offer.
- **Contribution layer (the "publicly gathered data server").** Accounts,
  submission of waypoints/hazards/observations/harvest reports, moderation and
  abuse handling, all under an open data license so it stays free forever.
- **ML ecosystem.** Models trained on open + contributed data, open weights,
  reproducible training:
  - Waterfowl activity/abundance from weather fronts, water levels, eBird,
    historical harvest and season timing.
  - Deer movement/activity from moon phase, weather, barometric pressure,
    hunting pressure, rut timing.
  - Fish activity from water temp, flow, stage, barometric trend.
  Cold-start by training on existing public datasets, then improve with
  contributed observations (a data flywheel onX's closed model cannot match).
- **SDKs + clients.** Swift first (MarshSight consumes it), then JS and Python.

## Licensing

- Code: MPL-2.0 for the app and SDKs; AGPL-3.0 for server components so
  hosted forks stay open.
- Data: ODbL for the contributed/aggregated database (attribution + share-alike).
- Public-domain government layers are passed through with source credit.
- Never ingest onX data, tiles, or API responses. See
  [DATA_SOURCES.md](DATA_SOURCES.md).

## Hard problems (do not pretend these are free)

- Parcel owner data (the gap above).
- Hosting cost: nationwide imagery + tiles + 3DEP is real storage and bandwidth.
- ML labeled data cold-start; bootstrap from public datasets first.
- Safety/liability: navigation and hunting-access errors have real consequences;
  ship clear "aid, not authority" framing and keep the map authoritative.
- Moderation and abuse on contributed data.
- Funding an open platform sustainably (grants, optional paid tiers for the
  paid-license layers like parcels, hosted-API plans, donations).

## Roadmap

- **Phase 0 (done).** MarshSight client; live USGS gauge + NHD river layers
  consumed directly on device.
- **Phase 1.** Stand up the hosted data API (USGS + NHD + PAD-US public land);
  move the app to consume it; serve vector tiles; offline tile packs for a
  region (Arkansas duck country, Alabama lakes/land).
- **Phase 2.** Accounts + contribution layer + moderation; the public data
  server begins gathering.
- **Phase 3.** ML v1 forecasts (duck / deer / fish activity) on public data,
  served via the inference API and surfaced in the app.
- **Phase 4.** Multi-language SDKs, public docs, community and governance; paid
  add-on for licensed parcel data to fund the free core.

## Near-term concrete targets (owner's regions)

- **Arkansas rivers (duck):** USGS stage/discharge + NHD flowlines (live now),
  plus Arkansas Game and Fish WMA boundaries (Bayou Meto, Dave Donaldson Black
  River, etc.) and flooded-timber stage thresholds.
- **Alabama lakes (fish):** lake polygons (NHD), USGS lake gauges, public access
  ramps, water temp where available.
- **Alabama land (hunt):** PAD-US + state WMA/national forest boundaries, 3DEP
  terrain, and the parcel layer as the eventual paid add-on.
