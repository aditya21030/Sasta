/**
 * Sasta Shared Cache Proxy Core (zero dependencies — works on Node 18+ & Cloudflare Workers).
 *
 * Designed to cut QuickCommerceAPI credit burn by 90–99% at scale:
 * - Snaps lat/lon to ~2.2 km neighborhood hubs (0.02 deg) so nearby users share one cache key
 * - Multi-tier TTLs (6h home catalog, 1h searches, 24h serviceability, 30m empty results)
 * - Superset cache slicing (if 4 stores are cached, a 2-store request costs 0 credits)
 * - In-flight coalescing (concurrent identical searches share 1 upstream call)
 * - Global daily credit cap + per-IP uncached miss rate limit
 * - Keeps QUICKCOMMERCE_API_KEY strictly server-side
 */

const CATEGORY_DEFAULT_QUERY = {
  dairy: 'milk',
  fruits_veg: 'tomato potato onion',
  snacks: 'chips biscuits',
  beverages: 'tea coffee',
  staples: 'atta rice',
  cooking: 'cooking oil',
  personal_care: 'shampoo soap',
  household: 'detergent',
  baby_care: 'diapers',
  frozen: 'ice cream',
  bakery: 'bread butter',
  meat: 'eggs',
};

const KNOWN_PINCODE_COORDS = {
  '110001': { lat: 28.6304, lng: 77.2177 },
  '560001': { lat: 12.9716, lng: 77.5946 },
  '560034': { lat: 12.9352, lng: 77.6245 },
  '560038': { lat: 12.9784, lng: 77.6408 },
  '560102': { lat: 12.9116, lng: 77.6389 },
  '400001': { lat: 18.9388, lng: 72.8354 },
  '400050': { lat: 19.0607, lng: 72.8362 },
  '500001': { lat: 17.385, lng: 78.4867 },
  '600001': { lat: 13.0827, lng: 80.2707 },
  '700001': { lat: 22.5726, lng: 88.3639 },
  '411001': { lat: 18.5204, lng: 73.8567 },
  '122001': { lat: 28.4595, lng: 77.0266 },
  '201301': { lat: 28.5355, lng: 77.391 },
};

const ALL_PLATFORMS = ['BlinkIt', 'Minutes', 'Swiggy', 'Zepto'];

const PLATFORM_ALIASES = {
  blinkit: 'BlinkIt',
  grofers: 'BlinkIt',
  zepto: 'Zepto',
  swiggy: 'Swiggy',
  instamart: 'Swiggy',
  swiggy_instamart: 'Swiggy',
  minutes: 'Minutes',
  flipkart_minutes: 'Minutes',
  'flipkart minutes': 'Minutes',
};

export function snapCoord(value, fallback) {
  const num = Number(value);
  if (!Number.isFinite(num)) return fallback;
  return (Math.round(num * 50) / 50).toFixed(4);
}

export function normalizeQuery(q, categoryId) {
  const trimmed = (q || '').trim().toLowerCase().replace(/\s+/g, ' ');
  if (trimmed) return trimmed;
  return CATEGORY_DEFAULT_QUERY[categoryId] || 'milk';
}

export function normalizePlatforms(raw) {
  if (!raw || !String(raw).trim()) return [...ALL_PLATFORMS];
  const out = new Set();
  for (const part of String(raw).split(',')) {
    const key = part.trim().toLowerCase();
    if (!key) continue;
    if (PLATFORM_ALIASES[key]) out.add(PLATFORM_ALIASES[key]);
  }
  const sorted = [...out].sort();
  return sorted.length > 0 ? sorted : [...ALL_PLATFORMS];
}

function resolveCoords(pincode, rawLat, rawLon) {
  const hub = KNOWN_PINCODE_COORDS[pincode] || { lat: 28.6139, lng: 77.209 };
  return {
    lat: snapCoord(rawLat, hub.lat.toFixed(4)),
    lon: snapCoord(rawLon, hub.lng.toFixed(4)),
  };
}

