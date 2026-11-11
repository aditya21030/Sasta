# Sasta Design System — v1.0

**Product:** Sasta — grocery price comparison for India (Android, Flutter)
**Retailers compared:** Blinkit, Zepto, Swiggy Instamart, Flipkart Minutes
**Tagline:** *Mehenga Kyun? Sasta Hai Na!* · **Value line:** *Search once. Compare everywhere. Save more.*
**Design baseline:** 390 × 844 dp phone, light theme (dark theme tokens are listed in §12, not yet drawn)

This file is the source of truth for how Sasta looks and behaves. `design-system/design-system.html` shows every token and component visually, `design-system/tokens.json` is the machine-readable version, and `design-system/sasta_theme.dart` is a starting point for the Flutter theme. All 46 designed screens are in `screens/` (HTML) and `previews/` (PNG).

---

## 1. Principles

1. **Clear before clever.** One headline, one primary action, plenty of white space. A screen should read in two seconds.
2. **Playful, never noisy.** Pastel surfaces, soft shadows and friendly blob mascots carry the personality. Decoration never competes with prices.
3. **Prices are the hero.** The cheapest price is the biggest, boldest thing on a comparison screen. Everything else supports it.
4. **Honest numbers.** Totals are labelled *estimated* until fees are known. Unavailable is never shown as free or complete. Savings are estimates, not confirmed purchases.
5. **We don't sell groceries.** Every purchase hands off to the retailer's app ("Open Zepto app"). Say so wherever it matters.

---

## 2. Colour

### 2.1 Core

| Token | Hex | Use |
|---|---|---|
| `ink` | `#151515` | Text, primary buttons, active nav, chart annotations |
| `muted` | `#6A6578` | Secondary text, inactive icons, captions |
| `surface` | `#FFFFFF` | Cards, nav bar, sheets, inputs on tinted backgrounds |
| `field` | `#F4F1FB` | Search pill, chips, stepper well, segmented background |
| `divider` | `#EFEBF7` | Hairlines between list rows |
| `link` | `#B4380A` | Text links ("See all", "Clear", "View all") |
| `accent` | `#FF7A1A` | Brand dot in the wordmark, sparkles, decorative only (never text) |

### 2.2 Pastel card surfaces (pick by meaning, not randomly)

| Token | Hex | Typical meaning |
|---|---|---|
| `lavender` | `#EFE9FF` | Summary, plan, selected, "premium-adjacent" |
| `peach` | `#FFEBDC` | Basket, warm promos, neutral product cards |
| `mint` | `#E3F6EC` | Savings, success, in stock, cheapest |
| `butter` | `#FFF3C4` | Highlights, warnings that aren't errors, staples |
| `sky` | `#E4F1FF` | Dairy, information |
| `pink` | `#FFE4EE` | Alerts, errors that can be retried, recommendations |

Screen background is white with two soft radial glows: lavender (top left) and peach (top right).

### 2.3 Semantic pairs (text on tag background)

| State | Text | Background |
|---|---|---|
| Success / in stock / cheapest | `#14683F` | `#E3F6EC` |
| Warning / low stock / not refreshed | `#6B5200` | `#FFF3C4` (or `#8A4500` on `#FFF0D6`) |
| Danger / unavailable / failed | `#C0262D` | `#FFE4E4` |
| Neutral | `#4C4660` | `#F4F1FB` |

### 2.4 Retailer identity (mascot colours)

Used until official retailer logos are supplied. Each retailer has one colour; never reuse it for something else on a comparison screen.

| Retailer | Hex |
|---|---|
| Blinkit | `#FFD21F` |
| Zepto | `#A98BFF` |
| Swiggy Instamart | `#FF8A3D` |
| Flipkart Minutes | `#4FB3FF` |

> **Logo rule:** replace the mascots with the retailers' real icons only from official brand assets supplied by the team. Do not redraw trademarks.

### 2.5 Price gradient

