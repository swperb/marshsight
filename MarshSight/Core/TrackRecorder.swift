import Foundation
import CoreLocation
import Combine

/// Records a GPS track to a session you can save and export as GPX, the
/// standard interchange format. Independent of the always-on breadcrumb so a
/// hunt or float can be captured deliberately and shared.
@MainActor
final class TrackRecorder: ObservableObject {

    struct Point { var coordinate: CLLocationCoordinate2D; var time: Date }

    @Published private(set) var isRecording = false
    @Published private(set) var points: [Point] = []

    var hasTrack: Bool { points.count > 1 }

    var distanceMiles: Double {
        guard points.count > 1 else { return 0 }
        var meters = 0.0
        for i in 1..<points.count {
            meters += GeoMath.distance(points[i - 1].coordinate, points[i].coordinate)
        }
        return meters / 1609.344
    }

    func start() {
        points.removeAll()
        isRecording = true
    }

    func stop() {
        isRecording = false
    }

    /// Feed a fresh fix in; only stored while recording and once moved a bit.
    func record(_ fix: NavFix) {
        guard isRecording else { return }
        if let last = points.last, GeoMath.distance(last.coordinate, fix.coordinate) < 2 { return }
        points.append(Point(coordinate: fix.coordinate, time: fix.timestamp))
    }

    /// Write the current track to a GPX file and return its URL for sharing.
    func exportGPX() -> URL? {
        guard hasTrack else { return nil }
        let iso = ISO8601DateFormatter()
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="MarshSight" xmlns="http://www.topografix.com/GPX/1/1">
        <trk><name>MarshSight Track</name><trkseg>
        """
        for p in points {
            gpx += "\n<trkpt lat=\"\(p.coordinate.latitude)\" lon=\"\(p.coordinate.longitude)\">"
            gpx += "<time>\(iso.string(from: p.time))</time></trkpt>"
        }
        gpx += "\n</trkseg></trk></gpx>\n"

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("MarshSight-Track.gpx")
        do {
            try gpx.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
