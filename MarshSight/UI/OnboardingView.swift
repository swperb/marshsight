import SwiftUI

/// First-launch onboarding: a few paged screens that explain what MarshSight is,
/// how to use it, prime the Location permission, and fold in the safety
/// acknowledgement. Shown until the user taps through; the camera permission is
/// requested later, the first time they open AR.
struct OnboardingView: View {
    @ObservedObject var location: LocationProvider
    let onAccept: () -> Void

    @State private var page = 0
    private let lastPage = 3

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcome.tag(0)
                features.tag(1)
                howTo.tag(2)
                safety.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: next) {
                Text(page == lastPage ? "I Understand, Get Started" : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(page == lastPage ? Color.yellow : Color.cyan,
                                in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
    }

    private func next() {
        if page < lastPage {
            withAnimation { page += 1 }
        } else {
            location.start()   // triggers the system Location prompt
            onAccept()
        }
    }

    // MARK: - Pages

    private var welcome: some View {
        page(icon: "scope", tint: .cyan, title: "MarshSight",
             subtitle: "Your hunt and your water, in augmented reality.") {
            Text("A free, offline-capable map of public land, water, and hunting boundaries, built entirely on public government data. No subscription, no account.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 8)
        }
    }

    private var features: some View {
        page(icon: "map.fill", tint: .green, title: "What you get") {
            VStack(alignment: .leading, spacing: 14) {
                bullet("map.fill", "Public land, private property lines, trails, and the full water network down to creeks and ponds.")
                bullet("scope", "Hunting units for 47 states plus federal refuges, so you know which zone you're standing in.")
                bullet("camera.viewfinder", "An augmented-reality view that paints your route and boundaries onto the real world.")
                bullet("wifi.slash", "Download a region once and use it with no signal in the field.")
            }
        }
    }

    private var howTo: some View {
        page(icon: "hand.point.up.left.fill", tint: .cyan, title: "How to use it") {
            VStack(alignment: .leading, spacing: 14) {
                bullet("1.circle.fill", "Download your area so the map works offline.")
                bullet("2.circle.fill", "Tap \"Where to?\" to navigate to a marina, ramp, or saved spot. Follow the blue trackline.")
                bullet("3.circle.fill", "Tap \"Look Around in AR\" to see your route in the camera view.")
                bullet("4.circle.fill", "Save and share spots, and report anything from the menu.")
            }
        }
    }

    private var safety: some View {
        page(icon: "exclamationmark.shield.fill", tint: .yellow, title: "Before you head out") {
            VStack(alignment: .leading, spacing: 12) {
                bullet("circle.fill", "MarshSight is a navigation aid, not an authority. GPS and compass have real error, especially over open water and under cover.", small: true)
                bullet("circle.fill", "Always verify land access, boundaries, regulations, and hazards yourself. Data can be out of date or wrong.", small: true)
                bullet("circle.fill", "Carry a backup, watch the water and weather, and use your own judgment.", small: true)
                Text("Next, we'll ask for your location so the map can place you. The camera is only used later, when you open AR.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Building blocks

    private func page<Content: View>(icon: String, tint: Color, title: String,
                                     subtitle: String? = nil,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 18) {
            Spacer(minLength: 24)
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(tint)
            Text(title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 16)
            }
            content()
                .padding(.horizontal, 28)
            Spacer(minLength: 40)
        }
        .padding(.top, 20)
    }

    private func bullet(_ icon: String, _ text: String, small: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(small ? .system(size: 7) : .body)
                .foregroundStyle(small ? .yellow : .cyan)
                .frame(width: 22)
                .padding(.top, small ? 7 : 1)
            Text(text)
                .font(small ? .callout : .body)
                .foregroundStyle(.white.opacity(0.9))
            Spacer(minLength: 0)
        }
    }
}
