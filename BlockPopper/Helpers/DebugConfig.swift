import Foundation

/// Debug configuration for testing. Active only in simulators and connected dev devices.
struct DebugConfig {

    /// True when running on a simulator or a developer-connected device (not App Store).
    static let isTestEnvironment: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        // Connected device via Xcode = DEBUG build
        #if DEBUG
        return true
        #else
        return false
        #endif
        #endif
    }()

    // MARK: - Test Overrides (only applied when isTestEnvironment is true)

    /// Starting global score for testing phase transitions
    static let startingGlobalScore: Int = 80

    /// Starting phase score for testing
    static let startingPhaseScore: Int = 80
}
