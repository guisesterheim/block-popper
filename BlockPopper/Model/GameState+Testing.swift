import Foundation

// Internal test-support helpers. @testable import exposes these to the test target.
// Not compiled into release builds — guarded by #if DEBUG so production binary
// is not affected.
#if DEBUG
extension GameState {
    /// Directly overwrite the grid (test setup only).
    func _setGrid(_ newGrid: GameGrid) { grid = newGrid }

    /// Directly set the phase (test setup only).
    func _setPhase(_ newPhase: GamePhase) { phase = newPhase }

    /// Directly set the score (test setup only).
    func _setScore(_ value: Int) { score = value }

    /// Directly set the level (test setup only).
    func _setLevel(_ value: Int) { level = value }

    /// Directly set lives (test setup only).
    func _setLives(_ value: Int) { lives = value }
}
#endif
