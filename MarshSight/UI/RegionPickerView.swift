import SwiftUI
import MapKit
import CoreLocation

/// Pick a place (e.g. "Lay Lake"), download its offline map pack, or switch to
/// an already-downloaded region. This is what replaces loading everything at
/// once: you choose a bounded area and only that area is fetched and rendered.
struct RegionPickerView: View {
    @ObservedObject var store: RegionStore
    let currentLocation: CLLocationCoordinate2D?
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
                            Task { await store.download(name: "My Area", center: here) }
                        } label: {
                            Label("Download my current area", systemImage: "location.fill")
                        }
                        .disabled(store.isWorking)
                    }
                }

                if !store.saved.isEmpty {
                    Section("Downloaded regions") {
                        ForEach(store.saved) { region in
                            Button { store.activate(region.id); maybeDismiss() } label: {
                                HStack {
                                    Image(systemName: store.active?.id == region.id ? "checkmark.circle.fill" : "map")
                                        .foregroundStyle(store.active?.id == region.id ? .green : .secondary)
                                    Text(region.name)
                                    Spacer()
                                    Text(region.savedAt, style: .date)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { idx in idx.map { store.saved[$0].id }.forEach(store.delete) }
                    }
                }
            }
            .navigationTitle("Choose a Region")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if allowDismiss {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
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
