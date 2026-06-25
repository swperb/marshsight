import SwiftUI
import MapKit
import CoreLocation

/// "Take me to Little Tom's Marina." Search a place by name, or pick a saved
/// crowd-sourced spot (works offline). Choosing one starts navigation: a blue
/// trackline and a waypoint arrow guide you there on the map and in AR.
struct DestinationSearchView: View {
    let center: CLLocationCoordinate2D?
    let spots: [MarkerFeature]          // crowd-sourced + region markers, offline
    var onSelect: (NavDestination) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [Result] = []
    @State private var searching = false

    struct Result: Identifiable {
        let id = UUID()
        let name: String
        let subtitle: String
        let coordinate: CLLocationCoordinate2D
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Marina, ramp, sandbar, spot...", text: $query)
                            .onSubmit { Task { await search() } }
                            .submitLabel(.search)
                        if searching { ProgressView() }
                    }
                    ForEach(results) { r in
                        Button { choose(name: r.name, r.coordinate) } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.name).foregroundStyle(.primary)
                                if !r.subtitle.isEmpty {
                                    Text(r.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if !nearbySpots.isEmpty {
                    Section("Saved spots (offline)") {
                        ForEach(nearbySpots) { spot in
                            Button { choose(name: spot.name, spot.coordinate) } label: {
                                Label {
                                    Text(spot.name)
                                    if let d = distanceText(to: spot.coordinate) {
                                        Text("  \(d)").font(.caption).foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: spot.kind.symbol).foregroundStyle(spot.kind.tint)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Where to?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private var nearbySpots: [MarkerFeature] {
        guard let c = center else { return spots }
        return spots.sorted { GeoMath.distance($0.coordinate, c) < GeoMath.distance($1.coordinate, c) }
    }

    private func choose(name: String, _ coord: CLLocationCoordinate2D) {
        onSelect(NavDestination(name: name, latitude: coord.latitude, longitude: coord.longitude))
        dismiss()
    }

    private func distanceText(to coord: CLLocationCoordinate2D) -> String? {
        guard let c = center else { return nil }
        let mi = GeoMath.distance(c, coord) / 1609.344
        return mi < 0.2 ? String(format: "%.0f yd", mi * 1760) : String(format: "%.1f mi", mi)
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
