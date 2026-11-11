import { createMemoryCacheStore, createSastaProxyHandler } from './cache_core.mjs';

// Warm per-isolate memory store backed by Cloudflare Cache API for cross-request sharing.
const memoryStore = createMemoryCacheStore();

export default {
  async fetch(request, env, ctx) {
    const cache = typeof caches !== 'undefined' ? caches.default : null;
    const reqUrl = new URL(request.url);
    const cacheKey = new Request(reqUrl.toString(), { method: 'GET' });

    if (request.method === 'GET' && cache) {
      const edgeCached = await cache.match(cacheKey);
      if (edgeCached) {
        return edgeCached;
      }
    }

    const handler = createSastaProxyHandler({
      upstreamBaseUrl: env.UPSTREAM_BASE_URL || 'https://api.quickcommerceapi.com',
      apiKey: env.QUICKCOMMERCE_API_KEY || '',
      clientAppToken: env.CLIENT_APP_TOKEN || '',
      maxDailyCredits: Number(env.MAX_DAILY_CREDITS || 200),
      maxMissesPerIpPerHour: Number(env.MAX_MISSES_PER_IP_PER_HOUR || 20),
      cacheStore: memoryStore,
    });

    const clientIp = request.headers.get('CF-Connecting-IP') || 'unknown';
    const response = await handler(request, clientIp);

    if (request.method === 'GET' && response.status === 200 && cache && reqUrl.pathname !== '/v1/health') {
      const ttlSeconds = reqUrl.pathname === '/v1/catalog/home' ? 21600 : 3600;
      const toCache = new Response(response.clone().body, response);
      toCache.headers.set('Cache-Control', `public, max-age=${ttlSeconds}`);
      ctx.waitUntil(cache.put(cacheKey, toCache));
    }

    return response;
  },
};
