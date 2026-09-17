# Charles Translator iOS

Native iOS port of the [Charles Translator Android app](https://github.com/ufal/charles-translator-android),
translating via UFAL MFF UK's LINDAT/CLARIAH-CZ. SwiftUI + SwiftData, Swift 6 strict concurrency,
iOS 26.0 target, Xcode 27.0. Bundle `cz.cuni.mff.ufal.translator.ios`.

## For planning mode

**Read `Documentation/project-plan.md` before planning or starting significant work.** It is the
project's living plan (current state, roadmap, planned-but-unimplemented work, open decisions).
Keep that file as the single source of truth for the plan: update it when a phase completes or the
roadmap changes, and write new planning outcomes back into it instead of leaving them in one-off
notes or ad-hoc files.

Open items currently tracked there:
- **UWebASR voice recognition** — BLOCKED on an external (service-owner) decision about live
  streaming. Do not start implementing until the decision resolves. See
  `Documentation/UWebASR-Research.md` for full findings.

## Building and testing

Xcode 27.0 (or later) on macOS; test device iOS 26.0 or later.

```sh
xcodebuild test -project CharlesTranslator.xcodeproj -scheme CharlesTranslator \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Distribution (TestFlight)

Repo side is complete. What remains is account-side, one-time setup only a signed-in Xcode can do —
see `README.md` → "TestFlight distribution". Then per build:

```sh
Scripts/testflight.sh <next-build-number>
```

App Store Connect refuses a build number it has already accepted, so increment every time.
`MARKETING_VERSION` (currently `1.0`) and `CURRENT_PROJECT_VERSION` are the single source of truth.

## Localization

The app is fully localized in en, cs, uk, ru, sk via `Resources/Localizable.xcstrings`. Regenerate
after editing source strings:

```sh
python3 Scripts/generate_localizations.py
```

Strings that diverge from the Android app's approved wording are logged in
`Documentation/LocalizationNotes.md` for human review before release.

## Conventions

- `SpeechRecognitionService` / `TextToSpeechService` are the protocols behind all voice I/O; new
  backends (e.g. UWebASR) should conform to these rather than being wired directly into views.
- On-device speech capabilities are queried via `supportsOnDeviceRecognition` / high-quality voice
  presence — iOS exposes no true "model downloaded" flag; the premium/enhanced-voice proxy is the
  accepted stand-in (see `Documentation/project-plan.md`).
- Swift 6 strict concurrency is on — keep any `AVAudioSession`/actor work on the appropriate
  isolation or use a dedicated serial queue, as the existing services do.