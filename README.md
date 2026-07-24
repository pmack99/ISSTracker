# ISS Tracker (iOS)

Native iPhone port of [Brandnew_ISS_Tracker](https://github.com/pmack99/Brandnew_ISS_Tracker).

## Open in Xcode

1. Open `ISSTracker.xcodeproj` in Xcode.
2. Select the **ISSTracker** target and your **Team** for signing.
3. Run on a simulator or device (**⌘R**).

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
- [N2YO](https://www.n2yo.com/) — visual passes (API key in `Configuration/APIConfiguration.swift`)
- Apple **Core Location** / **CLGeocoder** — geocoding
- [NASA Image and Video Library](https://images.nasa.gov/) — photos

## Related repo

Web version: [Brandnew_ISS_Tracker](https://github.com/pmack99/Brandnew_ISS_Tracker)

## License

Licensed under the [MIT License](LICENSE), matching the original ISS Tracker web project (`Copyright (c) 2013-2018 Blackrock Digital LLC`).
