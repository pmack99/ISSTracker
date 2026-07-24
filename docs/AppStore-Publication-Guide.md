# App Store publication guide — ISS Tracker

Use this document when creating the app in **App Store Connect** and submitting **version 1.0**. Copy text from [App Store metadata (copy-paste)](AppStore-Metadata.md) into Connect fields.

**Last updated:** July 24, 2026

---

## 1. Prerequisites

| Item | Value / action |
|------|----------------|
| Apple Developer Program | Active membership (team **HF9W68H6LN** in Xcode) |
| App Store Connect | [appstoreconnect.apple.com](https://appstoreconnect.apple.com) |
| Bundle ID (app) | `com.pmack99.ISSTracker` |
| Widget extension | `com.pmack99.ISSTracker.ISSTrackerWidget` |
| Display name | **ISS Tracker** |
| Minimum iOS | **17.0** |
| Primary device | iPhone (portrait) |
| Price | Free (typical) |
| Build secrets | Optional `Config/Secrets.xcconfig` for local overrides (pass predictions need no API key) |

---

## 2. Public URLs (already live)

Use these in App Store Connect → **App Information** and **App Privacy** (Privacy Policy URL).

| Purpose | URL |
|---------|-----|
| Marketing | https://pmack99.github.io/ISSTracker/ |
| Support | https://pmack99.github.io/ISSTracker/support.html |
| Privacy Policy | https://pmack99.github.io/ISSTracker/privacy.html |

**Support email:** 3PMStudios@protonmail.com (also on support/privacy pages)

---

## 3. Create the app record

1. App Store Connect → **Apps** → **+** → **New App**.
2. **Platforms:** iOS.
3. **Name:** ISS Tracker (must be unique on the store; if taken, try “ISS Tracker – Live & Passes”).
4. **Primary language:** English (U.S.).
5. **Bundle ID:** select `com.pmack99.ISSTracker` (register in [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) first if missing).
6. **SKU:** e.g. `ISSTracker-2026` (internal only, any unique string).
7. **User Access:** Full Access (unless you use a limited role).

---

## 4. Metadata (copy from AppStore-Metadata.md)

Fill in **App Store** tab → **iOS App** → version **1.0**:

- Subtitle (30 characters max)
- Promotional text (170, optional, editable without new build)
- Description (4,000 max)
- Keywords (100 max, comma-separated, no spaces after commas)
- Support URL, Marketing URL (optional)
- **What's New** for 1.0 (first release blurb)

**Category (suggested):**

- **Primary:** Education *or* Reference  
- **Secondary:** Utilities *or* Weather (optional)

**Copyright:** `© 2026 Preston Mack` (or `© 2026 3PM Studios` if you publish under that name)

**Age rating:** Complete the questionnaire honestly (see §8).

---

## 5. Screenshots

App Store Connect shows **required sizes** for your account; capture on the **largest iPhone** you target (e.g. iPhone 17 Pro Max simulator), then upload. As of typical 2025–2026 requirements, plan for **6.9"** and **6.7"** iPhone sets if Connect asks for both—always follow the exact pixel sizes Connect lists.

### Recommended screens (5–8 shots)

| # | Tab / screen | What to show |
|---|----------------|--------------|
| 1 | **Live** | Hybrid map, red **ISS** label, station marker, Follow ISS enabled |
| 2 | **Overhead** | Pass list after a search (city or current location); optional Live dock CREW/CABIN |
| 3 | **Pass detail** | Compass / azimuth / elevation for one pass |
| 4 | **Notifications** | iOS Settings → ISS Tracker → Notifications *or* in-app pass with alerts scheduled |
| 5 | **Live Activity** | Pass detail with “Show Live Activity for this pass” enabled (physical iPhone) |
| 6 | **History** or **Saved places** | On-device history / saved places |
| 7 | **Photos** | NASA gallery (optional) |
| 8 | **About** | Data sources / credits (optional) |

### Capture tips

- Simulator: **File → Save Screen** or `⌘S` in Simulator; or run from Xcode on device.
- Use **light or dark** consistently (app supports both); dark map often looks best for Live.
- Hide personal location in screenshots if you prefer (search a public city).
- No “beta” or “TestFlight” in screenshot overlays.

---

## 6. App Privacy (Nutrition Label)

In Connect → **App Privacy** → **Get Started**. Answers below match the app behavior and [privacy.html](privacy.html). If you change the app, update both.

### Data collection summary

**Do you or your third-party partners collect data from this app?**  
→ **Yes** (network APIs receive IP address and request parameters; location is sent when user searches by current location).

Then declare:

| Data type | Collected? | Details |
|-----------|------------|---------|
| **Precise Location** | Yes | **App Functionality** — pass predictions for “current location” only while using the app. **Not linked to identity** (no accounts). **Not used for tracking.** |
| **Coarse Location** | Same as precise if you only use one; if Connect splits, same answers as precise. | |
| **User ID / Account** | No | |
| **Contact Info** | No | (Email is support-only on web, not collected in-app) |
| **Browsing History** | No | |
| **Search History** | Optional: **No** if pass search history never leaves device; stored in SwiftData locally only. | |
| **Identifiers (Device ID, etc.)** | No | (You do not use ad/analytics SDKs) |
| **Usage Data** | No | (Unless you add analytics later) |
| **Diagnostics** | No | (App does not collect crash reports itself; Apple may offer opt-in crash data separately) |
| **Other Data** | No | |

**Privacy Policy URL:** https://pmack99.github.io/ISSTracker/privacy.html

### Third-party data

Disclose in the questionnaire narrative / review notes that coordinates may be sent to **ISS Tracker API** and **Where The ISS At**, and place names to **Apple geocoding**, as described in the privacy policy.

---

## 7. App Review Information

| Field | Suggested content |
|-------|-------------------|
| **Contact — First / Last name** | Preston Mack |
| **Phone** | Your reachable number |
| **Email** | 3PMStudios@protonmail.com |
| **Sign-in required?** | **No** |
| **Notes** | See [Review notes (copy-paste)](AppStore-Metadata.md#review-notes-for-apple) |

Demo account: **Not required** (no login).

---

## 8. Age rating questionnaire (typical answers)

Answer based on final app content (no user-generated public content, no gambling, no unrestricted web):

- Cartoon/fantasy violence: None  
- Realistic violence: None  
- Sexual content: None  
- Profanity: None  
- Medical/treatment info: None  
- Gambling: None  
- Unrestricted web access: **No** (APIs only, no general browser)  
- Made for Kids: **No** (unless you intentionally target under 13)

Expect **4+** or low teen rating depending on Connect’s current rules.

---

## 9. Export compliance & encryption

When uploading the first build, Xcode/Connect asks about encryption:

- The app uses **HTTPS** only for standard API calls.
- **No custom cryptography** beyond Apple’s OS.
- Typically: **Yes, uses encryption** → **Exempt** under category (mass-market app using only standard HTTPS / `ITSAppUsesNonExemptEncryption` = **NO** in Info.plist if you add the key).

Optional: add to the merged Info.plist if Connect keeps prompting:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

(Only add if appropriate for your build; false is standard for apps that only use HTTPS.)

---

## 10. Content rights & trademarks

- **NASA media:** Gallery uses NASA Image and Video Library; follow [NASA media guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media/) (attribution in About tab).
- **ISS / NASA names:** Do not imply NASA endorsement; describe as unofficial tracker using public APIs.
- **MIT License:** Original web project and iOS port; see repo `LICENSE` and About tab.
- **Map data:** Apple MapKit / hybrid map — standard Apple terms.

---

## 11. Build, TestFlight, and submit

### Signing (Xcode)

1. **ISSTracker** target → **Signing & Capabilities** → Team **HF9W68H6LN**, Automatic signing.
2. Same for **ISSTrackerWidget** extension.
3. **Release** configuration: ensure `Secrets.xcconfig` exists if your checkout uses it (optional; no API keys required for passes).

### Archive

1. Scheme: **ISSTracker**, destination: **Any iOS Device** (or generic iOS device).
2. **Product → Archive**.
3. **Organizer → Distribute App → App Store Connect → Upload**.

Or: Connect → TestFlight and upload via Xcode as above.

### TestFlight (recommended)

1. Wait for processing (often 5–30 minutes).
2. **Internal testing** → add yourself → install TestFlight build.
3. Smoke test: Live map and dock, pass search, notifications permission, Live Activity on pass detail, one pass detail compass.

### Submit for review

1. App Store Connect → version **1.0** → select the uploaded build.
2. Complete **Export Compliance**, **Content Rights**, **Advertising Identifier** (No if you don’t use IDFA).
3. **Add for Review**.

Review often takes 24–48 hours; rejections commonly cite missing privacy details, broken links, or incomplete screenshots—verify all three URLs in a private browser window.

---

## 12. After approval

- Add **App Store link** to [docs/index.html](index.html) (“Download on the App Store”).
- **Promotional text** can be updated anytime without a new binary.
- For **1.0.1+**, update **What’s New** and increment `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in Xcode.

---

## 13. Checklist (printable)

- [ ] Developer Program active  
- [ ] Bundle IDs registered (app + widget)  
- [ ] App record created in Connect  
- [ ] Privacy Policy, Support, Marketing URLs live  
- [ ] Metadata pasted (subtitle, description, keywords)  
- [ ] Screenshots uploaded for required sizes  
- [ ] App Privacy questionnaire completed  
- [ ] Age rating completed  
- [ ] Review contact + notes filled  
- [ ] Release archive (no pass-prediction API key required)
- [ ] TestFlight smoke test  
- [ ] Submit for review  

---

## Related files

- [AppStore-Metadata.md](AppStore-Metadata.md) — copy-paste text for Connect fields  
- [privacy.html](privacy.html) — public privacy policy  
- [support.html](support.html) — public support  
- [index.html](index.html) — marketing page  
