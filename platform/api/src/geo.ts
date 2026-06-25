// Small geo helpers: build a bounding box from a center point and radius.

export interface BBox {
  west: number;
  south: number;
  east: number;
  north: number;
}

/** Approximate bounding box (WGS84) around a center point. */
export function bboxFrom(lat: number, lon: number, radiusKm: number): BBox {
  const metersPerDegLat = 111_320;
  const metersPerDegLon = 111_320 * Math.cos((lat * Math.PI) / 180);
  const dLat = (radiusKm * 1000) / metersPerDegLat;
  const dLon = (radiusKm * 1000) / Math.max(1, metersPerDegLon);
  return {
    west: lon - dLon,
    south: lat - dLat,
    east: lon + dLon,
    north: lat + dLat,
  };
}

/** ArcGIS envelope string: "west,south,east,north". */
export function envelope(b: BBox): string {
  return `${b.west.toFixed(5)},${b.south.toFixed(5)},${b.east.toFixed(5)},${b.north.toFixed(5)}`;
}

/** Parse and validate lat/lon/radiusKm query params. Throws on bad input. */
export function parseCenter(
  q: Record<string, unknown>,
  defaultRadiusKm: number
): { lat: number; lon: number; radiusKm: number } {
  const lat = Number(q.lat);
  const lon = Number(q.lon);
  const radiusKm = q.radiusKm !== undefined ? Number(q.radiusKm) : defaultRadiusKm;
  if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
    throw new BadRequest("lat is required and must be between -90 and 90");
  }
  if (!Number.isFinite(lon) || lon < -180 || lon > 180) {
    throw new BadRequest("lon is required and must be between -180 and 180");
  }
  if (!Number.isFinite(radiusKm) || radiusKm <= 0 || radiusKm > 200) {
    throw new BadRequest("radiusKm must be between 0 and 200");
  }
  return { lat, lon, radiusKm };
}

export class BadRequest extends Error {}
