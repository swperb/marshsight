// PAD-US (USGS Protected Areas Database) public-land boundaries via the public
// ArcGIS FeatureServer. GeoJSON in WGS84. Properties: Unit_Nm (name),
// Mang_Name (manager code), Pub_Access (OA open / RA restricted / XA closed).

import { BBox, envelope } from "../geo";
import { fetchJSON } from "../cache";

const ENDPOINT =
  "https://services.arcgis.com/v01gqwM5QqNysAAi/arcgis/rest/services/Manager_Name/FeatureServer/0/query";

type GeoJSON = { type: "FeatureCollection"; features: any[] };

export async function fetchPublicLands(box: BBox, maxRecords = 40): Promise<GeoJSON> {
  const url =
    `${ENDPOINT}?where=1=1` +
    `&geometry=${encodeURIComponent(envelope(box))}` +
    `&geometryType=esriGeometryEnvelope&inSR=4326` +
    `&spatialRel=esriSpatialRelIntersects` +
    `&outFields=${encodeURIComponent("OBJECTID,Unit_Nm,Mang_Name,Pub_Access")}` +
    `&returnGeometry=true&resultRecordCount=${maxRecords}&f=geojson`;
  const data = await fetchJSON(url);
  return { type: "FeatureCollection", features: data?.features ?? [] };
}