`linear-gradient(90deg, #E5560A, #D6338A)` — only on large price numerals (≥ 24 sp, bold). It passes 3:1 on white and on every pastel surface above.

### 2.6 Verified contrast (WCAG 2.x)

| Pair | Ratio | Passes |
|---|---|---|
| `ink` on white | 18.3 | AA/AAA |
| `muted` on white | 5.6 | AA |
| `muted` on lavender / pink (lowest case) | 4.7 | AA |
| `link` on white / on peach | 6.0 / 5.2 | AA |
| `#14683F` on mint | 6.1 | AA |
| `#6B5200` on butter | 6.7 | AA |
| `#C0262D` on red tint | 4.9 | AA |
| `ink` on yellow button | 12.6 | AAA |
| Price gradient, lightest end on lavender | 3.1 | AA (large text) |

Rules: body text ≥ 4.5:1, large text (≥ 24 sp or 18.7 sp bold) ≥ 3:1. Status is never colour alone: pair with an icon or a word ("In stock", "Unavailable").

---

## 3. Typography

| Role | Family | Weight | Size / line | Tracking |
|---|---|---|---|---|
| Hero wordmark | Bricolage Grotesque | 800 | 72 / 1.05 | -3% |
| Display XL (splash numerals, big price) | Bricolage Grotesque | 800 | 48–64 / 1.05 | -3% |
| Display L (screen headline) | Bricolage Grotesque | 800 | 36–38 / 1.05 | -3% |
| Display M (section heading) | Bricolage Grotesque | 800 | 22–28 / 1.05 | -3% |
| Title (card title, price) | Bricolage Grotesque | 800 | 20–26 / 1.1 | -2% |
| Body L | DM Sans | 500 | 16 / 1.4 | 0 |
| Body | DM Sans | 500–600 | 15 / 1.4 | 0 |
| Label (buttons, row titles) | DM Sans | 700 | 14–16 / 1.25 | 0 |
| Caption | DM Sans | 500 | 12–13 / 1.4 | 0 |
| Overline | DM Sans | 700 | 11 / 1.2, UPPERCASE | +6% |

Fonts load from Google Fonts: **Bricolage Grotesque** (700, 800) and **DM Sans** (500, 600, 700). Fallback: Inter, then system sans. The ₹ symbol and Devanagari fall back to the system font.

Minimum text size is 11 sp, used only for overlines and tags. Everything people must read is 12 sp or larger.

---

## 4. Spacing, shape, elevation

**Spacing scale (dp):** 4 · 6 · 8 · 10 · 12 · 14 · 16 · 18 · 22 · 28 · 40
Page padding: **22 left/right**, **54 top** (below the status bar), content ends at least **96** above the bottom of the screen when the nav bar is shown, **30** otherwise.

**Radius**

| Token | dp | Used on |
|---|---|---|
| `r-screen` | 44 | Artboard corners (mockups only) |
| `r-sheet` | 36 | Bottom sheets (top corners) |
| `r-card` | 28 | Cards, hero blocks |
| `r-pill` | 28 (height 56) / 29 (height 58) | Search pill, primary buttons |
| `r-tile` | 18–26 | Product and category tiles |
| `r-chip` | 22 (height 44) | Chips |
| `r-tag` | 999 | Tags |
| `r-nav` | 33 (height 66) | Floating nav |

**Elevation**

| Token | Value | Used on |
|---|---|---|
| `shadow-card` | `0 8px 22px rgba(120,60,10,.12)` | Cards, icon buttons, search pill |
| `shadow-float` | `0 16px 36px rgba(60,40,120,.20)` | Bottom navigation |
| `shadow-cta` | `0 14px 26px rgba(21,21,21,.25)` | Primary black button |
| `shadow-sheet` | `0 -20px 50px rgba(21,21,21,.20)` | Bottom sheets |

No borders on cards. The only borders are: selected plan/option (3 px ink), outlined button (2 px ink), dashed "add" slot (2 px `#D9D3EA`).

---

## 5. Iconography and illustration

