import Foundation
import Combine

/// A shared harvest/catch in the community feed ("Strava for hunting").
struct FeedPost: Identifiable, Decodable {
    var id: String
    var kind: String
    var note: String?
    var lat: Double?
    var lon: Double?
    var photoUrl: String?
    var tempF: Double?
    var wind: String?
    var moon: String?
    var author: String?
    var upvotes: Int?
    var createdAt: String?
}

/// Loads the community feed and shares your own trophies to it. Location is
/// opt-in (off by default) so the story can be shared without the honey hole.
@MainActor
final class FeedStore: ObservableObject {
    @Published private(set) var posts: [FeedPost] = []
    @Published private(set) var loading = false

    private struct FeedResponse: Decodable { let posts: [FeedPost] }

    func load() async {
        loading = true
        defer { loading = false }
        guard let url = URL(string: "\(PlatformAPI.baseURL)/v1/feed?limit=100") else { return }
        guard let (data, resp) = try? await URLSession.shared.data(from: url),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode(FeedResponse.self, from: data) else { return }
        posts = decoded.posts
    }

    /// Share a logbook entry to the feed. `includeLocation` defaults off.
    func share(_ entry: LogEntry, includeLocation: Bool, author: String?) async {
        guard let url = URL(string: "\(PlatformAPI.baseURL)/v1/posts") else { return }
        var body: [String: Any] = ["kind": entry.kind.rawValue]
        if !entry.note.isEmpty { body["note"] = entry.note }
        if includeLocation { body["lat"] = entry.latitude; body["lon"] = entry.longitude }
        if let t = entry.tempF { body["tempF"] = t }
        if let w = entry.windCardinal { body["wind"] = w }
        if let m = entry.moonPhase { body["moon"] = m }
        if let a = author, !a.isEmpty { body["author"] = a }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: req)
        await load()
    }
}
