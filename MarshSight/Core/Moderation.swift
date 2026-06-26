import Foundation
import Combine

/// Stable anonymous per-install id, shared by contributions, reports, and blocks.
enum DeviceID {
    static var current: String {
        if let saved = UserDefaults.standard.string(forKey: "deviceId") { return saved }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: "deviceId")
        return id
    }
}

/// User-generated-content safety: report, block, and a basic word filter. Apple
/// requires all of these for apps that host UGC (Guideline 1.2). Reports above a
/// threshold auto-hide content server-side; blocks and local reports hide it on
/// this device immediately.
@MainActor
final class ModerationStore: ObservableObject {
    @Published private(set) var blockedAuthors: Set<String> = []
    @Published private(set) var reportedIDs: Set<String> = []

    private let blockedKey = "blockedAuthors"
    private let reportedKey = "reportedContentIDs"

    init() {
        blockedAuthors = Set(UserDefaults.standard.stringArray(forKey: blockedKey) ?? [])
        reportedIDs = Set(UserDefaults.standard.stringArray(forKey: reportedKey) ?? [])
    }

    func isBlocked(author: String?) -> Bool {
        guard let a = author, !a.isEmpty else { return false }
        return blockedAuthors.contains(a)
    }

    func isHidden(id: String?, author: String?) -> Bool {
        if let id, reportedIDs.contains(id) { return true }
        return isBlocked(author: author)
    }

    func block(author: String?) {
        guard let a = author, !a.isEmpty else { return }
        blockedAuthors.insert(a)
        UserDefaults.standard.set(Array(blockedAuthors), forKey: blockedKey)
    }

    func unblockAll() {
        blockedAuthors = []
        UserDefaults.standard.set([String](), forKey: blockedKey)
    }

    /// Report a post or community spot. Hides it locally right away and tells the
    /// server, which auto-hides it for everyone once enough people report it.
    func report(contentType: String, contentId: String, reason: String? = nil) {
        reportedIDs.insert(contentId)
        UserDefaults.standard.set(Array(reportedIDs), forKey: reportedKey)
        Task { await send(contentType: contentType, contentId: contentId, reason: reason) }
    }

    private func send(contentType: String, contentId: String, reason: String?) async {
        guard let url = URL(string: "\(PlatformAPI.baseURL)/v1/reports") else { return }
        var body: [String: Any] = [
            "contentType": contentType, "contentId": contentId,
            "reporterDevice": DeviceID.current,
        ]
        if let reason { body["reason"] = reason }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: req)
    }
}

/// A conservative client-side filter for the worst slurs/obscenities so they
/// never reach the network. The server and the report flow are the real backstop;
/// this just keeps obvious garbage out at the source.
enum ContentFilter {
    private static let blocked: [String] = [
        "fuck", "shit", "bitch", "cunt", "nigger", "nigga", "faggot", "fag",
        "retard", "rape", "kike", "spic", "chink", "whore", "slut",
    ]

    /// True if the text contains an obviously objectionable token.
    static func isObjectionable(_ text: String?) -> Bool {
        guard let text, !text.isEmpty else { return false }
        let lowered = text.lowercased()
        let words = lowered.split { !$0.isLetter }.map(String.init)
        let wordSet = Set(words)
        for bad in blocked where wordSet.contains(bad) { return true }
        // Catch glued-together forms too (e.g. inside a longer string).
        for bad in blocked where lowered.contains(bad) { return true }
        return false
    }
}
