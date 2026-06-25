// Minimal file-backed persistence for user contributions and the waitlist.
// This is the MVP of the "publicly gathered data" server. It is intentionally
// simple (newline-delimited JSON files) so it runs with zero infrastructure;
// the production path is Postgres/PostGIS (e.g. Supabase). Swapping this module
// out for a real DB is the only change needed.

import { appendFile, readFile, mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import * as supa from "./supabase";

const DATA_DIR = process.env.DATA_DIR ?? join(process.cwd(), "data");
const CONTRIB_FILE = join(DATA_DIR, "contributions.ndjson");
const WAITLIST_FILE = join(DATA_DIR, "waitlist.ndjson");

export interface Contribution {
  id: string;
  kind: string;        // hazard | waypoint | blind | ramp | harvest | catch | note
  name: string;
  note?: string;
  lat: number;
  lon: number;
  visibility: "private" | "group" | "public";
  createdAt: string;
  deviceId?: string;   // anonymous author handle for now
}

async function ensureDir(file: string) {
  const dir = dirname(file);
  if (!existsSync(dir)) await mkdir(dir, { recursive: true });
}

async function appendLine(file: string, obj: unknown) {
  await ensureDir(file);
  await appendFile(file, JSON.stringify(obj) + "\n", "utf8");
}

async function readLines<T>(file: string): Promise<T[]> {
  if (!existsSync(file)) return [];
  const text = await readFile(file, "utf8");
  return text
    .split("\n")
    .filter((l) => l.trim().length > 0)
    .map((l) => JSON.parse(l) as T);
}

export async function addContribution(c: Contribution): Promise<void> {
  if (supa.supabaseEnabled()) return supa.addContribution(c);
  await appendLine(CONTRIB_FILE, c);
}

/// Public + group contributions near a point. Private ones are never returned
/// to other users (honey-hole protection).
export async function nearbyContributions(
  lat: number,
  lon: number,
  radiusKm: number,
  deviceId?: string
): Promise<Contribution[]> {
  if (supa.supabaseEnabled()) return supa.nearbyContributions(lat, lon, radiusKm, deviceId);
  const all = await readLines<Contribution>(CONTRIB_FILE);
  const degBox = radiusKm / 111; // rough degrees, fine for a coarse filter
  return all.filter((c) => {
    const visible = c.visibility !== "private" || (deviceId && c.deviceId === deviceId);
    if (!visible) return false;
    return Math.abs(c.lat - lat) <= degBox && Math.abs(c.lon - lon) <= degBox;
  });
}

export async function addWaitlistEmail(email: string): Promise<void> {
  if (supa.supabaseEnabled()) return supa.addWaitlistEmail(email);
  await appendLine(WAITLIST_FILE, { email, createdAt: new Date().toISOString() });
}
