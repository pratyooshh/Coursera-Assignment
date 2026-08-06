import Foundation

// MARK: - Default routines

extension Routine {
    /// Anchors, not schedules.
    ///
    /// Every step is deliberately tiny. A morning routine with eleven steps is a
    /// routine you'll abandon in four days and then feel bad about, which leaves
    /// you worse off than having none.
    static var seeds: [Routine] {
        [
            Routine(
                name: "Launch",
                symbol: "sun.max",
                steps: [
                    RoutineStep(text: "Daylight on your face — window or doorstep", minutes: 3),
                    RoutineStep(text: "Water before caffeine", minutes: 1),
                    RoutineStep(text: "Empty your head into Capture", minutes: 3),
                    RoutineStep(text: "Pick the one thing that matters today", minutes: 2),
                ],
                reminderMinutes: 8 * 60
            ),
            Routine(
                name: "Land",
                symbol: "moon.stars",
                steps: [
                    RoutineStep(text: "Note where you got to — close the loop", minutes: 3),
                    RoutineStep(text: "Tomorrow's one thing, written down", minutes: 2),
                    RoutineStep(text: "Set out anything that leaves with you", minutes: 3),
                    RoutineStep(text: "Log one thing that went right", minutes: 2),
                ],
                reminderMinutes: 21 * 60
            ),
            Routine(
                name: "Out the door",
                symbol: "figure.walk",
                steps: [
                    RoutineStep(text: "Keys, wallet, phone — say each one out loud", minutes: 1),
                    RoutineStep(text: "Anything that has to come back with you", minutes: 1),
                    RoutineStep(text: "Journey time, then add half again", minutes: 1),
                ],
                reminderMinutes: nil
            ),
        ]
    }
}

// MARK: - Dopamine menu

enum DopamineMenu {
    static let defaults: [String] = [
        "Cold water on my face",
        "Ten press-ups",
        "Step outside for two minutes",
        "One song, loud, standing up",
        "Walk round the block",
        "Message someone I like",
        "Make something to eat properly",
        "Ten minutes of an instrument",
        "Shower",
        "Podcast while I do the washing-up",
    ]
}

// MARK: - Task breakdown

enum BreakdownPrompts {
    /// Questions that turn a vague dread-object into a first physical movement.
    static let questions: [String] = [
        "What's the very first physical thing you'd do? Opening something counts.",
        "Where would you be sitting or standing when you do this?",
        "Does anything need to exist before you can start — a file, a number, a login?",
        "Is there a person involved? What's the first thing you'd say to them?",
        "What does \"finished\" actually look like? How would you know?",
        "What's the smallest version of this that would still count?",
    ]

    /// Common shapes, offered as starting points rather than templates.
    static let patterns: [(String, [String])] = [
        ("Send a message I've been avoiding", [
            "Open a blank reply",
            "Type the greeting only",
            "One sentence saying the actual thing",
            "Send without rereading it four times",
        ]),
        ("Paperwork or a form", [
            "Find the document and put it on the desk",
            "Read it once without filling anything in",
            "List what information I still need",
            "Fill in only the parts I already know",
            "Chase the one missing piece",
        ]),
        ("Tidy a space", [
            "Pick one surface, ignore everything else",
            "Rubbish only, nothing else",
            "Five things back where they live",
            "Stop — genuinely stop, even if it's going well",
        ]),
        ("Something with an appointment", [
            "Find the number or the booking page",
            "Write down what I need from them",
            "Write the opening line",
            "Book it, then put it in the calendar with a leave-by alarm",
        ]),
        ("Write something", [
            "Open the document, title it badly",
            "Bullet the points in any order",
            "Expand one bullet — not the first one, the easiest one",
            "Join them up",
            "Edit once, then stop",
        ]),
    ]
}

// MARK: - Crisis resources

struct CrisisResource: Identifiable {
    let id = UUID()
    let region: String
    let name: String
    let contact: String
    let detail: String
}

enum Crisis {
    static let message = "If you're in immediate danger, or you're thinking about harming yourself, please contact emergency services or one of these lines now. They're free, they're confidential, and you don't have to be in crisis to call."

    static let resources: [CrisisResource] = [
        CrisisResource(
            region: "International",
            name: "Find a helpline",
            contact: "findahelpline.com",
            detail: "Verified crisis lines in over 100 countries"
        ),
        CrisisResource(
            region: "United States",
            name: "988 Suicide & Crisis Lifeline",
            contact: "988",
            detail: "Call or text, 24/7"
        ),
        CrisisResource(
            region: "United Kingdom",
            name: "Samaritans",
            contact: "116 123",
            detail: "Free, 24/7"
        ),
        CrisisResource(
            region: "United Kingdom",
            name: "Shout",
            contact: "Text SHOUT to 85258",
            detail: "Free 24/7 text support"
        ),
        CrisisResource(
            region: "India",
            name: "Tele-MANAS",
            contact: "14416",
            detail: "Government mental health helpline, 24/7"
        ),
        CrisisResource(
            region: "India",
            name: "AASRA",
            contact: "9820466726",
            detail: "24/7 crisis support"
        ),
        CrisisResource(
            region: "Canada",
            name: "9-8-8 Suicide Crisis Helpline",
            contact: "988",
            detail: "Call or text, 24/7"
        ),
        CrisisResource(
            region: "Australia",
            name: "Lifeline",
            contact: "13 11 14",
            detail: "24/7 crisis support"
        ),
        CrisisResource(
            region: "Ireland",
            name: "Samaritans Ireland",
            contact: "116 123",
            detail: "Free, 24/7"
        ),
    ]
}

// MARK: - Feeling words

enum Feelings {
    /// Granularity helps. "Bad" is not actionable; "resentful" points somewhere.
    static let options: [String] = [
        "Flat", "Restless", "Wired", "Foggy", "Overwhelmed",
        "Ashamed", "Frustrated", "Anxious", "Numb", "Lonely",
        "Resentful", "Hopeful", "Calm", "Proud", "Content",
        "Irritable", "Rejected", "Bored", "Motivated", "Exhausted",
    ]
}
