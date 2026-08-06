import Foundation

/// The Adult ADHD Self-Report Scale (ASRS-v1.1) Symptom Checklist.
///
/// Developed by the World Health Organization in collaboration with the
/// Workgroup on Adult ADHD (Kessler, Adler, Ames, Demler, Faraone, Hiripi,
/// Howes, Jin, Secnik, Spencer, Ustun, Walters). The items are drawn from the
/// WHO Composite International Diagnostic Interview and map onto the eighteen
/// DSM-IV-TR criteria for ADHD.
///
/// Copyright © 2003 World Health Organization. Reproduced here for personal
/// screening use, unmodified.
///
/// IMPORTANT — what this instrument is and isn't:
/// The ASRS is a *screener*. Part A identifies people whose symptoms are highly
/// consistent with ADHD in adults and who warrant further investigation. It
/// cannot establish a diagnosis. Diagnosis additionally requires evidence of
/// onset in childhood, impairment in two or more settings, and — critically —
/// ruling out the many other conditions that produce the same surface pattern.
/// That last part needs a clinician, not an app.
enum ASRS {

    struct Item {
        let text: String
        /// Minimum response index (0...4) that counts as a positive screen for
        /// this item. The published form renders these as darkened boxes; the
        /// threshold varies per item rather than being uniform.
        let positiveThreshold: Int
    }

    static let responseLabels = ["Never", "Rarely", "Sometimes", "Often", "Very Often"]

    /// Part A — the six-question screener.
    static let partA: [Item] = [
        Item(text: "How often do you have trouble wrapping up the final details of a project, once the challenging parts have been done?", positiveThreshold: 2),
        Item(text: "How often do you have difficulty getting things in order when you have to do a task that requires organization?", positiveThreshold: 2),
        Item(text: "How often do you have problems remembering appointments or obligations?", positiveThreshold: 2),
        Item(text: "When you have a task that requires a lot of thought, how often do you avoid or delay getting started?", positiveThreshold: 3),
        Item(text: "How often do you fidget or squirm with your hands or feet when you have to sit down for a long time?", positiveThreshold: 3),
        Item(text: "How often do you feel overly active and compelled to do things, like you were driven by a motor?", positiveThreshold: 3),
    ]

    /// Part B — twelve further items. These are not scored against a published
    /// cut-off; they exist to give a clinician additional texture, so the app
    /// reports them descriptively rather than pretending there's a threshold.
    static let partB: [Item] = [
        Item(text: "How often do you make careless mistakes when you have to work on a boring or difficult project?", positiveThreshold: 3),
        Item(text: "How often do you have difficulty keeping your attention when you are doing boring or repetitive work?", positiveThreshold: 3),
        Item(text: "How often do you have difficulty concentrating on what people say to you, even when they are speaking to you directly?", positiveThreshold: 2),
        Item(text: "How often do you misplace or have difficulty finding things at home or at work?", positiveThreshold: 3),
        Item(text: "How often are you distracted by activity or noise around you?", positiveThreshold: 3),
        Item(text: "How often do you leave your seat in meetings or other situations in which you are expected to remain seated?", positiveThreshold: 3),
        Item(text: "How often do you feel restless or fidgety?", positiveThreshold: 3),
        Item(text: "How often do you have difficulty unwinding and relaxing when you have time to yourself?", positiveThreshold: 3),
        Item(text: "How often do you find yourself talking too much when you are in social situations?", positiveThreshold: 3),
        Item(text: "When you're in a conversation, how often do you find yourself finishing the sentences of the people you are talking to, before they can finish them themselves?", positiveThreshold: 3),
        Item(text: "How often do you have difficulty waiting your turn in situations when turn taking is required?", positiveThreshold: 3),
        Item(text: "How often do you interrupt others when they are busy?", positiveThreshold: 3),
    ]

    static var allItems: [Item] { partA + partB }

    /// DSM symptom-cluster groupings, using zero-based indices into `allItems`.
    static let inattentiveIndices = [0, 1, 2, 3, 6, 7, 8, 9, 10]
    static let hyperactiveIndices = [4, 5, 11, 12, 13, 14, 15, 16, 17]

    static func partAPositiveCount(_ answers: [Int]) -> Int {
        var count = 0
        for (i, item) in partA.enumerated() where answers.indices.contains(i) {
            if answers[i] >= item.positiveThreshold { count += 1 }
        }
        return count
    }

