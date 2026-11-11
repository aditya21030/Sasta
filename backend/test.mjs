import test from 'node:test';
import assert from 'node:assert/strict';
import { createMemoryCacheStore, createSastaProxyHandler } from './cache_core.mjs';

function samplePayload(platforms = ['BlinkIt', 'Zepto', 'Swiggy', 'Minutes']) {
  const results = {};
  for (const p of platforms) {
    results[p] = [
      {
        id: `${p}_milk_1`,
        name: 'Amul Taaza Toned Milk',
        brand: 'Amul',
        quantity: '500 ml',
        mrp: 28,
        offer_price: p === 'Zepto' ? 26 : 27,
        available: true,
        images: ['https://cdn.example.com/milk.png'],
        deeplink: `https://example.com/${p}/milk`,
        platform: { sla: '10 mins', open: true },
      },
    ];
  }
  return { status: 'success', credits_remaining: 80, data: { query: 'milk', results } };
}

test('snaps nearby GPS coordinates to ~2.2km hub & shares cached search across users', async () => {
  let upstreamHits = 0;
  const handler = createSastaProxyHandler({
    apiKey: 'secret-upstream-key',
    fetchImpl: async () => {
      upstreamHits++;
      return new Response(JSON.stringify(samplePayload()), { status: 200 });
    },
  });

  const res1 = await handler(
    new Request('https://proxy.sasta.test/v1/catalog/search?q=Milk&pincode=560102&lat=12.90211&lon=77.66391'),
    '10.0.0.1',
  );
  assert.equal(res1.status, 200);
  assert.equal(res1.headers.get('X-Sasta-Cache'), 'MISS');
  assert.equal(upstreamHits, 1);

  // User #2 is 300m away with uppercase spaces query -> hits exact hub cache (0 credits)
  const res2 = await handler(
    new Request('https://proxy.sasta.test/v1/catalog/search?q=%20milk%20&pincode=560102&lat=12.90489&lon=77.66412'),
    '10.0.0.2',
  );
  assert.equal(res2.status, 200);
  assert.equal(res2.headers.get('X-Sasta-Cache'), 'HIT');
  assert.equal(res2.headers.get('X-Sasta-Credits-Cost'), '0');
  assert.equal(upstreamHits, 1);
});

test('coalesces concurrent identical uncached requests into 1 upstream call', async () => {
  let upstreamHits = 0;
  const handler = createSastaProxyHandler({
    apiKey: 'secret-upstream-key',
    fetchImpl: async () => {
      upstreamHits++;
      await new Promise((r) => setTimeout(r, 25));
      return new Response(JSON.stringify(samplePayload()), { status: 200 });
    },
  });

  const responses = await Promise.all(
    Array.from({ length: 8 }, (_, i) =>
      handler(
        new Request('https://proxy.sasta.test/v1/catalog/home?pincode=110001&lat=28.6304&lng=77.2177'),
        `10.0.1.${i}`,
      ),
    ),
  );
  assert.equal(upstreamHits, 1);
  assert.equal(responses.every((r) => r.status === 200), true);
  assert.equal(responses.filter((r) => r.headers.get('X-Sasta-Cache') === 'MISS').length, 1);
  assert.equal(responses.filter((r) => r.headers.get('X-Sasta-Cache') === 'COALESCED').length, 7);
});

test('extracts subset of platforms from cached superset without spending extra credits', async () => {
  let upstreamHits = 0;
  const handler = createSastaProxyHandler({
    apiKey: 'secret-upstream-key',
    fetchImpl: async () => {
      upstreamHits++;
      return new Response(JSON.stringify(samplePayload()), { status: 200 });
    },
  });

  // First call caches all 4 platforms
  await handler(
    new Request('https://proxy.sasta.test/v1/catalog/search?q=bread&pincode=560102&platforms=BlinkIt,Zepto,Swiggy,Minutes'),
    '10.0.2.1',
  );
  assert.equal(upstreamHits, 1);

  // Second call only asks for BlinkIt,Zepto -> sliced locally from superset cache!
  const subsetRes = await handler(
    new Request('https://proxy.sasta.test/v1/catalog/search?q=bread&pincode=560102&platforms=blinkit,zepto'),
    '10.0.2.2',
  );
  assert.equal(subsetRes.headers.get('X-Sasta-Cache'), 'HIT_SUBSET');
  assert.equal(upstreamHits, 1);
  const body = await subsetRes.json();
  assert.deepEqual(Object.keys(body.rawGroupSearch.data.results).sort(), ['BlinkIt', 'Zepto']);
});

test('enforces daily credit budget & client token auth while still serving cached hits', async () => {
  let upstreamHits = 0;
  const store = createMemoryCacheStore();
  const handler = createSastaProxyHandler({
    apiKey: 'secret-upstream-key',
    clientAppToken: 'app-client-token',
    maxDailyCredits: 4,
    cacheStore: store,
    fetchImpl: async () => {
      upstreamHits++;
      return new Response(JSON.stringify(samplePayload()), { status: 200 });
    },
  });

  const unauth = await handler(new Request('https://proxy.sasta.test/v1/catalog/search?q=milk&pincode=110001'));
  assert.equal(unauth.status, 401);

  const ok = await handler(
    new Request('https://proxy.sasta.test/v1/catalog/search?q=milk&pincode=110001', {
      headers: { Authorization: 'Bearer app-client-token' },
    }),
    '10.0.3.1',
  );
  assert.equal(ok.status, 200);
  assert.equal(upstreamHits, 1);

  // Cached query still succeeds even after daily credit budget (4/4) is used
  const cachedStillOk = await handler(
    new Request('https://proxy.sasta.test/v1/catalog/search?q=milk&pincode=110001', {
      headers: { 'X-API-Key': 'app-client-token' },
    }),
    '10.0.3.2',
  );
  assert.equal(cachedStillOk.status, 200);

  // New uncached query exceeds maxDailyCredits=4 -> blocked before calling upstream
  const capped = await handler(
    new Request('https://proxy.sasta.test/v1/catalog/search?q=atta&pincode=110001', {
      headers: { Authorization: 'Bearer app-client-token' },
    }),
    '10.0.3.3',
  );
  assert.equal(capped.status, 429);
  assert.equal(upstreamHits, 1);
});
