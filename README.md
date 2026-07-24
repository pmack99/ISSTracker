# ISS Tracker (iOS)

Native iPhone port of [Brandnew_ISS_Tracker](https://github.com/pmack99/Brandnew_ISS_Tracker).

## Open in Xcode

1. Open `ISSTracker.xcodeproj` in Xcode.
2. Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig` and set your [N2YO](https://www.n2yo.com/) API key (`Secrets.xcconfig` is gitignored).
3. Select the **ISSTracker** target and your **Team** for signing.
4. Run on a simulator or device (**⌘R**).

If the key was ever committed to Git, **rotate it** in your N2YO account and use the new value only in `Secrets.xcconfig`.

## Features

| Tab | Description |
|-----|-------------|
| **Live** | MapKit map with ISS position (updates every 30s) |
| **Overhead** | Visible pass predictions by city/zip or current location |
| **History** | On-device search history (SwiftData) |
| **Photos** | NASA ISS image gallery |
| **About** | Credits and data sources |

## APIs

- [Where The ISS At](https://wheretheiss.at/) — live position
- [N2YO](https://www.n2yo.com/) — visible pass predictions (API key in `Config/Secrets.xcconfig`, not in git)
- Apple **Core Location** / **CLGeocoder** — geocoding
- [NASA Image and Video Library](https://images.nasa.gov/) — photos

## App Store web pages

Static **marketing**, **support**, and **privacy** pages live in [`docs/`](docs/). To publish on GitHub Pages:

1. On GitHub: **Settings → Pages → Build from branch** → branch `main`, folder **`/docs`**.
2. After deploy, URLs are typically:
   - Marketing: `https://pmack99.github.io/ISSTracker/`
   - Support: `https://pmack99.github.io/ISSTracker/support.html`
   - Privacy: `https://pmack99.github.io/ISSTracker/privacy.html`

## Related repo

Web version: [Brandnew_ISS_Tracker](https://github.com/pmack99/Brandnew_ISS_Tracker)

## License

Licensed under the [MIT License](LICENSE), matching the original ISS Tracker web project (`Copyright (c) 2013-2018 Blackrock Digital LLC`).
