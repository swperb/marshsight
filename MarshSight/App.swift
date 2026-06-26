import SwiftUI

@main
struct MarshSightApp: App {
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("ARHARNESS") {
                ARHarnessView().preferredColorScheme(.dark)   // dev-only AR HUD harness
            } else {
                ContentView().preferredColorScheme(.dark)
            }
        }
    }
}
