import SwiftUI

/// The route from "I think something's going on" to a productive appointment.
struct PathView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.stackGap) {
                    intro
                    screenerCard
                    evidenceCard
                    summaryCard
                    supportCard
                    settingsLink
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Path")
        }
    }

    private var intro: some View {
        Card(tint: Theme.violet) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Towards an answer")
                    .font(.headline)
                Text("Most adults who get diagnosed start exactly here — recognising themselves in something. The gap between that and an assessment is mostly organised information, which is what this section builds.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var screenerCard: some View {
        NavigationLink {
            ScreenerIntroView()
        } label: {
            Card(tint: Theme.sky) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.title3)
                            .foregroundStyle(Theme.sky)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screening questionnaire")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("ASRS v1.1 — the WHO's adult self-report scale")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    if let run = store.latestScreener {
                        Divider()
                        HStack(spacing: 8) {
                            Chip(
                                text: "\(run.partAFlags)/6 flagged",
                                tint: run.partAFlags >= ASRS.partAThreshold ? Theme.amber : Theme.mint,
                                filled: true
                            )
                            Text(run.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var evidenceCard: some View {
        NavigationLink {
            EvidenceView()
        } label: {
            Card(tint: Theme.amber) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title3)
                        .foregroundStyle(Theme.amber)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Evidence log")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(store.data.evidence.isEmpty
                             ? "Concrete examples beat adjectives in an assessment"
                             : "\(store.data.evidence.count) example\(store.data.evidence.count == 1 ? "" : "s") logged")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var summaryCard: some View {
        NavigationLink {
            ClinicianSummaryView()
        } label: {
            Card(tint: Theme.mint) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.on.square")
                        .font(.title3)
                        .foregroundStyle(Theme.mint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Summary to take in")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Everything organised the way a clinician will ask for it")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var supportCard: some View {
        NavigationLink {
            CrisisView()
        } label: {
            Card(tint: Theme.coral) {
                HStack(spacing: 12) {
                    Image(systemName: "lifepreserver")
                        .font(.title3)
                        .foregroundStyle(Theme.coral)
                    Text("Crisis support")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var settingsLink: some View {
        NavigationLink {
            SettingsView()
        } label: {
            Card(tint: Theme.violet) {
                HStack(spacing: 12) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundStyle(Theme.violet)
                    Text("Settings & privacy")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
