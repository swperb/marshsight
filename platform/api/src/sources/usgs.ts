// USGS NWIS Water Services: live gauge height (00065) and discharge (00060).
// Public domain, keyless. https://waterservices.usgs.gov

import { BBox, envelope } from "../geo";
import { fetchJSON } from "../cache";

const NO_DATA = -999999;

export interface Gauge {
  id: string;
  name: string;
  lat: number;
  lon: number;
  stageFeet: number | null;
  dischargeCfs: number | null;
  observedAt: string | null;
}

export async function fetchGauges(box: BBox): Promise<Gauge[]> {
  const url =
    `https://waterservices.usgs.gov/nwis/iv/?format=json` +
    `&bBox=${envelope(box)}` +
    `&parameterCd=00065,00060&siteStatus=active`;

  const data = await fetchJSON(url);
  const series: any[] = data?.value?.timeSeries ?? [];
  const bySite = new Map<string, Gauge>();

  for (const ts of series) {
    const site = ts?.sourceInfo?.siteCode?.[0]?.value;
    if (!site) continue;
    const geo = ts?.sourceInfo?.geoLocation?.geogLocation ?? {};
    const param = ts?.variable?.variableCode?.[0]?.value;
    const point = ts?.values?.[0]?.value?.[0];
    const raw = point ? Number(point.value) : NaN;
    const value = Number.isFinite(raw) && raw !== NO_DATA ? raw : null;

    const existing =
      bySite.get(site) ??
      ({
        id: site,
        name: ts?.sourceInfo?.siteName ?? site,
        lat: Number(geo.latitude),
        lon: Number(geo.longitude),
        stageFeet: null,
        dischargeCfs: null,
        observedAt: null,
      } as Gauge);

    if (param === "00065") existing.stageFeet = value;
    if (param === "00060") existing.dischargeCfs = value;
    if (!existing.observedAt && point?.dateTime) existing.observedAt = point.dateTime;
    bySite.set(site, existing);
  }

  return [...bySite.values()]
    .filter((g) => g.stageFeet !== null || g.dischargeCfs !== null)
    .sort((a, b) => a.name.localeCompare(b.name));
}
