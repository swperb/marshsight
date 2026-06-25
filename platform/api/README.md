# Open Outdoors Platform API (Phase 1)

The hosted API for the open, free alternative to onX. It unifies free public
geodata behind one clean REST interface so any client (the MarshSight app, web
maps, other apps) can build on it without calling a dozen government services
directly. See [../../PLATFORM.md](../../PLATFORM.md) for the full vision.

No onX data, tiles, or endpoints are used. Every layer is sourced from its
original public publisher.

## Run

```sh
cd platform/api
npm install
npm run dev          # tsx watch, http://localhost:8088
# or
npm run build && npm start
```

Set `PORT` to change the port (default 8088).

## Endpoints

All take `lat`, `lon` (required) and `radiusKm` (optional).

| Endpoint | Returns | Default radius |
| --- | --- | --- |
| `GET /health` | service status | - |
| `GET /v1/gauges` | `{gauges:[{id,name,lat,lon,stageFeet,dischargeCfs,observedAt}]}` | 40 km |
| `GET /v1/rivers` | GeoJSON FeatureCollection (NHD flowlines) | 12 km |
| `GET /v1/lakes` | GeoJSON FeatureCollection (NHD waterbodies) | 12 km |
| `GET /v1/public-lands` | GeoJSON FeatureCollection (PAD-US, with `Pub_Access`) | 15 km |
| `GET /v1/region-pack` | all layers in one bundle, for offline caching | 12 km |

### Examples

```sh
# River stage near a NE Arkansas duck river
curl "http://localhost:8088/v1/gauges?lat=35.6&lon=-91.25&radiusKm=40"

# Bayou Meto WMA boundary (AR)
curl "http://localhost:8088/v1/public-lands?lat=34.45&lon=-91.55&radiusKm=15"

# Lake Guntersville (AL) shoreline for fishing
curl "http://localhost:8088/v1/lakes?lat=34.42&lon=-86.30&radiusKm=12"

# One offline bundle for a region
curl "http://localhost:8088/v1/region-pack?lat=34.45&lon=-91.55&radiusKm=12"
```

The `region-pack` is the offline bundle the app caches for no-signal areas; a
failed layer comes back empty with an `errors` note rather than failing the
whole pack.

## Data provenance

- **Gauges:** USGS NWIS Water Services (public domain).
- **Rivers / lakes:** USGS National Hydrography Dataset (public domain).
- **Public land:** USGS PAD-US via its public ArcGIS FeatureServer (public domain).

Responses are cached in-memory for 5 minutes to be a good citizen of these free
services.

## License

AGPL-3.0-or-later (server). Keeps hosted forks open, per the platform plan.
