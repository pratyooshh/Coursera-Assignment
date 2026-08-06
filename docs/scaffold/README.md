# Scaffold — web build

The installable version of the [iOS app](../../ios/README.md), for people without a Mac.

Once this branch is on `main`, it deploys to:

**https://pratyooshh.github.io/Coursera-Assignment/scaffold/**

## Installing it on your iPhone

1. Open that URL in **Safari** (not Chrome — only Safari can install to the Home Screen on iOS)
2. Tap the **Share** button
3. **Add to Home Screen**

You get an icon, a fullscreen app with no browser chrome, and it works offline.

## What's the same as the native app

Everything except notifications. Capture, tasks with micro-step breakdown, the
visual countdown ring, all 14 Toolbox scripts, all 18 articles, the ASRS v1.1
screener, the evidence log, and the clinician summary export are byte-identical —
the prose is extracted from the Swift sources rather than retyped.

## What's different

| | iOS | Web |
|---|---|---|
| Routine nudges, hyperfocus body checks | Local notifications | In-app only, needs the screen on |
| Haptics | Full taptic engine | `navigator.vibrate` — ignored by iOS Safari |
| Storage | JSON file in Application Support | `localStorage` |
| Sharing the summary | Share sheet | Share sheet, falling back to clipboard |

iOS restricts web-app notifications heavily, which is the one place the native
build is meaningfully better. If routine reminders matter to you, that's the
reason to build the Xcode project.

## Storage warning

Data lives in this browser's `localStorage`, on this device. Nothing is uploaded —
there's no server. Two consequences worth knowing:

- Clearing Safari's website data erases everything.
- iOS may evict storage for web apps you haven't opened in **7 days**. Adding it
  to the Home Screen and opening it regularly avoids this, but if you're logging
  evidence for an assessment, export the clinician summary periodically.

The native build has no such eviction risk.

## Content pipeline

`content.js` is generated, not hand-written. A parser reads the Swift sources and
emits the articles, toolbox scripts, ASRS items, routines and crisis resources as
JSON, so the two builds can't drift and the prose can't pick up transcription
errors. Regenerate it after editing anything under `ios/Scaffold/Content/`.

## Files

```
docs/scaffold/
├── index.html      # shell
├── styles.css      # theme, light + dark
├── content.js      # GENERATED from ios/Scaffold/Content/*.swift
├── store.js        # state, localStorage, derived stats
├── app.js          # router, views, timer
├── sw.js           # offline cache
├── manifest.json
└── icons/
```

## Verification

Driven end to end in headless Chromium (iPhone 13 viewport): 33 steps covering
onboarding, capture → triage → task → breakdown → completion, the focus timer,
a full Toolbox script, all 18 articles, the 18-question screener and its scoring,
the evidence log, clinician-summary generation, persistence across reload, service
worker registration, and both colour schemes. No console or page errors.

**Not medical advice.** Scaffold cannot diagnose anyone. If you're in crisis, use
the numbers under Path → Crisis support.
