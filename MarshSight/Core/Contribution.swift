import Foundation
import CoreLocation
import Combine

/// A user-submitted field observation: a hazard, blind, ramp, harvest, etc.
/// This is the seed of the crowdsourced data layer. Stored locally first so it
/// works with no signal, then synced to the platform API when reachable.
struct Contribution: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable {
        case hazard, waypoint, blind, ramp, harvest, fish, note
        case feeder, camera, foodPlot, gate, owner

        var title: String {
            switch self {
            case .hazard: return "Hazard"
            case .waypoint: return "Waypoint"
            case .blind: return "Blind / Stand"
            case .ramp: return "Boat Ramp"
            case .harvest: return "Harvest"
            case .fish: return "Catch"
            case .note: return "Note"
            case .feeder: return "Feeder"
            case .camera: return "Trail Camera"
            case .foodPlot: return "Food Plot"
            case .gate: return "Gate"
            case .owner: return "Property Owner"
            }
        }

        /// Map to a map/AR marker kind for rendering.
        var markerKind: MarkerFeature.Kind {
            switch self {
            case .hazard: return .hazard
            case .blind: return .blind
            case .ramp: return .access
            case .feeder: return .feeder
            case .camera: return .camera
            case .foodPlot: return .foodPlot
            case .gate: return .gate
            case .owner: return .owner
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

    // Community review. Optional so older saved data still decodes.
    var upvotes: Int?
    var downvotes: Int?
    var status: String?     // "pending" until the community verifies it
    var myVote: Int?        // this device's vote: +1, -1, or nil

    var score: Int { (upvotes ?? 0) - (downvotes ?? 0) }

    /// A spot is community-verified once it clears the vote threshold.
    var isVerified: Bool { (status ?? "pending") == "verified" || score >= Contribution.verifyThreshold }
    static let verifyThreshold = 3

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
    /// Spots others have shared, fetched from the server and cached for offline.
    @Published private(set) var communitySpots: [Contribution] = []

    private var lastFetchCenter: CLLocationCoordinate2D?

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
        loadCommunity()
    }

    var markers: [MarkerFeature] { contributions.map { $0.asMarkerFeature() } }
    var communityMarkers: [MarkerFeature] { communitySpots.map { $0.asMarkerFeature() } }
    /// Own spots plus shared community spots, for the map and search.
    var allMarkers: [MarkerFeature] { markers + communityMarkers }
    /// Every votable spot (own + community), deduped by id.
    var allSpots: [Contribution] {
        var seen = Set<String>()
        return (contributions + communitySpots).filter { seen.insert($0.id).inserted }
    }

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

    /// Save a named place from search as a public community spot. It starts as
    /// pending and becomes verified once the community upvotes it.
    func saveSpot(name: String, at coordinate: CLLocationCoordinate2D) {
        add(kind: .waypoint, name: name, note: nil, at: coordinate, visibility: .public)
    }

    /// The community-tagged owner for a parcel, where the county withholds it:
    /// the most-upvoted owner tag whose point falls inside the parcel.
    func communityOwner(in parcel: Parcel) -> String? {
        allSpots
            .filter { $0.kind.markerKind == .owner && parcel.contains($0.coordinate) }
            .max { $0.score < $1.score }?
            .name
    }

    /// Cast or toggle a vote on a spot (own or community). Updates locally and
    /// posts to the server, where the canonical tallies and status are computed.
    func vote(_ spot: Contribution, _ delta: Int) {
        let apply: (Contribution) -> Contribution = { input in
            var c = input
            let prev = c.myVote ?? 0
            if prev == 1 { c.upvotes = max(0, (c.upvotes ?? 0) - 1) }
            if prev == -1 { c.downvotes = max(0, (c.downvotes ?? 0) - 1) }
            let newVote = (prev == delta) ? 0 : delta
            if newVote == 1 { c.upvotes = (c.upvotes ?? 0) + 1 }
            if newVote == -1 { c.downvotes = (c.downvotes ?? 0) + 1 }
            c.myVote = newVote == 0 ? nil : newVote
            if (c.status ?? "pending") != "verified", c.score >= Contribution.verifyThreshold { c.status = "verified" }
            return c
        }
        if let i = contributions.firstIndex(where: { $0.id == spot.id }) {
            contributions[i] = apply(contributions[i]); save()
        } else if let i = communitySpots.firstIndex(where: { $0.id == spot.id }) {
            communitySpots[i] = apply(communitySpots[i]); saveCommunity()
        } else { return }
        let newVote = (spot.myVote ?? 0) == delta ? 0 : delta
        Task { await postVote(spotID: spot.id, value: newVote) }
    }

    /// Fetch shared spots near a point from the server, cached for offline use.
    func fetchNearby(_ center: CLLocationCoordinate2D) async {
        if let last = lastFetchCenter, GeoMath.distance(last, center) < 4_000 { return }
        guard !PlatformAPI.baseURL.isEmpty,
              var comps = URLComponents(string: "\(PlatformAPI.baseURL)/v1/contributions") else { return }
        comps.queryItems = [
            .init(name: "lat", value: String(center.latitude)),
            .init(name: "lon", value: String(center.longitude)),
            .init(name: "radiusKm", value: "30"),
            .init(name: "deviceId", value: deviceId),
        ]
        guard let url = comps.url,
              let (data, resp) = try? await URLSession.shared.data(from: url),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode(ServerResponse.self, from: data) else { return }
        lastFetchCenter = center
        // Community = others' spots (our own already live in `contributions`).
        communitySpots = decoded.contributions.filter { $0.deviceId != deviceId }.map { $0.toContribution() }
        saveCommunity()
    }

    private func postVote(spotID: String, value: Int) async {
        guard !PlatformAPI.baseURL.isEmpty,
              let url = URL(string: "\(PlatformAPI.baseURL)/v1/votes") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "contributionId": spotID, "deviceId": deviceId, "value": value
        ])
        _ = try? await URLSession.shared.data(for: req)
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

    private var communityFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("community_spots.json")
    }
    private func loadCommunity() {
        guard let data = try? Data(contentsOf: communityFileURL),
              let decoded = try? JSONDecoder().decode([Contribution].self, from: data) else { return }
        communitySpots = decoded
    }
    private func saveCommunity() {
        guard let data = try? JSONEncoder().encode(communitySpots) else { return }
        try? data.write(to: communityFileURL, options: .atomic)
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

// MARK: - Server DTOs

private struct ServerResponse: Decodable { let contributions: [ServerContribution] }

private struct ServerContribution: Decodable {
    let id: String
    let kind: String
    let name: String
    let note: String?
    let lat: Double
    let lon: Double
    let visibility: String
    let createdAt: String
    let deviceId: String?
    let upvotes: Int?
    let downvotes: Int?
    let status: String?

    func toContribution() -> Contribution {
        Contribution(
            id: id,
            kind: Contribution.Kind(rawValue: kind) ?? .waypoint,
            name: name, note: note,
            latitude: lat, longitude: lon,
            visibility: Contribution.Visibility(rawValue: visibility) ?? .public,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            upvotes: upvotes, downvotes: downvotes, status: status, myVote: nil)
    }
}

/// Platform API configuration. Spots, votes, and the waitlist sync here once the
/// DNS for this host resolves and the schema is applied; calls fail gracefully
/// until then.
enum PlatformAPI {
    static let baseURL = "https://api.marshsight.com"
}
