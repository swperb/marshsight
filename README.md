# MarshSight

An iPhone AR navigation aid for the outdoors. It overlays route waypoints,
channel markers, hazards, and public-access boundaries onto the live camera
view, driven by GPS, compass, and the device IMU. The first profile targets
**duck boats navigating murky water**; deer-hunter and fisherman profiles reuse
the same engine.

This is the open-data answer to onX-style mapping in augmented reality.

## Why this is not built on onX

onX has no public developer API or SDK. Their old API was shut down and they
have enforced against third parties reusing their data. Their GitHub org is only
forks of open mapping tools (Cesium, Mapbox GL, OpenStreetMap libraries), none
of which expose onX data. The only commercial path is "onX for Business", an
enterprise data license sold through sales, not a self-serve developer product.

So MarshSight rebuilds the same capability on open and public data:

| Layer | onX source | Open replacement used here |
| --- | --- | --- |
| Public / private land boundaries | proprietary Land Identity engine | PAD-US (USGS), BLM, state GIS; Regrid for parcels + owner names (paid) |
| Topo / terrain / bathymetry | proprietary | USGS 3DEP, NOAA bathymetry |
| Water charts (markers, depths) | licensed | NOAA ENC vector charts, RNC raster |
| Hydrography (rivers, water bodies) | proprietary | USGS NHD |
| River flow / stage | n/a | USGS water-data gauges, USACE |
| Base map rendering | Mapbox fork | MapKit now, MapLibre Native + offline tiles next |

## The hard part: AR without geo-anchors

Apple's `ARGeoTrackingConfiguration` (geo-anchors) only works in pre-mapped urban
areas. On open water, under forest canopy, and on rivers it does not function.
MarshSight instead runs `ARWorldTrackingConfiguration` with
`worldAlignment = .gravityAndHeading`, which aligns the AR world axes to true
geographic directions (east = +x, north = -z, up = +y). Every GPS coordinate is
then placed at a computed metric offset from the camera. See
[GeoMath.swift](MarshSight/Core/GeoMath.swift).

Accuracy is bounded by GPS and the magnetometer (roughly 3-10 m and a few
degrees of heading), so this is a navigation aid, not a survey instrument. The
2D map stays the source of truth and the HUD surfaces live GPS quality.

## Architecture

```
LocationProvider  ->  NavFix (GPS + true heading + speed + accuracy)
       |
NavigationEngine  ->  Guidance (active waypoint, distance, steering, hazards, return-to-launch)
       |
   +---+-----------------------------+
   |                                 |
ARNavView (RealityKit)         MiniMapView (MapKit)
  MarkerEntity billboards        route + breadcrumb + pins
       |
  HUDOverlay (steering arrow, speed, GPS quality, hazard alerts)
```

Key files:
- `Core/GeoMath.swift` - WGS84 to local ENU and AR-frame projection
- `Core/LocationProvider.swift` - CoreLocation fusion, breadcrumb track
- `Core/NavigationEngine.swift` - guidance derivation (testable, no UI)
- `AR/ARNavView.swift` + `AR/MarkerEntity.swift` - RealityKit overlay
- `Map/MiniMapView.swift` - synced 2D inset
- `UI/ContentView.swift` + `UI/HUDOverlay.swift` - app shell and HUD
- `Data/sample_route.json` - a demo marsh route to run against

## Build

Requires full Xcode (not just Command Line Tools).

```sh
brew install xcodegen          # already done if you set this up with Claude
xcodegen generate              # regenerate MarshSight.xcodeproj from project.yml
open MarshSight.xcodeproj
```

In Xcode: set your Signing Team on the MarshSight target, then run on a physical
iPhone. AR and the camera do not work in the Simulator, so the AR overlay needs a
real device; the Simulator is only useful for the map and HUD layout.

The Simulator can be used for a quick compile check:

```sh
xcodebuild -project MarshSight.xcodeproj -scheme MarshSight \
  -destination 'generic/platform=iOS Simulator' build
```

## Roadmap

1. Swap MapKit for MapLibre Native with cached offline NOAA chart tiles.
2. Real data ingest: NOAA ENC parser, USGS NHD, PAD-US access boundaries.
3. Profiles: deer-hunter (parcel boundaries, terrain, stands, wind) and
   fisherman (river path, access points, USGS flow gauges).
4. Heading stabilization: fuse compass with ARKit yaw drift, sea-state damping.
5. CarPlay / boat-display mirror and offline route packs.
