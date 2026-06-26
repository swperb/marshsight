import Foundation
import CoreLocation
import Combine

/// A logged harvest or catch, stamped with the conditions at the time: location,
/// weather, moon, and tide. Private to the device, and the seed of the
/// crowd-sourced dataset the platform can learn from later.
struct LogEntry: Identifiable, Codable {
    var id = UUID()
    var kind: Kind
    var note: String = ""
    var latitude: Double
    var longitude: Double
    var date: Date
    var photoFile: String?

    // Conditions captured automatically when logged.
    var tempF: Double?
    var windCardinal: String?
    var windMph: Double?
    var moonPhase: String?
    var tideNote: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case deer, duck, turkey, fish, small, other
        var id: String { rawValue }
        var label: String {
            switch self {
            case .deer: return "Deer"
            case .duck: return "Waterfowl"
            case .turkey: return "Turkey"
            case .fish: return "Fish"
            case .small: return "Small game"
            case .other: return "Other"
            }
        }
        var icon: String {
            switch self {
            case .deer: return "hare.fill"
            case .duck: return "bird.fill"
            case .turkey: return "bird"
            case .fish: return "fish.fill"
            case .small: return "tortoise.fill"
            case .other: return "scope"
            }
        }
    }
}

/// Stores logbook entries and their photos on the device, persisted to JSON.
@MainActor
final class LogbookStore: ObservableObject {
    @Published private(set) var entries: [LogEntry] = []

    init() { load() }

    func add(_ entry: LogEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(_ entry: LogEntry) {
        if let f = entry.photoFile { try? FileManager.default.removeItem(at: photoURL(f)) }
        entries.removeAll { $0.id == entry.id }
        save()
    }

    // MARK: - Photos

    private var dir: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }

    func photoURL(_ name: String) -> URL { dir.appendingPathComponent(name) }

    /// Persist photo bytes and return the stored filename.
    func savePhoto(_ data: Data) -> String? {
        let name = "log_\(UUID().uuidString).jpg"
        do { try data.write(to: photoURL(name), options: .atomic); return name }
        catch { return nil }
    }

    // MARK: - Persistence

    private var fileURL: URL { dir.appendingPathComponent("logbook.json") }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([LogEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
