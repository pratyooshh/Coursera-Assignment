import SwiftUI

// MARK: - Intro

struct ScreenerIntroView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.stackGap) {
                Card(tint: Theme.sky) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Before you start")
                            .font(.headline)
                        Text("This is the Adult ADHD Self-Report Scale (ASRS v1.1), developed by the World Health Organization with the Workgroup on Adult ADHD. It's used in clinical practice and research, and the items map onto the diagnostic criteria.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Card(tint: Theme.coral) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(title: "What it can't tell you", systemImage: "exclamationmark.triangle")
                        Text("It cannot diagnose you. A screener sorts people into \"worth assessing\" and \"less likely\" — nothing finer than that.\n\nA diagnosis additionally needs evidence the pattern predates age 12, impairment in more than one setting, and the other conditions that look identical ruled out. That last part is genuinely difficult and it needs a clinician.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Card(tint: Theme.violet) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeading(title: "Answering it usefully", systemImage: "hand.raised")
                        Text("Answer for the last 6 months, and answer for how things actually are — not how they are once your workarounds are running.\n\nIf you only remember appointments because you set four alarms, the honest answer to \"do you have problems remembering appointments\" is yes. The alarms are the evidence, not the counter-evidence.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                NavigationLink {
                    ScreenerQuestionsView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                        Text("Start — 18 questions")
                    }
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .foregroundStyle(.white)
                    .background(Theme.sky, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Text("ASRS-v1.1 © 2003 World Health Organization. Reproduced unmodified for personal screening use.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Screener")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Questions

struct ScreenerQuestionsView: View {
    @EnvironmentObject private var store: DataStore

    @State private var answers: [Int] = Array(repeating: -1, count: 18)
    @State private var index = 0
    @State private var showingResult = false

    private var items: [ASRS.Item] { ASRS.allItems }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                HStack {
                    Text("\(index + 1) of \(items.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Chip(text: index < 6 ? "Screening section" : "Additional", tint: index < 6 ? Theme.sky : Theme.violet)
                }
                ThinProgressBar(value: Double(index) / Double(items.count), tint: Theme.sky)

                Card(tint: Theme.sky) {
                    Text(items[index].text)
                        .font(.title3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 8)
                }

                VStack(spacing: 8) {
                    ForEach(Array(ASRS.responseLabels.enumerated()), id: \.offset) { value, label in
                        OptionRow(
                            label: label,
                            isSelected: answers[index] == value,
                            tint: Theme.sky
                        ) {
                            answers[index] = value
                            advance()
                        }
                    }
                }

                if index > 0 {
                    Button {
                        withAnimation { index -= 1 }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Questions")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showingResult) {
            ScreenerResultView(answers: answers)
        }
    }

    private func advance() {
        Haptics.tap()
        if index + 1 < items.count {
            withAnimation { index += 1 }
        } else {
            let run = ScreenerRun(answers: answers)
            store.saveScreener(run)
            showingResult = true
        }
    }
}

// MARK: - Result

struct ScreenerResultView: View {
    let answers: [Int]

    private var flags: Int { ASRS.partAPositiveCount(answers) }
    private var interp: (headline: String, body: String) { ASRS.interpretation(partAFlags: flags) }

    private var inattentive: Int {
        ASRS.inattentiveIndices.reduce(0) { $0 + max(0, answers[$1]) }
    }

    private var hyperactive: Int {
        ASRS.hyperactiveIndices.reduce(0) { $0 + max(0, answers[$1]) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                Card(tint: flags >= ASRS.partAThreshold ? Theme.amber : Theme.mint) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(flags)")
                                .font(.system(size: 46, weight: .bold, design: .rounded))
                                .foregroundStyle(flags >= ASRS.partAThreshold ? Theme.amber : Theme.mint)
                            Text("of 6 flagged")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        Text(interp.headline)
                            .font(.title3.bold())
                        Text(interp.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Card(tint: Theme.violet) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(
                            title: "Your profile",
                            subtitle: "Descriptive only — there's no published cut-off for these two.",
                            systemImage: "chart.bar"
                        )
                        subscale("Inattentive", score: inattentive, max: 36, tint: Theme.sky)
                        subscale("Hyperactive / impulsive", score: hyperactive, max: 36, tint: Theme.coral)
                        Text("Adults are frequently much higher on one than the other. A low hyperactivity score is not evidence against anything — the predominantly inattentive presentation is the one that gets missed for decades precisely because it never disrupted anybody.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Card(tint: Theme.coral) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(title: "Read this part", systemImage: "exclamationmark.triangle")
                        Text("This is not a diagnosis and it is not close to one. Sleep disorders, thyroid problems, iron deficiency, depression, anxiety, trauma and autism all produce overlapping pictures, and several of them commonly co-occur with ADHD rather than replacing it.\n\nSorting that out is what an assessment is for.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        NavigationLink {
                            if let article = Library.all.first(where: { $0.id == "not-adhd" }) {
                                ArticleView(article: article)
                            }
                        } label: {
                            Text("What else looks like this →")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.coral)
                        }
                    }
                }

                NavigationLink {
                    EvidenceView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                        Text("Next: log some real examples")
                    }
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .foregroundStyle(.white)
                    .background(Theme.violet, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Text("ASRS-v1.1 © 2003 World Health Organization.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func subscale(_ title: String, score: Int, max maxScore: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(score)/\(maxScore)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
            }
            ThinProgressBar(value: Double(score) / Double(maxScore), tint: tint)
        }
    }
}
