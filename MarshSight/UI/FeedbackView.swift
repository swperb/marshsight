import SwiftUI
import MessageUI
import UIKit

/// In-app reporting: report a bug, request a feature, or ask a question. It
/// composes an email to the developer so a report is delivered immediately,
/// with the app version and device attached. If mail is not set up, the address
/// is shown to copy. A structured server-side pipeline can replace this later.
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss

    enum Kind: String, CaseIterable, Identifiable {
        case issue = "Bug or issue"
        case feature = "Feature request"
        case question = "Question"
        case data = "Map data problem"
        var id: String { rawValue }
        var emoji: String { "" }
        var tag: String {
            switch self {
            case .issue: return "Issue"
            case .feature: return "Feature"
            case .question: return "Question"
            case .data: return "Data"
            }
        }
    }

    private let supportEmail = "stephenproctor291@gmail.com"

    @State private var kind: Kind = .issue
    @State private var message = ""
    @State private var showMail = false
    @State private var showNoMail = false

    var body: some View {
        NavigationStack {
            Form {
                Section("What's this about?") {
                    Picker("Type", selection: $kind) {
                        ForEach(Kind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
                Section("Details") {
                    TextField("Tell us what happened, or what you'd like",
                              text: $message, axis: .vertical)
                        .lineLimit(5...12)
                }
                Section {
                    Button {
                        if MFMailComposeViewController.canSendMail() { showMail = true }
                        else { showNoMail = true }
                    } label: {
                        Label("Send", systemImage: "paperplane.fill")
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } footer: {
                    Text("Your report goes straight to the developer. We never collect anything without you sending it.")
                }
            }
            .navigationTitle("Help & Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .sheet(isPresented: $showMail) {
                MailComposeView(recipients: [supportEmail],
                                subject: "MarshSight \(kind.tag)",
                                body: composedBody()) { dismiss() }
            }
            .alert("Mail not set up", isPresented: $showNoMail) {
                Button("Copy address") { UIPasteboard.general.string = supportEmail }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Email your report to \(supportEmail).")
            }
        }
    }

    private func composedBody() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return """
        \(message)


        ---
        Type: \(kind.rawValue)
        MarshSight \(v) (\(b))
        Device: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion)
        """
    }
}

/// UIKit mail composer wrapped for SwiftUI.
struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    var onFinish: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }

    func updateUIViewController(_ vc: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) { self.onFinish() }
        }
    }
}
