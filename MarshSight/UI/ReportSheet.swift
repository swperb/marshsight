import SwiftUI
import CoreLocation

/// Sheet for dropping a field report (hazard, blind, ramp, harvest, etc.) at the
/// current location. Private by default to protect honey holes.
struct ReportSheet: View {
    let coordinate: CLLocationCoordinate2D?
    var initialKind: Contribution.Kind = .hazard
    let onSave: (Contribution.Kind, String, String?, Contribution.Visibility) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var kind: Contribution.Kind = .hazard
    @State private var name = ""
    @State private var note = ""
    @State private var visibility: Contribution.Visibility = .private

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $kind) {
                        ForEach(Contribution.Kind.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
                Section("Details") {
                    TextField("Name (optional)", text: $name)
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section {
                    Picker("Visibility", selection: $visibility) {
                        ForEach(Contribution.Visibility.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text("Private stays on your device and your account. Public shares with the community to improve the map for everyone.")
                }
                if coordinate == nil {
                    Text("Waiting for a GPS fix...").foregroundStyle(.secondary)
                }
            }
            .navigationTitle(initialKind == .owner ? "Tag the Owner" : "Drop a Report")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { kind = initialKind }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let coordinate {
                            onSave(kind, name, note, visibility)
                        }
                        dismiss()
                    }
                    .disabled(coordinate == nil)
                }
            }
        }
    }
}

/// First-launch safety notice. This is a navigation aid built on public data,
/// not an authority. The user must acknowledge before using the app.
struct SafetyDisclaimerView: View {
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text("Before you head out")
                .font(.title.weight(.bold))
            VStack(alignment: .leading, spacing: 14) {
                bullet("MarshSight is a navigation aid, not an authority. GPS and compass have real error, especially over open water and under cover.")
                bullet("Always verify land access, boundaries, regulations, and hazards yourself. Boundary and chart data can be out of date or wrong.")
                bullet("Do not rely on this app alone for safety. Carry a backup, watch the water and weather, and use your own judgment.")
                bullet("You are responsible for hunting and boating legally and safely.")
            }
            .font(.callout)
            .foregroundStyle(.white.opacity(0.9))
            Spacer()
            Button(action: onAccept) {
                Text("I Understand")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.yellow, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.black)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill").font(.system(size: 6)).padding(.top, 7)
            Text(text)
        }
    }
}
