import SwiftUI
import UIKit

/// A branded, shareable image of a harvest or catch - the viral engine. A user
/// taps "Share Card" and gets a clean image (photo + species + conditions +
/// MarshSight mark) they can post to a group chat or Facebook, which doubles as
/// an ad for the app. Rendered at 1080x1350 (portrait, social-friendly).
struct ShareCardView: View {
    let entry: LogEntry
    let photo: UIImage?
    let author: String

    private var conditions: String {
        var parts: [String] = []
        if let t = entry.tempF { parts.append("\(Int(t))°") }
        if let w = entry.windCardinal { parts.append("Wind \(w)") }
        if let m = entry.moonPhase { parts.append(m) }
        return parts.joined(separator: "   ·   ")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Hero
            if let photo {
                Image(uiImage: photo).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [Color(hex: "0E4A42"), Color(hex: "071A18")],
                               startPoint: .top, endPoint: .bottom)
                Image(systemName: entry.kind.icon)
                    .font(.system(size: 300, weight: .regular))
                    .foregroundStyle(.white.opacity(0.12))
            }

            // Scrim for legibility
            LinearGradient(colors: [.clear, .black.opacity(0.25), .black.opacity(0.88)],
                           startPoint: .center, endPoint: .bottom)

            // Footer
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text(headline)
                        .font(.system(size: 84, weight: .heavy, design: .default))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
                if !conditions.isEmpty {
                    Text(conditions)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color(hex: "9FE0E6"))
                }
                Rectangle().fill(.white.opacity(0.18)).frame(height: 2).padding(.vertical, 4)
                HStack(spacing: 16) {
                    brandMark
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MarshSight").font(.system(size: 40, weight: .bold)).foregroundStyle(.white)
                        Text("Free hunting & fishing map  ·  marshsight.com")
                            .font(.system(size: 28, weight: .medium)).foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }
            }
            .padding(64)
        }
        .frame(width: 1080, height: 1350)
        .clipped()
    }

    private var headline: String {
        let a = author.trimmingCharacters(in: .whitespaces)
        return a.isEmpty ? entry.kind.label : "\(a)'s \(entry.kind.label)"
    }

    private var brandMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(Color(hex: "13212B")).frame(width: 76, height: 76)
            Image(systemName: "hexagon").font(.system(size: 40, weight: .regular)).foregroundStyle(Color(hex: "EDE8DC"))
            Circle().fill(Color(hex: "5BC4E0")).frame(width: 18, height: 18)
        }
    }
}

/// Rasterize a share card to a UIImage for the system share sheet.
@MainActor
func renderShareCard(entry: LogEntry, photo: UIImage?, author: String) -> UIImage? {
    let renderer = ImageRenderer(content: ShareCardView(entry: entry, photo: photo, author: author))
    renderer.scale = 1   // the view is already sized at 1080x1350 points
    return renderer.uiImage
}

/// Wraps a rendered card so it can drive `.sheet(item:)`.
struct ShareCardItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Presents the system share sheet (Messages, Facebook, save to Photos, etc.).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
