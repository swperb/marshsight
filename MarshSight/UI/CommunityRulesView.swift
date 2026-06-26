import SwiftUI

/// One-time agreement shown before a user first posts to the feed or shares a
/// public spot. Apple requires an explicit agreement to terms with no tolerance
/// for objectionable content or abusive users (Guideline 1.2). Gated by
/// @AppStorage("acceptedCommunityRules").
struct CommunityRulesView: View {
    let onAgree: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let rules: [(icon: String, title: String, body: String)] = [
        ("hand.raised.fill", "Be decent", "No harassment, hate speech, threats, or obscene content. Zero tolerance."),
        ("leaf.fill", "Respect the land & the law", "Don't post anything that encourages trespassing, poaching, or illegal harvest."),
        ("eye.slash.fill", "Protect honey holes", "Sharing a public spot reveals its location. Keep private spots private."),
        ("flag.fill", "Report what's wrong", "Flag anything objectionable. We review reports and remove violators within 24 hours."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Before you post")
                        .font(.title2.weight(.bold))
                    Text("MarshSight's feed and community spots are made by hunters and anglers like you. To keep it useful and safe, everyone agrees to these rules.")
                        .font(.subheadline).foregroundStyle(.secondary)

                    VStack(spacing: 16) {
                        ForEach(rules, id: \.icon) { rule in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: rule.icon).font(.title3)
                                    .foregroundStyle(.cyan).frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rule.title).font(.subheadline.weight(.semibold))
                                    Text(rule.body).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }

                    Text("Objectionable posts are removed and repeat offenders are banned. By continuing you agree to the Community Guidelines and that you are responsible for what you post.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .navigationTitle("Community Guidelines")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Button {
                        onAgree(); dismiss()
                    } label: {
                        Text("I Agree").font(.headline).frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(.cyan, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.black)
                    }
                    Button("Not now") { dismiss() }
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20).padding(.bottom, 8)
                .background(.bar)
            }
        }
    }
}
