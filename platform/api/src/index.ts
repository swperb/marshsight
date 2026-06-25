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
import { addContribution, nearbyContributions, addWaitlistEmail, Contribution } from "./store";
import { randomUUID } from "node:crypto";

const app = express();
const PORT = Number(process.env.PORT ?? 8088);
const TTL = 5 * 60 * 1000; // 5 minutes
const startedAt = Date.now();

app.use(express.json({ limit: "256kb" }));

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

app.post("/v1/waitlist", asyncRoute(async (req, res) => {
  const email = String(req.body?.email ?? "").trim().toLowerCase();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw new BadRequest("valid email required");
  await addWaitlistEmail(email);
  res.status(201).json({ ok: true });
}));

// 404 + error handlers.
app.use((_req, res) => res.status(404).json({ error: "not found" }));
app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  if (err instanceof BadRequest) return res.status(400).json({ error: err.message });
  const message = err instanceof Error ? err.message : "internal error";
  res.status(502).json({ error: message });
});

app.listen(PORT, () => {
  console.log(`Open Outdoors Platform API listening on http://localhost:${PORT}`);
});

/** Wrap an async route so thrown errors reach the error handler. */
function asyncRoute(
  fn: (req: Request, res: Response) => Promise<void>
): (req: Request, res: Response, next: NextFunction) => void {
  return (req, res, next) => fn(req, res).catch(next);
}
