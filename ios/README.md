# Scaffold

A native iOS app for adults who suspect they have ADHD and haven't been assessed.

The premise, borrowed from Russell Barkley: ADHD is not a disorder of *knowing* what
to do, it's a disorder of doing what you already know at the moment it matters. So
nothing here tries to teach you to try harder. Everything is about moving structure
out of working memory and into the environment — visible, immediate, present at the
point of performance.

---

## Requirements

- **Xcode 16 or later** (the project uses synchronized folder groups, `objectVersion 77`)
- **iOS 17.0+** deployment target
- No third-party dependencies, no package resolution, no network access at runtime

## Running it

```bash
open ios/Scaffold.xcodeproj
```

Select a simulator or your device and hit run. Set your own signing team under
*Signing & Capabilities* if deploying to hardware.

If your Xcode is older than 16, regenerate the project instead:

```bash
brew install xcodegen
cd ios && rm -rf Scaffold.xcodeproj && xcodegen generate
```

---

## What's in it

| Area | What it does | Why it's there |
|---|---|---|
| **Today** | Single home screen — capture, today's tasks, anchors, wins | One-at-a-time framing; a full task list is a wall |
| **Capture** | Frictionless brain dump, one line per item, triage later | Categorising at the moment of capture is how thoughts get lost |
| **Tasks** | Micro-step breakdown, activation-cost rating, predict-vs-actual timing | Avoidance tracks the cost of *starting*, not difficulty |
| **Focus** | Sprint / Body double / Hyperfocus guard, depleting visual ring | Analogue countdowns beat digital readouts for time blindness |
| **Time multiplier** | Learns your personal estimate-to-actual ratio | Systematic error is correctable; you don't get better at estimating |
| **Toolbox** | 14 guided in-the-moment scripts, one step at a time | Indexed by how it feels ("I can't start"), not by taxonomy |
| **Mood** | Valence + energy + granular feeling words, RSD episode flagging | Emotional dysregulation predicts quality of life more than core symptoms |
| **Routines** | Short anchors, one step on screen at a time, optional nudges | An 11-step routine gets abandoned and becomes another failure |
| **Learn** | 18 research-grounded articles with sources listed | Explanation does real work — much of the harm is the shame layer |
| **Path** | ASRS v1.1 screener, evidence log, clinician summary export | Turns "I think I might have ADHD" into something assessable |
| **Wins** | Cumulative count, deliberately **not** a streak | Streaks reset on exactly the failure mode ADHD produces |

### Two design decisions worth calling out

**No streaks, ever.** A streak counter punishes the inconsistent day, which reliably
converts a small miss into abandoning the tool entirely. The Wins count only goes up.

**No overdue red.** Nothing in the app turns red or shouts about being late. A wall of
red is a shame trigger and shame produces avoidance of the app, which is the opposite
of useful.

---

## The clinician summary

The highest-leverage feature for someone undiagnosed. It assembles everything logged —
ASRS item-level responses, dated functional-impact examples grouped by life domain,
childhood indicators, mood/RSD patterns, the time multiplier — into one page you can
share, print, or read off your phone.

Assessments run 45–90 minutes, and adults are bad at summarising thirty years under
time pressure while masking runs automatically. Handing over an organised page converts
the appointment from recall-under-pressure into review.

---

## Privacy

Everything is a single JSON file in the app's Application Support directory. No account,
no sign-in, no server, no analytics, no network calls of any kind. The app holds notes
about someone's mental health that they may not have told anyone, so the only defensible
place for them is one device.

The one way data leaves is the Share button on the clinician summary — a deliberate
action the user takes. Consequence worth knowing: deleting the app is a permanent erase.

---

## Safety framing

This is not a medical device and it doesn't pretend to be:

- The ASRS is presented as a **screener**, never a diagnosis, with the distinction
  restated at the intro, the result, and in the exported summary.
- A below-threshold result explicitly does **not** tell someone nothing is wrong —
  screeners miss adults with decades of workarounds and inattentive presentations.
- A whole article and a result-screen callout cover the **differential**: sleep apnoea,
  thyroid, iron/B12/vitamin D, depression, anxiety, autism, trauma, substances.
- Crisis resources are two taps from anywhere and surface automatically on a low mood entry.
- No medication content, no dosing, no treatment recommendations.

---

## Sources

Content is drawn from published research and clinical guidance; every article lists its
own sources in-app.

**Core theory**
- Barkley, R. A. — *ADHD and the Nature of Self-Control*; *Executive Functions: What They Are, How They Work, and Why They Evolved*
- Brown, T. E. (2005) — *Attention Deficit Disorder: The Unfocused Mind in Children and Adults*
- Dodson, W. — the interest-based nervous system; rejection sensitive dysphoria

**Instruments & guidelines**
- ASRS-v1.1 Symptom Checklist © 2003 World Health Organization (Kessler, Adler, Ames, Demler, Faraone, Hiripi, Howes, Jin, Secnik, Spencer, Ustun, Walters)
- NICE Guideline NG87 — ADHD: diagnosis and management
- Kooij, J. J. S. et al. (2019) — Updated European Consensus Statement on adult ADHD
- CADDRA Canadian ADHD Practice Guidelines; DSM-5-TR; DIVA-5

**Specific findings**
- Beheshti, A. et al. (2020) — Emotion dysregulation in adults with ADHD: a meta-analysis, *BMC Psychiatry*
- Shaw, P. et al. (2014) — Emotional dysregulation in ADHD, *Am J Psychiatry*
- Van Veen, M. M. et al. (2010) — Delayed circadian rhythm in adults with ADHD, *Biological Psychiatry*
- Kooij & Bijlenga (2013) — The circadian rhythm in adult ADHD
- Mehren, A. et al. (2020) — Physical exercise in ADHD: evidence and implications
- Cerrillo-Urbina, A. J. et al. (2015) — Effects of physical exercise in ADHD: meta-analysis
- Ashinoff, B. K. & Abu-Akel, A. (2021) — Hyperfocus: the forgotten frontier of attention, *Psychological Research*
- Lieberman, M. D. et al. (2007) — Affect labeling disrupts amygdala activity, *Psychological Science*
- Kahneman & Tversky (1979); Buehler, Griffin & Ross (1994) — the planning fallacy
- Young, S. et al. (2020) — Females with ADHD: consensus statement, *BMC Psychiatry*
- Eagle, T. et al. (2023) — Body doubling as a continuum of space/time and mutuality, *CHI EA*
- Ramsay & Rostain (2015); Solanto (2011) — CBT for adult ADHD
- Mahan, B. — the Wall of Awful
- Neff, K. D. (2011) — *Self-Compassion*

---

## Layout

```
ios/
├── Scaffold.xcodeproj/
├── project.yml                 # XcodeGen fallback
└── Scaffold/
    ├── ScaffoldApp.swift       # entry point
    ├── RootView.swift          # 5-tab shell
    ├── Models/                 # Codable domain types
    ├── Store/                  # DataStore — JSON persistence, all derived stats
    ├── Content/                # ASRS, article library, toolbox scripts, seeds
    ├── DesignSystem/           # Theme + shared components
    ├── Services/               # notifications, haptics
    └── Features/               # one folder per tab/flow
```

**Not medical advice.** Scaffold cannot diagnose anyone. If you're struggling, talk to
a clinician; if you're in crisis, use the numbers under Path → Crisis support.
