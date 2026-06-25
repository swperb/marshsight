# Data Sources and Provenance

This file documents where every map and navigation layer in MarshSight comes
from, its license, and how we obtain it. The purpose is twofold: to comply with
each source's license, and to demonstrate independent sourcing if the project is
ever challenged. MarshSight uses no onX data, endpoints, tiles, or screenshots.

## Principle

Every layer is pulled directly from its original publisher (a US government
agency or a vendor we hold a license with). We never seed our database from a
competitor's product, and we never access onX's service in any form.

## Layers

| Layer | Publisher | License / status | How we retrieve it |
| --- | --- | --- | --- |
| Nautical charts (markers, depths, soundings) | NOAA Office of Coast Survey (ENC / RNC) | US Government work, public domain | NOAA ENC Direct to GIS / chart downloads |
| Hydrography (rivers, lakes, flow lines) | USGS National Hydrography Dataset (NHD) | Public domain | USGS NHD download / The National Map |
| Elevation / terrain / bathymetry | USGS 3DEP | Public domain | USGS 3DEP services |
| River flow and gauge height | USGS Water Data / USACE | Public domain | USGS Water Services API |
| Public land boundaries | USGS PAD-US, BLM, state GIS | Public domain | PAD-US / agency open data portals |
| Private parcel boundaries + owner names | Free statewide state GIS (per state) | Public records / open state data | Direct ArcGIS REST query per state (AR/WA/NY/MT/VT verified) |
| Weather (wind, temp, pressure) | Open-Meteo | Free, CC-BY 4.0, no key | Direct API for the user's coordinate |
| Moon phase | Computed locally (synodic month) | n/a, no source | On-device calculation, no network |
| Base map rendering engine | MapLibre Native | BSD-3-Clause | Swift Package |
| Demo route data | Authored by us | Original, owned by project | `MarshSight/Data/sample_route.json` |

## Attribution obligations

- **NOAA, USGS, BLM, PAD-US:** US Government works. No attribution legally
  required, but we credit them in the app's About screen as good practice.
- **MapLibre Native:** BSD-3-Clause. Include the copyright notice in the app's
  acknowledgements.
- **Regrid (if/when integrated):** follow the attribution and display terms in
  our Regrid contract.
- **OpenStreetMap (only if added later):** ODbL requires attribution and
  share-alike on derived databases. Not currently used.

## Per-layer provenance

Following the handoff template. Every layer is independently sourced and was
NOT derived from onX, BaseMap, HuntStand, or any commercial product.

### Private parcels (statewide, free)
- **Source:** State GIS offices, per state. Verified: Arkansas (GeoStor),
  Washington, New York, Montana, Vermont.
- **License:** Public records / open state data, no key, no auth.
- **Processing:** ArcGIS REST bbox query, GeoJSON (WGS84), Douglas-Peucker
  simplified on device. Owner/parcel-id fields read generically.
- **Not derived from:** onX or any commercial parcel vendor.
- **Note:** There is no free NATIONAL parcel layer. Coverage is per state and
  grows one registry entry at a time. Alabama is county-only (no statewide).

### Weather
- **Source:** Open-Meteo (https://open-meteo.com).
- **License:** Free, CC-BY 4.0, no API key.
- **Processing:** Current conditions for the user's coordinate. Pressure
  converted hPa to inHg on device. Moon phase computed locally from the synodic
  month (no source, no network).
- **Not derived from:** any commercial product.

## Hard rules

1. Never scrape, cache, or reverse-engineer onX tiles, API responses, or
   screenshots.
2. Never call onX endpoints from the app or the data pipeline.
3. Pull each layer from its named publisher above, not from any aggregator that
   repackages a competitor's compilation.
4. Honor every paid license (Regrid) and keys are kept out of source control
   (see `.gitignore`).
