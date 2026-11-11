# Sasta — Design Package

Everything for the Sasta grocery price-comparison app design (Android / Flutter), v1.0.

## What is inside

| Path | What it is |
|---|---|
| `DESIGN.md` | The design system: principles, tokens, components, patterns, accessibility, Flutter notes, QA checklist |
| `design-system/design-system.html` | Visual design system page (open in a browser; needs internet for Google Fonts) |
| `design-system/tokens.json` | Machine-readable tokens (colour, type, space, radius, shadow, motion, sizes) |
| `design-system/sasta_theme.dart` | Flutter tokens and `ThemeData` starting point |
| `screens/*.dc.html` | The 46 screens as standalone HTML (390 px wide; open any file in a browser) |
| `screens/canvas.json` | Board layout used on the design canvas (sections, positions, sizes) |
| `previews/*.png` | PNG render of every screen, plus `_overview.png` |

> **Preview fonts:** the PNG previews were rendered in a sandbox without Google Fonts, so they use a fallback typeface. In the real design the display font is Bricolage Grotesque and the text font is DM Sans.
> **Sample data:** every price, total, date, reference number and brand name is sample data. Legal pages are draft summaries.
> **Logos:** retailer logos are not included. Mascots stand in until official logo files are supplied.

## Screens

| # | Section | Screen | Preview | HTML |
|---|---|---|---|---|
| 1 | 01 · Onboarding & location | Splash | `previews/01-splash.png` | `screens/Splash.dc.html` |
| 2 | 01 · Onboarding & location | Onboarding | `previews/01-onboarding.png` | `screens/Onboard.dc.html` |
| 3 | 01 · Onboarding & location | Pincode | `previews/01-pincode.png` | `screens/Empty.dc.html` |
| 4 | 02 · Home | Home | `previews/02-home.png` | `screens/Main.dc.html` |
| 5 | 02 · Home | Home · first-time user | `previews/02-home-first-time-user.png` | `screens/HomeFirst.dc.html` |
| 6 | 02 · Home | Search suggestions | `previews/02-search-suggestions.png` | `screens/HomeSearch.dc.html` |
| 7 | 02 · Home | All categories | `previews/02-all-categories.png` | `screens/HomeCategories.dc.html` |
| 8 | 02 · Home | Home · can’t load | `previews/02-home-can-t-load.png` | `screens/HomeError.dc.html` |
| 9 | 03 · Search & products | Search results | `previews/03-search-results.png` | `screens/Search.dc.html` |
| 10 | 03 · Search & products | Product comparison | `previews/03-product-comparison.png` | `screens/Cart.dc.html` |
| 11 | 03 · Search & products | Product details | `previews/03-product-details.png` | `screens/Details.dc.html` |
| 12 | 03 · Search & products | Price history | `previews/03-price-history.png` | `screens/PriceHistory.dc.html` |
| 13 | 03 · Search & products | Saved | `previews/03-saved.png` | `screens/Favourites.dc.html` |
| 14 | 03 · Search & products | Search history | `previews/03-search-history.png` | `screens/History.dc.html` |
| 15 | 03 · Search & products | Notifications | `previews/03-notifications.png` | `screens/Notifications.dc.html` |
| 16 | 04 · Smart Basket | Basket · with products | `previews/04-basket-with-products.png` | `screens/Basket.dc.html` |
| 17 | 04 · Smart Basket | Basket · empty | `previews/04-basket-empty.png` | `screens/BasketEmpty.dc.html` |
| 18 | 04 · Smart Basket | Basket · selected items | `previews/04-basket-selected-items.png` | `screens/BasketSelect.dc.html` |
| 19 | 04 · Smart Basket | Basket · more options | `previews/04-basket-more-options.png` | `screens/BasketMenu.dc.html` |
| 20 | 04 · Smart Basket | Basket · share | `previews/04-basket-share.png` | `screens/BasketShare.dc.html` |
| 21 | 04 · Smart Basket | Basket · comparison unavailable | `previews/04-basket-comparison-unavailable.png` | `screens/BasketError.dc.html` |
| 22 | 05 · Basket comparison | Comparison · single store | `previews/05-comparison-single-store.png` | `screens/BasketCompare.dc.html` |
| 23 | 05 · Basket comparison | Comparison · split basket | `previews/05-comparison-split-basket.png` | `screens/BasketSplit.dc.html` |
| 24 | 05 · Basket comparison | Comparison · savings | `previews/05-comparison-savings.png` | `screens/BasketSavings.dc.html` |
| 25 | 06 · Profile & account | Profile | `previews/06-profile.png` | `screens/Filter.dc.html` |
| 26 | 06 · Profile & account | Personal information | `previews/06-personal-information.png` | `screens/PersonalInfo.dc.html` |
| 27 | 06 · Profile & account | Manage locations | `previews/06-manage-locations.png` | `screens/Locations.dc.html` |
| 28 | 06 · Profile & account | Account security | `previews/06-account-security.png` | `screens/Security.dc.html` |
| 29 | 06 · Profile & account | Saved baskets | `previews/06-saved-baskets.png` | `screens/SavedBaskets.dc.html` |
| 30 | 06 · Profile & account | Comparison preferences | `previews/06-comparison-preferences.png` | `screens/Prefs.dc.html` |
| 31 | 06 · Profile & account | Appearance | `previews/06-appearance.png` | `screens/Appearance.dc.html` |
| 32 | 06 · Profile & account | Notification settings | `previews/06-notification-settings.png` | `screens/NotifSettings.dc.html` |
| 33 | 07 · Sasta+ | Sasta+ · landing | `previews/07-sasta-landing.png` | `screens/PlusLanding.dc.html` |
| 34 | 07 · Sasta+ | Sasta+ · plans | `previews/07-sasta-plans.png` | `screens/Plans.dc.html` |
| 35 | 07 · Sasta+ | Sasta+ · checkout | `previews/07-sasta-checkout.png` | `screens/Checkout.dc.html` |
| 36 | 07 · Sasta+ | Sasta+ · payment success | `previews/07-sasta-payment-success.png` | `screens/PaySuccess.dc.html` |
| 37 | 07 · Sasta+ | Sasta+ · manage | `previews/07-sasta-manage.png` | `screens/ManageMember.dc.html` |
| 38 | 07 · Sasta+ | Sasta+ · history | `previews/07-sasta-history.png` | `screens/SubHistory.dc.html` |
| 39 | 08 · Help & legal | Help centre | `previews/08-help-centre.png` | `screens/HelpCentre.dc.html` |
| 40 | 08 · Help & legal | FAQs | `previews/08-faqs.png` | `screens/Faq.dc.html` |
| 41 | 08 · Help & legal | Contact support | `previews/08-contact-support.png` | `screens/Contact.dc.html` |
| 42 | 08 · Help & legal | Send feedback | `previews/08-send-feedback.png` | `screens/Feedback.dc.html` |
| 43 | 08 · Help & legal | About Sasta | `previews/08-about-sasta.png` | `screens/About.dc.html` |
| 44 | 08 · Help & legal | App information | `previews/08-app-information.png` | `screens/AppInfo.dc.html` |
| 45 | 08 · Help & legal | Privacy policy | `previews/08-privacy-policy.png` | `screens/Privacy.dc.html` |
| 46 | 08 · Help & legal | Terms & conditions | `previews/08-terms-conditions.png` | `screens/Terms.dc.html` |

## Not yet designed (from the specs)

Create/edit price alert · Price drop alerts list · Smart recommendations list · Monthly savings report · Category product listing · Basket templates preview · Basket activity history · Subscription cancel confirmation. Guest and premium variants of Home.
