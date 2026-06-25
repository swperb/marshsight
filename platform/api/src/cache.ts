// Tiny in-memory TTL cache to avoid hammering upstream public services.

interface Entry {
  value: unknown;
  expires: number;
}

const store = new Map<string, Entry>();

export async function cached<T>(
  key: string,
  ttlMs: number,
  produce: () => Promise<T>
): Promise<T> {
  const now = Date.now();
  const hit = store.get(key);
  if (hit && hit.expires > now) {
    return hit.value as T;
  }
  const value = await produce();
  store.set(key, { value, expires: now + ttlMs });
  return value;
}

/** Round coordinates so nearby requests share a cache entry. */
export function cacheKey(prefix: string, lat: number, lon: number, radiusKm: number): string {
  return `${prefix}:${lat.toFixed(2)}:${lon.toFixed(2)}:${radiusKm}`;
}

/** Fetch JSON with a timeout; throws on non-200. */
export async function fetchJSON(url: string, timeoutMs = 30_000): Promise<any> {
  const res = await fetch(url, { signal: AbortSignal.timeout(timeoutMs) });
  if (!res.ok) {
    throw new Error(`upstream ${res.status} for ${new URL(url).host}`);
  }
  return res.json();
}
