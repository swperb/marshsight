import SwiftUI
import MapKit
import CoreLocation

/// "Take me to Little Tom's Marina." Search a place, save it as a named
/// community spot (shared and reviewed by votes), or pick an existing spot
/// (works offline). Choosing one starts navigation.
struct DestinationSearchView: View {
    let center: CLLocationCoordinate2D?
    @ObservedObject var contributions: ContributionStore
    @ObservedObject var moderation: ModerationStore
    let extraSpots: [MarkerFeature]      // gauges / region markers (navigable)
    var onSelect: (NavDestination) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var reportTarget: Contribution?
    @State private var results: [Result] = []
    @State private var searching = false
    @State private var drivePreview: NavDestination?

    struct Result: Identifiable {
        let id = UUID()
        let name: String
        let subtitle: String
        let coordinate: CLLocationCoordinate2D
    }

    var body: some View {
        NavigationStack {
            List {
                searchSection
                if !communitySpots.isEmpty { communitySection }
                if !nearbyMarkers.isEmpty { nearbySection }
            }
            .navigationTitle("Where to?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .sheet(item: $drivePreview) { dest in
                DrivePreviewView(destination: dest, origin: center)
            }
            .confirmationDialog("Report this spot?",
                                isPresented: Binding(get: { reportTarget != nil },
                                                     set: { if !$0 { reportTarget = nil } }),
                                titleVisibility: .visible) {
                Button("Report as inaccurate or objectionable", role: .destructive) {
                    if let s = reportTarget { moderation.report(contentType: "contribution", contentId: s.id) }
                    reportTarget = nil
                }
                Button("Cancel", role: .cancel) { reportTarget = nil }
            } message: {
                Text("Reported spots are reviewed and removed within 24 hours if they break the rules.")
            }
        }
    }

    /// Preview the drive to a place, then optionally hand off to Apple Maps.
    private func driveButton(_ name: String, _ coord: CLLocationCoordinate2D) -> some View {
        Button {
            drivePreview = NavDestination(name: name, latitude: coord.latitude, longitude: coord.longitude)
        } label: {
            Image(systemName: "car.fill").font(.title3).foregroundStyle(.cyan)
        }
        .buttonStyle(.borderless)
        .help("Preview the drive")
    }

    // MARK: - Sections

    private var searchSection: some View {
        Section {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Marina, ramp, sandbar, spot...", text: $query)
                    .onSubmit { Task { await search() } }
                    .submitLabel(.search)
                if searching { ProgressView() }
            }
            ForEach(results) { r in
                HStack {
                    Button { choose(r.name, r.coordinate) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.name).foregroundStyle(.primary)
                            if !r.subtitle.isEmpty {
                                Text(r.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }.buttonStyle(.plain)
                    Spacer()
                    driveButton(r.name, r.coordinate)
                    Button { contributions.saveSpot(name: r.name, at: r.coordinate) } label: {
                        Image(systemName: "plus.circle").font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .help("Save as community spot")
                }
            }
        } footer: {
            if !results.isEmpty {
                Text("Tap a result to navigate, or + to save it as a community spot others can find and verify.")
            }
        }
    }

    private var communitySection: some View {
        Section("Community & saved spots (offline)") {
            ForEach(communitySpots) { spot in
                HStack(spacing: 10) {
                    Button { choose(spot.name, spot.coordinate) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: spot.kind.markerKind.symbol)
                                .foregroundStyle(spot.kind.markerKind.tint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(spot.name).foregroundStyle(.primary)
                                statusBadge(spot)
                            }
                        }
                    }.buttonStyle(.plain)
                    Spacer()
                    driveButton(spot.name, spot.coordinate)
                    voteControl(spot)
                }
                .contextMenu {
                    Button(role: .destructive) { reportTarget = spot } label: {
                        Label("Report this spot", systemImage: "flag")
                    }
                }
            }
        }
    }

    private var nearbySection: some View {
        Section("Nearby") {
            ForEach(nearbyMarkers) { spot in
                HStack {
                    Button { choose(spot.name, spot.coordinate) } label: {
                        Label {
                            Text(spot.name)
                        } icon: {
                            Image(systemName: spot.kind.symbol).foregroundStyle(spot.kind.tint)
                        }
                    }.buttonStyle(.plain)
                    Spacer()
                    driveButton(spot.name, spot.coordinate)
                }
            }
        }
    }

    private func statusBadge(_ spot: Contribution) -> some View {
        HStack(spacing: 5) {
            if spot.isVerified {
                Label("Verified", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
            } else {
                Label("Pending review", systemImage: "clock").foregroundStyle(.orange)
            }
            Text("· \(spot.score)").foregroundStyle(.secondary)
        }
        .font(.caption2)
    }

    private func voteControl(_ spot: Contribution) -> some View {
        HStack(spacing: 14) {
            Button { contributions.vote(spot, 1) } label: {
                Image(systemName: spot.myVote == 1 ? "arrow.up.circle.fill" : "arrow.up.circle")
                    .foregroundStyle(spot.myVote == 1 ? .green : .secondary)
            }
            Button { contributions.vote(spot, -1) } label: {
                Image(systemName: spot.myVote == -1 ? "arrow.down.circle.fill" : "arrow.down.circle")
                    .foregroundStyle(spot.myVote == -1 ? .red : .secondary)
            }
        }
        .font(.title3)
        .buttonStyle(.borderless)
    }

    // MARK: - Data

    private var communitySpots: [Contribution] {
        let q = query.trimmingCharacters(in: .whitespaces)
        let base = contributions.allSpots.filter { !moderation.isHidden(id: $0.id, author: nil) }
        let matched = q.isEmpty ? base
            : base.filter { $0.name.localizedCaseInsensitiveContains(q) }
        guard let c = center else { return matched }
        return matched.sorted { GeoMath.distance($0.coordinate, c) < GeoMath.distance($1.coordinate, c) }
    }

    private var nearbyMarkers: [MarkerFeature] {
        let q = query.trimmingCharacters(in: .whitespaces)
        let matched = q.isEmpty ? extraSpots : extraSpots.filter { $0.name.localizedCaseInsensitiveContains(q) }
        guard let c = center else { return matched }
        return matched.sorted { GeoMath.distance($0.coordinate, c) < GeoMath.distance($1.coordinate, c) }
    }

    private func choose(_ name: String, _ coord: CLLocationCoordinate2D) {
        onSelect(NavDestination(name: name, latitude: coord.latitude, longitude: coord.longitude))
        dismiss()
    }

    private func search() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return }
        searching = true
        defer { searching = false }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = q
        if let c = center {
            request.region = MKCoordinateRegion(center: c,
                                                span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.6))
        }
        guard let response = try? await MKLocalSearch(request: request).start() else { results = []; return }
        results = response.mapItems.prefix(10).map { item in
            Result(name: item.name ?? "Place",
                   subtitle: [item.placemark.locality, item.placemark.administrativeArea]
                       .compactMap { $0 }.joined(separator: ", "),
                   coordinate: item.placemark.coordinate)
        }
    }
}
