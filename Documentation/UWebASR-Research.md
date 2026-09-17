# UWebASR Speech Recognition — Research Findings

**Status:** Research + live prototype only. No implementation performed.
**Date:** 2026-09-16
**Decision pending:** whether to pursue UWebASR's live-streaming path (option 2) — to be discussed with the service owners.

---

## Context

The iOS app's voice input currently uses Apple's `SFSpeechRecognizer` (via
`LiveSpeechRecognitionService`, behind the `SpeechRecognitionService` protocol).

The user wants the ability to optionally switch voice recognition to **UWebASR** —
UFAL's cloud speech-to-text service — used **selectively, only for supported
languages**, and **only when enabled in Settings**. This mirrors the Android
app, which has a "Voice recognition system" setting (`Google` vs `Charles University`).

The purpose of this document is to record the findings of the investigation and the
live prototype, and to capture the open decision.

---

## Key clarification: cunispeech ≠ UWebASR

These are **two separate services with completely separate models**:

| | Android "Charles University" option | UWebASR |
|---|---|---|
| Endpoint | `wss://lindat.cz/services/cunispeech/socket.io:8082` | `https://uwebasr.zcu.cz/api/v2/...` |
| Maintainer | UFAL CUNI (Charles University) | **Pilsen group** (University of West Bohemia, `zcu.cz`) |
| Protocol | Custom WebSocket Socket.IO (Float32 PCM chunks + `"Done"` frame) | Modern HTTP API |
| Model family | older | Zipformer (2023+) / Wav2Vec 2.0 |
| Modernity | older, less maintained | **better maintained, newer models** |

The Android app's "Charles University" recognizer connects to **cunispeech**, which
is **not** the same engine as UWebASR. There is therefore **no existing Android or
iOS UWebASR client to copy** — this is a net-new integration.

The user specifically wants **UWebASR** (Pilsen group), which is better maintained.

---

## The UWebASR service

- **Service homepage:** `https://uwebasr.zcu.cz/` (redirect from the LINDAT alias).
- **API root:** `https://uwebasr.zcu.cz/api/v2/lindat/<instance>/<lang>/<model>`
- **Model IDs (Zipformer, recommended):**
  - `generic/cs/zipformer` (Czech), `generic/sk/zipformer` (Slovak),
    `generic/en/zipformer` (English), `generic/de/zipformer` (German),
    `generic/pl/zipformer` (Polish), `generic/hu/zipformer` (Hungarian),
    `generic/hr/zipformer` (Croatian), `generic/sr/zipformer` (Serbian)
  - Adapted Zipformer (oral histories): `malach/{cs,sk,en,de,pl,hu}/zipformer`
  - Wav2Vec 2.0 (Dutch + older): `generic/{cs,sk,de,en,nl}`
- **Available languages (9):** Czech, Slovak, English, German, Dutch, Polish,
  Hungarian, Croatian, Serbian.
- **Response formats:** `plaintext`, `json` (per-word `start`/`end`/`word`/`confidence`/`speech_end`),
  `webvtt`, `trs`, `extended_trs`, `speechcloud_json`.
- **`speechcloud_json`** is the format suitable for integration: it carries
  message types including `asr_offline_started`, `asr_result` (`partial_result`
  true/false, `result`, `word_1best`, `word_times`, `word_conf`, `word_array`,
  `word_punctuation`), `asr_input_processed`, and (for adapted Zipformer)
  `asr_accuracy_estimate`.
- **Limits:** recognition runs on a pool of SpeechCloud workers; if all workers for
  a model are busy the API responds **HTTP 503**. A session is limited to 3600 s.

### Mapping to the app's six languages

| App language | UWebASR? | Model |
|---|---|---|
| `cs` | ✅ | `generic/cs/zipformer` |
| `en` | ✅ | `generic/en/zipformer` |
| `pl` | ✅ | `generic/pl/zipformer` |
| `fr` | ❌ | not offered |
| `ru` | ❌ | not offered |
| `uk` | ❌ | not offered |

