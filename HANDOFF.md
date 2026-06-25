# Outdoor Navigation App — Claude Code Handoff

## Project overview

Build a FOSS outdoor navigation app for hunters, anglers, and public land users — inspired by onX Hunt but built entirely on public-domain data and open-source tooling. The app is free, open-source (MIT or GPL), and privacy-first. No paywalled features, no locked data, no subscription required for core functionality.

> **Legal north star:** Every data source, algorithm, and UI pattern must be independently derived. Nothing scraped, mirrored, or reverse-engineered from onX or any competitor. Document the provenance of every data layer.

---

## ⚠️ DMCA & legal risk management

This section is the most important part of this document. Read it before writing a single line of code.

### What onX can legitimately sue over

| Risk | Details |
|---|---|
| Parcel data scraping | Do NOT scrape onX's property boundary display, even via screenshot or automated requests. Their aggregated parcel dataset is a protectable compilation even though the underlying county records are public. |
| UI copying | Do not clone their UI layout, color scheme, icon system, or interaction patterns closely enough to constitute trade dress infringement. Take functional inspiration, not visual copying. |
| ToS violation | If any developer on this project has an onX account, they must not reverse-engineer, inspect network traffic, or reproduce any data from their app. Tainted knowledge taints the codebase. |
| Database copyright | Even public-domain underlying records can form a copyrightable database if onX's selection, arrangement, or enhancement is copied. Always build parcel pipelines from raw county sources, never from onX's output. |
| Mountain Project precedent | onX filed a DMCA against competitor Open Beta after acquiring Mountain Project. They have demonstrated willingness to use legal tools aggressively against FOSS competitors. Take this seriously. |

### What they cannot touch

- Any data downloaded directly from government sources (BLM, USGS, USDA, USFS, NPS, state wildlife agencies).
- Functional features that are industry-standard GIS capabilities (waypoints, track recording, offline maps, area measurement).
- Open-source libraries and their standard usage.
- Independently derived ML models trained on your own crowdsourced or public data.
- General app concepts — you cannot copyright "show property boundaries on a map."

### Required documentation practices

Every data layer in the app must have a corresponding entry in `DATA_SOURCES.md` (see template below) with:
- Source agency / URL
- Download date
- License / public domain status
- Any transformations applied (GDAL commands, projections, etc.)
- Explicit statement that it was NOT derived from any commercial product

Run a legal review before shipping parcel data in any form. Consider having an attorney review the data pipeline for the first release.

---

## Tech stack

### Mobile (primary)
- **SwiftUI + Swift** — iOS/iPadOS first. Target iOS 17+.
- **MapLibre GL Native (iOS)** — open-source map rendering. Drop-in replacement for Mapbox GL Native without the licensing restrictions.
- **Core Location** — GPS, compass, altitude.
- **ARKit + RealityKit** — AR camera overlay (primary differentiator vs. onX).
- **Core ML + Create ML** — on-device ML for animal movement patterns.
- **Combine / async-await** — reactive data layer.
- **SQLite (via GRDB.swift)** — local data persistence, offline map tile cache.
- **PMTiles** — single-file tile archive format for offline map bundles.

### Backend (minimal — privacy-first means minimal server)
- **Supabase (self-hostable)** — optional cloud sync for waypoints/tracks. Users can self-host or use the official instance.
- **PostGIS** — spatial queries for parcel and boundary lookups.
- **FastAPI (Python)** — lightweight tile server and data API.
- **GDAL / GeoPandas** — data processing pipeline.
- **Apache Sedona** — large-scale spatial processing for parcel aggregation.

### Data pipeline
- **GDAL/OGR** — format conversion, projection, clipping.
- **Tippecanoe** — generate vector tiles from GeoJSON/shapefiles.
- **go-pmtiles** — bundle tiles into PMTiles archives for distribution.
- **rio-cogeo** — Cloud-Optimized GeoTIFF for raster layers.

### Web (companion / e-scouting)
- **SvelteKit** — lightweight web companion for desktop e-scouting.
- **MapLibre GL JS** — same rendering engine as mobile.
- **Turf.js** — client-side geospatial analysis (distance, area, viewshed approximation).

