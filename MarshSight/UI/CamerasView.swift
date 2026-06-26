import SwiftUI
import Combine

/// A trail-camera photo ingested by email.
struct CameraPhoto: Identifiable, Decodable {
    var id: String
    var photoUrl: String
    var cameraName: String?
    var createdAt: String?
    enum CodingKeys: String, CodingKey {
        case id
        case photoUrl = "photo_url"
        case cameraName = "camera_name"
        case createdAt = "created_at"
    }
}

@MainActor
final class CameraStore: ObservableObject {
    @Published private(set) var photos: [CameraPhoto] = []
    @Published private(set) var loading = false

    private struct Response: Decodable { let photos: [CameraPhoto] }

    func load(code: String) async {
        guard !code.isEmpty,
              let url = URL(string: "\(PlatformAPI.baseURL)/v1/cameras?code=\(code)") else { return }
        loading = true
        defer { loading = false }
        guard let (data, resp) = try? await URLSession.shared.data(from: url),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode(Response.self, from: data) else { return }
        photos = decoded.photos
    }
}

/// Grid of your trail-camera photos, newest first. Fed by the email inbox.
struct CamerasView: View {
    let code: String
    @StateObject private var store = CameraStore()
    @Environment(\.dismiss) private var dismiss

    private let cols = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.photos.isEmpty {
                    empty
                } else {
                    LazyVGrid(columns: cols, spacing: 8) {
                        ForEach(store.photos) { photo in card(photo) }
                    }
                    .padding(8)
                }
            }
            .navigationTitle("Trail Cameras")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task { await store.load(code: code) }
            .refreshable { await store.load(code: code) }
        }
    }

    private func card(_ p: CameraPhoto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: p.photoUrl)) { img in
                img.resizable().scaledToFill()
            } placeholder: { Color.gray.opacity(0.15) }
                .frame(height: 150).frame(maxWidth: .infinity).clipped()
            if let name = p.cameraName, !name.isEmpty {
                Text(name).font(.caption.weight(.semibold)).lineLimit(1).padding(8)
            }
        }
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.badge.clock").font(.system(size: 44)).foregroundStyle(.blue.opacity(0.6))
            Text("No camera photos yet").font(.headline)
            Text("Once you forward your trail-camera alerts to your inbox address, photos show up here.")
                .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
}
