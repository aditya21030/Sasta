<div align="center">
  <img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="116" alt="Sasta App Icon" />
  <h1>sasta.</h1>
  <p><strong>Mehenga Kyun? Sasta Hai Na!</strong></p>
  <p>Search once. Compare everywhere. Save more across quick-commerce apps in India.</p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-3.41+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-3.11+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/Theme-Light%20%26%20Dark-1C1C22?style=for-the-badge" alt="Light and Dark Theme" />
    <img src="https://img.shields.io/badge/Platforms%20Compared-Blinkit%20%7C%20Zepto%20%7C%20Instamart%20%7C%20Minutes-6F38C5?style=for-the-badge" alt="Retailers" />
  </p>
</div>

---

## Overview

**Sasta** is a Flutter quick-commerce grocery price comparison app built for Indian shoppers. Instead of jumping back and forth between **Blinkit**, **Zepto**, **Swiggy Instamart**, and **Flipkart Minutes**, users enter their delivery pincode once, compare item prices and pack sizes side by side, track 30–90 day price trends, and optimize their entire shopping basket in seconds.

---

## Key Features

| Area | Capabilities |
| :--- | :--- |
| **Hyperlocal Pincode & GPS** | Real India Post pincode area lookup (`api.postalpincode.in`), GPS coordinate detection (`geolocator` + native `geocoding` + OSM Nominatim fallback), and persistent saved delivery addresses. |
| **Quick-Commerce REST API** | Configurable `QuickCommerceRepository` (`--dart-define` or runtime Profile → Comparison Preferences setup), pull-to-refresh home feed sync, remote search merge, live price history fetch, and automatic offline/cached fallback. |
| **Side-by-Side Comparison** | Search with recent history, trending queries, category tiles, pack-size variant switches (`250 ml`, `500 ml`, `1 L`), unit-price breakdown, and mismatch/stock status badges. |
| **Deep-Link Handoff & Share** | Opens native Blinkit, Zepto, Swiggy Instamart, and Flipkart Minutes search intents (`url_launcher`) with official web store fallbacks, plus native OS share sheet (`share_plus`), WhatsApp share, clipboard copy, and email support links. |
| **Persistent State (`SharedPreferences`)** | Saves active location, theme preference, custom/multiple grocery baskets, price alerts, favourites, search history, comparison prefs, support tickets, and cached live catalog items across restarts. |
| **Sasta+ Membership & Profile** | Light/Dark/System theme switcher, editable profile, Sasta+ plans & checkout funnel with invoices, Help Centre FAQs, and support requests. |

---

## Quick-Commerce API Integration

Configure your backend base URL and API key at build time or at runtime inside **Profile → Comparison Preferences**:

```bash
flutter run --dart-define=SASTA_API_BASE_URL=https://api.yourdomain.com --dart-define=SASTA_API_KEY=your_api_key
```

### Expected REST Endpoints

- `GET /v1/catalog/home?pincode=<pin>&lat=<lat>&lng=<lng>` — returns `{ "products": [...], "area": "...", "serviceableRetailers": [...] }`
- `GET /v1/catalog/search?q=<query>&pincode=<pin>&categoryId=<id>` — returns `{ "products": [...] }`
- `GET /v1/catalog/products/<id>?pincode=<pin>` — returns `{ "product": {...} }`
- `GET /v1/catalog/products/<id>/history?pincode=<pin>` — returns `{ "historyByRange": { "7D": ..., "30D": ..., "90D": ... } }`
- `GET /v1/serviceability?pincode=<pin>` — returns `{ "pincode": "...", "area": "...", "serviceable": true, "retailers": [...] }`

When `SASTA_API_BASE_URL` is unconfigured or offline, Sasta automatically serves its cached catalog so comparison workflows keep working seamlessly.

---

## Project Structure

