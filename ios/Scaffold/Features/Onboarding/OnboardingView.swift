import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: DataStore
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                pageOne.tag(0)
                pageTwo.tag(1)
                pageThree.tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 10) {
                BigButton(
                    title: page < 2 ? "Next" : "Start",
                    systemImage: page < 2 ? "arrow.right" : "checkmark",
                    tint: Theme.violet
                ) {
                    if page < 2 {
                        withAnimation { page += 1 }
                    } else {
                        store.data.hasOnboarded = true
                    }
                }
                if page < 2 {
                    Button("Skip") { store.data.hasOnboarded = true }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var pageOne: some View {
        OnboardPage(
            symbol: "square.stack.3d.up",
            title: "Scaffold",
            lines: [
                "Built for adults who suspect they have ADHD and haven't been assessed — or who were assessed a long time ago and never got much beyond the label.",
                "The idea is simple. If your brain struggles to hold structure internally, put the structure outside it: visible, immediate, and present at the moment you need it.",
                "Nothing in here asks you to try harder.",
            ]
        )
    }

    private var pageTwo: some View {
        OnboardPage(
            symbol: "lock.shield",
            title: "It stays on this phone",
            lines: [
                "No account. No sign-in. No servers. Nothing you write here is uploaded anywhere, because there is nowhere for it to go.",
                "That matters more than usual here — this app holds notes about your mental health that you may not have told anyone. The safest place for those is one device.",
                "You can export a summary to take to a clinician when you want to. That's a deliberate action you take, never something that happens on its own.",
            ]
        )
    }

    private var pageThree: some View {
        OnboardPage(
            symbol: "stethoscope",
            title: "What this can't do",
            lines: [
                "Scaffold cannot diagnose you. No app can, and any that implies otherwise is worth deleting.",
                "It includes a validated screening questionnaire, and a screener tells you whether it's worth seeing someone — not what you have. Diagnosis needs a clinician who can rule out the other things that look identical from the inside.",
                "What this app is genuinely for: making daily life work better, and helping you arrive at that appointment with something more useful than \"I think I might have ADHD\".",
            ],
            footnote: "If you're in crisis, please use the resources under Path → Crisis support."
        )
    }
}

private struct OnboardPage: View {
    let symbol: String
    let title: String
    let lines: [String]
    var footnote: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: symbol)
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.gradientCool)
                    .padding(.top, 60)

                Text(title)
                    .font(.largeTitle.bold())

                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let footnote {
                    DisclaimerNote(text: footnote)
                        .padding(.top, 4)
                }

                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
        }
    }
}
