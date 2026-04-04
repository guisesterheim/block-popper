import Foundation

struct LevelConfig {
    /// Target score to reach the given level.
    /// Formula: 100 * level + 50 * level * (level - 1)
    /// Level 1: 100, Level 2: 300, Level 3: 600, Level 4: 1000
    /// Marked as tunable -- adjust multipliers to change difficulty curve.
    static func targetScore(forLevel level: Int) -> Int {
        guard level >= 1 else { return 0 }
        return 100 * level + 50 * level * (level - 1)
    }
}
