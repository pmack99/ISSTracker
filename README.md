# ISS Tracker (iOS)

Native iPhone port of [Brandnew_ISS_Tracker](https://github.com/pmack99/Brandnew_ISS_Tracker).

## Open in Xcode

1. Open `ISSTracker.xcodeproj` in Xcode.
2. Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig` if the file is missing (optional local overrides; `Secrets.xcconfig` is gitignored).
3. Select the **ISSTracker** target and your **Team** for signing.
4. Run on a simulator or device (**⌘R**).

Run unit tests: **⌘U** or `xcodebuild test -scheme ISSTracker -destination 'platform=iOS Simulator,name=iPhone 17'`.

## Features

| Tab | Description |
|-----|-------------|
| **Live** | Hybrid map with smooth ISS motion; dock panels for orbit, crew (Open Notify), and cabin telemetry (NASA ISSLIVE) |
| **Passes** | Visible pass predictions by city/ZIP or current location; default saved place; local reminders |
| **History** | On-device pass search history (SwiftData) |
| **Photos** | NASA ISS image gallery |
| **About** | Credits, data sources, support & privacy links |

Also: **Live Activity** on supported iPhones for pass countdown (Lock Screen / Dynamic Island); compass assist on pass detail.

## APIs

- [Where The ISS At](https://wheretheiss.at/) — live position
- [ISS Tracker API](https://iss.cdnspace.ca/) — visible pass predictions (no API key)
- [Open Notify](http://open-notify.org/) — people in space (crew)
- NASA **ISSLIVE** / Lightstreamer — cabin environment telemetry
- Apple **Core Location** / **CLGeocoder** — geocoding
- [NASA Image and Video Library](https://images.nasa.gov/) — photos

## App Store web pages

Static **marketing**, **support**, and **privacy** pages live in [`docs/`](docs/). To publish on GitHub Pages:

1. On GitHub: **Settings → Pages → Build from branch** → branch `main`, folder **`/docs`**.
2. After deploy, URLs are typically:
   - Marketing: `https://pmack99.github.io/ISSTracker/`
   - Support: `https://pmack99.github.io/ISSTracker/support.html`
   - Privacy: `https://pmack99.github.io/ISSTracker/privacy.html`

**App Store submission:** [publication guide](docs/AppStore-Publication-Guide.md) · [metadata copy-paste](docs/AppStore-Metadata.md)

## Related repo

Web version: [Brandnew_ISS_Tracker](https://github.com/pmack99/Brandnew_ISS_Tracker)

## License

Licensed under the [MIT License](LICENSE), matching the original ISS Tracker web project (`Copyright (c) 2013-2018 Blackrock Digital LLC`).
