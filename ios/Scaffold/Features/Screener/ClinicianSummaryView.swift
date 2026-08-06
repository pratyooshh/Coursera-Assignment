import SwiftUI

/// Turns everything logged into one page a clinician can read in two minutes.
///
/// This is the single highest-leverage thing the app does for someone who is
/// undiagnosed. Assessments are short and adults are bad at summarising thirty
/// years under time pressure — particularly while masking, which runs
/// automatically in exactly that setting. Handing over an organised page
/// converts the appointment from recall-under-pressure into review.
struct ClinicianSummaryView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                Card(tint: Theme.mint) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("For your appointment")
                            .font(.headline)
                        Text("Everything you've logged, arranged the way an assessment moves. Print it, email it to yourself, or read it off your phone.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Card(tint: Theme.coral) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeading(title: "One thing before you go in", systemImage: "person.wave.2")
                        Text("Don't present the polished version. You have decades of practice at appearing fine and it runs without you deciding to — which is the most common reason capable adults get turned away.\n\nThey need the cost, not the coping. Describe what it takes to hold it together, not how well it's held.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Card(tint: Theme.violet) {
                    Text(summaryText)
                        .font(.system(.footnote, design: .monospaced))
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }

                ShareLink(item: summaryText) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share or save")
                    }
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .foregroundStyle(.white)
                    .background(Theme.mint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                DisclaimerNote(text: "Self-reported information, generated on this device. It is not a diagnosis, not a clinical record, and carries no medical authority — it's your notes, tidied up.")
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Generation

    private var summaryText: String {
        var out: [String] = []
        let df = DateFormatter()
        df.dateStyle = .medium

        out.append("SELF-REPORTED SUMMARY FOR CLINICAL DISCUSSION")
        out.append("Prepared \(df.string(from: Date())) using Scaffold")
        out.append("Self-reported by the patient. Not a diagnosis or clinical assessment.")
        out.append("")

        // Screener
        out.append("— SCREENING (ASRS v1.1, WHO) —")
        if let run = store.latestScreener {
            out.append("Completed: \(df.string(from: run.date))")
            out.append("Part A (screener): \(run.partAFlags) of 6 items at or above threshold (published cut-off: 4).")
            out.append("Inattentive item total: \(run.inattentiveScore)/36")
            out.append("Hyperactive/impulsive item total: \(run.hyperactiveScore)/36")
            out.append("")
            out.append("Item-level responses (0=Never, 4=Very Often):")
            for (i, item) in ASRS.allItems.enumerated() where run.answers.indices.contains(i) {
                let a = run.answers[i]
                guard a >= 0 else { continue }
                let flag = (i < 6 && a >= item.positiveThreshold) ? " *" : ""
                out.append("  \(i + 1). [\(a)]\(flag) \(item.text)")
            }
        } else {
            out.append("Not completed.")
        }
        out.append("")

        // Evidence
        out.append("— FUNCTIONAL IMPACT (self-reported examples) —")
        if store.data.evidence.isEmpty {
            out.append("None logged.")
        } else {
            for domain in LifeDomain.allCases {
                let notes = store.data.evidence.filter { $0.domain == domain && !$0.isChildhood }
                guard !notes.isEmpty else { continue }
                out.append("\(domain.title.uppercased()):")
                for note in notes {
                    out.append("  · [\(df.string(from: note.date))] \(note.text)")
                }
            }
        }
        out.append("")

        // Childhood
        out.append("— REPORTED BEFORE AGE 12 —")
        let childhood = store.data.evidence.filter(\.isChildhood)
        if childhood.isEmpty {
            out.append("None logged.")
        } else {
            for note in childhood {
                out.append("  · [\(domainLabel(note.domain))] \(note.text)")
            }
        }
        out.append("")

        // Emotional regulation
        out.append("— MOOD & EMOTIONAL REGULATION —")
        if store.data.moods.isEmpty {
            out.append("No entries logged.")
        } else {
            let moods = store.data.moods
            let avgV = Double(moods.map(\.valence).reduce(0, +)) / Double(moods.count)
            let rsd = moods.filter(\.wasRejectionEpisode).count
            out.append("Entries logged: \(moods.count) since \(df.string(from: moods.last?.date ?? Date()))")
            out.append("Mean self-rated mood: \(String(format: "%.1f", avgV))/5")
            out.append("Entries flagged by the patient as rejection-sensitivity episodes: \(rsd)")
            let common = mostCommonFeelings(moods)
            if !common.isEmpty {
                out.append("Most frequently selected states: \(common.joined(separator: ", "))")
            }
        }
        out.append("")

        // Time
        out.append("— TIME ESTIMATION —")
        if let mult = store.timeMultiplier {
            out.append("Across \(store.calibrationSampleCount) timed tasks, actual duration averaged \(String(format: "%.1f", mult))× the patient's own prior estimate.")
        } else {
            out.append("Insufficient data logged.")
        }
        out.append("")

        // Engagement
        out.append("— SELF-MANAGEMENT ATTEMPTS —")
        out.append("Focus sessions logged: \(store.data.sessions.count)")
        out.append("Tasks broken into sub-steps: \(store.data.tasks.filter { !$0.steps.isEmpty }.count)")
        out.append("Tasks marked as high activation cost (\"a wall\"): \(store.data.tasks.filter { $0.activationCost == .wall }.count)")
        out.append("")

        out.append("— NOTES —")
        out.append("Generated locally on the patient's device from their own entries.")
        out.append("The ASRS v1.1 is a screening instrument (© 2003 WHO) and is not diagnostic.")

        return out.joined(separator: "\n")
    }

    private func domainLabel(_ d: LifeDomain) -> String { d.title }

    private func mostCommonFeelings(_ moods: [MoodEntry]) -> [String] {
        var counts: [String: Int] = [:]
        for mood in moods {
            for feeling in mood.feelings {
                counts[feeling, default: 0] += 1
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { "\($0.key) (\($0.value))" }
    }
}
