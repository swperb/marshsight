import StoreKit
import Combine

/// A capability that MarshSight+ unlocks. The core app (map, nav, AR, public
/// land/units/water, weather, community owner-tags) is never a PremiumFeature.
enum PremiumFeature {
    case trailCameras       // camera inbox, markers, photos
    case forecasts          // AI movement/bite forecasts + scent/wind cone
    case unlimitedOffline   // unlimited offline regions + cloud sync
}

/// Manages the MarshSight+ entitlement via StoreKit 2. The core app is free
/// forever; this gates only the things that cost real money to provide (cloud
/// sync, trail-camera ingest, ML forecasts). One cheap annual subscription plus
/// a one-time Founder lifetime.
@MainActor
final class PremiumStore: ObservableObject {
    @Published private(set) var isPremium = false
    @Published private(set) var products: [Product] = []
    /// Master switch. While false (the beta), every premium feature stays open
    /// for everyone. Flip to true once IAP is live in App Store Connect.
    @Published var gatingEnabled = UserDefaults.standard.bool(forKey: "gatingEnabled")

    static let annualID = "com.marshsight.premium.annual"
    static let lifetimeID = "com.marshsight.premium.lifetime"
    private let ids = [annualID, lifetimeID]

    /// True if this feature should be locked for the current user right now.
    func locked(_ feature: PremiumFeature) -> Bool {
        gatingEnabled && !isPremium
    }

    private var updates: Task<Void, Never>?

    init() {
        updates = listenForTransactions()
        Task {
            await load()
            await refreshEntitlements()
        }
    }

    deinit { updates?.cancel() }

    func load() async {
        let fetched = (try? await Product.products(for: ids)) ?? []
        products = fetched.sorted { $0.price < $1.price }
    }

    /// Returns true if the purchase completed and the entitlement is now active.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        guard let result = try? await product.purchase() else { return false }
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                await refreshEntitlements()
                return isPremium
            }
            return false
        default:
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, ids.contains(t.productID), t.revocationDate == nil {
                active = true
            }
        }
        isPremium = active
    }

    /// Display price for a product id, e.g. "$24.99".
    func price(_ id: String) -> String? {
        products.first { $0.id == id }?.displayPrice
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result { await t.finish() }
                await self?.refreshEntitlements()
            }
        }
    }
}
