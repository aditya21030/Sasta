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
| **Hyperlocal Discovery** | Auto-advancing Splash, onboarding carousel, and 6-digit Indian pincode selector with recent & preset areas (`Central Delhi`, saved delivery addresses). |
| **Side-by-Side Comparison** | Search with recent history, trending queries, category tiles, pack-size variant switches (`250 ml`, `500 ml`, `1 L`), unit-price breakdown, and mismatch/stock status badges. |
| **Price History & Alerts** | Interactive `7D` / `30D` / `90D` / `All` price trend charts with Lowest, Average, and Highest markers plus target price-drop alerts. |
| **Smart Basket Optimizer** | Multiple saved baskets (`Weekly Essentials`, templates, quick sharing), quantity steppers, and a live **Single Store vs. Split Basket vs. Savings** comparison engine. |
| **Sasta+ Membership** | Full upgrade funnel with benefits landing view, Monthly/Yearly plan selector, checkout flow with celebratory confetti transition, membership management, and invoice history. |
| **Profile, Light/Dark & Help** | Editable profile, delivery locations, notification & retailer preferences, Light/Dark/System appearance switcher, Help Centre topics, searchable FAQs, support tickets, feedback, and legal pages. |

---

## Project Structure

```text
sasta/
├── assets/
│   └── app_icon.png                 # Source Sasta 3D mascot app icon
├── lib/
│   ├── main.dart                    # App entry point, ThemeMode & SastaScope setup
│   ├── app/
│   │   ├── sasta_routes.dart        # Typed route constants & navigation helpers
│   │   └── sasta_router.dart        # Root flow (Splash -> Onboarding -> Shell) & page transitions
│   ├── theme/
│   │   ├── sasta_tokens.dart        # Brand palette, semantic pastels, spacing & motion tokens
│   │   └── sasta_theme.dart         # Light/Dark ThemeData & DMSans typography scale
│   ├── models/
│   │   └── models.dart              # Retailers, Products, Variants, Baskets & Comparison models
│   ├── data/
│   │   ├── mock_catalog.dart        # Grocery catalog, categories, price series, FAQs
│   │   └── sasta_app_state.dart     # ChangeNotifier app state & basket optimizer logic
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

- `flutter analyze` — static checks across all Dart sources and widget tests.
- `flutter test` — comparison math assertions (`Single store`, `Split basket`, savings), full onboarding & back-navigation flows, search to product comparison & price history, basket quantity steppers, Dark Mode switching, Sasta+ checkout, Help/FAQs, and compact `360x640` layout verification.