**3 of the 6 app languages (cs, en, pl) have a UWebASR model; the other 3 (fr, ru,
uk) do not.** This maps cleanly onto a selective language→model gating table.

---

## Live prototype results

A hands-on probe was built and run against the live endpoint using synthesized
speech (macOS `say` → ffmpeg → HTTP). All three supported app languages were
verified end-to-end via **batch POST**:

| Lang | Model | Synthesized input | Result |
|---|---|---|---|
| `cs` | `generic/cs/zipformer` | "Dobrý den, test rozpoznání řeči…" | ✅ exact transcript, word conf ~0.78–0.96 |
| `en` | `generic/en/zipformer` | "This is a test of English speech recognition…" | ✅ exact transcript |
| `pl` | `generic/pl/zipformer` | "To jest test rozpoznawania mowy…" | ✅ exact transcript |

**Working audio format:** **16 kHz mono Ogg/Opus** (`ffmpeg -ar 16000 -ac 1 -c:a libopus -b:a 32k -f ogg`). Opus transcodes and transcribes cleanly — simpler than the docs' Vorbis example and needs no `libvorbis`.

### Streaming findings (the decisive part)

Three ways to get audio to the server were tested:

1. **POST batch** (whole body with `Content-Length`)
   - ✅ Works. Returns the full transcript.
   - **No partials stream during upload** — the full response arrives at the end
     (`asr_offline_started → … → asr_result(partial_result:false) → asr_input_processed`),
     even though the service page says it "decodes data progressively while uploaded."

2. **POST with `Transfer-Encoding: chunked`** (the natural live-mic push)
   - ❌ **Hard-blocked by the nginx reverse proxy** with HTTP 400 "Bad Request",
     regardless of container (WAV or Ogg/Opus). A client cannot stream chunks
     into a POST from iOS.

3. **GET `?url=<remote audio>&stream=1`**
   - ✅ **Genuinely streams.** The response trickles back incrementally as the
     recognizer processes the audio. Captured an 18-chunk, ~92 KB streamed response
     of real English speech, transcribed correctly with word-level timestamps.
   - ⚠️ **Requires a publicly reachable remote audio URL** for UWebASR's server to
     fetch (server pulls; it does not accept a push). Not directly usable for a
     device mic without a relay.
   - ⚠️ **Flaky under load:** repeated `503 WORKER_SEND_FAILED` / "Cannot upload
     data to SpeechCloud" errors on retry (server-side worker pool issues, which
     the docs warn about).

---

## Conclusion & open decision

- **UWebASR is a viable, modern, well-maintained service** and its language coverage
  (cs/en/pl) lines up well with the app's languages for a selective, Settings-gated
  integration.
- **However, the only true live-streaming path (`GET stream=1`) requires a
  publicly reachable audio URL**, which for a device mic implies hosting our own
  streaming relay — infrastructure the app does not currently own.
- **The batch POST path (record → upload on stop → return transcript) is simple and
  verified** and matches the Android cunispeech UX, **but it loses live partial
  transcripts** — a regression compared to Apple's `SFSpeechRecognizer`.

**Assessment (user's):** as it stands, Apple's ASR provides a better service than a
batch-POST UWebASR implementation (option a). UWebASR would only be worth adopting
if live streaming (option 2 / `GET stream=1`) can be made to work for a device mic.

**Next step:** the user will discuss enabling the live-streaming option (2) with the
service owners. No implementation is performed until that is resolved.

---

## References

- UWebASR service & API docs: `https://uwebasr.zcu.cz/`
- UWebASR skill (usage + models): `https://github.com/honzas83/uwebasr-skill/blob/main/SKILL.md`
- UWebASR client script (batch example): `https://github.com/honzas83/uwebasr-skill/blob/main/scripts/uwebasr.py`
- Charles Translator Android (cunispeech path, for reference): `https://github.com/ufal/charles-translator-android`