import SwiftUI

/// Explains what the dots, colors, and buttons on the map mean. Reached from the
/// map's "..." menu, so a new user can decode the screen at a glance.
struct LegendView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Map markers — tap any dot to act on it") {
                    dot("#30B0C7", "River gauge", "Live stage and flow")
                    dot("#22D3EE", "Saved spot", "A place you saved or shared")
                    dot("#22C55E", "Channel marker", "A marked channel or route point")
                    dot("#FF3B30", "Hazard", "A reported hazard")
                    dot("#FFD60A", "Launch / ramp", "A boat ramp or put-in")
                    dot("#FF9500", "Access point", "Access to land or water")
                    dot("#AF52DE", "Blind / stand", "A hunting blind or stand")
                }
                Section("Land & boundaries") {
                    swatch("#34C759", filled: true, "Public land — open access")
                    swatch("#30B0C7", filled: true, "Public land — restricted access")
                    swatch("#FF3B30", filled: true, "Public land — closed")
                    swatch("#A855F7", dashed: true, "Hunting unit boundary")
                    swatch("#F59E0B", "Private property line")
                }
                Section("Water") {
                    swatch("#4DA6FF", "River / creek")
                    swatch("#2E78D6", filled: true, "Lake or wide river")
                }
                Section("Trails & overlays") {
                    swatch("#E0903C", dashed: true, "Trail")
                    swatch("#FB923C", filled: true, "Scent cone — where deer smell you, downwind")
                }
                Section("Buttons on the right") {
                    button("map.fill", "Basemap", "Satellite, topo, or terrain")
                    button("square.3.layers.3d", "Layers", "Show or hide what's on the map")
                    button("car", "Return", "Back to your truck, or retrace your steps")
                    button("arrow.down.circle", "Download", "Save this area for offline use")
                    button("record.circle", "Record", "Record a GPS track")
                    button("plus", "Mark", "Drop a spot, hazard, blind, or ramp")
                    button("location.fill.viewfinder", "Recenter", "Snap the map back to you")
                }
            }
            .navigationTitle("Map Legend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func dot(_ hex: String, _ title: String, _ sub: String) -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color(hex: hex))
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(sub).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func swatch(_ hex: String, filled: Bool = false, dashed: Bool = false, _ title: String) -> some View {
        HStack(spacing: 12) {
            Group {
                if filled {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: hex).opacity(0.5))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: hex), lineWidth: 1.5))
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(hex: hex), style: StrokeStyle(lineWidth: 3, dash: dashed ? [4, 3] : []))
                        .frame(height: 3)
                }
            }
            .frame(width: 26, height: filled ? 18 : 12)
            Text(title)
        }
    }

    private func button(_ icon: String, _ title: String, _ sub: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 30, height: 30)
                .background(.black.opacity(0.7), in: Circle())
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(sub).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

extension Color {
    /// Build a Color from a "#RRGGBB" hex string.
    init(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(.sRGB,
                  red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255)
    }
}
