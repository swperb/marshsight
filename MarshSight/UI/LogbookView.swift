import SwiftUI
import PhotosUI
import CoreLocation

/// The harvest and catch logbook: a list of past entries, each stamped with the
/// conditions at the time, plus a button to log a new one.
struct LogbookView: View {
    @ObservedObject var store: LogbookStore
    let coordinate: CLLocationCoordinate2D?
    let weather: Weather?
    let tideNote: String?

    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if store.entries.isEmpty {
                    empty
                } else {
                    List {
                        ForEach(store.entries) { entry in
                            row(entry)
                        }
                        .onDelete { idx in idx.map { store.entries[$0] }.forEach(store.delete) }
                    }
                }
            }
            .navigationTitle("Logbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) {
                LogEntrySheet(store: store, coordinate: coordinate, weather: weather, tideNote: tideNote)
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed").font(.system(size: 48)).foregroundStyle(.secondary)
            Text("No entries yet").font(.headline)
            Text("Log a harvest or catch and MarshSight stamps it with the location, weather, moon, and tide.")
                .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 40)
            Button { showAdd = true } label: {
                Label("Log one", systemImage: "plus").font(.headline)
            }.buttonStyle(.borderedProminent).padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(_ e: LogEntry) -> some View {
        HStack(spacing: 12) {
            if let f = e.photoFile, let img = UIImage(contentsOfFile: store.photoURL(f).path) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: 52, height: 52).clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: e.kind.icon).font(.title2).foregroundStyle(.green)
                    .frame(width: 52, height: 52).background(.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(e.kind.label).font(.headline)
                Text(e.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
                Text(conditions(e)).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func conditions(_ e: LogEntry) -> String {
        var parts: [String] = []
        if let t = e.tempF { parts.append("\(Int(t))°") }
        if let c = e.windCardinal, let w = e.windMph { parts.append("\(c) \(Int(w))mph") }
        if let m = e.moonPhase { parts.append(m) }
        if let tide = e.tideNote { parts.append(tide) }
        return parts.joined(separator: " · ")
    }
}

/// Form to record a new harvest or catch. Conditions are captured automatically.
struct LogEntrySheet: View {
    @ObservedObject var store: LogbookStore
    let coordinate: CLLocationCoordinate2D?
    let weather: Weather?
    let tideNote: String?

    @Environment(\.dismiss) private var dismiss
    @State private var kind: LogEntry.Kind = .deer
    @State private var note = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(LogEntry.Kind.allCases) { k in
                            Label(k.label, systemImage: k.icon).tag(k)
                        }
                    }
                    TextField("Notes (optional)", text: $note, axis: .vertical).lineLimit(1...4)
                }
                Section("Photo") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        if let d = photoData, let img = UIImage(data: d) {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(height: 160).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Label("Add a photo", systemImage: "camera")
                        }
                    }
                }
                Section("Captured conditions") {
                    if let w = weather {
                        labelRow("Weather", "\(Int(w.temperatureF))°, wind \(w.windFromCardinal) \(Int(w.windSpeedMph)) mph")
                    }
                    labelRow("Moon", MoonPhase.current().name)
                    if let tide = tideNote { labelRow("Tide", tide) }
                    labelRow("Location", coordinate == nil ? "Waiting for GPS" : "Current position")
                }
            }
            .navigationTitle("Log a harvest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(coordinate == nil)
                }
            }
            .onChange(of: photoItem) { _, item in
                Task { photoData = try? await item?.loadTransferable(type: Data.self) }
            }
        }
    }

    private func labelRow(_ title: String, _ value: String) -> some View {
        HStack { Text(title); Spacer(); Text(value).foregroundStyle(.secondary) }
    }

    private func save() {
        guard let c = coordinate else { return }
        let photoFile = photoData.flatMap { store.savePhoto($0) }
        let entry = LogEntry(
            kind: kind, note: note,
            latitude: c.latitude, longitude: c.longitude, date: Date(),
            photoFile: photoFile,
            tempF: weather?.temperatureF,
            windCardinal: weather?.windFromCardinal,
            windMph: weather?.windSpeedMph,
            moonPhase: MoonPhase.current().name,
            tideNote: tideNote)
        store.add(entry)
        dismiss()
    }
}
