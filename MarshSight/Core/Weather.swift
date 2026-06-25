import Foundation
import CoreLocation
import Combine

/// Current conditions a hunter actually reads: wind (the whole game for scent
/// and waterfowl), temperature, barometric pressure, and the moon. Sourced from
/// Open-Meteo, which is free and needs no API key, and a local moon-phase
/// calculation. No third party sees the user's location for this.
struct Weather: Equatable {
    var temperatureF: Double
    var windSpeedMph: Double
    var windFromDegrees: Double     // meteorological: direction wind blows FROM
    var pressureInHg: Double
    var fetchedAt: Date

    /// 16-point cardinal of the direction the wind is coming from.
    var windFromCardinal: String { Self.cardinal(windFromDegrees) }

    static func cardinal(_ deg: Double) -> String {
        let dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"]
        let i = Int((deg.truncatingRemainder(dividingBy: 360) / 22.5).rounded()) % 16
        return dirs[(i + 16) % 16]
    }
}

enum WeatherService {
    enum ServiceError: Error { case badResponse }

    static func current(at c: CLLocationCoordinate2D) async throws -> Weather {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            .init(name: "latitude", value: String(format: "%.4f", c.latitude)),
            .init(name: "longitude", value: String(format: "%.4f", c.longitude)),
            .init(name: "current", value: "temperature_2m,wind_speed_10m,wind_direction_10m,surface_pressure"),
            .init(name: "temperature_unit", value: "fahrenheit"),
            .init(name: "wind_speed_unit", value: "mph")
        ]
        guard let url = comps.url else { throw ServiceError.badResponse }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ServiceError.badResponse
        }
        let decoded = try JSONDecoder().decode(OpenMeteo.self, from: data)
        let cur = decoded.current
        return Weather(
            temperatureF: cur.temperature_2m,
            windSpeedMph: cur.wind_speed_10m,
            windFromDegrees: cur.wind_direction_10m,
            pressureInHg: cur.surface_pressure * 0.02953,  // hPa -> inHg
            fetchedAt: Date()
        )
    }

    private struct OpenMeteo: Decodable {
        let current: Current
        struct Current: Decodable {
            let temperature_2m: Double
            let wind_speed_10m: Double
            let wind_direction_10m: Double
            let surface_pressure: Double
        }
    }
}

/// Compact moon-phase calculation from the synodic month. Good enough for a
/// hunting app's "what is the moon doing tonight" panel.
enum MoonPhase {
    /// Returns the phase name, illuminated fraction (0...1), and an SF Symbol.
    static func current(_ date: Date = Date()) -> (name: String, illumination: Double, symbol: String) {
        let synodic = 29.530588853
        // Reference new moon: 2000-01-06 18:14 UTC.
        let refNewMoon = Date(timeIntervalSince1970: 947182440)
        let days = date.timeIntervalSince(refNewMoon) / 86400
        var age = days.truncatingRemainder(dividingBy: synodic)
        if age < 0 { age += synodic }
        let phase = age / synodic                       // 0 = new, 0.5 = full
        let illumination = (1 - cos(2 * .pi * phase)) / 2

        let name: String
        switch phase {
        case ..<0.03, 0.97...: name = "New Moon"
        case ..<0.22: name = "Waxing Crescent"
        case ..<0.28: name = "First Quarter"
        case ..<0.47: name = "Waxing Gibbous"
        case ..<0.53: name = "Full Moon"
        case ..<0.72: name = "Waning Gibbous"
        case ..<0.78: name = "Last Quarter"
        default: name = "Waning Crescent"
        }
        return (name, illumination, "moon.stars.fill")
    }
}

/// Holds current weather for the user's location, refreshed sparingly.
@MainActor
final class WeatherStore: ObservableObject {
    @Published private(set) var weather: Weather?
    private var lastFetch: Date?
    private var lastCoord: CLLocationCoordinate2D?

    func refreshIfStale(at c: CLLocationCoordinate2D) async {
        if let last = lastFetch, Date().timeIntervalSince(last) < 1200,  // 20 min
           let lc = lastCoord, GeoMath.distance(lc, c) < 8000 {
            return
        }
        await refresh(at: c)
    }

    func refresh(at c: CLLocationCoordinate2D) async {
        guard let w = try? await WeatherService.current(at: c) else { return }
        weather = w
        lastFetch = Date()
        lastCoord = c
    }
}
