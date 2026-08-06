import Foundation

// NOTE: this type is deliberately *not* called `Task` — that name is taken by
// Swift Concurrency and shadowing it makes every `Task { }` in the app ambiguous.

// MARK: - Tasks

struct MicroStep: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var text: String
    var isDone: Bool = false
}

/// How much *activation energy* a task costs — not how hard it is.
///
/// This distinction matters. ADHD task avoidance tracks the cost of *starting*,
/// not the difficulty of doing. People routinely avoid a 90-second task for
/// weeks while completing genuinely hard work, which looks irrational until you
/// measure the right variable.
enum ActivationCost: Int, Codable, CaseIterable, Identifiable {
    case easy = 1
    case medium = 2
    case wall = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .easy: return "I could just do it"
        case .medium: return "Needs a run-up"
        case .wall: return "There's a wall in front of it"
        }
    }

    var shortLabel: String {
        switch self {
        case .easy: return "Low"
        case .medium: return "Medium"
        case .wall: return "Wall"
        }
    }

    var symbol: String {
        switch self {
        case .easy: return "figure.walk"
        case .medium: return "figure.stair.stepper"
        case .wall: return "shield.lefthalf.filled"
        }
    }
}

struct FocusTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var notes: String = ""
    var steps: [MicroStep] = []
    var activationCost: ActivationCost = .medium

    /// What the user guessed before starting, in minutes.
    var predictedMinutes: Int? = nil
    /// What it actually took, in minutes. Together these build the personal
    /// time-multiplier that makes time blindness visible instead of theoretical.
    var actualMinutes: Int? = nil

    var isOnToday: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date? = nil

    var isDone: Bool { completedAt != nil }

    var stepProgress: Double {
        guard !steps.isEmpty else { return isDone ? 1 : 0 }
        return Double(steps.filter(\.isDone).count) / Double(steps.count)
    }

    /// The single smallest thing that would count as having started.
    var firstUndoneStep: MicroStep? {
        steps.first { !$0.isDone }
    }
}

// MARK: - Capture

/// A frictionless inbox item. Capture is deliberately separated from organising:
/// requiring someone to categorise a thought at the moment they have it is the
/// fastest way to lose the thought.
struct CaptureItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var text: String
    var createdAt: Date = Date()
    var isTriaged: Bool = false
}

// MARK: - Mood & emotional regulation

struct MoodEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    /// 1 (rough) ... 5 (good)
    var valence: Int
    /// 1 (flat/empty) ... 5 (wired)
    var energy: Int
    var feelings: [String] = []
    var note: String = ""
    /// Flagged when the entry was logged during a rejection-sensitivity episode.
    var wasRejectionEpisode: Bool = false
}

// MARK: - Routines

struct RoutineStep: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var text: String
    var minutes: Int = 2
}

struct Routine: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var symbol: String = "sun.max"
    var steps: [RoutineStep] = []
    var isEnabled: Bool = true
    /// Optional daily nudge time, stored as minutes past midnight.
    var reminderMinutes: Int? = nil

    var totalMinutes: Int { steps.reduce(0) { $0 + $1.minutes } }
}

// MARK: - Focus sessions

enum FocusMode: String, Codable, CaseIterable, Identifiable {
    case sprint
    case bodyDouble
    case hyperfocusGuard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sprint: return "Sprint"
        case .bodyDouble: return "Body double"
        case .hyperfocusGuard: return "Hyperfocus guard"
        }
    }

    var blurb: String {
        switch self {
        case .sprint:
            return "A short, bounded block. The end is visible from the start."
        case .bodyDouble:
            return "Work alongside a presence that checks in. Borrowed activation."
        case .hyperfocusGuard:
            return "For when you'll disappear into it. Nudges you to eat, drink, move."
        }
    }

    var symbol: String {
        switch self {
        case .sprint: return "bolt.fill"
        case .bodyDouble: return "person.2.fill"
        case .hyperfocusGuard: return "shield.fill"
        }
    }
}

struct FocusSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var mode: FocusMode
    var startedAt: Date
    var endedAt: Date? = nil
    var plannedMinutes: Int
    var taskTitle: String? = nil
    /// Minutes the user predicted the *task* would take, captured at session start.
    var predictedMinutes: Int? = nil
    var completedFully: Bool = false

    var elapsedMinutes: Int {
        let end = endedAt ?? Date()
        return max(0, Int(end.timeIntervalSince(startedAt) / 60))
    }
}

// MARK: - Wins

/// Deliberately not a streak.
///
/// Streaks punish the exact failure mode ADHD produces — an inconsistent day
/// resets the counter to zero, which reliably converts a small miss into
/// abandoning the tool. Wins only accumulate; nothing here can be lost.
struct WinEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var text: String
    var source: String = "manual"
}

// MARK: - Screener

struct ScreenerRun: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    /// 18 answers, each 0...4 (Never ... Very Often). Part A is indices 0..<6.
    var answers: [Int]

    var partAFlags: Int {
        ASRS.partAPositiveCount(answers)
    }

    var inattentiveScore: Int {
        ASRS.inattentiveIndices.reduce(0) { $0 + (answers.indices.contains($1) ? answers[$1] : 0) }
    }

    var hyperactiveScore: Int {
        ASRS.hyperactiveIndices.reduce(0) { $0 + (answers.indices.contains($1) ? answers[$1] : 0) }
    }
}

/// Evidence for a future assessment: concrete, dated, real-world examples.
///
/// Clinicians assessing adults need functional impairment across settings, plus
/// indications the pattern predates age 12. "I'm forgetful" is not assessable.
/// "I missed my sister's birthday twice, and my manager raised it in March" is.
struct EvidenceNote: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var domain: LifeDomain
    var text: String
    var isChildhood: Bool = false
}

enum LifeDomain: String, Codable, CaseIterable, Identifiable {
    case work
    case home
    case money
    case relationships
    case health
    case selfEsteem

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work: return "Work or study"
        case .home: return "Home & admin"
        case .money: return "Money"
        case .relationships: return "Relationships"
        case .health: return "Health & sleep"
        case .selfEsteem: return "How I see myself"
        }
    }

    var symbol: String {
        switch self {
        case .work: return "briefcase"
        case .home: return "house"
        case .money: return "creditcard"
        case .relationships: return "heart"
        case .health: return "bed.double"
        case .selfEsteem: return "person"
        }
    }
}
