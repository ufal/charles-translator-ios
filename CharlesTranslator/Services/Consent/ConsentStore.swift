import Foundation

/// Backed by `UserDefaults` directly rather than `@AppStorage` — `@AppStorage`
/// doesn't compose with the `@Observable` macro's synthesized storage, and this
/// type needs to be usable outside a SwiftUI View context (injected as a service).
@MainActor
@Observable
final class ConsentStore {
    private let defaults: UserDefaults

    var hasAnswered: Bool {
        didSet { defaults.set(hasAnswered, forKey: Keys.hasAnswered) }
    }

    var dataCollectionConsent: Bool {
        didSet { defaults.set(dataCollectionConsent, forKey: Keys.dataCollectionConsent) }
    }

    var organizationName: String {
        didSet { defaults.set(organizationName, forKey: Keys.organizationName) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasAnswered = defaults.bool(forKey: Keys.hasAnswered)
        dataCollectionConsent = defaults.bool(forKey: Keys.dataCollectionConsent)
        organizationName = defaults.string(forKey: Keys.organizationName) ?? ""
    }

    func recordConsentDecision(agreed: Bool) {
        dataCollectionConsent = agreed
        hasAnswered = true
    }

    /// Backs Settings' "Erase all app data" action.
    func reset() {
        hasAnswered = false
        dataCollectionConsent = false
        organizationName = ""
    }

    private enum Keys {
        static let hasAnswered = "charlesTranslator.hasAnsweredDataConsent"
        static let dataCollectionConsent = "charlesTranslator.dataCollectionConsent"
        static let organizationName = "charlesTranslator.organizationName"
    }
}
