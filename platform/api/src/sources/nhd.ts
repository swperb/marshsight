// USGS National Hydrography Dataset (NHD) via ArcGIS REST. Rivers are flowlines
// (layer 6), lakes are waterbodies (layer 12). Requested as GeoJSON (WGS84).

import { BBox, envelope } from "../geo";
import { fetchJSON } from "../cache";

const BASE = "https://hydro.nationalmap.gov/arcgis/rest/services/nhd/MapServer";

type GeoJSON = { type: "FeatureCollection"; features: any[] };

async function queryLayer(
  layer: number,
  box: BBox,
  outFields: string,
  maxRecords: number
): Promise<GeoJSON> {
  const url =
    `${BASE}/${layer}/query?where=1=1` +
    `&geometry=${encodeURIComponent(envelope(box))}` +
    `&geometryType=esriGeometryEnvelope&inSR=4326` +
    `&spatialRel=esriSpatialRelIntersects` +
    `&outFields=${encodeURIComponent(outFields)}` +
    `&returnGeometry=true&resultRecordCount=${maxRecords}&f=geojson`;
  const data = await fetchJSON(url);
  return { type: "FeatureCollection", features: data?.features ?? [] };
}

/** River and stream centerlines. */
export function fetchRivers(box: BBox, maxRecords = 60): Promise<GeoJSON> {
  return queryLayer(6, box, "gnis_name", maxRecords);
}

/** Lake and reservoir polygons. */
export function fetchLakes(box: BBox, maxRecords = 30): Promise<GeoJSON> {
  return queryLayer(12, box, "gnis_name", maxRecords);
}
