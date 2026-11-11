import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { createMemoryCacheStore, createSastaProxyHandler } from './cache_core.mjs';

const PORT = Number(process.env.PORT || 8787);
const CACHE_FILE = process.env.CACHE_FILE || path.join(process.cwd(), '.sasta-cache.json');

function loadPersistedCache() {
  try {
    if (!fs.existsSync(CACHE_FILE)) return {};
    const parsed = JSON.parse(fs.readFileSync(CACHE_FILE, 'utf8'));
    const now = Date.now();
    const active = {};
    for (const [k, v] of Object.entries(parsed || {})) {
      if (v && v.expiresAt > now) active[k] = v;
    }
    return active;
  } catch {
    return {};
  }
}

let writeTimer = null;
function schedulePersist(cacheStore) {
  if (writeTimer) return;
  writeTimer = setTimeout(() => {
    writeTimer = null;
    try {
      const snapshot = {};
      const now = Date.now();
      for (const [k, v] of cacheStore.entries()) {
        if (v && v.expiresAt > now) snapshot[k] = v;
      }
      fs.writeFileSync(CACHE_FILE, JSON.stringify(snapshot), 'utf8');
    } catch (err) {
      console.error('[sasta-proxy] cache persist warning:', err?.message);
    }
  }, 500);
}

const cacheStore = createMemoryCacheStore(loadPersistedCache());
const handleRequest = createSastaProxyHandler({
  upstreamBaseUrl: process.env.UPSTREAM_BASE_URL || 'https://api.quickcommerceapi.com',
  apiKey: process.env.QUICKCOMMERCE_API_KEY || '',
  clientAppToken: process.env.CLIENT_APP_TOKEN || '',
  maxDailyCredits: Number(process.env.MAX_DAILY_CREDITS || 200),
  maxMissesPerIpPerHour: Number(process.env.MAX_MISSES_PER_IP_PER_HOUR || 20),
  cacheStore,
  onCacheWrite: () => schedulePersist(cacheStore),
});

const server = http.createServer(async (req, res) => {
  try {
    const fullUrl = `http://${req.headers.host || 'localhost'}${req.url || '/'}`;
    const headers = new Headers();
    for (const [k, v] of Object.entries(req.headers)) {
      if (Array.isArray(v)) headers.set(k, v.join(','));
      else if (v !== undefined) headers.set(k, String(v));
    }
    const webReq = new Request(fullUrl, { method: req.method, headers });
    const clientIp =
      String(req.headers['x-forwarded-for'] || '').split(',')[0].trim() ||
      req.socket.remoteAddress ||
      'unknown';

    const webRes = await handleRequest(webReq, clientIp);
    res.statusCode = webRes.status;
    webRes.headers.forEach((val, key) => res.setHeader(key, val));
    const text = await webRes.text();
    res.end(text);
  } catch (err) {
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ error: String(err?.message || err) }));
  }
});

server.listen(PORT, () => {
  console.log(`[sasta-proxy] Listening on http://0.0.0.0:${PORT}`);
});
