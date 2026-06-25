import Foundation
import CoreLocation
import Combine

/// A user-submitted field observation: a hazard, blind, ramp, harvest, etc.
/// This is the seed of the crowdsourced data layer. Stored locally first so it
/// works with no signal, then synced to the platform API when reachable.
struct Contribution: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable {
        case hazard, waypoint, blind, ramp, harvest, fish, note

        var title: String {
            switch self {
            case .hazard: return "Hazard"
            case .waypoint: return "Waypoint"
            case .blind: return "Blind / Stand"
            case .ramp: return "Boat Ramp"
            case .harvest: return "Harvest"
            case .fish: return "Catch"
            case .note: return "Note"
            }
        }

        /// Map to a map/AR marker kind for rendering.
        var markerKind: MarkerFeature.Kind {
            switch self {
            case .hazard: return .hazard
            case .blind: return .blind
            case .ramp: return .access
            case .waypoint, .harvest, .fish, .note: return .waypoint
            }
        }
    }

    enum Visibility: String, Codable, CaseIterable {
        case `private`, group, `public`
        var title: String {
            switch self {
            case .private: return "Private"
            case .group: return "My Group"
            case .public: return "Public"
            }
        }
    }

    var id: String
    var kind: Kind
    var name: String
    var note: String?
    var latitude: Double
    var longitude: Double
    var visibility: Visibility
    var createdAt: Date

    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }

    func asMarkerFeature() -> MarkerFeature {
        MarkerFeature(kind: kind.markerKind, name: name, latitude: latitude, longitude: longitude)
    }
}

/// Holds user contributions, persists them to disk, renders them, and makes a
/// best-effort sync to the platform API. Honey-hole safe: defaults to private.
@MainActor
final class ContributionStore: ObservableObject {

    @Published private(set) var contributions: [Contribution] = []

    /// Anonymous per-install author handle (until real accounts land).
    private let deviceId: String

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("contributions.json")
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "deviceId") {
            deviceId = saved
        } else {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: "deviceId")
            deviceId = id
        }
        load()
    }

    var markers: [MarkerFeature] { contributions.map { $0.asMarkerFeature() } }

    func add(kind: Contribution.Kind, name: String, note: String?,
             at coordinate: CLLocationCoordinate2D, visibility: Contribution.Visibility) {
        let c = Contribution(
            id: UUID().uuidString, kind: kind,
            name: name.isEmpty ? kind.title : name,
            note: note?.isEmpty == true ? nil : note,
            latitude: coordinate.latitude, longitude: coordinate.longitude,
            visibility: visibility, createdAt: Date()
        )
        contributions.append(c)
        save()
        Task { await sync(c) }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Contribution].self, from: data) else { return }
        contributions = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(contributions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Best-effort sync to the platform API

    private func sync(_ c: Contribution) async {
        guard !PlatformAPI.baseURL.isEmpty,
              let url = URL(string: "\(PlatformAPI.baseURL)/v1/contributions") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "kind": c.kind.rawValue, "name": c.name, "note": c.note ?? "",
            "lat": c.latitude, "lon": c.longitude,
            "visibility": c.visibility.rawValue, "deviceId": deviceId
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: req)
    }
}

/// Platform API configuration. Empty base URL means local-only (no server yet);
/// set this to the deployed API host to enable sync.
enum PlatformAPI {
    static let baseURL = ""   // e.g. "https://api.marshsight.app"
}
