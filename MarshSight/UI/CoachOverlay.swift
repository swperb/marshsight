import SwiftUI

/// A one-time, dismissible guide shown the first time the map appears. It names
/// every control so a brand-new hunter isn't staring at a wall of unlabeled
/// icons. Keyed by @AppStorage so it only shows once.
struct CoachOverlay: View {
    let onDismiss: () -> Void

    private let controls: [(String, String, String)] = [
        ("magnifyingglass", "Where to?", "Search a marina, ramp, or saved spot, then navigate"),
        ("square.stack.3d.up.fill", "Region (top-left)", "Tap to change or download your area for offline"),
        ("ellipsis", "Menu (top-right)", "Feed, Trophy Room, Logbook, Trail Cameras, Legend, Help"),
        ("globe.americas.fill", "Basemap", "Switch satellite, topo, or terrain"),
        ("square.3.layers.3d", "Layers", "Show/hide land, units, water, trails, scent cone, radar"),
        ("car", "Return", "Mark your truck, then get back to it or retrace your steps"),
        ("arrow.down.circle", "Download", "Save this area to use with no signal"),
        ("plus", "Report", "Drop a hazard, blind, feeder, camera, or tag an owner"),
        ("location.fill.viewfinder", "Recenter", "Snap back to your location"),
        ("camera.viewfinder", "Look Around in AR", "See boundaries and your spots in the live camera"),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Image(systemName: "hand.wave.fill").font(.largeTitle).foregroundStyle(.cyan)
                    Text("Welcome to your map").font(.title2.weight(.bold))
                    Text("Here's where everything lives.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 24).padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(controls, id: \.1) { c in
                            HStack(spacing: 14) {
                                Image(systemName: c.0).font(.system(size: 18))
                                    .foregroundStyle(.cyan).frame(width: 30)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(c.1).font(.subheadline.weight(.semibold))
                                    Text(c.2).font(.caption).foregroundStyle(.white.opacity(0.65))
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                }

                Button(action: onDismiss) {
                    Text("Got it").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(.cyan, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.black)
                }
                .padding(20)
            }
            .foregroundStyle(.white)
        }
    }
}
