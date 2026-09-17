# Charles Translator iOS — Project Plan

> **Purpose:** This is the project's living plan. Claude Code's planning mode reads this file and
> updates it. Any session that enters plan mode should start here, treat the relevant sections as
> ground truth, and write its outcomes back into this file rather than scattering plans across
> ad-hoc notes.
>
> **Status:** v1 feature-complete. Distribution tooling in place; one-time App Store Connect setup
> and an external (speech-service) decision remain.

---

## Project snapshot

A native iOS port of the [Charles Translator Android app](https://github.com/ufal/charles-translator-android)
(`cz.cuni.mff.ufal.translator.ios`), translating via UFAL MFF UK's [LINDAT/CLARIAH-CZ](https://lindat.mff.cuni.cz).

- **Stack:** SwiftUI + SwiftData, Swift 6 (strict concurrency), iOS 26.0 deployment target, Xcode 27.0.
- **Features:** Translate, Conversation, History, Settings (privacy consent, offline speech-model
  availability, About), onboarding consent sheet.
- **Languages (6):** cs, en, fr, pl, ru, uk.
- **Translation:** `LiveTranslationAPIClient` (LINDAT API, HTTPS only — `ITSAppUsesNonExemptEncryption = false`).
- **Voice in/out:** Apple `SFSpeechRecognizer` (dictation) + `AVSpeechSynthesisVoice` (speech),
  behind the `SpeechRecognitionService` / `TextToSpeechService` protocols.
- **Localization:** fully localized en, cs, uk, ru, sk via `Resources/Localizable.xcstrings`.
  See `Documentation/LocalizationNotes.md` for human-review items.

### Current state (verified)

- Working tree is clean; everything on `main` is committed and pushed.
- `Scripts/testflight.sh` + privacy manifest + export-compliance key are in place; the repo side of
  distribution is done.

---

## Roadmap

### ✅ Done — v1 core
- Native iOS scaffold (translation, conversation, history, settings, consent).
- Swift 6 / actor-isolation, AVAudioSession threading, audio-format crash, shared-speech-service
  fixes, keyboard dismiss, full iPad orientation support, in-memory SwiftData fallback.
- On-device speech-model availability surfaced in Settings + a blue on-device dot on the mic
  (see plan below).
- TestFlight tooling, privacy manifest, export compliance, app icon, provisional App Store screenshots.
- Localization review notes (see `Documentation/LocalizationNotes.md`).

### 📋 Completed implementation plan — Offline-model indicators & mic on-device styling
*Source: plan-mode file `golden-waddling-river.md`; implemented in commit `0d91fd8`.*

The app forces on-device recognition when the locale supports it but gave the user no way to see
which languages work offline, and the mic button was hidden for languages where the recognizer was
momentarily unavailable. Two changes:

1. **Settings "Offline speech models" section** — lists all 6 languages with per-language indicators
   for whether the **dictation** (recognition) model and the **speech** (synthesis) model are
   downloaded for on-device/offline use (filled blue = on-device, gray = online-only/unavailable).
2. **Mic button always shown** when Apple supports the source language (even server-only), with a
   small **blue corner dot** when that language's dictation model is on-device.

Key implementation notes:
- `SFSpeechRecognizer` is used for dictation; `AVSpeechSynthesisVoice` for speech. There is **no true
  public "is Downloaded" flag on iOS** — presence of a `.premium`/`.enhanced` voice for the locale is
  the standard proxy for an offline-capable voice. Documented, not a bug.
- Done: `SpeechRecognitionService.supportsRecognition(/supportsOnDeviceRecognition)`,
  `TextToSpeechService.hasVoice(/supportsOnDeviceVoice)`, `OfflineSpeechStatusStore`,
  `SettingsView` section, `MicButton` corner dot, `Color.charlesBlue`.

### 🔜 Future work (documented, not yet implemented)

#### Speech output / speech-to-speech seed
A speech-output (speaker) control that reads the translated text aloud via `TextToSpeechService`.
- Default off — tap to read the current output once.
- Optional always-on mode (e.g. long-press/double-tap on the speaker icon) that auto-reads each new
  translation immediately.
- Guarded by `supportsOnDeviceVoice(for:)` / `hasVoice(for:)` — the capabilities surfaced by the
  Settings section added above.

#### Full offline translation
Downloadable translation models (per the backend's future offering) enabling Translate and
Conversation fully offline, complementing the on-device dictation/synthesis models.
- Needs a model download/store mechanism and offline inference.
- The Settings "Offline speech models" section is the natural home for the language-coverage UI.
- **Major milestone, out of scope now.**

---

## Open decision — UWebASR voice recognition (in progress)

Full research and live-prototype findings: [`Documentation/UWebASR-Research.md`](UWebASR-Research.md).

**The ask:** optionally switch voice input to [UWebASR](https://uwebasr.zcu.cz/) (Pilsen group),
selectively for supported languages, gated by a Settings "Voice recognition system" toggle
(mirroring Android's `Google` vs `Charles University`). **Net-new integration** — the Android app
actually uses *cunispeech*, a different engine with no existing iOS/Android UWebASR client.

**Findings (verified):**
- Languages: UWebASR covers **cs/en/pl** of our six; fr/ru/uk are not offered → clean gating table.
- **Batch POST** works (16 kHz mono Ogg/Opus) and returns exact transcripts, but shows **no live
  partials** during upload — a regression vs Apple's `SFSpeechRecognizer`.
- `Transfer-Encoding: chunked` POST is **hard-blocked** (HTTP 400) by their nginx proxy.
- The only genuine live-streaming path, **`GET ?url=<public-audio>&stream=1`**, streams partials but
  requires a **publicly reachable audio URL** (server pulls), i.e. a relay we don't own — plus it's
  flaky under load (503 `WORKER_SEND_FAILED`).

**Assessment (user's):** Apple ASR currently gives a better service than a batch-POST UWebASR build.
UWebASR is only worth adopting if the **live-streaming option** (`GET stream=1`) can work for a
device mic.

**Status: BLOCKED on an external decision.** The user is discussing enabling live streaming with the
service owners. **No implementation is performed until that resolves.**

**If the decision lands:**
1. Add a Settings "Voice recognition system" toggle (Apple vs UWebASR), defaulting to Apple.
2. Gate UWebASR to cs/en/pl; fall back to Apple for fr/ru/uk (and for unsupported pairs).
3. Resolve relay architecture for live streaming (the open engineering question).

---

## How to work on this project

- Read `Documentation/project-plan.md` before planning or starting significant work. Update it when
  a phase completes or the roadmap changes.
- Keep the plan in this file rather than one-off markdown notes, so it is discoverable across sessions.
- See `CLAUDE.md` at the repo root for build/test commands, distribution, and localization workflow.