    /// Four or more positive Part A items is the published threshold for
    /// "symptoms highly consistent with ADHD in adults; further investigation
    /// is warranted."
    static let partAThreshold = 4

    static func interpretation(partAFlags: Int) -> (headline: String, body: String) {
        if partAFlags >= partAThreshold {
            return (
                "Worth taking to a clinician",
                "You flagged \(partAFlags) of 6 on the screening section. The published threshold is 4. That means your answers fall in the range the screener was built to detect — the range where a proper assessment is considered warranted.\n\nThis is not a diagnosis, and it isn't close to one. What it is: a reason to book the appointment, and something concrete to hand over when you do."
            )
        } else {
            return (
                "Below the screening threshold",
                "You flagged \(partAFlags) of 6 on the screening section, and the threshold is 4.\n\nRead that carefully, because it doesn't mean nothing is going on. Screeners miss people — particularly adults who've spent decades building workarounds, whose presentation is mainly inattentive, or who were never flagged as children because they were quiet rather than disruptive. If your life is genuinely harder than it looks like it should be, that's still worth raising with a clinician. A below-threshold score is not a verdict on your experience."
            )
        }
    }
}

/// Reflective prompts covering the diagnostic requirements the ASRS doesn't touch.
enum ContextQuestions {

    struct Prompt: Identifiable {
        let id = UUID()
        let question: String
        let why: String
    }

    /// DSM-5 requires several symptoms to have been present before age 12.
    static let childhood: [Prompt] = [
        Prompt(
            question: "Before you were 12, did school reports mention things like \"not living up to potential\", daydreaming, chattiness, or careless mistakes?",
            why: "Old school reports are some of the strongest retrospective evidence a clinician can work with. Diagnosis requires the pattern to predate age 12."
        ),
        Prompt(
            question: "As a child, did you lose things, forget instructions, or leave work unfinished more than other kids did?",
            why: "Establishes that the pattern is developmental rather than something that started with adult stress."
        ),
        Prompt(
            question: "Did anyone in your family have similar difficulties, diagnosed or not?",
            why: "ADHD is among the more heritable psychiatric conditions. An undiagnosed parent or sibling with the same pattern is meaningful family history."
        ),
    ]

    /// Impairment must show up in more than one setting.
    static let impairment: [Prompt] = [
        Prompt(
            question: "Where does this cost you most — work, home, money, relationships, health?",
            why: "Symptoms alone aren't enough. Clinicians need functional impairment across two or more settings."
        ),
        Prompt(
            question: "What have you already tried, and what happened?",
            why: "\"I've used four planners and abandoned all of them\" tells a clinician far more than a symptom list does."
        ),
    ]

    /// The differential. Being upfront here protects the user.
    static let differential: [Prompt] = [
        Prompt(
            question: "How is your sleep — and has anyone ever mentioned you snore or stop breathing?",
            why: "Untreated sleep apnoea and chronic sleep deprivation reproduce nearly the entire ADHD attention profile. This gets missed constantly."
        ),
        Prompt(
            question: "Have you had your thyroid, iron/ferritin, B12 and vitamin D checked recently?",
            why: "Thyroid dysfunction and iron deficiency both cause brain fog and fatigue that mimic inattention. A blood panel is cheap and rules them out."
        ),
        Prompt(
            question: "Did the difficulties come and go with periods of low mood or anxiety, or have they been steady since childhood?",
            why: "Depression and anxiety impair concentration episodically. ADHD is comparatively stable across time. The shape of the timeline is diagnostic."
        ),
        Prompt(
            question: "How much alcohol, cannabis or caffeine is in a typical week?",
            why: "Substances affect attention and sleep directly, and clinicians will ask. Knowing the honest answer in advance makes the appointment go better."
        ),
        Prompt(
            question: "Do you also find social situations exhausting in a way that seems different from other people, or rely heavily on routine and sameness?",
            why: "Autism and ADHD co-occur often and overlap on the surface. Naming it early leads to a more useful assessment."
        ),
        Prompt(
            question: "Is there significant trauma in your history?",
            why: "Hypervigilance and dissociation can look a great deal like inattention. This does not rule ADHD out — the two frequently coexist — but a clinician needs to know."
        ),
    ]
}