---

## Feature build order

Build in this order. Each phase ships something usable.

### Phase 1 — core map (MVP)

**Goal:** A working offline map app with public land boundaries. Ship this.

- [ ] MapLibre GL Native integration with SwiftUI
- [ ] Basemap switcher: Satellite (Sentinel-2/NAIP), Topo (USGS 3DEP contours), Hybrid
- [ ] 3D terrain view (MapLibre terrain3D + USGS 3DEP DEM tiles)
- [ ] Offline map download (PMTiles bundles by county or hunting unit)
- [ ] Core Location GPS dot + accuracy ring
- [ ] Compass heading integration
- [ ] Public land boundary overlay (PAD-US dataset)
  - BLM, USFS, NPS, state land — color-coded by agency
- [ ] PLSS township/range grid (BLM GeoCommunicator data)
- [ ] Basic waypoint: drop, name, icon, save to SQLite
- [ ] GPS track recorder: start/stop, save as GPX

**Data sources for Phase 1:**
- PAD-US v4: https://www.usgs.gov/programs/gap-analysis-project/science/pad-us-data-download
- USGS 3DEP: https://www.usgs.gov/3d-elevation-program
- BLM PLSS: https://www.blm.gov/services/land-records
- Sentinel-2: https://browser.dataspace.copernicus.eu (Copernicus Open Access Hub)

---

### Phase 2 — hunting layers

**Goal:** Feature parity with onX Premium for public-land hunters.

- [ ] Hunting unit / GMU boundaries overlay (aggregate all 50 state shapefiles)
- [ ] State land boundaries (per-state GIS portals)
- [ ] Trails layer (OpenStreetMap + USFS MVUM)
- [ ] Campgrounds (Recreation.gov API)
- [ ] Roads layer (OSM / TIGER)
- [ ] Slope angle layer (derived from USGS 3DEP with GDAL `gdaldem slope`)
- [ ] Tree cover / NLCD land cover layer
- [ ] USDA Cropland Data Layer (CDL) — food source identification
- [ ] CWD zone overlay (USGS NWHC + state agency data)
- [ ] Historic wildfire perimeters (NIFC)
- [ ] Leaf-off imagery option (NAIP winter acquisitions)
- [ ] Weather overlay: wind direction/speed, temp, barometric pressure, moon phase
  - Use Open-Meteo API (free, no key required)
  - Use SunCalc for moon phase and rise/set times
- [ ] Optimal wind per waypoint (store preferred bearing, compare to forecast)
- [ ] Waypoint expansion: 50+ icon types (use SF Symbols or Maki icons — open license)
- [ ] Area shape tool (Turf.js polygon area)
- [ ] Line distance tool with elevation profile
- [ ] Markup sharing: export as GeoJSON or GPX

---

### Phase 3 — social & collaboration

**Goal:** Group hunting features. No server required for core; optional server for sync.

- [ ] Live group location sharing (peer-to-peer via MultipeerConnectivity for local, WebSocket for remote)
- [ ] Collaborative folders: shared waypoints/tracks via GeoJSON sync
- [ ] Deep-link waypoint sharing (encoded in URL)
- [ ] GPX/GeoJSON import from other apps
- [ ] Desktop companion (SvelteKit) for e-scouting — syncs with mobile via Supabase

---

### Phase 4 — AR camera overlay (primary differentiator)

**Goal:** Live property boundary and waypoint overlay in iPhone camera view. onX does not have this.

**This is the key feature gap vs. onX. Build it carefully.**

- [ ] ARKit session with world tracking
- [ ] Anchor property boundary polylines to real-world coordinates using:
  - GPS position (Core Location)
  - Compass bearing (CLHeading)
  - Device pitch/roll (CMMotionManager)
  - Terrain DEM for horizon registration
- [ ] Render public land boundary edges as AR overlays in camera view
- [ ] Render waypoints as floating AR pins with distance labels
- [ ] Trespass warning: highlight when camera points toward private land boundary
- [ ] Terrain occlusion: use iPhone LiDAR (Pro models) to hide overlays behind real terrain features
- [ ] Distance-adaptive label sizing (labels shrink at distance, expand nearby)
- [ ] AR calibration flow for GPS drift compensation
- [ ] Fallback for non-LiDAR iPhones (no occlusion, but boundaries still render)

