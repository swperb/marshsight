import Foundation

/// Loads routes. For now it reads a bundled sample marsh route. The real app
/// will fetch NOAA ENC chart features, USGS NHD hydrography, and PAD-US public
/// access boundaries, then cache them on device for offline use.
enum RouteStore {

    static func loadSample() -> NavRoute {
        guard let url = Bundle.main.url(forResource: "sample_route", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let route = try? JSONDecoder().decode(NavRoute.self, from: data) else {
            return NavRoute(name: "Empty", features: [])
        }
        return route
    }
}
