import SwiftUI
import StoreKit

/// MarshSight+ upgrade screen. Sells the things that cost money to run, never the
/// public-data core. The Founder lifetime bootstraps the project and locks in
/// every premium feature as it ships.
struct PaywallView: View {
    @ObservedObject var store: PremiumStore
    @Environment(\.dismiss) private var dismiss
    @State private var working = false

    private let perks: [(String, String, String)] = [
        ("camera.fill", "Trail-camera sync", "Email your Moultrie, Spypoint, and more straight onto your map"),
        ("wind", "Scent cone & wind", "See your wind and scent drift right on the map before you set up"),
        ("brain.head.profile", "AI movement & bite forecasts", "On-device predictions from weather, moon, and tide"),
        ("icloud.fill", "Unlimited offline & cloud sync", "Download the whole flyway, back up your spots, sync every device"),
        ("leaf.fill", "Keep the core free for everyone", "Your support funds the open map the rest of us use free"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    VStack(spacing: 14) {
                        ForEach(perks, id: \.0) { perk in perkRow(perk) }
                    }
                    .padding(.horizontal, 4)
                    purchaseButtons
                    Button("Restore Purchases") { Task { await store.restore() } }
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("The map, public land, hunting units, water, trails, AR, and weather are free forever. MarshSight+ only unlocks the layers that cost money to run.")
                        .font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 12)
                }
                .padding(20)
            }
            .navigationTitle("MarshSight+")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Not now") { dismiss() } } }
            .onChange(of: store.isPremium) { _, premium in if premium { dismiss() } }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "scope")
                .font(.system(size: 50)).foregroundStyle(.cyan)
            Text("Back the open alternative")
                .font(.title2.weight(.bold)).multilineTextAlignment(.center)
            Text("Everything's unlocked and free during the beta. MarshSight+ is how you keep the map free for everyone and fund the layers below as they roll out.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Label("Beta: every feature is on right now — no wall", systemImage: "lock.open.fill")
                .font(.caption.weight(.semibold)).foregroundStyle(.green)
                .padding(.top, 2)
        }
    }

    private func perkRow(_ perk: (String, String, String)) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: perk.0).font(.title3).foregroundStyle(.cyan).frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(perk.1).font(.subheadline.weight(.semibold))
                Text(perk.2).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var purchaseButtons: some View {
        VStack(spacing: 10) {
            if let lifetime = store.products.first(where: { $0.id == PremiumStore.lifetimeID }) {
                Button { buy(lifetime) } label: {
                    planLabel(title: "Founder — Lifetime", price: lifetime.displayPrice,
                              sub: "One time, everything forever", highlight: true)
                }.disabled(working)
            }
            if let annual = store.products.first(where: { $0.id == PremiumStore.annualID }) {
                Button { buy(annual) } label: {
                    planLabel(title: "Annual", price: "\(annual.displayPrice)/yr",
                              sub: "Renews yearly, cancel anytime", highlight: false)
                }.disabled(working)
            }
            if store.products.isEmpty {
                Text("Plans aren't available yet — check back soon.")
                    .font(.footnote).foregroundStyle(.secondary).padding(.vertical, 8)
            }
        }
    }

    private func planLabel(title: String, price: String, sub: String, highlight: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(sub).font(.caption).foregroundStyle(highlight ? .black.opacity(0.7) : .secondary)
            }
            Spacer()
            Text(price).font(.headline.weight(.bold))
        }
        .foregroundStyle(highlight ? .black : .primary)
        .padding(14)
        .background(highlight ? AnyShapeStyle(.cyan) : AnyShapeStyle(.gray.opacity(0.15)),
                    in: RoundedRectangle(cornerRadius: 14))
    }

    private func buy(_ product: Product) {
        working = true
        Task { await store.purchase(product); working = false }
    }
}
