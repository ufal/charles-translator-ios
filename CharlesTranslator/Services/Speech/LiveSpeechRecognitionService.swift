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
        try await requestPermissionsIfNeeded()

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale.bcp47Locale)),
              recognizer.isAvailable
        else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        self.recognizer = recognizer

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        self.request = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
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
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
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
