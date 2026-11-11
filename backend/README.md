# Sasta Shared Cache Proxy

Moves your QuickCommerceAPI key off the Android APK and caches results across all users per ~2.2 km neighborhood hub.

## How it saves 90–99% of credits
* **2.2 km hub snapping:** Minor GPS changes (`12.9021` vs `12.9048`) resolve to one cache bucket.
* **Shared multi-user cache:** `6h` Home catalog, `1h` searches, `24h` ETA/serviceability, `30m` empty searches.
* **Superset slicing:** If 4 platforms were cached and a device only requests `BlinkIt,Zepto`, the proxy filters from cache at `0` credits.
* **In-flight coalescing:** Concurrent users searching the same item trigger `1` upstream call total.
* **Hard caps:** `MAX_DAILY_CREDITS` (default `200`) and `MAX_MISSES_PER_IP_PER_HOUR` (default `20`) prevent runaway credit drain.

---

## Option A: Deploy Free on Cloudflare Workers (`$0/month` free tier)

```bash
cd backend
npx wrangler login
npx wrangler secret put QUICKCOMMERCE_API_KEY
# optional client header lock:
npx wrangler secret put CLIENT_APP_TOKEN
npx wrangler deploy
```

Then build the Flutter APK pointing to your Worker URL (never embedding `QUICKCOMMERCE_API_KEY` in the app):

```bash
flutter build apk --release ^
  --dart-define=SASTA_API_BASE_URL=https://sasta-cache-proxy.<your-subdomain>.workers.dev ^
  --dart-define=SASTA_API_KEY=<your-CLIENT_APP_TOKEN-or-empty>
```

---

## Option B: Run on Node 18+ (Render / Railway / VPS)

```bash
set QUICKCOMMERCE_API_KEY=your-key-here
set MAX_DAILY_CREDITS=200
node backend/server.mjs
```

Run tests anytime with:

```bash
node --test backend/test.mjs
```
