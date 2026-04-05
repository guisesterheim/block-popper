import Foundation

// Internal test-support helpers. @testable import exposes these to the test target.
// Not compiled into release builds — guarded by #if DEBUG so production binary
// is not affected.
#if DEBUG
extension GameState {
    /// Directly overwrite the grid (test setup only).
    func _setGrid(_ newGrid: GameGrid) { grid = newGrid }

    /// Directly set the game phase (test setup only).
    func _setPhase(_ newPhase: GamePhase) { gamePhase = newPhase }

    /// Directly set the global score (test setup only).
    func _setScore(_ value: Int) { globalScore = value }

    /// Directly set the phase number (test setup only).
    func _setLevel(_ value: Int) { phase = value }

    /// Directly set lives (test setup only).
    func _setLives(_ value: Int) { lives = value }

    /// Directly set the phase score (test setup only).
    func _setPhaseScore(_ value: Int) { phaseScore = value }

    /// Directly set hacks used (test setup only).
    func _setHacksUsed(_ value: Int) { hacksUsed = value }
}
#endif
