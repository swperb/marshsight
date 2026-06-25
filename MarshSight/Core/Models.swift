import Foundation
import CoreLocation
import SwiftUI

/// A navigation feature placed in the world. Kept deliberately generic so the
/// same engine serves duck-boat, deer-hunter, and fisherman profiles later.
struct MarkerFeature: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable {
        case waypoint        // a point on the planned route
        case channelMarker   // navigational aid (buoy, daymark)
        case hazard          // stump field, sandbar, snag, shallow
        case launch          // boat ramp / put-in, the "home" point
        case access          // public access boundary point of interest
        case blind           // duck blind or stand
        case gauge           // live USGS river/lake gauge (stage, discharge)

        var symbol: String {
            switch self {
            case .waypoint: return "flag.fill"
            case .channelMarker: return "triangle.fill"
            case .hazard: return "exclamationmark.triangle.fill"
            case .launch: return "house.fill"
            case .access: return "mappin.and.ellipse"
            case .blind: return "scope"
            case .gauge: return "gauge.with.dots.needle.bottom.50percent"
            }
        }

        var tint: Color {
            switch self {
            case .waypoint: return .cyan
            case .channelMarker: return .green
            case .hazard: return .red
            case .launch: return .yellow
            case .access: return .orange
            case .blind: return .purple
            case .gauge: return .teal
            }
        }
    }

    var id: UUID
    var kind: Kind
    var name: String
    var latitude: Double
    var longitude: Double
    /// Optional charted water depth in feet at this point.
    var depthFeet: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(id: UUID = UUID(), kind: Kind, name: String,
         latitude: Double, longitude: Double, depthFeet: Double? = nil) {
        self.id = id
        self.kind = kind
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.depthFeet = depthFeet
    }
}

/// An ordered route the boat is following, plus loose features (hazards, markers).
struct NavRoute: Codable {
    var name: String
    var features: [MarkerFeature]

    /// Ordered route points only, in travel order.
    var waypoints: [MarkerFeature] {
        features.filter { $0.kind == .waypoint }
    }

    var launch: MarkerFeature? {
        features.first { $0.kind == .launch }
    }
}

/// Live snapshot of where the user is. Heading is published separately by the
/// location provider so that turning the phone (heading-only updates) does not
/// retrigger the coordinate-dependent work (land lookups, AR sync).
struct NavFix: Equatable {
    var coordinate: CLLocationCoordinate2D
    var speedMetersPerSecond: Double
    var horizontalAccuracy: Double  // meters, lower is better
    var timestamp: Date

    static func == (lhs: NavFix, rhs: NavFix) -> Bool {
        lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.timestamp == rhs.timestamp
    }
}
