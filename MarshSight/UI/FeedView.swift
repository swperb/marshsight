import SwiftUI

/// The community feed: harvests and catches shared by other hunters and anglers.
/// Optional location, conditions auto-stamped. The social front of MarshSight.
struct FeedView: View {
    @ObservedObject var store: FeedStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.posts.isEmpty {
                    empty
                } else {
                    List(store.posts) { row($0) }
                        .listStyle(.plain)
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task { await store.load() }
            .refreshable { await store.load() }
        }
    }

    private func row(_ p: FeedPost) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon(p.kind)).font(.title3).foregroundStyle(.cyan)
                    .frame(width: 34, height: 34).background(.cyan.opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text(p.author?.isEmpty == false ? p.author! : "A hunter").font(.subheadline.weight(.semibold))
                    Text("\(label(p.kind))\(p.lat != nil ? "" : "  ·  location hidden")")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(relative(p.createdAt)).font(.caption2).foregroundStyle(.secondary)
            }
            if let url = p.photoUrl, let u = URL(string: url) {
                AsyncImage(url: u) { img in img.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.15) }
                    .frame(height: 180).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            if let note = p.note, !note.isEmpty {
                Text(note).font(.callout)
            }
            if let cond = conditions(p) {
                Text(cond).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func conditions(_ p: FeedPost) -> String? {
        var parts: [String] = []
        if let t = p.tempF { parts.append("\(Int(t))°") }
        if let w = p.wind { parts.append("wind \(w)") }
        if let m = p.moon { parts.append(m) }
        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }

    private func label(_ kind: String) -> String { LogEntry.Kind(rawValue: kind)?.label ?? kind.capitalized }
    private func icon(_ kind: String) -> String { LogEntry.Kind(rawValue: kind)?.icon ?? "scope" }

    private func relative(_ iso: String?) -> String {
        guard let iso, let date = ISO8601DateFormatter().date(from: iso) else { return "" }
        return date.formatted(.relative(presentation: .named))
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill").font(.system(size: 44)).foregroundStyle(.cyan.opacity(0.6))
            Text("The feed is quiet").font(.headline)
            Text("Share a harvest or catch from your logbook and it shows up here for the community.")
                .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
}