**Known hard problems in AR geo-registration:**
- GPS accuracy degrades in canyons and under canopy. Implement Kalman filter on location stream.
- At distances >500m, small compass errors cause large positional errors in AR overlay. Add manual calibration gesture.
- DEM resolution (10m from 3DEP) limits horizon accuracy. Interpolate between grid points.

---

### Phase 5 — ML & intelligence

**Goal:** On-device animal activity intelligence. No raw user data leaves the device.

**Architecture: federated learning**
- Train a local model on each user's GPS tracks, waypoints, and (optionally) trail cam images
- Only model weight deltas are uploaded to the aggregation server — never raw location data
- Differential privacy noise added before upload
- Server aggregates weights and pushes improved global model back

**Models to build:**

1. **Activity heatmap** — Kernel Density Estimation on anonymized, opt-in user GPS tracks. Shows where hunters have historically moved (pressure map). Geo-fuzz by ±250m before aggregation.

2. **Terrain feature classifier** — CNN on NAIP satellite tiles to classify:
   - Oak flat / mast-producing forest
   - Open meadow / food source
   - Water features
   - Dense canopy / bedding
   - Topographic funnels / saddles
   - Use ResNet-18 or EfficientNet-B0 backbone via Core ML

3. **Animal movement forecast** — predict likely activity windows using:
   - Temperature (Open-Meteo)
   - Wind speed/direction
   - Barometric pressure trend
   - Moon phase (SunCalc)
   - Day of season (rut calendar)
   - User's own GPS track timing (on-device only)
   - Start simple: rule-based model, evolve to gradient boosting (XGBoost via ONNX → Core ML)

4. **Trail cam photo classifier** (optional, user-initiated) — on-device CV model to tag photos:
   - Deer / no deer
   - Buck / doe / fawn
   - Time-of-day binning for movement charts
   - Use Apple's Vision framework (no model download required)
   - **Important:** All photo processing happens on-device. No images are ever uploaded.

---

### Phase 6 — research tools

**Goal:** Draw odds and tag research. Data is all public — just tedious to aggregate.

- [ ] Tag draw odds database (scrape/download all 50 state wildlife agency portals — document each source URL)
- [ ] Harvest statistics by GMU and species
- [ ] Application deadline calendar with push notification reminders
- [ ] Tag opportunity finder: filter by species, state, residency, point requirements
- [ ] Cell coverage layer (FCC National Broadband Map — free)

---

## Data source registry template

Create `DATA_SOURCES.md` in the repo root. Add an entry for every layer before it ships.

```markdown
## [Layer name]

- **Source:** [Agency name]
- **URL:** [Direct download URL]
- **Downloaded:** [YYYY-MM-DD]
- **License:** Public Domain / CC0 / [specific license]
- **Format:** Shapefile / GeoJSON / GeoTIFF / etc.
- **Projection:** EPSG:[code]
- **Processing:** [GDAL commands or pipeline description]
- **Not derived from:** onX, BaseMap, HuntStand, or any commercial product
- **Notes:** [Anything else relevant]
```

---

## Privacy architecture

This is a core value proposition, not an afterthought.

- **No account required** for any core feature. GPS, offline maps, waypoints, tracks — all fully local.
- **Optional sync account** for cloud backup and collaboration. Self-hostable Supabase backend.
- **No analytics SDKs** (no Firebase, no Amplitude, no Mixpanel) in the core app.
- **No ad SDKs** ever.
- **Federated ML only:** model weight deltas, never raw location data.
- **Differential privacy:** add calibrated Laplace noise to any aggregated location contributions before upload.
- **Geo-fuzzing:** any crowdsourced point contributions blurred by ±250m server-side before storage.
- **User data portability:** full export of all user data as GeoJSON/GPX at any time, one tap.
- **Data deletion:** account + all server-side data deleted within 24 hours of request.
- **No subpoena risk by design:** the server holds no precise user location history. There is nothing to produce.

