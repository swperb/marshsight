// Open Outdoors Platform API (Phase 1).
// Unifies free public geodata behind one REST interface. No onX data is used.

// Load platform/api/.env if present (Node 20.6+). No dependency needed.
try { (process as any).loadEnvFile?.(); } catch { /* no .env, use the file store */ }

import express, { Request, Response, NextFunction } from "express";
import { bboxFrom, parseCenter, BadRequest } from "./geo";
import { cached, cacheKey } from "./cache";
import { fetchGauges } from "./sources/usgs";
import { fetchRivers, fetchLakes } from "./sources/nhd";
import { fetchPublicLands } from "./sources/padus";
import { addContribution, nearbyContributions, addWaitlistEmail, vote as castVote, Contribution } from "./store";
import { addPost, recentPosts, addCameraPhoto, cameraPhotos, uploadPhoto, reportContent, supabaseEnabled } from "./supabase";
import { randomUUID } from "node:crypto";

const app = express();
const PORT = Number(process.env.PORT ?? 8088);
const TTL = 5 * 60 * 1000; // 5 minutes
const startedAt = Date.now();

app.use(express.json({ limit: "8mb" }));

// CORS: allow any origin, GET/POST.
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.sendStatus(204);
  next();
});

app.get("/health", (_req, res) => {
  res.json({ status: "ok", version: "0.1.0", uptimeSeconds: Math.round((Date.now() - startedAt) / 1000) });
});

app.get("/v1/gauges", asyncRoute(async (req, res) => {
  const { lat, lon, radiusKm } = parseCenter(req.query, 40);
  const gauges = await cached(cacheKey("gauges", lat, lon, radiusKm), TTL, () =>
    fetchGauges(bboxFrom(lat, lon, radiusKm))
  );
  res.json({ center: { lat, lon }, radiusKm, gauges });
}));

app.get("/v1/rivers", asyncRoute(async (req, res) => {
  const { lat, lon, radiusKm } = parseCenter(req.query, 12);
  const fc = await cached(cacheKey("rivers", lat, lon, radiusKm), TTL, () =>
    fetchRivers(bboxFrom(lat, lon, radiusKm))
  );
  res.json(fc);
}));

app.get("/v1/lakes", asyncRoute(async (req, res) => {
  const { lat, lon, radiusKm } = parseCenter(req.query, 12);
  const fc = await cached(cacheKey("lakes", lat, lon, radiusKm), TTL, () =>
    fetchLakes(bboxFrom(lat, lon, radiusKm))
  );
  res.json(fc);
}));

app.get("/v1/public-lands", asyncRoute(async (req, res) => {
  const { lat, lon, radiusKm } = parseCenter(req.query, 15);
  const fc = await cached(cacheKey("lands", lat, lon, radiusKm), TTL, () =>
    fetchPublicLands(bboxFrom(lat, lon, radiusKm))
  );
  res.json(fc);
}));

// A single offline bundle. A failed layer becomes an empty result with an error
// noted, so the pack never 500s the whole region.
app.get("/v1/region-pack", asyncRoute(async (req, res) => {
  const { lat, lon, radiusKm } = parseCenter(req.query, 12);
  const box = bboxFrom(lat, lon, radiusKm);

  const [gauges, rivers, lakes, lands] = await Promise.allSettled([
    cached(cacheKey("gauges", lat, lon, radiusKm), TTL, () => fetchGauges(box)),
    cached(cacheKey("rivers", lat, lon, radiusKm), TTL, () => fetchRivers(box)),
    cached(cacheKey("lakes", lat, lon, radiusKm), TTL, () => fetchLakes(box)),
    cached(cacheKey("lands", lat, lon, radiusKm), TTL, () => fetchPublicLands(box)),
  ]);

  const errors: Record<string, string> = {};
  const unwrap = <T,>(r: PromiseSettledResult<T>, name: string, fallback: T): T => {
    if (r.status === "fulfilled") return r.value;
    errors[name] = (r.reason as Error)?.message ?? "failed";
    return fallback;
  };
  const empty = { type: "FeatureCollection" as const, features: [] as any[] };

  res.json({
    generatedAt: new Date().toISOString(),
    center: { lat, lon },
    radiusKm,
    gauges: unwrap(gauges, "gauges", []),
    rivers: unwrap(rivers, "rivers", empty),
    lakes: unwrap(lakes, "lakes", empty),
    publicLands: unwrap(lands, "publicLands", empty),
    errors: Object.keys(errors).length ? errors : undefined,
  });
}));

// --- Crowdsourced contributions (the public data flywheel) ---

const ALLOWED_KINDS = new Set([
  "hazard", "waypoint", "blind", "ramp", "harvest", "catch", "note",
]);

app.post("/v1/contributions", asyncRoute(async (req, res) => {
  const b = req.body ?? {};
  const lat = Number(b.lat), lon = Number(b.lon);
  if (!ALLOWED_KINDS.has(b.kind)) throw new BadRequest("invalid kind");
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) throw new BadRequest("lat/lon required");
  const visibility: Contribution["visibility"] =
    b.visibility === "public" || b.visibility === "group" ? b.visibility : "private";

  const contribution: Contribution = {
    id: randomUUID(),
    kind: b.kind,
    name: String(b.name ?? b.kind).slice(0, 120),
    note: b.note ? String(b.note).slice(0, 1000) : undefined,
    lat, lon, visibility,
    createdAt: new Date().toISOString(),
    deviceId: b.deviceId ? String(b.deviceId).slice(0, 64) : undefined,
  };
  await addContribution(contribution);
  res.status(201).json(contribution);
}));

