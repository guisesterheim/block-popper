import Foundation

struct LevelConfig {
    /// Target score for a given phase.
    /// Phase 1: 100, Phase 2: 120, Phase 3: 140, ...
    /// Linear progression: 100 + (phase - 1) * 20
    static func targetScore(forPhase phase: Int) -> Int {
        guard phase >= 1 else { return 100 }
        return 100 + (phase - 1) * 20
    }

    /// Legacy — kept for backward compatibility with tests.
    static func targetScore(forLevel level: Int) -> Int {
        targetScore(forPhase: level)
    }
}
