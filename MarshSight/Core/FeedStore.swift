import Foundation
import UIKit
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

    /// Share a logbook entry to the feed. `includeLocation` defaults off; the
    /// photo (if any) is downscaled and uploaded with the post.
    func share(_ entry: LogEntry, photoData: Data?, includeLocation: Bool, author: String?) async {
        guard let url = URL(string: "\(PlatformAPI.baseURL)/v1/posts") else { return }
        var body: [String: Any] = ["kind": entry.kind.rawValue]
        if !entry.note.isEmpty { body["note"] = entry.note }
        if includeLocation { body["lat"] = entry.latitude; body["lon"] = entry.longitude }
        if let t = entry.tempF { body["tempF"] = t }
        if let w = entry.windCardinal { body["wind"] = w }
        if let m = entry.moonPhase { body["moon"] = m }
        if let a = author, !a.isEmpty { body["author"] = a }
        if let photoData { body["photoBase64"] = "data:image/jpeg;base64,\(photoData.base64EncodedString())" }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: req)
        await load()
    }
}

extension UIImage {
    /// A downscaled JPEG suitable for upload (keeps payloads small).
    func compressedJPEG(maxDimension: CGFloat = 1200, quality: CGFloat = 0.7) -> Data? {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return jpegData(compressionQuality: quality) }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let img = UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        return img.jpegData(compressionQuality: quality)
    }
}