function jsonResponse(body, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key',
      ...extraHeaders,
    },
  });
}

function filterGroupSearchPayload(payload, requestedPlatforms) {
  const wanted = new Set(requestedPlatforms);
  const srcData =
    payload && typeof payload === 'object' && payload.data && typeof payload.data === 'object'
      ? payload.data
      : payload || {};
  const srcResults =
    srcData.results && typeof srcData.results === 'object' ? srcData.results : {};
  const filteredResults = {};
  for (const [platformName, items] of Object.entries(srcResults)) {
    if (wanted.has(platformName)) {
      filteredResults[platformName] = items;
    }
  }
  return {
    ...payload,
    data: {
      ...srcData,
      results: filteredResults,
    },
  };
}

function hasAnyResultItems(payload) {
  const results = payload?.data?.results;
  if (!results || typeof results !== 'object') return false;
  return Object.values(results).some((arr) => Array.isArray(arr) && arr.length > 0);
}

/**
 * Abstract storage interface defaults to in-memory Map; Node server or Worker KV
 * can pass persistent `loadAll()` / `onWrite(key, entry)`.
 */
export function createMemoryCacheStore(initialEntries = {}) {
  const map = new Map(Object.entries(initialEntries));
  return {
    get(key) {
      return map.get(key) || null;
    },
    set(key, entry) {
      map.set(key, entry);
    },
    findSuperset(basePrefix, requestedPlatforms, now) {
      const wanted = new Set(requestedPlatforms);
      for (const [key, entry] of map.entries()) {
        if (!key.startsWith(basePrefix)) continue;
        if (!entry || entry.expiresAt <= now) continue;
        const cachedPlats = new Set(entry.platforms || []);
        let coversAll = true;
        for (const p of wanted) {
          if (!cachedPlats.has(p)) {
            coversAll = false;
            break;
          }
        }
        if (coversAll) return entry;
      }
      return null;
    },
    entries() {
      return map.entries();
    },
  };
}