The Wyoming corner-crossing case showed that onX data can be subpoenaed. Design the architecture so that even a court order directed at the server produces nothing useful.

---

## Open-source / FOSS strategy

- **License:** GPL-3.0 for the app, MIT for any standalone libraries or the data pipeline tooling
- **Data:** All processed public-domain datasets published to a public S3-compatible bucket (Cloudflare R2 or Backblaze B2) under CC0
- **Community parcel corrections:** build an OSM-style contribution flow where users can flag incorrect property boundaries. Corrections go through a review queue and are published back to the community.
- **Plugin API:** design a documented extension interface so the community can build species-specific modules (waterfowl migration layers, fish habitat overlays, etc.)
- **No contributor license agreement required** — keep it frictionless
- **Governance:** adopt an RFC process for major feature decisions

---

## Repository structure

```
/
├── ios/                    # SwiftUI app
│   ├── App/
│   ├── Features/
│   │   ├── Map/
│   │   ├── AR/             # Phase 4
│   │   ├── Waypoints/
│   │   ├── Tracks/
│   │   ├── Weather/
│   │   ├── Layers/
│   │   └── ML/             # Phase 5
│   ├── Data/
│   └── Resources/
├── web/                    # SvelteKit companion
├── backend/                # FastAPI + PostGIS
│   ├── api/
│   ├── tiles/              # Tile server
│   └── ml/                 # Federated learning aggregation
├── pipeline/               # Data processing
│   ├── scripts/            # GDAL, Python ETL
│   ├── pad_us/
│   ├── hunting_units/
│   ├── parcel/             # County pipeline — read legal notes
│   └── raster/             # DEM, NAIP, Sentinel-2 processing
├── DATA_SOURCES.md         # REQUIRED — provenance for every layer
├── LEGAL.md                # License, data rights, DMCA policy
└── CONTRIBUTING.md
```

---

## Known hard problems (flag for senior engineering review)

| Problem | Difficulty | Notes |
|---|---|---|
| Parcel aggregation (3,000 counties) | High | Each county uses different schemas, projections, and update cadences. Budget 6-12 months for 50-state coverage. Consider starting with 10 high-density hunting states. |
| AR geo-registration accuracy | High | GPS + compass errors compound at distance. Kalman filter + manual calibration + LiDAR depth are all necessary for Pro models. |
| Offline tile bundle size | Medium | A full state at useful zoom levels can exceed 2GB. Implement progressive download by region/GMU. |
| Federated learning cold start | Medium | Need ~1,000+ contributing users before ML models produce useful signal. Ship rule-based forecasting first. |
| CarPlay entitlement | Medium | Requires Apple approval for navigation entitlement. Apply early — approval takes weeks. |
| State hunting data normalization | Medium | 50 states, 50 different GIS formats and update schedules. Build a state adapter pattern. |
| Viewshed computation on-device | Medium | GDAL viewshed on 3DEP DEM is server-side today. For mobile, pre-compute viewshed tiles at 100m resolution or use a simplified ray-casting approximation. |

---

## What NOT to build (legal risk)

- Do not build a "import from onX" feature that reads their file exports and reproduces their data
- Do not integrate with any commercial parcel data provider's API without a written license that permits redistribution
- Do not use Bing Maps, Google Maps, or Apple Maps satellite tiles as basemaps — license restrictions prohibit offline caching
- Do not replicate onX's exact UI chrome, color palette, or icon system
- Do not build any feature that requires scraping a competitor's app or website

---

## Competitive positioning summary

| Dimension | onX Hunt | This app |
|---|---|---|
| Price | $35-100/yr | Free |
| Source | Proprietary | Open source (GPL-3) |
| Offline maps | Paywalled (LiDAR = Elite only) | All public layers free offline |
| Data export | Locked in | Open GeoJSON/GPX |
| Privacy | Subpoena risk (demonstrated) | No server-side location history |
| AR overlay | None | Core feature (Phase 4) |
| Parcel data | 161M properties, aggregated | Community-built, starts smaller |
| ML intelligence | Proprietary (100M+ trail cam images) | Federated, on-device, grows with users |
| Plugin ecosystem | None | Open plugin API |
