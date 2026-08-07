import Foundation
import Speech
import AVFoundation

/// `SFSpeechRecognizer` + `AVAudioEngine`, chosen over the newer iOS 26
/// `SpeechAnalyzer`/`SpeechTranscriber` because `SFSpeechRecognizer` has long
/// established, broad locale coverage for all six languages this app needs
/// (cs/en/fr/pl/ru/uk) — `SpeechAnalyzer`'s locale rollout is newer and narrower,
/// and Czech/Ukrainian/Polish coverage isn't reliably confirmed yet. On-device
/// recognition is used when the locale supports it, falling back to server-based
/// automatically, exactly mirroring how Android's engine choice is transparent
/// to the rest of the app.
@MainActor
final class LiveSpeechRecognitionService: SpeechRecognitionService {
    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var continuation: CheckedContinuation<String, Error>?
    private var hasFinished = false

    func startListening(
        locale: Language,
        onPartialTranscript: @escaping (String) -> Void
    ) async throws -> String {
        // Guard against re-entrant use on this instance: if a previous session
        // hasn't finished, end it cleanly first rather than reconfiguring a
        // still-active AVAudioEngine graph out from under it — mutating a live
        // engine/tap from another logical session is exactly the kind of race
        // that crashes on a background audio thread instead of throwing a
        // catchable Swift error.
        if continuation != nil {
            stopListening()
            finish(throwing: CancellationError())
        }

        try await requestPermissionsIfNeeded()

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale.bcp47Locale)),
              recognizer.isAvailable
        else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        self.recognizer = recognizer

        try await activateAudioSession()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        self.request = request

        // Reset stale state from a previous start/stop cycle before reconfiguring —
        // starting a fresh AVAudioEngine session on top of leftover taps/format
        // state is a common source of crashes across repeated mic toggles.
        audioEngine.stop()
        audioEngine.reset()
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        // On a real device, the input node can briefly report an invalid (zero
        // sample rate / channel count) format in the moment right after mic/speech
        // permission is freshly granted, before the audio route has settled.
        // Installing a tap with that format is a fatal Objective-C precondition
        // failure inside AVAudioEngine — NOT a catchable Swift error — so retry
        // briefly for a valid format instead of crashing the app.
        guard let recordingFormat = await validRecordingFormat(for: inputNode) else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        hasFinished = false
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                    guard let self else { return }
                    Task { @MainActor in
                        if let result {
                            onPartialTranscript(result.bestTranscription.formattedString)
                            if result.isFinal {
                                self.finish(returning: result.bestTranscription.formattedString)
                            }
                        }
                        if let error {
                            self.finish(throwing: error)
                        }
                    }
                }
            }
        } onCancel: {
            Task { @MainActor in self.stopListening() }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
    }

    private func finish(returning text: String) {
        guard !hasFinished else { return }
        hasFinished = true
        teardown()
        continuation?.resume(returning: text)
        continuation = nil
    }

    private func finish(throwing error: Error) {
        guard !hasFinished else { return }
        hasFinished = true
        teardown()
        continuation?.resume(throwing: error)
        continuation = nil
    }

    private func teardown() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        task?.cancel()
        task = nil
        request = nil
        deactivateAudioSession()
    }

    /// `AVAudioSession.setActive` is documented by Apple as a call that must
    /// never happen on the main thread — it can block for a noticeable amount
    /// of time, and doing so on the main actor risks a UI hang and eventual
    /// watchdog termination. This class is otherwise `@MainActor` (it needs to
    /// be, for the UI-facing parts), so activation/deactivation are the two
    /// spots that must explicitly hop off it.
    ///
    /// Uses one dedicated, stable serial queue rather than `Task.detached`
    /// (Swift's anonymous shared concurrent thread pool) — a `dispatch_assert_
    /// queue` crash was observed with the detached-task version, consistent
    /// with AVFoundation's audio-session internals expecting session control
    /// calls to serialize through the same identifiable queue every time
    /// rather than an arbitrary pool thread that can differ call to call.
    private static let audioSessionQueue = DispatchQueue(label: "cz.cuni.mff.ufal.translator.audioSession", qos: .userInitiated)

    private func activateAudioSession() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Self.audioSessionQueue.async {
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func deactivateAudioSession() {
        Self.audioSessionQueue.async {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func validRecordingFormat(for inputNode: AVAudioInputNode) async -> AVAudioFormat? {
        for _ in 0..<10 {
            let format = inputNode.outputFormat(forBus: 0)
            if format.sampleRate > 0, format.channelCount > 0 {
                return format
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return nil
    }

    private func requestPermissionsIfNeeded() async throws {
        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else { throw SpeechRecognitionError.permissionDenied }

        let speechStatus = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else { throw SpeechRecognitionError.permissionDenied }
    }
}
