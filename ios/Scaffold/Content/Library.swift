import Foundation

// MARK: - Article structure

enum Block: Identifiable {
    case heading(String)
    case paragraph(String)
    case bullets([String])
    case callout(String)
    case quote(text: String, attribution: String)

    var id: String {
        switch self {
        case .heading(let s): return "h" + s
        case .paragraph(let s): return "p" + String(s.prefix(40))
        case .bullets(let b): return "b" + (b.first ?? "")
        case .callout(let s): return "c" + String(s.prefix(40))
        case .quote(let t, _): return "q" + String(t.prefix(40))
        }
    }
}

enum ArticleCategory: String, CaseIterable, Identifiable {
    case foundations = "Foundations"
    case time = "Time"
    case doing = "Getting things done"
    case feelings = "Feelings"
    case body = "Body & sleep"
    case identity = "Identity & diagnosis"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .foundations: return "book.closed"
        case .time: return "clock"
        case .doing: return "checkmark.circle"
        case .feelings: return "heart"
        case .body: return "bed.double"
        case .identity: return "person.crop.circle.badge.questionmark"
        }
    }
}

struct Article: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let category: ArticleCategory
    let symbol: String
    let readMinutes: Int
    let body: [Block]
    let sources: [String]
}

// MARK: - The library

enum Library {

