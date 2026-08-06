import SwiftUI

/// In-the-moment interventions, indexed by how the problem actually feels.
///
/// The organising principle: someone reaching for this is already depleted, so
/// the entry point has to match their words ("I can't start"), not a taxonomy
/// they'd have to translate into. Each script is short, sequential, and asks for
/// one action at a time — because a list of five things to consider is, right
/// now, another decision to make.
struct ToolStep: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    /// If set, the step gets a countdown and won't let you rush past it.
    var seconds: Int? = nil
    /// If set, the step asks the user to type something.
    var prompt: String? = nil
}

struct Intervention: Identifiable {
    let id: String
    /// Phrased as the user would say it, not as a clinician would classify it.
    let trigger: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let steps: [ToolStep]
    var closingNote: String? = nil
}

enum Toolbox {

    static let all: [Intervention] = [

        Intervention(
            id: "cant-start",
            trigger: "I can't start",
            subtitle: "The task is small and you still can't touch it",
            symbol: "shield.lefthalf.filled",
            tint: Theme.violet,
            steps: [
                ToolStep(
                    title: "Name what's actually there",
                    detail: "Not the task — the feeling in front of it. Dread? Shame about how long it's been? Fear of what you'll find when you open it? Boredom so intense it feels physical?\n\nPut it in words. Naming an emotion measurably lowers its intensity, and this wall is made of emotion.",
                    prompt: "What's in front of the task?"
                ),
                ToolStep(
                    title: "Say it out loud, once",
                    detail: "Actually out loud, even if it feels ridiculous. Silent acknowledgement doesn't do the same thing.\n\n\"I'm avoiding this because I feel ___, and that's understandable.\"",
                    seconds: 15
                ),
                ToolStep(
                    title: "Shrink it until it's almost insulting",
                    detail: "Not the task. The first physical movement. Not \"do the taxes\" — open the folder. Not \"write the email\" — open a blank reply and type \"Hi\".\n\nIf it still feels heavy, it's too big. Halve it again.",
                    prompt: "The first physical movement is..."
                ),
                ToolStep(
                    title: "Move your body first",
                    detail: "Stand up. Ten seconds of anything — shake out your hands, walk to the window and back, press-ups against the wall.\n\nParalysis is a physical state as much as a mental one, and physical states shift faster through the body than through reasoning.",
                    seconds: 20
                ),
                ToolStep(
                    title: "Two minutes. That's the whole deal.",
                    detail: "Do the tiny thing for two minutes. You are genuinely allowed to stop after.\n\nUsually you won't — starting is what was blocked, not continuing. But the permission has to be real, or your brain won't accept the terms.",
                    seconds: 120
                ),
            ],
            closingNote: "If you're still stuck after this, that's information rather than failure. The task may need a person alongside you — try Body Double in Focus."
        ),

        Intervention(
            id: "overwhelmed",
            trigger: "I'm overwhelmed",
            subtitle: "Everything at once, nothing possible",
            symbol: "tornado",
            tint: Theme.coral,
            steps: [
                ToolStep(
                    title: "Breathe out longer than you breathe in",
                    detail: "In through the nose for 4. Out through the mouth for 8.\n\nThe long exhale is the part that matters — it's what engages the parasympathetic response. Five rounds.",
                    seconds: 60
                ),
                ToolStep(
                    title: "Get it out of your head",
                    detail: "Every single thing that's circling. Don't organise, don't judge how big or small, don't stop to categorise. Just empty it out.\n\nOverwhelm is partly a working-memory overflow — you're trying to hold twelve things in a space that fits four. Writing them down isn't a productivity trick, it's decompression.",
                    prompt: "Everything that's circling (one per line)"
                ),
                ToolStep(
                    title: "Circle exactly one",
                    detail: "Not the most important. Not the most urgent. The one you could actually do in the state you're currently in.\n\nOptimising the choice is how you stay frozen. Pick a workable one and move.",
                    prompt: "The one I'm picking"
                ),
                ToolStep(
                    title: "Everything else is parked",
                    detail: "It's written down now. It's not lost. It will still be there.\n\nYou aren't ignoring it — you've put it somewhere. That's the difference between avoidance and triage.",
                    seconds: 15
                ),
            ],
            closingNote: "Your brain dump is saved in Capture. Triage it later, when you have something left in the tank."
        ),

        Intervention(
            id: "spiralling",
            trigger: "I'm spiralling",
            subtitle: "Something landed badly and you can't put it down",
            symbol: "heart.slash",
            tint: Theme.coral,
            steps: [
                ToolStep(
                    title: "Name it as what it is",
                    detail: "\"This is a rejection response. It arrived at full volume before I had a say in it.\"\n\nThis isn't dismissing the feeling. It's putting a frame around it so you're observing it rather than inside it.",
                    seconds: 20
                ),
                ToolStep(
                    title: "Separate what happened from what you added",
                    detail: "Two columns, honestly.\n\nWhat actually happened: the observable facts. What someone said, what they did, the words in the message.\n\nWhat your nervous system wrote on top: the interpretation. What it means about you. What they must think. Where this is heading.\n\nThe second column arrived in under a second and it feels exactly as factual as the first. It isn't.",
                    prompt: "What actually happened (facts only)"
                ),
                ToolStep(
                    title: "Ten minutes before you respond",
                    detail: "Don't reply. Don't seek reassurance. Don't check whether they've read it.\n\nNot forever — ten minutes. The peak of this is genuinely short, and almost everything you'd send during it is something you'd want back.",
                    seconds: 600
                ),
                ToolStep(
                    title: "Change your physical state",
                    detail: "Cold water on your face or wrists. Step outside. Walk somewhere and back.\n\nThe flood is physiological. Interrupting it physically works faster than arguing with the thoughts.",
                    seconds: 90
                ),
                ToolStep(
                    title: "Check what's actually true now",
                    detail: "Is the story still as certain as it was ten minutes ago?\n\nIf yes — fine, there may be something real to address, and you can address it from here rather than from the peak. If it's already loosened, you've just watched the mechanism work. Both outcomes are useful.",
                    prompt: "Where it's at now"
                ),
            ],
            closingNote: "Logged as a rejection-sensitivity episode if you want it — the pattern over time is genuinely worth showing a clinician, since it rarely comes up on standard screeners."
        ),

        Intervention(
            id: "cant-stop-scrolling",
            trigger: "I can't stop scrolling",
            subtitle: "An hour gone and you didn't enjoy any of it",
            symbol: "iphone.slash",
            tint: Theme.sky,
            steps: [
                ToolStep(
                    title: "Stand up",
                    detail: "Right now, before anything else. The posture is part of the loop.",
                    seconds: 10
                ),
                ToolStep(
                    title: "Put the phone somewhere else",
                    detail: "Not face-down beside you. Another surface, ideally another room. Distance matters more than intention.",
                    seconds: 20
                ),
                ToolStep(
                    title: "What were you actually after?",
                    detail: "Scrolling is rarely about the content. Underneath it's usually one of: understimulated and looking for input, avoiding something specific, genuinely exhausted and needing rest, or wanting company.\n\nEach of those has a better answer than the feed. But you have to know which one it is.",
                    prompt: "What I was actually looking for"
                ),
                ToolStep(
                    title: "Take it from the menu instead",
                    detail: "If it was stimulation — a starter from your dopamine menu. If it was avoidance — the \"I can't start\" script. If it was exhaustion — rest properly, deliberately, and without a screen. If it was company — message someone real.",
                    seconds: 20
                ),
            ],
            closingNote: "No shame component to this one. The feed is engineered by people who are very good at their jobs, and it's aimed at exactly the mechanism you're running."
        ),

        Intervention(
            id: "forgot",
            trigger: "I forgot what I was doing",
            subtitle: "You walked in here for a reason",
            symbol: "questionmark.bubble",
            tint: Theme.sky,
            steps: [
                ToolStep(
                    title: "Don't chase it",
                    detail: "Grasping at it makes it worse. Let it sit for a second.",
                    seconds: 10
                ),
                ToolStep(
                    title: "Go back physically",
                    detail: "Return to the room you came from and stand where you were standing.\n\nContext-dependent memory is well established: physical location is a retrieval cue, and re-entering the location often restores it without effort.",
                    seconds: 30
                ),
                ToolStep(
                    title: "Capture it the instant it lands",
                    detail: "The moment it comes back, write it down before doing anything else. Including before doing the thing itself.",
                    prompt: "It was..."
                ),
            ],
            closingNote: "This happens because the intention was being held in working memory with nothing external backing it up. Speaking intentions aloud as you move — \"going to the kitchen for the charger\" — sounds absurd and works surprisingly well."
        ),

        Intervention(
            id: "understimulated",
            trigger: "I'm bored and restless",
            subtitle: "Crawling out of your skin, can't settle to anything",
            symbol: "waveform.path",
            tint: Theme.amber,
            steps: [
                ToolStep(
                    title: "Take this seriously",
                    detail: "Understimulation isn't mild boredom for you — it's aversive and it's urgent, and if you don't answer it deliberately, it gets answered by whatever's nearest.",
                    seconds: 15
                ),
                ToolStep(
                    title: "Something physical, right now",
                    detail: "Twenty seconds of real intensity. Press-ups, stairs, jumping, sprint on the spot, cold water.\n\nIt sounds far too simple for how bad the feeling is. Do it anyway — it moves the needle faster than anything cognitive.",
                    seconds: 30
                ),
                ToolStep(
                    title: "Order from your menu",
                    detail: "You wrote it down in advance precisely so you wouldn't have to decide from this state. Open it and take something.",
                    seconds: 20
                ),
                ToolStep(
                    title: "Or aim it at something useful",
                    detail: "Restlessness is available energy. If there's a physical, low-thought task around — dishes, laundry, tidying one surface — this is the state that does it easily.",
                    seconds: 15
                ),
            ],
            closingNote: nil
        ),

        Intervention(
            id: "phone-call",
            trigger: "I have to make a call",
            subtitle: "It's been on the list for weeks",
            symbol: "phone.badge.waveform",
            tint: Theme.violet,
            steps: [
                ToolStep(
                    title: "What's the fear, specifically?",
                    detail: "Usually one of: I'll be judged for leaving it this long, I won't know what to say, they'll ask something I can't answer, or I'll have to improvise in real time with no undo.\n\nAll of those are addressable — but only once you know which one it is.",
                    prompt: "The specific fear"
                ),
                ToolStep(
                    title: "Write your opening line",
                    detail: "Word for word. Just the first sentence — that's the part that's actually blocked.\n\n\"Hi, I'm calling about ___, my reference is ___.\"",
                    prompt: "First line, verbatim"
                ),
                ToolStep(
                    title: "Write the one thing you need",
                    detail: "The single outcome that makes the call a success. If you get that, you can hang up.",
                    prompt: "What I need from this call"
                ),
                ToolStep(
                    title: "Two lines for the awkward bits",
                    detail: "\"Can you give me a moment to write that down?\"\n\"I'm not sure — can you send that in writing?\"\n\nHaving these ready removes the improvise-under-pressure problem, which is usually the real obstacle.",
                    seconds: 30
                ),
                ToolStep(
                    title: "Dial now, before the prep wears off",
                    detail: "You have the script. Preparation decays fast — the window is open right now and it will not be more open later.",
                    seconds: 20
                ),
            ],
            closingNote: "Log it as a win afterwards. Calls you've been dreading for weeks are exactly the thing your memory will erase by tomorrow."
        ),

        Intervention(
            id: "late-again",
            trigger: "I'm late again",
            subtitle: "Before the spiral gets going",
            symbol: "clock.badge.exclamationmark",
            tint: Theme.amber,
            steps: [
                ToolStep(
                    title: "Deal with the actual situation first",
                    detail: "One message. \"Running about 15 late, sorry.\" No explanation, no self-flagellation.\n\nOver-apologising makes it about your feelings rather than their time, which is worse for both of you.",
                    seconds: 30
                ),
                ToolStep(
                    title: "Cut off the spiral",
                    detail: "You know the sequence: always late, unreliable, everyone's tired of it, why can't I just.\n\nThat rumination will not make you earlier. It's a tax you pay on the way to being late anyway.",
                    seconds: 20
                ),
                ToolStep(
                    title: "One diagnostic question",
                    detail: "Where did the time actually go? Was it a late start, a task that overran, an underestimated journey, or one-more-thing before leaving?\n\nEach has a different fix. \"Try harder\" fixes none of them.",
                    prompt: "Where the time went"
                ),
                ToolStep(
                    title: "One structural change",
                    detail: "Not a resolution — a change to the environment. An alarm for leaving rather than for arriving. A launch pad by the door. Journey time × your multiplier. Nothing new started after a certain hour.",
                    prompt: "The change I'm making"
                ),
            ],
            closingNote: "Lateness in ADHD is usually time blindness plus an underestimated final task, not indifference. It responds to structure and doesn't respond to remorse."
        ),

        Intervention(
            id: "cant-sleep",
            trigger: "I should be asleep",
            subtitle: "Tired, wired, still awake",
            symbol: "moon.zzz",
            tint: Theme.violet,
            steps: [
                ToolStep(
                    title: "What's this hour for?",
                    detail: "Be honest. Are you avoiding tomorrow, or reclaiming time because today didn't contain any that was yours?\n\nIf it's the second one — that need is real, and pretending otherwise is why every bedtime plan you've made has failed.",
                    prompt: "What I'm actually getting from being up"
                ),
                ToolStep(
                    title: "Get tomorrow out of your head",
                    detail: "Everything you're holding onto so you won't forget it by morning. Write it down and stop holding it.",
                    prompt: "Anything I'm trying not to forget"
                ),
                ToolStep(
                    title: "Dim everything",
                    detail: "Lights down, screen brightness to minimum. If the ceiling light is on, that's the first thing.",
                    seconds: 30
                ),
                ToolStep(
                    title: "Lower the stimulation, don't remove it",
                    detail: "\"Lie in the dark with your thoughts\" is not achievable for you and it isn't worth pretending otherwise. An audiobook or a familiar podcast at low volume gives the mind something to hold that isn't tomorrow.",
                    seconds: 30
                ),
                ToolStep(
                    title: "Tomorrow's fix is in the morning",
                    detail: "Bright light within an hour of waking does more for a delayed body clock than anything you can do at this hour.\n\nTonight is already what it is. Go gently on yourself about it.",
                    seconds: 20
                ),
            ],
            closingNote: "Recurring? Read \"Why you can't go to bed\" in Learn. Delayed sleep phase is common in ADHD and it's a physiological problem, not a discipline one."
        ),

        Intervention(
            id: "transition",
            trigger: "I can't switch tasks",
            subtitle: "Stuck in the last thing, or stuck between things",
            symbol: "arrow.triangle.swap",
            tint: Theme.mint,
            steps: [
                ToolStep(
                    title: "Close the last thing properly",
                    detail: "One line on where you got to and what's next. Unclosed loops keep consuming attention in the background.",
                    prompt: "Where I left off"
                ),
                ToolStep(
                    title: "Move, physically",
                    detail: "Stand, walk somewhere, get water. Transitions land better when the body marks them — the same reason a commute used to work.",
                    seconds: 60
                ),
                ToolStep(
                    title: "Say the next thing out loud",
                    detail: "\"I am now going to ___ for ___ minutes.\"\n\nDeclaring it externally is doing real work here — it's the same mechanism that makes body doubling effective.",
                    prompt: "Next task, and for how long"
                ),
            ],
            closingNote: "Switching is expensive for you specifically. Batching similar work and building in a real gap between different kinds of work costs less than powering through."
        ),

        Intervention(
            id: "flooded",
            trigger: "I'm furious",
            subtitle: "Anger arrived at full volume and it's still climbing",
            symbol: "flame",
            tint: Theme.coral,
            steps: [
                ToolStep(
                    title: "Leave the situation if you can",
                    detail: "Another room. Outside. Anywhere that isn't here.\n\nNothing you say in the next few minutes will be something you're glad you said.",
                    seconds: 30
                ),
                ToolStep(
                    title: "Cold, on your face",
                    detail: "Cold water on the face, or something cold held against your cheeks and around the eyes, for thirty seconds.\n\nThis triggers the mammalian dive reflex — heart rate drops, physiological arousal drops. It's a DBT distress-tolerance technique and it works on the body directly, which is where the problem currently is.",
                    seconds: 45
                ),
                ToolStep(
                    title: "Burn some of it off",
                    detail: "Sixty seconds of hard physical output. Stairs, press-ups, fast walking, anything intense.\n\nAnger is mobilised energy. It settles much faster once the energy has somewhere to go.",
                    seconds: 60
                ),
                ToolStep(
                    title: "Now paced breathing",
                    detail: "In for 4, out for 8. Ten rounds. The long exhale is the active ingredient.",
                    seconds: 90
                ),
                ToolStep(
                    title: "Check before re-entering",
                    detail: "Still above a 7 out of 10? Stay out. There's no deadline on going back in, and the thing you'd say at a 7 is the thing you'll be apologising for.",
                    prompt: "Where I'm at, 0-10"
                ),
            ],
            closingNote: "Emotional dysregulation in ADHD means arriving at full intensity without a ramp. That's a real mechanism — and it's still your responsibility to handle, which is what this script is for."
        ),

        Intervention(
            id: "decision-paralysis",
            trigger: "I can't decide",
            subtitle: "Stuck between options, and the stuckness is costing more than the choice",
            symbol: "arrow.triangle.branch",
            tint: Theme.mint,
            steps: [
                ToolStep(
                    title: "How much does this actually matter?",
                    detail: "Reversible and low-stakes? Then the deliberation has already cost more than the wrong choice would. Take the next step anyway — you'll feel better having decided.",
                    seconds: 20
                ),
                ToolStep(
                    title: "Cut it to two",
                    detail: "Whatever the list is, get it to two. Comparing across many options is where the freeze lives — and past a handful, more options reliably make it harder, not better.",
                    prompt: "The two options"
                ),
                ToolStep(
                    title: "Flip a coin, and watch yourself",
                    detail: "Assign each option to a side and flip.\n\nYou're not obeying the coin. You're watching your reaction to the result — relief or disappointment tells you what you already preferred. That's the information you couldn't reach by thinking.",
                    seconds: 30
                ),
                ToolStep(
                    title: "Commit and close it",
                    detail: "Say it: \"I've chosen ___ and I'm not reopening it today.\"\n\nRe-litigating a made decision is where the remaining cost is.",
                    prompt: "I've chosen"
                ),
            ],
            closingNote: nil
        ),

        Intervention(
            id: "mess",
            trigger: "The mess is too much",
            subtitle: "It's been building and now you can't look at it",
            symbol: "shippingbox",
            tint: Theme.amber,
            steps: [
                ToolStep(
                    title: "Forget the room",
                    detail: "You're not tidying the room. The room is not on the table. Trying to see the whole thing is what's freezing you.",
                    seconds: 15
                ),
                ToolStep(
                    title: "One surface. Pick it.",
                    detail: "The smallest one. A single table, one counter, the bedside. That's the entire scope now.",
                    prompt: "The one surface"
                ),
                ToolStep(
                    title: "Five things, that's all",
                    detail: "Not the surface — five objects. Anywhere they belong. Count them out.\n\nIf you stop at five, that's a genuine success and the script is over.",
                    seconds: 180
                ),
                ToolStep(
                    title: "Still going?",
                    detail: "Then set ten minutes and keep going with music on. Stop when the timer stops, even mid-flow.\n\nStopping while it still feels good is what makes tomorrow's attempt possible. Going until you're wrecked is what turned it into this.",
                    seconds: 30
                ),
            ],
            closingNote: "Visible clutter and ADHD reinforce each other — the mess costs attention, which makes the mess harder. Bit by bit is the only version that holds."
        ),

        Intervention(
            id: "rumination",
            trigger: "I can't stop replaying it",
            subtitle: "Something from earlier, or from nine years ago",
            symbol: "arrow.triangle.2.circlepath",
            tint: Theme.sky,
            steps: [
                ToolStep(
                    title: "Notice the loop is a loop",
                    detail: "You've been round this several times already. It hasn't produced anything new on any of them.\n\nThat's the tell: this isn't problem-solving that's nearly there. It's a groove.",
                    seconds: 20
                ),
                ToolStep(
                    title: "Is there an action in it?",
                    detail: "Sometimes there genuinely is — an apology, a message, a decision. If so, write it down as a task and the loop can stop carrying it.\n\nIf there's no action, name that plainly: \"there is nothing to do here.\"",
                    prompt: "Action, or 'nothing to do'"
                ),
                ToolStep(
                    title: "Postpone it",
                    detail: "\"I'll think about this tomorrow at 6pm.\"\n\nThis sounds like it couldn't possibly work. It has decent support in the worry-postponement literature, and it works better than trying to stop — because you're not refusing the thought, you're scheduling it.",
                    seconds: 20
                ),
                ToolStep(
                    title: "Give the mind something demanding",
                    detail: "Suppression fails; occupation works. Something with enough load to crowd it out — count backwards from 300 in 7s, name every street on a familiar route, describe the room in detail.",
                    seconds: 120
                ),
            ],
            closingNote: "If the replaying is nightly or centred on the same event, that's worth raising with a clinician in its own right."
        ),
    ]

    static func intervention(id: String) -> Intervention? {
        all.first { $0.id == id }
    }
}
