import Foundation

/// Shared, consistent distance formatting in US units, used by the map and the
/// AR HUD so they never disagree (feet up close, miles once it's far).
enum Fmt {
    static func distance(_ meters: Double) -> String {
        let miles = meters / 1609.344
        if miles >= 0.1 {
            return miles >= 10 ? String(format: "%.0f mi", miles) : String(format: "%.1f mi", miles)
        }
        let feet = (meters * 3.28084 / 10).rounded() * 10   // nearest 10 ft
        return "\(Int(feet)) ft"
    }
}