```text
sasta/
├── assets/
│   └── app_icon.png                 # Source Sasta 3D mascot app icon
├── lib/
│   ├── main.dart                    # Persistent SastaAppState.createAndLoad & SastaScope entry
│   ├── app/
│   │   ├── sasta_routes.dart        # Typed route constants & navigation helpers
│   │   └── sasta_router.dart        # Root flow (Splash -> Onboarding -> Shell) & page transitions
│   ├── services/
│   │   ├── quick_commerce_api.dart  # QuickCommerceRepository & HttpQuickCommerceRepository REST client
│   │   ├── local_storage_service.dart # SharedPreferences snapshot persistence & catalog cache
│   │   ├── pincode_location_service.dart # India Post API + Geolocator/Geocoding/Nominatim GPS resolver
│   │   ├── retailer_launcher_service.dart # Blinkit/Zepto/Instamart/Minutes native + web deep-links
│   │   └── share_service.dart       # Native OS share sheet & WhatsApp share integration
│   ├── theme/
│   │   ├── sasta_tokens.dart        # Brand palette, semantic pastels, spacing & motion tokens
│   │   └── sasta_theme.dart         # Light/Dark ThemeData & DMSans typography scale
│   ├── models/
│   │   └── models.dart              # Retailers, Products, Baskets & JSON serialization (`toJson`/`fromJson`)
│   ├── data/
│   │   ├── mock_catalog.dart        # Initial bundled grocery catalog fallback & FAQs
│   │   └── sasta_app_state.dart     # ChangeNotifier state, live API sync, persistence & basket math
│   ├── widgets/
│   │   ├── sasta_components.dart    # Cards, gradient price text, chips, tags, steppers, bottom nav
│   │   ├── sasta_motion.dart        # Reduced-motion-safe FadeUp & FloatBob animations
│   │   ├── sasta_background.dart    # Soft ambient gradient background painter
│   │   ├── sasta_mascot.dart        # Custom-painted expressive Sasta mascot
│   │   ├── product_art.dart         # Custom vector grocery product illustrations
│   │   ├── product_grid_card.dart   # Compact price-comparison product card
│   │   └── sasta_sheets.dart        # Modal sheets (create alert, basket actions, share)
│   └── screens/
│       ├── onboarding/              # Splash, Onboarding carousel, Pincode picker
│       ├── home/                    # Home feed, Instant search, Categories
│       ├── search_products/         # Results, Details, Compare, History, Saved, Alerts
│       ├── basket/                  # Smart Basket, Saved baskets, Share & Steppers
│       ├── comparison/              # Single store vs Split basket & Savings breakdown
│       ├── profile/                 # Account, Appearance, Locations, Preferences, Security
│       ├── sasta_plus/              # Landing, Plans, Checkout, Success, Manage, Invoices
│       └── help_legal/              # Help Centre, FAQs, Contact, Feedback, About, Legal
├── sasta-design-package/            # Reference DESIGN.md + 46 HTML UI screen specs
└── test/
    └── widget_test.dart             # Comparison engine unit tests & full E2E widget tests
```

---

## Design Language

- **Warm Minimalist Editorial UI**: Warm paper backdrop (`#FFFCFA`) in Light Mode and deep obsidian surfaces (`#131215`) in Dark Mode paired with soft mint, peach, lavender, butter, and sky pastel containers.
- **Smooth & Accessible Motion**: Spring-eased fade-up reveals (`FadeUp`) and gentle floating hero motion (`FloatBob`) that automatically respect OS reduced-motion preferences (`MediaQuery.disableAnimations`).
- **Adaptive Android Launcher**: Configured with `assets/app_icon.png` across all `mipmap-*` densities plus API 26+ adaptive squircle/circle layers.

---

## Getting Started

### Prerequisites

- Flutter SDK `>= 3.41` (Dart SDK `^3.11.1`)
- Android Studio / Android SDK (for APK builds or emulator runs)

### Run Locally

```bash
flutter pub get
flutter run
```

### Static Analysis & Tests

```bash
flutter analyze
flutter test
```

### Build Android APK

```bash
flutter build apk --release
```

The release APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Verification

- `flutter analyze` — zero static issues across all Dart sources, services, models, screens, and tests.
- `flutter test` — comparison engine math, JSON model serialization, `SharedPreferences` persistence round-trip, mocked HTTP Quick-Commerce API sync, India Post + GPS Nominatim lookup, Blinkit/Zepto/Instamart/Minutes URL & OS Share delegates, full onboarding & back-navigation flows, Dark Mode switching, Sasta+ checkout, Help/FAQs, and compact `360x640` layout verification.