export function createSastaProxyHandler(options = {}) {
  const {
    upstreamBaseUrl = 'https://api.quickcommerceapi.com',
    apiKey = '',
    clientAppToken = '',
    fetchImpl = fetch,
    cacheStore = createMemoryCacheStore(),
    homeTtlMs = 6 * 60 * 60 * 1000, // 6 hours
    searchTtlMs = 60 * 60 * 1000, // 1 hour
    emptyTtlMs = 30 * 60 * 1000, // 30 minutes
    serviceabilityTtlMs = 24 * 60 * 60 * 1000, // 24 hours
    maxDailyCredits = 200,
    maxMissesPerIpPerHour = 20,
    nowFn = () => Date.now(),
    onCacheWrite = null,
  } = options;

  const inFlight = new Map();
  const ipMissTimestamps = new Map();
  let dailyBucketDate = '';
  let dailyCreditsUsed = 0;

  function todayUtc(now) {
    return new Date(now).toISOString().slice(0, 10);
  }

  function resetDailyIfNeeded(now) {
    const day = todayUtc(now);
    if (day !== dailyBucketDate) {
      dailyBucketDate = day;
      dailyCreditsUsed = 0;
    }
  }

  function checkRateLimitAndBudget(clientIp, cost, now) {
    resetDailyIfNeeded(now);
    if (dailyCreditsUsed + cost > maxDailyCredits) {
      return {
        ok: false,
        status: 429,
        code: 'DAILY_BUDGET_CAP',
        message: 'Daily proxy credit budget reached. Cached items remain available.',
      };
    }

    const windowStart = now - 60 * 60 * 1000;
    const prev = (ipMissTimestamps.get(clientIp) || []).filter((t) => t > windowStart);
    if (prev.length >= maxMissesPerIpPerHour) {
      ipMissTimestamps.set(clientIp, prev);
      return {
        ok: false,
        status: 429,
        code: 'IP_RATE_LIMIT',
        message: 'Too many uncached live searches from this device. Try again shortly.',
      };
    }
    return { ok: true, prevWindow: prev };
  }

  async function fetchUpstreamGroupSearch({ query, pincode, lat, lon, platforms, ttlMs, basePrefix, now }) {
    const platKey = platforms.join(',');
    const cacheKey = `${basePrefix}|${platKey}`;

    if (inFlight.has(cacheKey)) {
      const coalesced = await inFlight.get(cacheKey);
      return {
        ...coalesced,
        cacheStatus: 'COALESCED',
        creditsCost: 0,
      };
    }

    const work = (async () => {
      const upstreamUrl = new URL('/v1/groupsearch', upstreamBaseUrl);
      upstreamUrl.searchParams.set('q', query);
      upstreamUrl.searchParams.set('lat', lat);
      upstreamUrl.searchParams.set('lon', lon);
      upstreamUrl.searchParams.set('pincode', pincode);
      upstreamUrl.searchParams.set('platforms', platKey);

      const res = await fetchImpl(upstreamUrl.toString(), {
        method: 'GET',
        headers: {
          Accept: 'application/json',
          'X-API-Key': apiKey,
        },
      });

      if (!res.ok) {
        const errText = await res.text().catch(() => '');
        return {
          ok: false,
          status: res.status,
          errorBody: {
            error: 'Upstream QuickCommerceAPI request failed',
            upstreamStatus: res.status,
            detail: errText.slice(0, 300),
          },
        };
      }

      const payload = await res.json();
      const nonEmpty = hasAnyResultItems(payload);
      const effectiveTtl = nonEmpty ? ttlMs : emptyTtlMs;
      const entry = {
        payload,
        platforms,
        fetchedAt: now,
        expiresAt: now + effectiveTtl,
      };
      cacheStore.set(cacheKey, entry);
      if (onCacheWrite) {
        await onCacheWrite(cacheKey, entry);
      }

      dailyCreditsUsed += platforms.length;
      return {
        ok: true,
        payload,
        fetchedAt: now,
        cacheStatus: 'MISS',
        creditsCost: platforms.length,
      };
    })();

    inFlight.set(cacheKey, work);
    try {
      return await work;
    } finally {
      inFlight.delete(cacheKey);
    }
  }

  async function handleGroupSearchRoute({ request, url, mode, clientIp }) {
    const now = nowFn();
    const pincode = (url.searchParams.get('pincode') || '110001').trim();
    const categoryId = url.searchParams.get('categoryId') || '';
    const query = mode === 'home' ? 'milk' : normalizeQuery(url.searchParams.get('q'), categoryId);
    const platforms = normalizePlatforms(url.searchParams.get('platforms'));
    const { lat, lon } = resolveCoords(
      pincode,
      url.searchParams.get('lat'),
      url.searchParams.get('lon') || url.searchParams.get('lng'),
    );

    const ttlMs = mode === 'home' ? homeTtlMs : searchTtlMs;
    const basePrefix = `gs|${pincode}|${lat}|${lon}|${query}`;
    const exactKey = `${basePrefix}|${platforms.join(',')}`;

    const exactHit = cacheStore.get(exactKey);
    if (exactHit && exactHit.expiresAt > now) {
      return formatSearchResponse(mode, exactHit.payload, pincode, exactHit.fetchedAt, {
        'X-Sasta-Cache': 'HIT',
        'X-Sasta-Credits-Cost': '0',
        'X-Sasta-Daily-Credits-Used': String(dailyCreditsUsed),
      });
    }

    const subsetHit = cacheStore.findSuperset(basePrefix, platforms, now);
    if (subsetHit) {
      const sliced = filterGroupSearchPayload(subsetHit.payload, platforms);
      return formatSearchResponse(mode, sliced, pincode, subsetHit.fetchedAt, {
        'X-Sasta-Cache': 'HIT_SUBSET',
        'X-Sasta-Credits-Cost': '0',
        'X-Sasta-Daily-Credits-Used': String(dailyCreditsUsed),
      });
    }

    if (!apiKey) {
      return jsonResponse(
        { error: 'Server missing QUICKCOMMERCE_API_KEY configuration.' },
        500,
      );
    }

    const guard = checkRateLimitAndBudget(clientIp, platforms.length, now);
    if (!guard.ok) {
      // Fall back gracefully to stale cache if available rather than failing completely.
      if (exactHit) {
        return formatSearchResponse(mode, exactHit.payload, pincode, exactHit.fetchedAt, {
          'X-Sasta-Cache': 'STALE_FALLBACK',
          'X-Sasta-Credits-Cost': '0',
          'X-Sasta-Daily-Credits-Used': String(dailyCreditsUsed),
        });
      }
      return jsonResponse({ error: guard.message, code: guard.code }, guard.status, {
        'X-Sasta-Cache': guard.code,
      });
    }

    const outcome = await fetchUpstreamGroupSearch({
      query,
      pincode,
      lat,
      lon,
      platforms,
      ttlMs,
      basePrefix,
      now,
    });

    if (!outcome.ok) {
      return jsonResponse(outcome.errorBody, outcome.status || 502);
    }

    if (outcome.cacheStatus === 'MISS') {
      ipMissTimestamps.set(clientIp, [...guard.prevWindow, now]);
    }

    return formatSearchResponse(mode, outcome.payload, pincode, outcome.fetchedAt, {
      'X-Sasta-Cache': outcome.cacheStatus,
      'X-Sasta-Credits-Cost': String(outcome.creditsCost),
      'X-Sasta-Daily-Credits-Used': String(dailyCreditsUsed),
    });
  }

  function formatSearchResponse(mode, groupSearchPayload, pincode, fetchedAt, headers) {
    if (mode === 'direct') {
      return jsonResponse(groupSearchPayload, 200, headers);
    }
    return jsonResponse(
      {
        pincode,
        syncedAt: new Date(fetchedAt).toISOString(),
        rawGroupSearch: groupSearchPayload,
        serviceableRetailers: extractServiceableRetailers(groupSearchPayload),
      },
      200,
      headers,
    );
  }

  function extractServiceableRetailers(payload) {
    const results = payload?.data?.results || {};
    const out = [];
    for (const [plat, list] of Object.entries(results)) {
      if (Array.isArray(list) && list.length > 0) {
        const firstOpen = list[0]?.platform?.open;
        if (firstOpen !== false) out.push(plat);
      }
    }
    return out;
  }

  async function handleServiceabilityRoute({ url, clientIp }) {
    const now = nowFn();
    const pincode = (url.searchParams.get('pincode') || '110001').trim();
    const platforms = normalizePlatforms(url.searchParams.get('platforms'));
    const { lat, lon } = resolveCoords(
      pincode,
      url.searchParams.get('lat'),
      url.searchParams.get('lon') || url.searchParams.get('lng'),
    );
    const cacheKey = `eta|${pincode}|${lat}|${lon}|${platforms.join(',')}`;
    const cached = cacheStore.get(cacheKey);
    if (cached && cached.expiresAt > now) {
      return jsonResponse(cached.payload, 200, {
        'X-Sasta-Cache': 'HIT',
        'X-Sasta-Credits-Cost': '0',
      });
    }

    // Derive serviceability cleanly from any cached groupsearch entry for this hub at 0 credits.
    const hubPrefix = `gs|${pincode}|${lat}|${lon}|`;
    for (const [k, entry] of cacheStore.entries()) {
      if (k.startsWith(hubPrefix) && entry && entry.expiresAt > now) {
        const etas = {};
        const retailers = [];
        const results = entry.payload?.data?.results || {};
        for (const [plat, items] of Object.entries(results)) {
          if (Array.isArray(items) && items.length > 0) {
            const pInfo = items[0]?.platform || {};
            if (pInfo.open !== false) {
              retailers.push(plat);
              if (pInfo.sla) etas[plat] = pInfo.sla;
            }
          }
        }
        if (retailers.length > 0) {
          return jsonResponse(
            { pincode, serviceable: true, retailers, etas },
            200,
            { 'X-Sasta-Cache': 'DERIVED_ZERO_COST', 'X-Sasta-Credits-Cost': '0' },
          );
        }
      }
    }

    if (!apiKey) {
      return jsonResponse({ error: 'Server missing QUICKCOMMERCE_API_KEY configuration.' }, 500);
    }

    const guard = checkRateLimitAndBudget(clientIp, platforms.length, now);
    if (!guard.ok) {
      return jsonResponse({ error: guard.message, code: guard.code }, guard.status);
    }

    const etaUrl = new URL('/v1/groupeta', upstreamBaseUrl);
    etaUrl.searchParams.set('lat', lat);
    etaUrl.searchParams.set('lon', lon);
    etaUrl.searchParams.set('pincode', pincode);
    etaUrl.searchParams.set('platforms', platforms.join(','));

    const res = await fetchImpl(etaUrl.toString(), {
      method: 'GET',
      headers: { Accept: 'application/json', 'X-API-Key': apiKey },
    });
    if (!res.ok) {
      return jsonResponse({ error: 'Upstream groupeta failed' }, res.status);
    }
    const decoded = await res.json();
    const results = decoded?.data?.results || decoded?.results || [];
    const retailers = [];
    const etas = {};
    for (const row of Array.isArray(results) ? results : []) {
      if (row && row.open !== false && row.platform) {
        retailers.push(row.platform);
        if (row.eta) etas[row.platform] = row.eta;
      }
    }
    const body = { pincode, serviceable: retailers.length > 0, retailers, etas };
    const entry = {
      payload: body,
      platforms,
      fetchedAt: now,
      expiresAt: now + serviceabilityTtlMs,
    };
    cacheStore.set(cacheKey, entry);
    if (onCacheWrite) await onCacheWrite(cacheKey, entry);
    dailyCreditsUsed += platforms.length;
    ipMissTimestamps.set(clientIp, [...guard.prevWindow, now]);

    return jsonResponse(body, 200, {
      'X-Sasta-Cache': 'MISS',
      'X-Sasta-Credits-Cost': String(platforms.length),
      'X-Sasta-Daily-Credits-Used': String(dailyCreditsUsed),
    });
  }

  return async function handleRequest(request, clientIp = 'unknown') {
    if (request.method === 'OPTIONS') {
      return jsonResponse({}, 204);
    }

    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, '') || '/';

    if (path === '/v1/health' || path === '/health') {
      const now = nowFn();
      resetDailyIfNeeded(now);
      return jsonResponse({
        ok: true,
        dailyCreditsUsed,
        maxDailyCredits,
      });
    }

    if (clientAppToken) {
      const bearer = (request.headers.get('authorization') || '').replace(/^Bearer\s+/i, '').trim();
      const apiKeyHdr = (request.headers.get('x-api-key') || '').trim();
      if (bearer !== clientAppToken && apiKeyHdr !== clientAppToken) {
        return jsonResponse({ error: 'Unauthorized' }, 401);
      }
    }

    if (path === '/v1/catalog/home') {
      return handleGroupSearchRoute({ request, url, mode: 'home', clientIp });
    }
    if (path === '/v1/catalog/search') {
      return handleGroupSearchRoute({ request, url, mode: 'search', clientIp });
    }
    if (path === '/v1/groupsearch') {
      return handleGroupSearchRoute({ request, url, mode: 'direct', clientIp });
    }
    if (path === '/v1/serviceability') {
      return handleServiceabilityRoute({ url, clientIp });
    }

    return jsonResponse({ error: 'Not found' }, 404);
  };
}
