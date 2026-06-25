import SwiftUI
import MapKit
import CoreLocation

/// Pick a place (e.g. "Lay Lake"), download its offline map pack, or switch to
/// an already-downloaded region. This is what replaces loading everything at
/// once: you choose a bounded area and only that area is fetched and rendered.
struct RegionPickerView: View {
    @ObservedObject var store: RegionStore
    @ObservedObject var offline: OfflineManager
    let currentLocation: CLLocationCoordinate2D?
    var basemap: Basemap = .hybrid
    var allowDismiss: Bool = true

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [PlaceResult] = []
    @State private var searching = false

    struct PlaceResult: Identifiable {
        let id = UUID()
        let name: String
        let subtitle: String
        let coordinate: CLLocationCoordinate2D
    }

    var body: some View {
        NavigationStack {
            List {
                if store.isWorking {
                    Section {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(store.status ?? "Working...")
                        }
                    }
                }

                Section("Find a place") {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Lake, river, WMA, town...", text: $query)
                            .onSubmit { Task { await runSearch() } }
                        if searching { ProgressView() }
                    }
                    ForEach(results) { r in
                        Button { Task { await downloadPlace(r) } } label: {
                            VStack(alignment: .leading) {
                                Text(r.name).foregroundStyle(.primary)
                                if !r.subtitle.isEmpty {
                                    Text(r.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(store.isWorking)
                    }
                }

                if let here = currentLocation {
                    Section {
                        Button {
                            Task { await store.download(name: "", center: here) }
                        } label: {
                            Label("Download my current area", systemImage: "location.fill")
                        }
                        .disabled(store.isWorking)
                    }
                }

                if !store.saved.isEmpty {
                    Section {
                        ForEach(store.saved) { region in regionRow(region) }
                            .onDelete { idx in idx.map { store.saved[$0].id }.forEach(store.delete) }
                    } header: {
                        Text("Your regions")
                    } footer: {
                        Text("Each region's data (public land, water, parcels) is saved on your phone. Tap the cloud to also download its basemap tiles so the map works with no signal. Downloading again refreshes the tiles. Swipe a region to delete it.\(offline.totalMegabytes > 0 ? "\n\nOffline maps using \(sizeText(offline.totalMegabytes))." : "")")
                    }
                }
            }
            .navigationTitle("Regions & Offline Maps")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { offline.reload() }
            .toolbar {
                if allowDismiss {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }

    private func regionRow(_ region: RegionSummary) -> some View {
        let id = "\(region.name)|\(basemap.rawValue)"
        let map = offline.maps.first { $0.id == id }
        let downloading = offline.downloadingID == id
        return HStack {
            Button { store.activate(region.id); maybeDismiss() } label: {
                HStack(spacing: 10) {
                    Image(systemName: store.active?.id == region.id ? "checkmark.circle.fill" : "map")
                        .foregroundStyle(store.active?.id == region.id ? .green : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(region.name).foregroundStyle(.primary)
                        if let map, map.isComplete {
                            Label("Offline · \(sizeText(map.megabytes))", systemImage: "wifi.slash")
                                .font(.caption2).foregroundStyle(.green)
                        } else {
                            Text(region.savedAt, style: .date).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            if downloading {
                HStack(spacing: 6) {
                    ProgressView()
                    Text("\(Int((map?.progress ?? 0) * 100))%").font(.caption).foregroundStyle(.secondary)
                }
            } else if let map, map.isComplete {
                Button(role: .destructive) { offline.delete(map) } label: {
                    Image(systemName: "trash")
                }.buttonStyle(.borderless)
            } else {
                Button {
                    offline.download(regionName: region.name,
                                     center: CLLocationCoordinate2D(latitude: region.centerLat, longitude: region.centerLon),
                                     basemap: basemap)
                } label: {
                    Image(systemName: "arrow.down.circle").font(.title3)
                }.buttonStyle(.borderless)
            }
        }
    }

    private func sizeText(_ mb: Double) -> String {
        mb < 1 ? String(format: "%.0f KB", mb * 1000) : String(format: "%.0f MB", mb)
    }

    private func runSearch() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return }
        searching = true
        defer { searching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = q
        if let here = currentLocation {
            request.region = MKCoordinateRegion(center: here,
                                                span: MKCoordinateSpan(latitudeDelta: 3, longitudeDelta: 3))
        }
        guard let response = try? await MKLocalSearch(request: request).start() else {
            results = []
            return
        }
        results = response.mapItems.prefix(8).map { item in
            PlaceResult(
                name: item.name ?? "Unknown",
                subtitle: [item.placemark.locality, item.placemark.administrativeArea]
                    .compactMap { $0 }.joined(separator: ", "),
                coordinate: item.placemark.coordinate
            )
        }
    }

    private func downloadPlace(_ r: PlaceResult) async {
        await store.download(name: r.name, center: r.coordinate)
        maybeDismiss()
    }

    private func maybeDismiss() {
        if allowDismiss && store.active != nil { dismiss() }
    }
}
