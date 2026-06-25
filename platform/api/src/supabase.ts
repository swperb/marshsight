// Supabase (PostgREST) backend for contributions and the waitlist. Used when
// SUPABASE_URL and SUPABASE_SERVICE_KEY are set; otherwise the file store is
// used. No SDK dependency: this talks to PostgREST over fetch with the
// service-role key, and enforces honey-hole privacy in the query itself.

import type { Contribution } from "./store";

// Read env lazily so it works no matter the module load order relative to .env.
const urlBase = () => process.env.SUPABASE_URL;
const serviceKey = () => process.env.SUPABASE_SERVICE_KEY;

export function supabaseEnabled(): boolean {
  return Boolean(urlBase() && serviceKey());
}

function headers(extra: Record<string, string> = {}): Record<string, string> {
  return {
    apikey: serviceKey() as string,
    Authorization: `Bearer ${serviceKey()}`,
    "Content-Type": "application/json",
    ...extra,
  };
}

export async function addContribution(c: Contribution): Promise<void> {
  const res = await fetch(`${urlBase()}/rest/v1/contributions`, {
    method: "POST",
    headers: headers({ Prefer: "return=minimal" }),
    body: JSON.stringify({
      id: c.id, kind: c.kind, name: c.name, note: c.note ?? null,
      lat: c.lat, lon: c.lon, visibility: c.visibility, device_id: c.deviceId ?? null,
      created_at: c.createdAt,
    }),
    signal: AbortSignal.timeout(20000),
  });
  if (!res.ok) throw new Error(`supabase insert ${res.status}: ${await res.text()}`);
}

export async function nearbyContributions(
  lat: number, lon: number, radiusKm: number, deviceId?: string
): Promise<Contribution[]> {
  const dDeg = radiusKm / 111;
  const params = new URLSearchParams();
  params.set("select", "id,kind,name,note,lat,lon,visibility,device_id,created_at");
  params.append("lat", `gte.${lat - dDeg}`);
  params.append("lat", `lte.${lat + dDeg}`);
  params.append("lon", `gte.${lon - dDeg}`);
  params.append("lon", `lte.${lon + dDeg}`);
  // Public, OR the caller's own private/group rows. Honey-hole safe.
  const own = deviceId ? `,and(device_id.eq.${deviceId})` : "";
  params.set("or", `(visibility.eq.public${own})`);
  params.set("limit", "500");

  const res = await fetch(`${urlBase()}/rest/v1/contributions?${params}`, {
    headers: headers(), signal: AbortSignal.timeout(20000),
  });
  if (!res.ok) throw new Error(`supabase query ${res.status}`);
  const rows = (await res.json()) as any[];
  return rows.map((r) => ({
    id: r.id, kind: r.kind, name: r.name, note: r.note ?? undefined,
    lat: r.lat, lon: r.lon, visibility: r.visibility,
    createdAt: r.created_at, deviceId: r.device_id ?? undefined,
  }));
}

export async function addWaitlistEmail(email: string): Promise<void> {
  const res = await fetch(`${urlBase()}/rest/v1/waitlist`, {
    method: "POST",
    headers: headers({ Prefer: "resolution=ignore-duplicates,return=minimal" }),
    body: JSON.stringify({ email }),
    signal: AbortSignal.timeout(20000),
  });
  if (!res.ok && res.status !== 409) throw new Error(`supabase waitlist ${res.status}`);
}
