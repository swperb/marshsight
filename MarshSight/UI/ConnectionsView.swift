import SwiftUI

/// The Connections hub: bring closed ecosystems you already use (trail cameras,
/// GPX) onto one open map. Trail-camera email-in works by forwarding your cell
/// camera's photo alerts to a personal MarshSight address; the photos then drop
/// onto the map at the camera. The inbound-email service is the server-side piece.
struct ConnectionsView: View {
    @Environment(\.dismiss) private var dismiss

    /// A stable per-install code for the personal camera inbox address.
    @AppStorage("camInboxCode") private var camCode = ""

    private var inboxAddress: String {
        let code = camCode.isEmpty ? "setup" : camCode
        return "cam-\(code)@in.marshsight.com"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("MarshSight pulls the tools you already use onto one map, instead of making you toggle between apps.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                Section("Trail cameras") {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cameras on your map").font(.subheadline.weight(.semibold))
                            Text("Forward your cell camera's photo alerts to your personal address below and they drop onto the map at the camera.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    } icon: { Image(systemName: "camera.fill").foregroundStyle(.blue) }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your camera inbox").font(.caption).foregroundStyle(.secondary)
                            Text(inboxAddress).font(.callout.monospaced()).textSelection(.enabled)
                        }
                        Spacer()
                        Button { UIPasteboard.general.string = inboxAddress } label: {
                            Image(systemName: "doc.on.doc")
                        }.buttonStyle(.borderless)
                    }

                    Label("Activating soon — your address is reserved. We'll let you know when forwarding goes live.",
                          systemImage: "clock")
                        .font(.caption).foregroundStyle(.orange)
                }

                Section {
                    ForEach(["Moultrie Mobile", "Spypoint", "Tactacam Reveal", "Stealth Cam Command"], id: \.self) { name in
                        Label(name, systemImage: "checkmark.circle").foregroundStyle(.primary)
                    }
                } header: {
                    Text("Works with")
                } footer: {
                    Text("Any camera that can email photos on detection. Set the forwarding address in your camera app to the inbox above.")
                }
            }
            .navigationTitle("Connections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onAppear {
                if camCode.isEmpty { camCode = String(UUID().uuidString.prefix(8)).lowercased() }
            }
        }
    }
}
