import Foundation
import CoreLocation
import SwiftUI

/// Public access classification from PAD-US `Pub_Access`.
enum PublicAccess: String {
    case open = "OA"        // open access
    case restricted = "RA"  // restricted (permit, seasonal, WMA rules)
    case closed = "XA"      // closed to public
    case unknown = "UK"

    init(code: String?) { self = PublicAccess(rawValue: code ?? "UK") ?? .unknown }

    var label: String {
        switch self {
        case .open: return "Open Access"
        case .restricted: return "Restricted Access"
        case .closed: return "Closed"
        case .unknown: return "Access Unknown"
        }
    }

    var color: Color {
        switch self {
        case .open: return .green
        case .restricted: return .teal
        case .closed: return .red
        case .unknown: return .gray
        }
    }
}

/// A public-land unit from PAD-US: a WMA, national forest, refuge, etc., with
/// its boundary rings, managing agency, and public access status. This is the
/// core onX hunting layer, rebuilt on free federal data.
struct PublicLand: Identifiable, Equatable {
    let id: Int                                 // PAD-US OBJECTID
    let name: String                            // Unit_Nm
    let managerCode: String                     // Mang_Name (coded)
    let access: PublicAccess
    let rings: [[CLLocationCoordinate2D]]        // polygon rings, WGS84

    static func == (lhs: PublicLand, rhs: PublicLand) -> Bool { lhs.id == rhs.id }

    /// Human-readable managing agency from the PAD-US manager code.
    var manager: String {
        switch managerCode {
        case "FWS": return "US Fish & Wildlife Service"
        case "NPS": return "National Park Service"
        case "USFS": return "US Forest Service"
        case "BLM": return "Bureau of Land Management"
        case "USBR": return "Bureau of Reclamation"
        case "TVA": return "Tennessee Valley Authority"
        case "USACE": return "US Army Corps of Engineers"
        case "DOD": return "Department of Defense"
        case "SFW": return "State Fish & Wildlife"
        case "SPR": return "State Park & Recreation"
        case "SLB": return "State Land Board"
        case "STAT", "SDOL", "SDC": return "State"
        case "CITY", "CNTY", "REG": return "City / County"
        case "JNT": return "Joint"
        case "NGO", "PVT": return "Private / NGO"
        case "TRIB": return "Tribal"
        default: return managerCode
        }
    }

    /// Does `coordinate` fall inside this unit (any ring)?
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        rings.contains { GeoMath.pointInPolygon(coordinate, ring: $0) }
    }
}