- **Icons:** 24 dp grid, 2.3 px stroke, round caps and joins, `currentColor`. Sizes: 16 (inline), 18–20 (rows), 22–24 (buttons, nav). Icon-only buttons always carry an accessible label.
- **Mascots ("blobs"):** an 8-lobe flower body in a retailer or brand colour, dot or closed-arc eyes, small smile, pink cheeks. Dot eyes blink; arc eyes mean joy (success, celebration). A sad variant (grey body, flat mouth) is used for errors. Sizes: 24–44 (list avatars), 52–72 (cards), 100–150 (heroes).
- **Product art:** flat vector, soft ground shadow, one highlight. Set: milk carton, eggs, bread, rice/atta bag, curd tub, oil bottle. Sits on a pastel tile. Real product photography replaces these when available.
- **Sparkles:** 4-point stars, 1–1.3× scale, twinkle animation; at most 3 per illustration.
- **Never use emoji** as icons or illustration.

---

## 6. Layout

- **Screen anatomy:** status area (54) → header row (48) → content → optional persistent action bar → floating nav.
- **Header:** back button (48 circle) · optional centred title · optional right action. **Only one title per screen.** If a screen has a large headline, the header shows only the back button.
- **Grids:** product grid is 2 columns, gap 14. Category grid is 3 columns. Horizontal rails bleed past the right edge by 22 to signal scrolling.
- **Tall screens (Home, Basket, Profile)** scroll; the persistent bar and nav stay fixed.
- **Bottom sheets:** 36 dp top radius, 44 × 5 drag handle, dim scrim at 42% ink.

---

## 7. Components

### 7.1 Buttons
| Type | Spec |
|---|---|
| **Primary** | Height 58, pill, `ink` fill, white bold 16, `shadow-cta`, soft light sweep every ~3.4 s. One per screen. |
| **Primary on dark** | Height 50, yellow `#FFD21F` fill, ink text (inside the dark action bar). |
| **Secondary** | Height 58 (or 46–52 in cards), 2 px ink outline, ink text. |
| **Text** | Min height 48, bold 14–15, `ink` or `link`. Destructive text uses `#C0262D`. |
| **Icon** | 48 circle (44 minimum), white, `shadow-card`. |
| **Small action** | Height 36–44, pill, ink or `field` fill, bold 12–13. |

### 7.2 Inputs
Search/field pill: height 56, `field` fill (white when on a tinted card), 20 dp horizontal padding, 20 dp leading icon, 16 sp text, placeholder `#6F6A7C`. Label above fields: 12 sp bold, muted.

### 7.3 Chips, tags, toggles
- **Chip:** height 44, 18 dp padding, `field` fill; selected = ink fill + white text.
- **Tag:** pill, 11 sp bold, semantic colour pair (§2.3), never wraps.
- **Toggle:** 50 × 30, on = ink track, off = `#D9D3EA`, 24 dp white thumb.
- **Stepper:** pill well in `field`, two 34–36 dp round buttons and a count.
- **Segmented control:** `field` well, 44 dp segments, selected = ink pill.
- **Checkbox / radio:** 26 dp, selected = ink fill with white tick.

### 7.4 Cards
- Radius 28, padding 14–16, `shadow-card`, no border.
- Pastel cards use §2.2 surfaces. White cards sit on tinted or white backgrounds.
- **Product card:** tile with art (72–84), name (13–14 bold), pack size (12 muted), price (title style) and retailer avatars.
- **Retailer row:** mascot avatar 44–48, name, pack size · availability, price at the right. Best price row sits first with a "Cheapest" tag; unavailable rows are dimmed and show "—".
- **List row:** 44 icon tile (radius 16), title 15 bold, optional subtitle, trailing chevron/toggle/tag. Min height 56–60.

