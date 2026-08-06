import Foundation
import SwiftUI

/// Everything the app knows, in one Codable blob.
struct AppData: Codable {
    var tasks: [FocusTask] = []
    var captures: [CaptureItem] = []
    var moods: [MoodEntry] = []
    var routines: [Routine] = Routine.seeds
    var sessions: [FocusSession] = []
    var wins: [WinEntry] = []
    var screenerRuns: [ScreenerRun] = []
    var evidence: [EvidenceNote] = []
    var hasOnboarded: Bool = false
    var dopamineMenu: [String] = DopamineMenu.defaults
}

/// Single source of truth. Local file, no network, no account.
///
/// Persistence is a plain JSON file in Application Support. That is a deliberate
/// choice over SwiftData/CloudKit: this app holds someone's un-assessed mental
/// health notes, and the safest place for that is one device with no sync path.
final class DataStore: ObservableObject {

    @Published var data: AppData {
        didSet { scheduleSave() }
    }

    private let fileURL: URL
    private var saveWorkItem: DispatchWorkItem?

    init(inMemory: Bool = false) {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Scaffold", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("scaffold.json")

        if inMemory {
            self.data = AppData()
        } else if let raw = try? Data(contentsOf: fileURL),
                  let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
            self.data = decoded
        } else {
            self.data = AppData()
        }
    }

    // MARK: - Persistence

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let snapshot = data
        let url = fileURL
        let work = DispatchWorkItem {
            guard let encoded = try? JSONEncoder().encode(snapshot) else { return }
            try? encoded.write(to: url, options: .atomic)
        }
        saveWorkItem = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    func eraseEverything() {
        data = AppData()
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Capture

    func capture(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        data.captures.insert(CaptureItem(text: trimmed), at: 0)
        Haptics.success()
    }

    var untriagedCaptures: [CaptureItem] {
        data.captures.filter { !$0.isTriaged }
    }

    func promoteToTask(_ item: CaptureItem) {
        var task = FocusTask(title: item.text)
        task.isOnToday = true
        data.tasks.insert(task, at: 0)
        markTriaged(item)
    }

    func markTriaged(_ item: CaptureItem) {
        guard let idx = data.captures.firstIndex(where: { $0.id == item.id }) else { return }
        data.captures[idx].isTriaged = true
    }

    func deleteCapture(_ item: CaptureItem) {
        data.captures.removeAll { $0.id == item.id }
    }

    // MARK: - Tasks

    var todayTasks: [FocusTask] {
        data.tasks.filter { $0.isOnToday && !$0.isDone }
    }

    var openTasks: [FocusTask] {
        data.tasks.filter { !$0.isDone }
    }

    func addTask(_ task: FocusTask) {
        data.tasks.insert(task, at: 0)
    }

    func update(_ task: FocusTask) {
        guard let idx = data.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        data.tasks[idx] = task
    }

    func deleteTask(_ task: FocusTask) {
        data.tasks.removeAll { $0.id == task.id }
    }

    func complete(_ task: FocusTask) {
        guard let idx = data.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        data.tasks[idx].completedAt = Date()
        logWin(data.tasks[idx].title, source: "task")
        Haptics.success()
    }

    func toggleStep(taskID: UUID, stepID: UUID) {
        guard let t = data.tasks.firstIndex(where: { $0.id == taskID }),
              let s = data.tasks[t].steps.firstIndex(where: { $0.id == stepID }) else { return }
        data.tasks[t].steps[s].isDone.toggle()
        Haptics.tap()
    }

    // MARK: - Wins

    func logWin(_ text: String, source: String = "manual") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        data.wins.insert(WinEntry(text: trimmed, source: source), at: 0)
    }

    var winsToday: [WinEntry] {
        data.wins.filter { Calendar.current.isDateInToday($0.date) }
    }

    /// Total count only ever grows. There is no way to break it.
    var lifetimeWinCount: Int { data.wins.count }

    // MARK: - Mood

    func logMood(_ entry: MoodEntry) {
        data.moods.insert(entry, at: 0)
    }

    var latestMood: MoodEntry? { data.moods.first }

    var recentMoods: [MoodEntry] {
        Array(data.moods.prefix(14))
    }

    // MARK: - Focus sessions

    func startSession(mode: FocusMode, minutes: Int, taskTitle: String?, predicted: Int?) -> FocusSession {
        let session = FocusSession(
            mode: mode,
            startedAt: Date(),
            plannedMinutes: minutes,
            taskTitle: taskTitle,
            predictedMinutes: predicted
        )
        data.sessions.insert(session, at: 0)
        return session
    }

    func finishSession(_ id: UUID, completedFully: Bool) {
        guard let idx = data.sessions.firstIndex(where: { $0.id == id }) else { return }
        data.sessions[idx].endedAt = Date()
        data.sessions[idx].completedFully = completedFully
        if completedFully {
            logWin("Focused for \(data.sessions[idx].plannedMinutes) minutes", source: "focus")
        }
    }

    var focusMinutesToday: Int {
        data.sessions
            .filter { Calendar.current.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.elapsedMinutes }
    }

    // MARK: - Time calibration

    /// The user's personal "everything takes longer than I think" factor.
    ///
    /// Estimating duration draws on working memory and prospective timing, both
    /// of which run differently in ADHD — so the error is usually systematic
    /// rather than random. A systematic error can be corrected for: measure it,
    /// then multiply. Returns nil until there's enough data to be honest about.
    var timeMultiplier: Double? {
        let pairs = data.tasks.compactMap { task -> (Double, Double)? in
            guard let p = task.predictedMinutes, let a = task.actualMinutes, p > 0, a > 0 else { return nil }
            return (Double(p), Double(a))
        }
        guard pairs.count >= 3 else { return nil }
        let ratios = pairs.map { $0.1 / $0.0 }
        return ratios.reduce(0, +) / Double(ratios.count)
    }

    var calibrationSampleCount: Int {
        data.tasks.filter { $0.predictedMinutes != nil && $0.actualMinutes != nil }.count
    }

    // MARK: - Screener

    func saveScreener(_ run: ScreenerRun) {
        data.screenerRuns.insert(run, at: 0)
    }

    var latestScreener: ScreenerRun? { data.screenerRuns.first }

    // MARK: - Evidence

    func addEvidence(_ note: EvidenceNote) {
        data.evidence.insert(note, at: 0)
    }

    func deleteEvidence(_ note: EvidenceNote) {
        data.evidence.removeAll { $0.id == note.id }
    }

    // MARK: - Routines

    func updateRoutine(_ routine: Routine) {
        guard let idx = data.routines.firstIndex(where: { $0.id == routine.id }) else { return }
        data.routines[idx] = routine
    }

    func addRoutine(_ routine: Routine) {
        data.routines.append(routine)
    }

    func deleteRoutine(_ routine: Routine) {
        data.routines.removeAll { $0.id == routine.id }
    }
}