    static var byCategory: [(ArticleCategory, [Article])] {
        ArticleCategory.allCases.compactMap { cat in
            let items = all.filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    static let all: [Article] = [

        // MARK: Foundations

        Article(
            id: "not-lazy",
            title: "It isn't that you don't know what to do",
            subtitle: "The single most useful reframe in the adult ADHD literature",
            category: .foundations,
            symbol: "lightbulb",
            readMinutes: 4,
            body: [
                .paragraph("If you're reading this, you can probably describe your ideal morning in detail. You know that the tax return would take forty minutes. You know that going to bed now is the correct move. You have known all of this, precisely and in advance, every single time."),
                .paragraph("And you still didn't do it. Which is why the explanation you've most likely landed on is a character flaw."),
                .heading("The knowledge–performance gap"),
                .paragraph("Russell Barkley's central argument, developed across decades of research, is that ADHD is not a disorder of knowing. It is a disorder of doing what you already know, at the moment doing it matters."),
                .quote(text: "ADHD is not a disorder of knowledge. It is a disorder of performance — of using what you know at the points of performance where it matters.", attribution: "Russell A. Barkley"),
                .paragraph("This distinction explains something that otherwise makes no sense: why advice keeps failing you. Every productivity book, every well-meaning suggestion, every system you've bought into targets knowledge. But knowledge was never the bottleneck. The bottleneck sits between knowing and acting, and no amount of additional knowing widens it."),
                .heading("Why this reframe is worth something"),
                .paragraph("It changes what counts as a reasonable solution. If the gap is in execution rather than understanding, then interventions that put structure *outside* your head — visible, external, present at the moment of action — aren't cheating or crutches. They're the interventions that match the actual problem."),
                .paragraph("A timer you can see beats resolving to keep track of time. A note by the door beats intending to remember. A person sitting next to you beats deciding to focus. In every case the point is the same: move the regulation out of working memory and into the environment, where it doesn't have to be held."),
                .callout("Everything in this app is built on that single move. External, visible, present at the point of performance."),
            ],
            sources: [
                "Barkley, R. A. — Attention-Deficit Hyperactivity Disorder: A Handbook for Diagnosis and Treatment (4th ed., Guilford Press)",
                "Barkley, R. A. (1997) — Behavioral inhibition, sustained attention, and executive functions",
            ]
        ),

        Article(
            id: "interest-nervous-system",
            title: "The interest-based nervous system",
            subtitle: "Why you can do twelve hours of one thing and not four minutes of another",
            category: .foundations,
            symbol: "bolt.heart",
            readMinutes: 4,
            body: [
                .paragraph("Most productivity advice quietly assumes your brain allocates attention according to importance. Decide something matters, and attention follows. For a lot of people that's roughly true."),
                .paragraph("If it were true for you, you would not have spent six hours reorganising a bookshelf on the day before a deadline."),
                .heading("What actually turns the engine over"),
                .paragraph("William Dodson's clinical framing is that ADHD attention is recruited by interest rather than importance. Four things reliably generate enough activation to start:"),
                .bullets([
                    "Interest — it's genuinely engaging to you, right now",
                    "Novelty — it's new, or it's been made new again",
                    "Challenge — there's a real chance of failing at it",
                    "Urgency — the consequence has arrived, and it's here",
                ]),
                .paragraph("Notice what's absent from that list. \"It's important.\" \"I promised someone.\" \"It's good for me long-term.\" Those are the levers you keep reaching for, and they are not connected to anything."),
                .heading("The trap this sets"),
                .paragraph("Urgency is the one that's always available. You can manufacture it for free, at any time, by waiting. So a great many capable adults end up running their entire life on deadline panic — which does work, and which also costs a fortune in stress, sleep and self-respect, and collapses completely the moment a task has no external deadline."),
                .heading("Using it deliberately instead"),
                .paragraph("The move is to stop trying to run on importance and start engineering the other three on purpose. Add novelty: different room, different chair, music you haven't worn out. Add challenge: race a timer, cut the scope until it's genuinely tight. Add interest by attaching something you like to something you don't — a podcast that only gets played during the washing-up."),
                .callout("You aren't broken for needing this. You're running a nervous system with different ignition requirements, and it's worth learning what actually turns it over."),
            ],
            sources: [
                "Dodson, W. — Secrets of Your ADHD Brain (ADDitude)",
                "Volkow, N. D. et al. (2009) — Evaluating dopamine reward pathway in ADHD, JAMA",
            ]
        ),

        Article(
            id: "executive-functions",
            title: "The systems that run the show",
            subtitle: "Executive function, without the jargon",
            category: .foundations,
            symbol: "slider.horizontal.3",
            readMinutes: 5,
            body: [
                .paragraph("\"Executive function\" sounds like management consultancy. It's really just the set of processes that let you act on your own intentions instead of whatever's in front of you."),
                .heading("The pieces"),
                .bullets([
                    "Inhibition — the pause between impulse and action. Everything else is built on this one.",
                    "Working memory — holding the thing in mind while you do something else. Why you walk into rooms.",
                    "Emotional self-regulation — turning the volume down on a feeling once it has arrived.",
                    "Self-motivation — generating drive when nothing external supplies it.",
                    "Planning and problem-solving — running the simulation before acting rather than during.",
                ]),
                .paragraph("Barkley's model treats inhibition as foundational: it buys the delay in which the other four can operate. Shorten the pause and everything downstream gets less time to run."),
                .heading("The thirty percent rule"),
                .paragraph("A clinically useful rule of thumb from the same body of work: in executive-function terms, expect a developmental lag of roughly 30% relative to age peers. For a 30-year-old that's the self-management of someone in their early twenties."),
                .paragraph("This is not an insult and it isn't about intelligence — the two are unrelated. But it does explain the specific, disorienting experience of being obviously capable at your actual work while losing to a form that's been on the table for three weeks."),
                .callout("Expecting age-typical self-management from a system running a 30% lag is how you end up furious at yourself every evening. Adjust the expectation and you can start solving the real problem."),
            ],
            sources: [
                "Barkley, R. A. (2012) — Executive Functions: What They Are, How They Work, and Why They Evolved",
                "Brown, T. E. (2005) — Attention Deficit Disorder: The Unfocused Mind in Children and Adults",
            ]
        ),

        // MARK: Time

        Article(
            id: "time-blindness",
            title: "Time blindness",
            subtitle: "Why the future feels theoretical until it's on top of you",
            category: .time,
            symbol: "clock.badge.exclamationmark",
            readMinutes: 5,
            body: [
                .paragraph("Two distinct failures hide under \"bad with time\", and they need different fixes."),
                .heading("One: you can't feel it passing"),
                .paragraph("Most people carry a rough background sense of elapsed time. Yours is unreliable. Twenty minutes and ninety minutes feel similar from the inside, especially when you're absorbed in something. This is partly a working-memory problem — tracking duration means holding a start point while attending to something else, which is exactly the operation that's expensive for you."),
                .paragraph("The fix is external and it must be *visible*, not merely available. A number you'd have to check is a poor substitute for a shape that's visibly shrinking in your peripheral vision. This is why the timer in this app is a depleting ring rather than a digital readout."),
                .heading("Two: the future is discounted steeply"),
                .paragraph("Barkley calls this temporal myopia — nearsightedness for time. Consequences more than a short distance away lose their motivational force disproportionately fast. Not \"forgotten\": genuinely less real, in the way that something you've been told about is less real than something you can see."),
                .paragraph("It's why a deadline three weeks out generates nothing, and the same deadline tomorrow generates enough adrenaline to work through the night. Nothing changed about its importance. It moved into range."),
                .heading("What actually helps"),
                .bullets([
                    "Visible analogue countdowns rather than digital clocks — shape beats number",
                    "Pull deadlines forward artificially, and give the fake one a real witness",
                    "Time-anchor to events, not clock times: \"after coffee\", not \"at 9:40\"",
                    "Measure your predictions against reality until you know your personal multiplier",
                    "Alarms for *starting*, not just for being late — the start is what's missing",
                ]),
                .callout("Scaffold's Focus tab logs what you predicted against what it took. After a handful of tasks it can tell you your actual multiplier — most people land somewhere between 1.5× and 2.5×, and simply knowing the number changes how you plan."),
            ],
            sources: [
                "Barkley, R. A. (1997) — ADHD and the Nature of Self-Control",
                "Ptacek, R. et al. (2019) — Clinical implications of the perception of time in ADHD, Medical Science Monitor",
                "Weissenberger, S. et al. (2021) — Time perception in adults with ADHD",
            ]
        ),

        Article(
            id: "time-multiplier",
            title: "The planning fallacy, doubled",
            subtitle: "Everyone underestimates. You underestimate systematically.",
            category: .time,
            symbol: "chart.line.uptrend.xyaxis",
            readMinutes: 3,
            body: [
                .paragraph("Kahneman and Tversky named the planning fallacy in 1979: humans in general underestimate how long their own tasks will take, and keep doing it even when they have direct experience of the same task overrunning."),
                .paragraph("The ADHD version is the same bias with more amplitude. Duration estimation leans on working memory and on recalling how long the thing took last time — both of which are running at a disadvantage."),
                .heading("Why systematic error is good news"),
                .paragraph("Random error can't be corrected. Systematic error can. If you're consistently out by roughly the same factor, that factor is measurable, and once measured it's just arithmetic."),
                .paragraph("So stop trying to estimate better. You will not get better at estimating. Estimate the way you always do, then multiply by your number."),
                .heading("Getting your number"),
                .bullets([
                    "Before starting, write down your gut estimate. Don't refine it — the gut number is the one being calibrated.",
                    "Time the actual work.",
                    "After roughly five tasks, the ratio stabilises enough to trust.",
                ]),
                .callout("Most people are shocked by their multiplier the first time they see it, and then find it oddly freeing. \"I'm not bad at time, I'm consistently 2.1× — I can just plan for 2.1×.\""),
            ],
            sources: [
                "Kahneman, D. & Tversky, A. (1979) — Intuitive prediction: biases and corrective procedures",
                "Buehler, R., Griffin, D. & Ross, M. (1994) — Exploring the planning fallacy",
            ]
        ),

        // MARK: Getting things done

        Article(
            id: "wall-of-awful",
            title: "The Wall of Awful",
            subtitle: "Why a two-minute task can be genuinely impossible",
            category: .doing,
            symbol: "shield.lefthalf.filled",
            readMinutes: 4,
            body: [
                .paragraph("There's an email you need to send. It would take ninety seconds. It has been on the list for five weeks and you have thought about it, without exaggeration, two hundred times."),
                .paragraph("From outside, this is inexplicable. From inside, there is something there. An actual obstacle, with weight."),
                .heading("What the wall is made of"),
                .paragraph("Brendan Mahan's model: every time a task goes badly — you forget, you disappoint someone, you feel stupid — a brick of emotional residue gets attached to it. Over years, tasks that have gone wrong repeatedly accumulate a wall you have to get over before you can begin."),
                .paragraph("The wall is invisible to everyone else, which is why their advice is always \"just do it.\" They're looking at a ninety-second email. You're looking at a ninety-second email behind fifteen years of bricks."),
                .heading("The four things people do"),
                .bullets([
                    "Try to go around — avoidance. Adds a brick.",
                    "Try to smash through — force it with anger or panic. Sometimes works, exhausting, adds bricks either way.",
                    "Sit at the base and stare — the paralysis everyone recognises.",
                    "Climb it — acknowledge the wall exists, feel what's actually there, and go over.",
                ]),
                .heading("Climbing, specifically"),
                .paragraph("Climbing starts with naming the emotion, because the wall is made of emotion and unnamed emotion can't be worked with. Not \"I need to send this email\" but \"I feel ashamed that I left it this long, and I'm scared of what they'll say.\""),
                .paragraph("That sounds like a soft intervention. It isn't. The affect-labelling research is fairly consistent: putting feelings into words reduces amygdala reactivity. Naming it takes the charge down enough to move."),
                .callout("If a task is absurdly small and still undoable, stop looking for a productivity fix. There's a wall. The Toolbox has a guided climb under \"I can't start\"."),
            ],
            sources: [
                "Mahan, B. — ADHD Essentials: The Wall of Awful",
                "Lieberman, M. D. et al. (2007) — Putting feelings into words: affect labeling disrupts amygdala activity, Psychological Science",
            ]
        ),

        Article(
            id: "body-doubling",
            title: "Body doubling",
            subtitle: "Why another person in the room makes the impossible task possible",
            category: .doing,
            symbol: "person.2.fill",
            readMinutes: 3,
            body: [
                .paragraph("You've probably noticed you can do the washing-up while someone's on the phone to you, and not otherwise. Or that you cleared your entire inbox in a café. Or that the flat only gets tidied when someone's coming over."),
                .paragraph("That's body doubling, and it's one of the most reliably reported strategies in the adult ADHD community."),
                .heading("The mechanism"),
                .paragraph("The other person does nothing. They don't help, supervise, or even look at you. Their presence alone supplies enough activation to cross the threshold that starting requires — the working hypothesis being that social presence provides the arousal your system struggles to generate on demand for a task it finds uninteresting."),
                .paragraph("Worth saying plainly: the formal evidence base here is thinner than the strength of the anecdotal reports. It's widely used, widely described as effective, and under-studied. Treat it as a well-supported practice rather than an established finding."),
                .heading("Getting it to work"),
                .bullets([
                    "Presence, not accountability — being watched adds pressure, which adds bricks",
                    "Say out loud what you're about to do, then start. The declaration is doing real work.",
                    "A video call with someone silently working counts. So does a café. So does a scheduled call where you both just... work.",
                    "Same time each week beats ad hoc, because it removes the decision to arrange it",
                ]),
                .callout("Scaffold's Body Double mode simulates the rhythm — a start declaration, periodic quiet check-ins, a close-out. It's a stand-in, not a replacement. A real person is better."),
            ],
            sources: [
                "Eagle, T. et al. (2023) — Proposing body doubling as a continuum of space/time and mutuality, CHI EA",
                "ADDA — Body Doubling: The ADHD Productivity Strategy",
            ]
        ),

        Article(
            id: "task-paralysis",
            title: "Task paralysis isn't procrastination",
            subtitle: "Two different states that need opposite responses",
            category: .doing,
            symbol: "pause.circle",
            readMinutes: 3,
            body: [
                .paragraph("Procrastination is choosing something more pleasant instead. There's a substitution: you meant to do the report and you watched a video."),
                .paragraph("Task paralysis is different. You aren't doing anything else. You're sitting there, aware of the task, wanting to do the task, and nothing is happening. Often the enjoyable substitute isn't even enjoyable — you're scrolling without registering anything."),
                .heading("Why the distinction matters"),
                .paragraph("Standard procrastination advice — remove temptation, block the site, increase the stakes — is aimed at the substitution. Applied to paralysis it does nothing except add shame, because there was no temptation to remove. Raising the stakes on someone who is already frozen makes the freeze worse."),
                .heading("What paralysis usually responds to"),
                .bullets([
                    "Radical scope reduction — not the task, the first physical movement. Open the document. That's the whole goal.",
                    "Changing physical state first — stand up, cold water, ninety seconds of movement. Body before brain.",
                    "Externalising the choice — write three options down, pick with a coin. The deciding is what's stuck, not the doing.",
                    "Another person's presence",
                    "Saying the next action out loud",
                ]),
                .callout("Rule of thumb: if you're doing something else, treat it as procrastination. If you're doing nothing, treat it as paralysis and cut the scope until the first step is almost insultingly small."),
            ],
            sources: [
                "Ramsay, J. R. & Rostain, A. L. (2015) — Cognitive Behavioral Therapy for Adult ADHD",
                "Solanto, M. V. (2011) — Cognitive-Behavioral Therapy for Adult ADHD: Targeting Executive Dysfunction",
            ]
        ),

        Article(
            id: "object-permanence",
            title: "Out of sight, genuinely out of mind",
            subtitle: "Why things you can't see stop existing",
            category: .doing,
            symbol: "eye.slash",
            readMinutes: 3,
            body: [
                .paragraph("The vegetables liquefy in the drawer. The friend you love goes six months without a message. The important document is filed correctly, which is to say it is gone forever."),
                .paragraph("People in ADHD communities call this object permanence, borrowing the developmental term loosely. It's not literally that — it's prospective memory and cue-dependent recall. But the lived experience is close enough that the name stuck: what you can't see doesn't reliably generate a thought."),
                .heading("The organising trap"),
                .paragraph("Conventional tidiness — everything in drawers, surfaces clear, items filed away — is the exact opposite of what you need. A perfectly organised system where nothing is visible is a system where nothing exists. This is why the tidy-up never survives the week."),
                .heading("Design for visibility instead"),
                .bullets([
                    "Clear containers, open shelves, pegboards. See it or lose it.",
                    "One designated launch pad by the door for everything that leaves with you",
                    "Keep in-progress work physically out — a visible pile is a working-memory extension",
                    "Move calendar events into the physical world: put the passport on the suitcase",
                    "Recurring nudges for people you care about. Not cold — a prosthetic for a memory that doesn't cue.",
                ]),
                .callout("Aim for \"visible and roughly grouped\", not \"tidy\". Tidy is a system optimised for someone else's brain, and you will lose to it every time."),
            ],
            sources: [
                "Fuermaier, A. B. M. et al. (2013) — Prospective memory in adults with ADHD",
                "Altgassen, M. et al. (2014) — Prospective memory deficits in ADHD",
            ]
        ),

        Article(
            id: "dopamine-menu",
            title: "Build a dopamine menu",
            subtitle: "Decide what you reach for before you need to reach for something",
            category: .doing,
            symbol: "list.clipboard",
            readMinutes: 3,
            body: [
                .paragraph("Understimulation isn't a mild state for you. It's aversive, and it's urgent, and when it hits, your brain will find stimulation in whatever is nearest. Which is a phone engineered by very talented people to be the nearest thing."),
                .paragraph("The problem isn't that you reach for something. It's that you're choosing in the exact moment you're least equipped to choose."),
                .heading("The menu"),
                .paragraph("A concept popularised by Eric Tivers and now widespread in ADHD coaching: write the options down in advance, structured like a restaurant menu, while your judgement is intact."),
                .bullets([
                    "Starters — under 2 minutes. Cold water on the face, ten press-ups, step outside, one song loud.",
                    "Mains — 20 to 60 minutes and genuinely restorative. A walk, an instrument, cooking, actual exercise.",
                    "Sides — things that pair with boring work. Podcast during chores, music during admin.",
                    "Desserts — the good stuff that eats the evening if unsupervised. Games, scrolling, binge-watching. Not forbidden. Portioned.",
                ]),
                .paragraph("Keep it somewhere you'll actually see it when the craving arrives. On the fridge. In this app. Not in a note you'd have to remember to open."),
                .callout("Scaffold keeps your menu one tap from the Today screen, and offers it by default whenever you say you're understimulated."),
            ],
            sources: [
                "Tivers, E. — ADHD reWired: the Dopamine Menu",
                "Volkow, N. D. et al. (2011) — Motivation deficit in ADHD is associated with dysfunction of the dopamine reward pathway",
            ]
        ),

        // MARK: Feelings

        Article(
            id: "rsd",
            title: "Rejection sensitivity",
            subtitle: "The part nobody warned you about",
            category: .feelings,
            symbol: "heart.slash",
            readMinutes: 5,
            body: [
                .paragraph("A colleague replies \"ok\" instead of \"ok!\" and your entire afternoon is gone. A mild piece of feedback lands like a physical blow and you're still composing responses to it at 2am. Someone cancels a plan and you know — not suspect, know — that they've been tolerating you for years."),
                .paragraph("If that's recognisable, the term you're looking for is rejection sensitivity."),
                .heading("What it is and isn't"),
                .paragraph("Rejection sensitive dysphoria is a clinical description popularised by William Dodson, not a DSM-5 diagnosis. That distinction matters and you'll see it argued about: the underlying construct — emotional dysregulation in ADHD — is well established, while RSD as a specific named entity has a thinner formal evidence base and is the subject of genuine debate among researchers."),
                .paragraph("What is not in dispute: emotional dysregulation is extremely common in adult ADHD, with estimates commonly ranging from about 30% to 70%, and it predicts quality of life more strongly than the inattention and hyperactivity symptoms do. That last finding is worth sitting with, because it's the part that gets left out of every ADHD checklist you've ever seen."),
                .heading("Why it's so fast"),
                .paragraph("The emotion arrives at full intensity before any appraisal happens. There's no ramp. By the time the reasoning part of you is online, you are already flooded and it is already writing the story. This is what makes \"just don't take it personally\" useless — the taking-it-personally completed before you had a vote."),
                .heading("What actually helps in the moment"),
                .bullets([
                    "Name it while it's happening: \"this is a rejection response.\" Affect labelling measurably reduces the intensity.",
                    "Delay any response by ten minutes. Not forever — ten minutes. The peak is short.",
                    "Separate the observation from the story. \"They replied briefly\" is data. \"They're done with me\" is a story your nervous system wrote at speed.",
                    "Do not seek reassurance during the peak. Relief lasts minutes and trains the loop.",
                    "Change your physical state — cold water, walking. Shifting the body shifts the flood faster than reasoning does.",
                ]),
                .heading("What helps long-term"),
                .paragraph("Knowing the pattern has a name and isn't a personal defect does a surprising amount of work on its own. Beyond that: CBT approaches adapted for adult ADHD address exactly this, and if the episodes are frequent or severe it's worth naming specifically to a clinician — it's treatable, and it's routinely missed because it isn't on the standard screener."),
                .callout("The Toolbox has a guided script for this under \"I'm spiralling\". Use it during, not after — that's when it's worth something."),
            ],
            sources: [
                "Dodson, W. — Rejection Sensitive Dysphoria and ADHD (ADDitude)",
                "Beheshti, A. et al. (2020) — Emotion dysregulation in adults with ADHD: a meta-analysis, BMC Psychiatry",
                "Shaw, P. et al. (2014) — Emotional dysregulation in ADHD, American Journal of Psychiatry",
                "Bodalski, E. A. et al. (2019) — Adult ADHD, emotion dysregulation, and functional outcomes",
            ]
        ),

        Article(
            id: "shame",
            title: "The shame layer",
            subtitle: "Thirty years of small failures, and what they built",
            category: .feelings,
            symbol: "cloud.rain",
            readMinutes: 4,
            body: [
                .paragraph("By adulthood, an undiagnosed person has absorbed an enormous amount of feedback. Careless. Lazy. Not applying yourself. So much potential. You'd forget your head. Why can't you just."),
                .paragraph("Estimates put it around twenty thousand more corrective messages than a neurotypical child receives by age twelve. Whatever the true figure, the accumulation is not neutral. It becomes the voice you use on yourself."),
                .heading("What it costs"),
                .paragraph("The secondary damage is often larger than the primary symptoms. Not attempting things you'd be good at. Overworking to pre-empt criticism. Apologising constantly. Perfectionism as armour — if it's flawless nobody can say the thing they've always said. And the specific exhaustion of masking, which is expensive in a way that doesn't show up anywhere."),
                .heading("Why late recognition hits so hard"),
                .paragraph("People often expect relief and get grief instead. Relief that there's an explanation, and then genuine mourning for the version of your life that had support in it. Both at once is normal, and the grief is not ingratitude."),
                .heading("Working on it"),
                .bullets([
                    "Separate the mechanism from the meaning. \"I forgot\" is a working-memory event. \"I'm a terrible friend\" is thirty years of narration attached to it.",
                    "Notice how you'd speak to someone else with the same difficulty. The gap is the problem, not your standards.",
                    "Log what worked. Your memory for your own competence is unreliable and needs external evidence — which is what the Wins tab is for.",
                    "Self-compassion here isn't indulgence. Neff's research consistently links it to better follow-through, not worse.",
                ]),
                .callout("If the self-criticism is constant or you're low most days, that's worth raising with a clinician on its own — independently of anything ADHD-related. It's treatable and it doesn't have to wait for an assessment."),
            ],
            sources: [
                "Neff, K. D. (2011) — Self-Compassion: The Proven Power of Being Kind to Yourself",
                "Beaton, D. M. et al. (2022) — Self-compassion and PTSD-like symptoms in adults with ADHD",
                "Young, S. et al. (2020) — Females with ADHD: consensus statement on identification and treatment, BMC Psychiatry",
            ]
        ),

        // MARK: Body & sleep

        Article(
            id: "sleep",
            title: "Why you can't go to bed",
            subtitle: "Delayed body clock, plus the only hours that felt like yours",
            category: .body,
            symbol: "moon.stars",
            readMinutes: 4,
            body: [
                .paragraph("You are tired. You know exactly what time it is. You want to sleep. You are still awake at 1:40am, and not doing anything you'd describe as worth being awake for."),
                .heading("Two things are going on"),
                .paragraph("First, the physiology. Delayed sleep phase is markedly more common in ADHD — melatonin onset runs late, so the biological signal to sleep simply hasn't arrived at the hour your schedule requires. You aren't ignoring the signal. It isn't there yet."),
                .paragraph("Second, the psychology. Revenge bedtime procrastination: when the whole day has been spent meeting other people's demands, the late-night hours become the only stretch that belongs to you. Giving them up feels like surrendering the last piece of autonomy in the day — and it is, in a real sense, exactly that."),
                .heading("Why willpower fails here"),
                .paragraph("Because both drivers are legitimate. Your body genuinely isn't ready, and the unmet need for unclaimed time is genuinely unmet. Discipline aimed at either one loses."),
                .heading("What has better odds"),
                .bullets([
                    "Deliberately claim time earlier in the day. If the need gets met at 8pm it's less desperate at midnight.",
                    "Bright light within an hour of waking — the strongest lever on a delayed clock, and it works on the front end, not the back.",
                    "Shift bedtime in 15-minute steps. An hour-and-a-half jump will fail and cost you the attempt.",
                    "A wind-down alarm, not a bedtime alarm. The transition is the hard part, not the sleeping.",
                    "Discuss timed low-dose melatonin with a clinician — evidence for circadian shift in ADHD is reasonable, but timing is what makes it work, and getting that wrong makes it useless.",
                    "Make the last hour non-zero-stimulation. \"Lie in the dark doing nothing\" is not achievable for you; audiobook or podcast is.",
                ]),
                .callout("Get screened for sleep apnoea if you snore, wake unrefreshed, or someone has mentioned you stop breathing. Untreated apnoea produces almost the whole ADHD attention profile, and it's missed constantly."),
            ],
            sources: [
                "Van Veen, M. M. et al. (2010) — Delayed circadian rhythm in adults with ADHD and chronic sleep-onset insomnia, Biological Psychiatry",
                "Kooij, J. J. S. & Bijlenga, D. (2013) — The circadian rhythm in adult ADHD",
                "Bijlenga, D. et al. (2019) — The role of the circadian system in the etiology of ADHD",
            ]
        ),

        Article(
            id: "movement",
            title: "Movement is not a wellness suggestion",
            subtitle: "The intervention with the least glamorous delivery and the best evidence",
            category: .body,
            symbol: "figure.run",
            readMinutes: 3,
            body: [
                .paragraph("Being told to exercise when you can't start a task is infuriating advice, so here's the specific version, which is more useful than the general one."),
                .heading("The finding"),
                .paragraph("Acute aerobic exercise — a single session, roughly 20 to 30 minutes at moderate intensity — produces measurable short-term improvements in attention, inhibitory control and executive function in people with ADHD. Meta-analyses support it, effects are modest but real, and the window afterwards is roughly one to two hours."),
                .paragraph("The practical implication is about *scheduling*, not about fitness. It's not \"get in shape and your ADHD improves.\" It's: move first, then do the hard thing, inside the window."),
                .heading("Using it deliberately"),
                .bullets([
                    "Put the movement immediately before the task you've been avoiding, not at whatever time is convenient",
                    "Intensity matters more than duration — ten hard minutes beats a gentle hour for this purpose",
                    "It stacks well with a wall: it changes physical state, which is the part that's stuck",
                    "Anything counts. Stairs, a fast walk, dancing badly in the kitchen. The delivery mechanism is irrelevant.",
                ]),
                .callout("This is not a replacement for treatment and the literature doesn't claim it is. It's a free, immediately available intervention with a real effect size, which makes it worth scheduling on purpose."),
            ],
            sources: [
                "Cerrillo-Urbina, A. J. et al. (2015) — Effects of physical exercise in children and adolescents with ADHD: meta-analysis",
                "Mehren, A. et al. (2020) — Physical exercise in ADHD: evidence and implications, Borderline Personality Disorder and Emotion Dysregulation",
                "Ratey, J. (2008) — Spark: The Revolutionary New Science of Exercise and the Brain",
            ]
        ),

        Article(
            id: "hyperfocus",
            title: "Hyperfocus",
            subtitle: "The superpower framing undersells the cost",
            category: .body,
            symbol: "scope",
            readMinutes: 3,
            body: [
                .paragraph("Six hours vanish. You haven't eaten, you're desperately thirsty, you needed the toilet two hours ago, and you've missed a call. The work might be excellent. You feel wrecked."),
                .heading("Why it isn't simply an asset"),
                .paragraph("Hyperfocus is usually described as ADHD's compensation, and it can be genuinely productive. But it isn't chosen and it isn't steerable — it attaches to whatever is engaging, which is frequently not the thing that needed doing. It's better understood as an attention-regulation failure in the other direction: not too little attention, but attention that can't be released."),
                .paragraph("The costs are real: skipped meals, dehydration, missed commitments, wrecked sleep, and a physical crash afterwards that eats the following day."),
                .heading("Guarding it rather than avoiding it"),
                .bullets([
                    "Set the exit alarm before you enter. Once you're in you will not think to.",
                    "Put water within arm's reach in advance — a barrier of any size will not be crossed",
                    "One alarm won't do it. Recurring nudges, and place the phone across the room so stopping it means standing up.",
                    "Log where the hyperfocus went. Over weeks the pattern tells you what genuinely engages you, which is useful information.",
                ]),
                .callout("Scaffold's Hyperfocus Guard mode is built for this — long session, recurring body checks for water, food, posture, eyes. Set it before you start."),
            ],
            sources: [
                "Ashinoff, B. K. & Abu-Akel, A. (2021) — Hyperfocus: the forgotten frontier of attention, Psychological Research",
                "Hupfeld, K. E. et al. (2019) — Living in the zone: hyperfocus in adult ADHD",
            ]
        ),

        // MARK: Identity & diagnosis

        Article(
            id: "missed",
            title: "How it gets missed for thirty years",
            subtitle: "Especially if you were quiet, bright, or a girl",
            category: .identity,
            symbol: "person.crop.circle.badge.questionmark",
            readMinutes: 4,
            body: [
                .paragraph("The stereotype is a disruptive eight-year-old boy who can't stay in his chair. Referral has historically followed disruption — which means the criterion for being noticed was never severity, it was inconvenience to adults."),
                .heading("The ways through the net"),
                .bullets([
                    "Predominantly inattentive presentation — no visible hyperactivity, so nothing to disrupt anyone",
                    "Girls and women, who are diagnosed far later on average and whose hyperactivity is more often internal: racing thoughts, chatter, restlessness that doesn't leave the chair",
                    "High academic ability, which absorbs the impairment right up until the external structure disappears — often at university, or the first demanding job",
                    "Chaotic households, where the pattern didn't stand out",
                    "Anxiety or depression diagnosed first, treated, and the underlying pattern never revisited",
                ]),
                .heading("The point it usually surfaces"),
                .paragraph("Almost always a moment when external scaffolding is removed or demand jumps: leaving home, finishing a structured degree, promotion into unstructured work, becoming a parent. Nothing about you changed. The structure that was holding it together left."),
                .heading("On masking"),
                .paragraph("Decades of compensation — triple-checking, elaborate reminders, rehearsing conversations, working late to hide that the day was lost — is genuinely effective and genuinely exhausting. It's also why an assessment can go badly if you present the polished version. Clinicians need to see the cost, not the coping."),
                .callout("\"But I've managed until now\" is not evidence against ADHD. What it took to manage is the evidence."),
            ],
            sources: [
                "Young, S. et al. (2020) — Females with ADHD: consensus statement, BMC Psychiatry",
                "Quinn, P. O. & Madhoo, M. (2014) — A review of ADHD in women and girls, Primary Care Companion",
                "Attoe, D. E. & Climie, E. A. (2023) — Miss. Diagnosis: a systematic review of ADHD in adult women",
            ]
        ),

        Article(
            id: "not-adhd",
            title: "Things that look exactly like this",
            subtitle: "Read before you conclude anything",
            category: .identity,
            symbol: "questionmark.circle",
            readMinutes: 4,
            body: [
                .paragraph("Self-recognition is where most adult diagnoses genuinely begin, and it's a legitimate starting point. It's also where confirmation bias does its best work — once ADHD is the frame, every scattered moment becomes evidence, and everyone has scattered moments."),
                .paragraph("Taking the alternatives seriously is not talking yourself out of it. It's the thing that makes the eventual answer trustworthy, whichever way it goes."),
                .heading("The main differentials"),
                .bullets([
                    "Sleep deprivation and sleep apnoea — reproduce nearly the whole attention profile. Very commonly missed.",
                    "Thyroid dysfunction, iron deficiency, B12 and vitamin D deficiency — a routine blood panel settles these",
                    "Depression — impairs concentration and initiation, but typically episodic rather than lifelong",
                    "Anxiety — attention consumed by worry looks identical from outside",
                    "Autism — overlaps substantially, co-occurs often, and needs a different support approach",
                    "Trauma and PTSD — hypervigilance and dissociation present much like inattention",
                    "Chronic pain, long COVID, perimenopause — all produce genuine cognitive fog",
                    "Substance use, including heavy caffeine and cannabis",
                ]),
                .heading("The complication"),
                .paragraph("These aren't alternatives in an either/or sense. ADHD co-occurs with most of them at elevated rates, and untreated ADHD contributes causally to several — the sleep debt, the anxiety, the demoralisation. Sorting cause from consequence is genuinely difficult and is a large part of what a proper assessment is for."),
                .callout("Two questions worth answering honestly before your appointment: has this been lifelong or did it start at an identifiable point, and is it present everywhere or only in specific settings? Those two answers do a lot of the diagnostic work."),
            ],
            sources: [
                "NICE Guideline NG87 — Attention deficit hyperactivity disorder: diagnosis and management",
                "Kooij, J. J. S. et al. (2019) — Updated European Consensus Statement on diagnosis and treatment of adult ADHD",
                "CADDRA Canadian ADHD Practice Guidelines (4.1 ed.)",
            ]
        ),

        Article(
            id: "assessment",
            title: "Getting assessed",
            subtitle: "What actually happens, and how to arrive prepared",
            category: .identity,
            symbol: "stethoscope",
            readMinutes: 5,
            body: [
                .paragraph("The route varies by country, but the shape of the assessment is fairly consistent internationally."),
                .heading("What the appointment involves"),
                .paragraph("Typically 45 to 90 minutes with a psychiatrist, specialist nurse, or clinical psychologist. Structured or semi-structured interview covering current symptoms, developmental history, family history, medical and psychiatric history, and functional impact. Standardised rating scales, usually including something like the ASRS or DIVA. Where possible, collateral history from someone who knew you as a child."),
                .heading("What they're establishing"),
                .bullets([
                    "Enough symptoms present, persistently, for at least six months",
                    "Several symptoms evident before age 12",
                    "Impairment in two or more settings — not just work, or just home",
                    "Clear interference with functioning",
                    "Not better explained by something else",
                ]),
                .heading("Preparing properly"),
                .paragraph("The biggest failure mode is arriving with adjectives instead of examples. \"I'm disorganised\" is not assessable. \"I've been late for 40% of meetings this year, I've paid three late fees since January, and my partner now handles all the bills because I stopped opening post\" is."),
                .bullets([
                    "Dated, concrete examples across several life areas — Scaffold's Evidence log exists for exactly this",
                    "School reports if you can find them. Enormously useful.",
                    "Someone who knew you before 12, if that's possible for you",
                    "A list of workarounds you've built, and what it costs to run them",
                    "What you've already tried and how it failed",
                    "An honest account of sleep, alcohol, caffeine, and other substances",
                ]),
                .heading("Two things worth knowing in advance"),
                .paragraph("Don't present the polished version. Masking in the appointment is the single most common reason capable adults get turned away — you have decades of practice at appearing fine, and it will run automatically unless you deliberately override it."),
                .paragraph("And if you're dismissed on weak grounds — \"you have a degree, so you can't have ADHD\", \"everyone's a bit like that\" — a second opinion is reasonable. Adult ADHD is still unevenly understood, and that response says more about the clinician's familiarity with it than about you."),
                .callout("Scaffold can generate a clinician summary from your screener answers, logged evidence and tracked patterns. Take it in. It's not a diagnosis and it doesn't pretend to be — it's organised information that makes the appointment more productive."),
            ],
            sources: [
                "NICE Guideline NG87 — ADHD: diagnosis and management",
                "Kooij, J. J. S. et al. (2019) — Updated European Consensus Statement on adult ADHD",
                "DIVA-5 — Diagnostic Interview for ADHD in Adults",
                "American Psychiatric Association — DSM-5-TR criteria for ADHD",
            ]
        ),
    ]
}
