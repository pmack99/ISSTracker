# App Store screenshot previews

Marketing frames for **App Store Connect** (headline + subhead on a dark space-themed background).

## Ready to upload (6.7″ iPhone)

**Folder:** [`output/6.7-inch-1284x2778/`](output/6.7-inch-1284x2778/)

| File | Headline | Your source screen |
|------|----------|-------------------|
| `01-live.png` | Track the ISS live | Live map (globe, dark) |
| `02-orbit.png` | Orbit at a glance | Live → Orbit dock |
| `03-cabin.png` | Inside the station | Live → Cabin (dark) |
| `04-passes.png` | Visible passes | Overhead pass list (dark) |
| `05-compass.png` | Know where to look | Pass detail + compass |
| `06-reminders.png` | Never miss a pass | Tonight’s pass + alerts (light) |
| `07-history.png` | On your device | History (dark) |
| `08-photos.png` | NASA gallery | ISS Photos tab |

Upload in order **01 → 08** under **App Store → iOS App → 1.0 → Screenshots → iPhone 6.5" / 6.7" Display**. Required portrait size is **1284×2778** (also accepted: 1242×2688, 2778×1284 landscape). Do **not** use 1290×2796 — Connect rejects it for this slot.

## Important: resolution

The first build used **chat thumbnails (~470px wide)**. They will look **soft** on the store. For sharp listings:

1. Re-export **full-size** PNGs from your phone or Simulator (**File → Save Screen** on iPhone 16 Pro Max / 17 Pro Max).
2. Replace files in [`source/`](source/) (same names: `live-globe.png`, `orbit-shadow.png`, …).
3. Regenerate:

```bash
cd marketing/app-store
../.venv-screenshots/bin/python generate_previews.py
```

## Regenerate / customize

- Edit headlines in `generate_previews.py` → `SLIDES`.
- Swap art: drop PNGs into `source/` (see `SOURCE_MAP` in the script).
- Orange accent matches the in-app tab tint.

## Plain screenshots (no text)

If Apple’s review or your taste prefers **no marketing copy**, upload your raw captures instead (Live, Passes, Pass detail, History, Photos). Keep **one** appearance (mostly **dark** for Live; light **06-reminders** is fine as a contrast slide or replace with a dark pass list).

## App Preview video (optional)

Connect allows a **15–30s** video per size. Suggested beats: Live follow → Orbit → Cabin → search passes → open pass detail → toggle Live Activity. Not included here; record with **QuickTime + iPhone** or Simulator screen recording.
