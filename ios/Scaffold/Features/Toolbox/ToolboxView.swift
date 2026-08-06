import SwiftUI

struct ToolboxView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Card(tint: Theme.violet) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("What's happening right now?")
                                .font(.headline)
                            Text("Pick the one that matches. Each is a short script — one thing at a time, no reading required.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    ForEach(Toolbox.all) { tool in
                        NavigationLink {
                            InterventionRunnerView(interventionID: tool.id)
                        } label: {
                            Card(tint: tool.tint) {
                                HStack(spacing: 14) {
                                    Image(systemName: tool.symbol)
                                        .font(.title3)
                                        .foregroundStyle(tool.tint)
                                        .frame(width: 30)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tool.trigger)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(tool.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
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

                    NavigationLink {
                        CrisisView()
                    } label: {
                        Card(tint: Theme.coral) {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(Theme.coral)
                                Text("If things are worse than this")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Toolbox")
        }
    }
}
