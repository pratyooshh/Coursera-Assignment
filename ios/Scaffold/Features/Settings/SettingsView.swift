import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: DataStore

    @State private var notificationsEnabled = false
    @State private var showingEraseConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                Card(tint: Theme.mint) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(title: "Where your data lives", systemImage: "lock.shield")
                        Text("On this phone, in a file only this app can read. There's no account, no server, and no analytics — nothing is uploaded, because there's nowhere for it to go.\n\nThe only way anything leaves is if you tap Share on your clinician summary, and that's you sending it, not the app.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Practical consequence: delete the app and it's all gone. Uninstalling is a permanent erase, and there's no backup to restore from.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Card(tint: Theme.violet) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(
                            title: "Notifications",
                            subtitle: "Only what you set up — block endings, body checks, and your anchor nudges. Nothing motivational.",
                            systemImage: "bell"
                        )
                        if notificationsEnabled {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.mint)
                                Text("Allowed")
                                    .font(.subheadline)
                            }
                        } else {
                            BigButton(title: "Allow notifications", systemImage: "bell.badge", tint: Theme.violet, style: .tonal) {
                                Notifications.requestPermission { granted in
                                    notificationsEnabled = granted
                                    if granted {
                                        Notifications.syncRoutineReminders(store.data.routines)
                                    }
                                }
                            }
                        }
                    }
                }

                Card(tint: Theme.sky) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeading(title: "What's in here", systemImage: "tray.full")
                        stat("Tasks", store.data.tasks.count)
                        stat("Captured thoughts", store.data.captures.count)
                        stat("Mood entries", store.data.moods.count)
                        stat("Focus sessions", store.data.sessions.count)
                        stat("Evidence examples", store.data.evidence.count)
                        stat("Wins", store.data.wins.count)
                    }
                }

                Card(tint: Theme.coral) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(title: "What this app isn't", systemImage: "exclamationmark.triangle")
                        Text("Scaffold does not diagnose, treat, or provide medical advice. It includes a screening questionnaire and general information drawn from published research, and neither of those is a substitute for a clinician who can assess you properly.\n\nIf you're struggling with your mental health, please talk to a professional. If you're in crisis, use the numbers under Crisis support.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Card(tint: Theme.coral) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(title: "Erase everything", systemImage: "trash")
                        Text("Deletes every task, note, mood entry, screener result and piece of evidence. Immediate and irreversible.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        BigButton(title: "Erase all my data", systemImage: "trash", tint: Theme.coral, style: .tonal) {
                            showingEraseConfirm = true
                        }
                    }
                }

                Text("Scaffold 1.0 · Built on published ADHD research. Sources are listed at the bottom of every article in Learn.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Notifications.authorizationStatus { status in
                notificationsEnabled = (status == .authorized || status == .provisional)
            }
        }
        .alert("Erase everything?", isPresented: $showingEraseConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Erase", role: .destructive) {
                Notifications.cancelAll()
                store.eraseEverything()
            }
        } message: {
            Text("This cannot be undone. Everything you've logged will be permanently deleted from this device.")
        }
    }

    private func stat(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(value)")
                .font(.subheadline.weight(.semibold))
        }
    }
}
