import Foundation
import CoreLocation
import Combine

/// Holds the nearest-station tide predictions and refreshes them when the user
/// moves a meaningful distance. Stays nil inland, where the card simply hides.
@MainActor
final class TideStore: ObservableObject {
    @Published private(set) var result: TideService.Result?
    private var lastCenter: CLLocationCoordinate2D?

    func refreshIfStale(at coord: CLLocationCoordinate2D) async {
        if let last = lastCenter, GeoMath.distance(last, coord) < 15_000 { return }
        lastCenter = coord
        result = await TideService.tides(near: coord)
    }

    var stationName: String? { result?.stationName }
    /// The next high or low still in the future.
    var next: TideService.Tide? { result?.tides.first { $0.time > Date() } }
}

/// Tide predictions from NOAA CO-OPS (free, public, no key). Finds the nearest
/// tide station to the user and returns today's highs and lows. Coastal only;
/// inland there is no station within range and it returns nil.
enum TideService {

    struct Tide: Identifiable {
        let id = UUID()
        let type: String        // "H" or "L"
        let time: Date
        let heightFt: Double
        var isHigh: Bool { type == "H" }
    }

    struct Result { let stationName: String; let tides: [Tide] }

    private struct Station { let id: String; let name: String; let coord: CLLocationCoordinate2D }
    private static var stationsCache: [Station]?

    static func tides(near coord: CLLocationCoordinate2D, maxKm: Double = 60) async -> Result? {
        guard let stations = await loadStations() else { return nil }
        let nearest = stations.min { GeoMath.distance(coord, $0.coord) < GeoMath.distance(coord, $1.coord) }
        guard let st = nearest, GeoMath.distance(coord, st.coord) <= maxKm * 1000 else { return nil }
        guard let tides = await predictions(station: st.id) else { return nil }
        return Result(stationName: st.name, tides: tides)
    }

    // MARK: - Stations (fetched once, cached to disk; they rarely change)

    private static func loadStations() async -> [Station]? {
        if let c = stationsCache { return c }
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("tide_stations.json")
        if let data = try? Data(contentsOf: cacheURL), let s = parseStations(data) {
            stationsCache = s; return s
        }
        let url = URL(string: "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json?type=tidepredictions")!
        guard let (data, resp) = try? await URLSession.shared.data(from: url),
              (resp as? HTTPURLResponse)?.statusCode == 200, let s = parseStations(data) else { return nil }
        try? data.write(to: cacheURL, options: .atomic)
        stationsCache = s
        return s
    }

    private static func parseStations(_ data: Data) -> [Station]? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let arr = root["stations"] as? [[String: Any]] else { return nil }
        let s = arr.compactMap { d -> Station? in
            guard let id = d["id"] as? String, let name = d["name"] as? String,
                  let lat = d["lat"] as? Double, let lng = d["lng"] as? Double else { return nil }
            return Station(id: id, name: name, coord: CLLocationCoordinate2D(latitude: lat, longitude: lng))
        }
        return s.isEmpty ? nil : s
    }

    // MARK: - Predictions

    private static func predictions(station: String) async -> [Tide]? {
        let df = DateFormatter(); df.dateFormat = "yyyyMMdd"; df.locale = Locale(identifier: "en_US_POSIX")
        let today = df.string(from: Date())
        var comps = URLComponents(string: "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter")!
        comps.queryItems = [
            .init(name: "product", value: "predictions"),
            .init(name: "datum", value: "MLLW"),
            .init(name: "station", value: station),
            .init(name: "time_zone", value: "lst_ldt"),
            .init(name: "interval", value: "hilo"),
            .init(name: "units", value: "english"),
            .init(name: "format", value: "json"),
            .init(name: "begin_date", value: today),
            .init(name: "range", value: "48")
        ]
        guard let url = comps.url,
              let (data, resp) = try? await URLSession.shared.data(from: url),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let arr = root["predictions"] as? [[String: Any]] else { return nil }

        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd HH:mm"
        parser.locale = Locale(identifier: "en_US_POSIX")
        return arr.compactMap { d -> Tide? in
            guard let t = d["t"] as? String, let type = d["type"] as? String,
                  let vStr = d["v"] as? String, let v = Double(vStr),
                  let date = parser.date(from: t) else { return nil }
            return Tide(type: type, time: date, heightFt: v)
        }
    }
}
