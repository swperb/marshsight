import SwiftUI

/// The trophy room: a gamified showcase of your logged harvests and catches -
/// stats, badges, and a photo grid. The retention hook, and (once sharing ships)
/// the front of the "Strava for hunting & fishing" social layer.
struct TrophyRoomView: View {
    @ObservedObject var store: LogbookStore
    @ObservedObject var feed: FeedStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("feedName") private var feedName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.entries.isEmpty {
                    empty
                } else {
                    VStack(spacing: 24) {
                        statsRow
                        badgesSection
                        trophiesSection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Trophy Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    // MARK: - Derived

    private var entries: [LogEntry] { store.entries }
    private var distinctKinds: Int { Set(entries.map { $0.kind }).count }
    private var thisYear: Int {
        let y = Calendar.current.component(.year, from: Date())
        return entries.filter { Calendar.current.component(.year, from: $0.date) == y }.count
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 0) {
            stat("\(entries.count)", "logged")
            divider
            stat("\(distinctKinds)", "species")
            divider
            stat("\(thisYear)", "this year")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.title.weight(.bold)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View { Rectangle().fill(.gray.opacity(0.25)).frame(width: 1, height: 34) }

    // MARK: - Badges

    private struct Badge: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let unlocked: Bool
    }

    private var badges: [Badge] {
        let kinds = Set(entries.map { $0.kind })
        let months = Set(entries.map { Calendar.current.component(.month, from: $0.date) })
        return [
            Badge(title: "First Entry", icon: "star.fill", unlocked: !entries.isEmpty),
            Badge(title: "Five Strong", icon: "5.circle.fill", unlocked: entries.count >= 5),
            Badge(title: "Full Freezer", icon: "snowflake", unlocked: entries.count >= 10),
            Badge(title: "Mixed Bag", icon: "square.grid.2x2.fill", unlocked: kinds.count >= 3),
            Badge(title: "Deer Down", icon: "hare.fill", unlocked: kinds.contains(.deer)),
            Badge(title: "Waterfowler", icon: "bird.fill", unlocked: kinds.contains(.duck)),
            Badge(title: "On the Fish", icon: "fish.fill", unlocked: kinds.contains(.fish)),
            Badge(title: "Longbeard", icon: "bird", unlocked: kinds.contains(.turkey)),
            Badge(title: "All Seasons", icon: "calendar", unlocked: months.count >= 4),
            Badge(title: "Picture Proof", icon: "photo.fill", unlocked: entries.contains { $0.photoFile != nil }),
        ]
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            let earned = badges.filter(\.unlocked).count
            Text("Badges  ·  \(earned)/\(badges.count)").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                ForEach(badges) { badge in
                    VStack(spacing: 6) {
                        Image(systemName: badge.icon)
                            .font(.title2)
                            .foregroundStyle(badge.unlocked ? .cyan : .gray.opacity(0.4))
                            .frame(width: 52, height: 52)
                            .background((badge.unlocked ? Color.cyan : .gray).opacity(0.15), in: Circle())
                        Text(badge.title)
                            .font(.caption2).multilineTextAlignment(.center)
                            .foregroundStyle(badge.unlocked ? .primary : .secondary)
                    }
                }
            }
        }
    }

    // MARK: - Trophies

    private var trophiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trophies").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                ForEach(entries) { trophyCard($0) }
            }
        }
    }

    private func trophyCard(_ e: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if let f = e.photoFile, let img = UIImage(contentsOfFile: store.photoURL(f).path) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Image(systemName: e.kind.icon).font(.system(size: 36)).foregroundStyle(.green)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.green.opacity(0.12))
                }
            }
            .frame(height: 120).frame(maxWidth: .infinity).clipped()
            VStack(alignment: .leading, spacing: 2) {
                Text(e.kind.label).font(.subheadline.weight(.semibold))
                Text(e.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(8)
        }
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button {
                Task { await feed.share(e, photoData: photoData(e), includeLocation: false, author: feedName.isEmpty ? nil : feedName) }
            } label: { Label("Share to Feed", systemImage: "square.and.arrow.up") }
            Button {
                Task { await feed.share(e, photoData: photoData(e), includeLocation: true, author: feedName.isEmpty ? nil : feedName) }
            } label: { Label("Share with location", systemImage: "mappin.and.ellipse") }
        }
    }

    private func photoData(_ e: LogEntry) -> Data? {
        guard let f = e.photoFile, let img = UIImage(contentsOfFile: store.photoURL(f).path) else { return nil }
        return img.compressedJPEG()
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill").font(.system(size: 48)).foregroundStyle(.cyan.opacity(0.6))
            Text("Your trophy room is empty").font(.headline)
            Text("Log a harvest or catch and it shows up here, with badges and stats as you go.")
                .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
}
