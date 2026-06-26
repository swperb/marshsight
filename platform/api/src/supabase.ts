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
  params.set("select", "id,kind,name,note,lat,lon,visibility,device_id,created_at,upvotes,downvotes,status");
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
    upvotes: r.upvotes ?? 0, downvotes: r.downvotes ?? 0, status: r.status ?? "pending",
  }));
}

/// Upsert a vote, then recompute the contribution's tallies and status.
export async function vote(contributionId: string, deviceId: string, value: number): Promise<void> {
  const up = await fetch(`${urlBase()}/rest/v1/votes?on_conflict=contribution_id,device_id`, {
    method: "POST",
    headers: headers({ Prefer: "resolution=merge-duplicates,return=minimal" }),
    body: JSON.stringify({ contribution_id: contributionId, device_id: deviceId, value }),
    signal: AbortSignal.timeout(20000),
  });
  if (!up.ok) throw new Error(`supabase vote ${up.status}: ${await up.text()}`);
  const rc = await fetch(`${urlBase()}/rest/v1/rpc/recompute_votes`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify({ cid: contributionId }),
    signal: AbortSignal.timeout(20000),
  });
  if (!rc.ok) throw new Error(`supabase recompute ${rc.status}`);
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

// ---- Social feed (posts) ----

export interface FeedPost {
  id?: string;
  kind: string;
  note?: string;
  lat?: number | null;
  lon?: number | null;
  photoUrl?: string;
  tempF?: number;
  wind?: string;
  moon?: string;
  author?: string;
  deviceId?: string;
  upvotes?: number;
  createdAt?: string;
}

export async function addPost(p: FeedPost): Promise<void> {
  const res = await fetch(`${urlBase()}/rest/v1/posts`, {
    method: "POST",
    headers: headers({ Prefer: "return=minimal" }),
    body: JSON.stringify({
      kind: p.kind, note: p.note ?? null,
      lat: p.lat ?? null, lon: p.lon ?? null, photo_url: p.photoUrl ?? null,
      temp_f: p.tempF ?? null, wind: p.wind ?? null, moon: p.moon ?? null,
      author: p.author ?? null, device_id: p.deviceId ?? null,
    }),
    signal: AbortSignal.timeout(20000),
  });
  if (!res.ok) throw new Error(`supabase post insert ${res.status}: ${await res.text()}`);
}

export async function recentPosts(limit = 100): Promise<FeedPost[]> {
  const params = new URLSearchParams();
  params.set("select", "id,kind,note,lat,lon,photo_url,temp_f,wind,moon,author,upvotes,created_at");
  params.set("order", "created_at.desc");
  params.set("limit", String(limit));
  const res = await fetch(`${urlBase()}/rest/v1/posts?${params}`, {
    headers: headers(), signal: AbortSignal.timeout(20000),
  });
  if (!res.ok) throw new Error(`supabase feed ${res.status}`);
  const rows = (await res.json()) as any[];
  return rows.map((r) => ({
    id: r.id, kind: r.kind, note: r.note ?? undefined,
    lat: r.lat ?? undefined, lon: r.lon ?? undefined, photoUrl: r.photo_url ?? undefined,
    tempF: r.temp_f ?? undefined, wind: r.wind ?? undefined, moon: r.moon ?? undefined,
    author: r.author ?? undefined, upvotes: r.upvotes ?? 0, createdAt: r.created_at,
  }));
}

// ---- Trail-camera ingest ----

export async function addCameraPhoto(
  camCode: string, photoUrl: string,
  cameraName?: string, takenAt?: string, lat?: number, lon?: number
): Promise<void> {
  const res = await fetch(`${urlBase()}/rest/v1/camera_photos`, {
    method: "POST",
    headers: headers({ Prefer: "return=minimal" }),
    body: JSON.stringify({
      cam_code: camCode, photo_url: photoUrl, camera_name: cameraName ?? null,
      taken_at: takenAt ?? null, lat: lat ?? null, lon: lon ?? null,
    }),
    signal: AbortSignal.timeout(20000),
  });
  if (!res.ok) throw new Error(`supabase camera insert ${res.status}: ${await res.text()}`);
}

export async function cameraPhotos(camCode: string, limit = 200): Promise<any[]> {
  const params = new URLSearchParams();
  params.set("select", "id,cam_code,photo_url,camera_name,taken_at,lat,lon,created_at");
  params.set("cam_code", `eq.${camCode}`);
  params.set("order", "created_at.desc");
  params.set("limit", String(limit));
  const res = await fetch(`${urlBase()}/rest/v1/camera_photos?${params}`, {
    headers: headers(), signal: AbortSignal.timeout(20000),
  });
  if (!res.ok) throw new Error(`supabase camera query ${res.status}`);
  return (await res.json()) as any[];
}

// Upload image bytes to the public storage bucket; returns the public URL (or
// undefined on failure, so a post still saves without the photo).
export async function uploadPhoto(bytes: Uint8Array, contentType: string, path: string): Promise<string | undefined> {
  const bucket = process.env.STORAGE_BUCKET || "media";
  const res = await fetch(`${urlBase()}/storage/v1/object/${bucket}/${path}`, {
    method: "POST",
    headers: {
      apikey: serviceKey() as string,
      Authorization: `Bearer ${serviceKey()}`,
      "Content-Type": contentType,
      "x-upsert": "true",
    },
    body: bytes as unknown as BodyInit,
    signal: AbortSignal.timeout(25000),
  });
  if (!res.ok) return undefined;
  return `${urlBase()}/storage/v1/object/public/${bucket}/${path}`;
}