### 7.5 Navigation
- **Bottom navigation:** floating white pill, 66 high, 22 dp side margins, 20 dp from bottom. Four destinations: Home, Basket, Saved, Profile. Active = 50 dp ink circle with white icon; inactive = muted icon. No labels (each has an accessible name).
- **Persistent action bar (Basket):** dark pill above the nav with item count, estimated total and the Compare button.
- **Bottom sheet:** menus (basket options, share). Title 24 display, rows 56 high.

### 7.6 Feedback and states
- **Loading:** skeleton blocks `#F1EEF8` with a moving highlight (1.4 s). No spinners on full screens.
- **Empty:** mascot or basket illustration, display headline, one-line explanation, one primary and at most one secondary action.
- **Error / offline:** sad mascot, plain-language cause, **Try again** primary button, the user's data stays visible.
- **Success:** celebration mascot, confetti (decorative), summary card, primary action.

---

## 8. Motion

| Name | What | Timing |
|---|---|---|
| `fade-up` | Cards and rows rise 16 dp and fade in, staggered by 80–100 ms | 600–700 ms, `cubic-bezier(.2,.8,.2,1)` |
| `float` | Illustrations and mascots bob 7–8 dp | 3.2–3.4 s, ease-in-out, loop |
| `blink` | Mascot eyes close briefly | 4.5 s loop |
| `twinkle` | Sparkles scale/fade | 2.4 s loop |
| `grow` | Chart bars scale from the baseline | 0.9–1 s |
| `draw` | Chart lines draw left to right | 1.8–2 s |
| `ripple` | Location pin ripple | 2.2 s loop |
| `pulse` | Unread dot, best-price card ring | 1.4–2.4 s loop |
| `sheen` | Light sweep across primary buttons | 3.2–3.4 s loop |

Rules: motion never carries information on its own; keep each screen to **three or fewer looping animations**; respect the OS "reduce motion" setting by disabling every loop and showing the final state (chart lines are drawn, bars are full).

---

## 9. Patterns

### 9.1 Navigation and routes
- **Tab roots** (Home, Basket, Saved, Profile): show the bottom nav, no back button.
- **Pushed screens** (results, comparison, details, history, settings pages): show a back button, **no bottom nav**.
- **Sheets and modals:** dim scrim, handle, one primary action.
- **One route per control.** A destination should be reachable from at most one prominent control per screen. Example: on the Basket screen the persistent bar is the single "Compare basket" action; the three comparison modes are chips inside the shortcut card.
- **One title per screen.** Either the header title or a large headline, not both.

### 9.2 Showing a comparison
1. Show the cheapest retailer first, with its price in the gradient display style and a "Cheapest" tag.
2. List the remaining retailers by price, with pack size and availability on the second line.
3. Show price per 100 g/ml or per piece when pack sizes differ; flag smaller packs.
4. Primary action: **Open `<retailer>` app**.
5. Show data freshness ("Last compared 2 hours ago", "Updated 2 min ago") wherever a number could be stale.

### 9.3 Estimates and savings
- Totals that exclude delivery/platform fees say **Estimated** and, where space allows, "fees may differ at checkout".
- Incomplete baskets say how many products are priced ("3 of 4") and never present a total as complete.
- Savings use "Estimated" and are compared against the priciest **complete** option, not an average that would overstate them.
- A split basket that saves less than it costs in extra fees says so ("Splitting isn't worth it here").

### 9.4 Availability states
In stock (mint tag, check) · Only N left (butter tag, clock) · Out of stock / Unavailable (red or grey tag, cross) · Price not refreshed (butter tag) · Only on one app (butter tag).

### 9.5 Sample data
All prices, totals, dates, references and brand names in the mockups are **sample data**. Real builds must use verified data. Legal pages are draft summaries for legal review.

---

## 10. Content style

- Voice: friendly, short, plain. Hinglish only in the tagline and small brand moments.
- Currency: `₹27`, `₹1,240`. No decimals unless needed. Use `~₹148` for estimates.
- Units: `500 ml`, `1 kg`, `6 pcs`; unit price as `₹5.4 per 100 ml`.
- Dates: `8 Nov 2026`; relative times for recent events (`2 min ago`, `Yesterday`).
- Buttons are verbs: *Compare basket*, *Open Zepto app*, *Create price alert*.
- Empty states say what to do next, not what is missing.