app.get("/v1/contributions", asyncRoute(async (req, res) => {
  const { lat, lon, radiusKm } = parseCenter(req.query, 25);
  const deviceId = req.query.deviceId ? String(req.query.deviceId) : undefined;
  const items = await nearbyContributions(lat, lon, radiusKm, deviceId);
  res.json({ center: { lat, lon }, radiusKm, contributions: items });
}));

app.post("/v1/votes", asyncRoute(async (req, res) => {
  const b = req.body ?? {};
  const value = Number(b.value);
  if (!b.contributionId || !b.deviceId) throw new BadRequest("contributionId and deviceId required");
  if (![-1, 0, 1].includes(value)) throw new BadRequest("value must be -1, 0, or 1");
  await castVote(String(b.contributionId), String(b.deviceId), value);
  res.json({ ok: true });
}));

app.post("/v1/waitlist", asyncRoute(async (req, res) => {
  const email = String(req.body?.email ?? "").trim().toLowerCase();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw new BadRequest("valid email required");
  await addWaitlistEmail(email);
  res.status(201).json({ ok: true });
}));

// ---- Social feed (trophy room) ----

app.post("/v1/posts", asyncRoute(async (req, res) => {
  const b = req.body ?? {};
  if (!b.kind) throw new BadRequest("kind required");
  const num = (v: unknown) => (Number.isFinite(Number(v)) ? Number(v) : undefined);

  // Optional photo: accept a base64 image, upload to storage, keep the URL.
  let photoUrl: string | undefined = b.photoUrl ? String(b.photoUrl) : undefined;
  if (!photoUrl && b.photoBase64 && supabaseEnabled()) {
    const m = String(b.photoBase64).match(/^data:(image\/\w+);base64,(.*)$/s);
    const ct = m ? m[1] : "image/jpeg";
    const bytes = Buffer.from(m ? m[2] : String(b.photoBase64), "base64");
    const ext = (ct.split("/")[1] || "jpg").replace("jpeg", "jpg");
    photoUrl = await uploadPhoto(new Uint8Array(bytes), ct, `trophies/${randomUUID()}.${ext}`);
  }

  if (supabaseEnabled()) await addPost({
    kind: String(b.kind).slice(0, 24),
    note: b.note ? String(b.note).slice(0, 1000) : undefined,
    lat: num(b.lat), lon: num(b.lon),                 // omitted = location hidden
    photoUrl,
    tempF: num(b.tempF), wind: b.wind ? String(b.wind) : undefined,
    moon: b.moon ? String(b.moon) : undefined,
    author: b.author ? String(b.author).slice(0, 60) : undefined,
    deviceId: b.deviceId ? String(b.deviceId).slice(0, 64) : undefined,
  });
  res.status(201).json({ ok: true });
}));

app.get("/v1/feed", asyncRoute(async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 100, 200);
  const posts = supabaseEnabled() ? await recentPosts(limit) : [];
  res.json({ posts });
}));

// Report a feed post or community spot. Three distinct reporters auto-hide the
// content pending review (App Store Guideline 1.2: objectionable-content flow).
app.post("/v1/reports", asyncRoute(async (req, res) => {
  const b = req.body ?? {};
  const type = String(b.contentType ?? "");
  const id = String(b.contentId ?? "");
  if ((type !== "post" && type !== "contribution") || !id)
    throw new BadRequest("contentType ('post'|'contribution') and contentId required");
  if (supabaseEnabled()) await reportContent(
    type, id,
    b.reason ? String(b.reason).slice(0, 200) : undefined,
    b.reporterDevice ? String(b.reporterDevice) : undefined);
  res.json({ ok: true });
}));

// ---- Trail-camera ingest ----

// Inbound-email webhook. Configure your email service (Cloudflare Email Worker
// or SendGrid Inbound Parse) to POST normalized JSON here:
//   { to: "cam-<code>@in.marshsight.com", photoUrl, cameraName?, takenAt?, lat?, lon? }
app.post("/v1/inbound/camera", asyncRoute(async (req, res) => {
  const b = req.body ?? {};
  const to = String(b.to ?? "");
  const camCode = (to.match(/cam-([a-z0-9]+)@/i)?.[1] ?? (b.camCode ? String(b.camCode) : "")).toLowerCase();
  const photoUrl = b.photoUrl ? String(b.photoUrl) : (b.photo_url ? String(b.photo_url) : "");
  if (!camCode || !photoUrl) throw new BadRequest("camCode and photoUrl required");
  const num = (v: unknown) => (Number.isFinite(Number(v)) ? Number(v) : undefined);
  if (supabaseEnabled()) await addCameraPhoto(camCode, photoUrl,
    b.cameraName ? String(b.cameraName) : undefined,
    b.takenAt ? String(b.takenAt) : undefined, num(b.lat), num(b.lon));
  res.json({ ok: true });
}));

app.get("/v1/cameras", asyncRoute(async (req, res) => {
  const code = String(req.query.code ?? "").toLowerCase();
  if (!code) throw new BadRequest("code required");
  const photos = supabaseEnabled() ? await cameraPhotos(code) : [];
  res.json({ photos });
}));

// 404 + error handlers.
app.use((_req, res) => res.status(404).json({ error: "not found" }));
app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  if (err instanceof BadRequest) return res.status(400).json({ error: err.message });
  const message = err instanceof Error ? err.message : "internal error";
  res.status(502).json({ error: message });
});

// Run a local server only when invoked directly (not on Vercel serverless).
if (!process.env.VERCEL) {
  app.listen(PORT, () => {
    console.log(`Open Outdoors Platform API listening on http://localhost:${PORT}`);
  });
}

export default app;

/** Wrap an async route so thrown errors reach the error handler. */
function asyncRoute(
  fn: (req: Request, res: Response) => Promise<void>
): (req: Request, res: Response, next: NextFunction) => void {
  return (req, res, next) => fn(req, res).catch(next);
}