---

## 11. Accessibility checklist

- Touch targets ≥ 44 × 44 dp (use 48 for icon buttons).
- Every icon-only control has a label; decorative SVGs are hidden from assistive tech.
- Text contrast per §2.6; status never by colour alone.
- Support font scaling to at least 130% without clipping (rows grow, never truncate prices).
- Provide reduced-motion behaviour (§8).
- Focus order follows reading order; sheets trap focus and return it on close.
- Inputs have visible labels or accessible names; errors are announced.

---

## 12. Dark theme (tokens only, to be designed)

| Light | Dark |
|---|---|
| Screen white | `#121118` |
| Surface white | `#1C1A24` |
| `field` | `#2A2735` |
| `ink` text | `#F4F1FB` |
| `muted` | `#A9A4BB` |
| Primary button | `#F4F1FB` fill, `#151515` text |
| Pastel surfaces | Same hue at ~18% over the dark surface |

Re-check every contrast pair in §2.6 before shipping dark mode.

---

## 13. Screen inventory (46)

| Section | Screens |
|---|---|
| 01 Onboarding & location | Splash · Onboarding · Pincode |
| 02 Home | Home (returning) · Home (first-time) · Search suggestions · All categories · Can't load |
| 03 Search & products | Search results · Product comparison · Product details · Price history · Saved · Search history · Notifications |
| 04 Smart Basket | With products · Empty · Selected items · More options · Share · Comparison unavailable |
| 05 Basket comparison | Single store · Split basket · Savings |
| 06 Profile & account | Profile · Personal information · Manage locations · Account security · Saved baskets · Comparison preferences · Notification settings · Appearance |
| 07 Sasta+ | Landing · Plans · Checkout · Payment success · Manage membership · Subscription history |
| 08 Help & legal | Help centre · FAQs · Contact support · Send feedback · About · Privacy policy · Terms · App information |

Not yet designed from the specs: Create/edit price alert, Price drop alerts list, Smart recommendations list, Monthly savings report, Category product listing, Basket templates preview, Basket activity history, Subscription cancel confirmation.

## 14. QA checklist (used to audit the screens)

Run on every screen before handoff:
1. Nothing is clipped at the bottom, nothing overflows horizontally (except intentional scroll rails).
2. Content ends ≥ 96 dp above the bottom when the nav is shown; ≥ 30 dp otherwise; fixed bars never cover content.
3. Blocks align to the 22 dp page grid; no stray margins.
4. No element is shrunk below its set height (buttons, pills).
5. One title, one primary action, one nav pattern per screen (§9.1).
6. No duplicated information (the same number or state twice without a reason).
7. Tags and labels don't wrap; text never clips.
8. Contrast and touch-target rules (§2.6, §11).

## 15. Flutter notes

- Packages: `google_fonts` (Bricolage Grotesque, DM Sans), `flutter_svg` for illustration, `flutter_animate` or implicit animations for §8.
- Build the theme from `design-system/sasta_theme.dart`; keep tokens in one `SastaTokens` file and never hard-code hex values in widgets.
- Suggested widgets: `SastaButton`, `SastaPill`, `SastaChip`, `SastaTag`, `SastaCard`, `RetailerRow`, `ProductCard`, `PriceText`, `Mascot`, `SastaNavBar`, `ActionBar`, `SastaSheet`, `SkeletonBlock`, `StateView` (empty/error/success).
- Respect `MediaQuery.disableAnimations` for reduced motion and `textScaler` for font scaling.
- Android navigation: back gesture pops pushed screens; tab roots exit the app after a double back.

## 16. Changelog

- **1.0** — First complete system: tokens, components, patterns and 46 screens. Audit fixes: single title per screen, nav only on tab roots, no duplicate compare routes, contrast-safe price gradient and link colour.
