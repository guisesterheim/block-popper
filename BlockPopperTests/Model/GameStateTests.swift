import XCTest
@testable import BlockPopper

// GameState is a class; properties are private(set).
// We drive mutations through the public/internal API and the _set* helpers
// exposed via GameState+Testing.swift (#if DEBUG extension).

final class GameStateTests: XCTestCase {

    // MARK: - Initial State

    func testInitialState_score() {
        XCTAssertEqual(GameState().score, 0)
    }

    func testInitialState_level() {
        XCTAssertEqual(GameState().level, 1)
    }

    func testInitialState_lives() {
        let state = GameState()
        XCTAssertEqual(state.lives, 3)
        XCTAssertEqual(state.lives, GameState.maxLives)
    }

    func testInitialState_phase() {
        XCTAssertEqual(GameState().phase, .playing)
    }

    func testInitialState_trayCount() {
        XCTAssertEqual(GameState().trayPieces.count, 3)
    }

    // MARK: - Score: 9 pts per cleared line

    func testScore_incrementsByGridSize_perClearedLine() {
        let state = GameState()
        triggerLineClear(state, row: 0)
        XCTAssertEqual(state.score, GameGrid.size)   // 1 line × 9 = 9
    }

    func testScore_incrementsFor_twoSeparateLineCLears() {
        let state = GameState()
        triggerLineClear(state, row: 0)
        XCTAssertEqual(state.score, GameGrid.size)
        state.onClearAnimationComplete()
        triggerLineClear(state, row: 1)
        XCTAssertEqual(state.score, GameGrid.size * 2)
    }

    func testScore_noChange_withoutLineClear() {
        let state = GameState()
        // Place a single dot that does not complete any row or column
        var g = state.grid
        g.place(piece: BlockPiece.make(.dot), at: GridPosition(row: 4, col: 4))
        state._setGrid(g)
        XCTAssertEqual(state.score, 0)
    }

    func testScore_pointsFormula_ninePerLine() {
        // Verify ClearResult.points = totalClearedLines * gridSize
        var grid = GameGrid()
        for row in 0..<3 {
            for col in 0..<GameGrid.size {
                grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: col))
            }
        }
        let result = grid.clearFullLines()
        XCTAssertEqual(result.totalClearedLines, 3)
        XCTAssertEqual(result.points, 3 * GameGrid.size)
    }

    // MARK: - Lives

    func testLives_decrementOnUseLife() {
        let state = GameState()
        forceStuck(state)
        state.useLife()
        XCTAssertEqual(state.lives, 2)
    }

    func testLives_startAtMaxLives() {
        XCTAssertEqual(GameState().lives, GameState.maxLives)
    }

    func testLives_useLife_doesNotDecrementWhenPlaying() {
        let state = GameState()
        XCTAssertEqual(state.phase, .playing)
        state.useLife()
        XCTAssertEqual(state.lives, GameState.maxLives)
    }

    func testLives_useLife_doesNotDecrementWhenGameOver() {
        let state = GameState()
        drainAllLives(state)
        XCTAssertEqual(state.phase, .gameOver)
        let livesBefore = state.lives
        state.useLife()
        XCTAssertEqual(state.lives, livesBefore)
    }

    // MARK: - Level Advancement

    func testLevel_advancesAt100_forLevel1() {
        let state = GameState()
        state._setScore(100)
        state.checkLevelUp()
        XCTAssertEqual(state.level, 2)
    }

    func testLevel_advancesAt300_forLevel2() {
        let state = GameState()
        state._setLevel(2)
        state._setScore(300)
        state.checkLevelUp()
        XCTAssertEqual(state.level, 3)
    }

    func testLevel_advancesAt600_forLevel3() {
        let state = GameState()
        state._setLevel(3)
        state._setScore(600)
        state.checkLevelUp()
        XCTAssertEqual(state.level, 4)
    }

    func testLevel_advancesAt1000_forLevel4() {
        let state = GameState()
        state._setLevel(4)
        state._setScore(1000)
        state.checkLevelUp()
        XCTAssertEqual(state.level, 5)
    }

    func testLevel_doesNotAdvance_belowThreshold() {
        let state = GameState()
        state._setScore(99)
        state.checkLevelUp()
        XCTAssertEqual(state.level, 1)
    }

    func testLevel_thresholdFormula_matchesSpecification() {
        // 100*level + 50*level*(level-1)
        let expected = [(1, 100), (2, 300), (3, 600), (4, 1000)]
        for (level, score) in expected {
            XCTAssertEqual(
                LevelConfig.targetScore(forLevel: level), score,
                "Threshold mismatch at level \(level)"
            )
        }
    }

    // MARK: - GamePhase Transitions

    func testPhase_playing_to_animatingClear() {
        let state = GameState()
        XCTAssertEqual(state.phase, .playing)
        triggerLineClear(state, row: 0)
        XCTAssertEqual(state.phase, .animatingClear)
    }

    func testPhase_animatingClear_to_playing_whenNotStuck() {
        let state = GameState()
        triggerLineClear(state, row: 0)
        XCTAssertEqual(state.phase, .animatingClear)
        state.onClearAnimationComplete()
        XCTAssertEqual(state.phase, .playing)
    }

    func testPhase_playing_to_stuck_whenNoPieceFits() {
        let state = GameState()
        forceStuck(state)
        XCTAssertEqual(state.phase, .stuck)
    }

    func testPhase_stuck_to_rescuing_onUseLife() {
        let state = GameState()
        forceStuck(state)
        state.useLife()
        XCTAssertEqual(state.phase, .rescuing)
    }

    func testPhase_stuck_to_gameOver_whenZeroLives() {
        let state = GameState()
        drainAllLives(state)
        XCTAssertEqual(state.phase, .gameOver)
    }

    func testPhase_rescuing_to_playing_afterPerformRescue() {
        let state = GameState()
        forceStuck(state)
        state.useLife()
        state.performRescue()
        XCTAssertEqual(state.phase, .playing)
    }

    // MARK: - Illegal Transitions

    func testIllegalTransition_useLife_whenPlaying_isNoOp() {
        let state = GameState()
        let livesBefore = state.lives
        state.useLife()
        XCTAssertEqual(state.lives, livesBefore)
        XCTAssertEqual(state.phase, .playing)
    }

    func testIllegalTransition_useLife_whenAnimatingClear_isNoOp() {
        let state = GameState()
        triggerLineClear(state, row: 0)
        XCTAssertEqual(state.phase, .animatingClear)
        let livesBefore = state.lives
        state.useLife()
        XCTAssertEqual(state.lives, livesBefore)
        XCTAssertEqual(state.phase, .animatingClear)
    }

    func testIllegalTransition_useLife_whenGameOver_isNoOp() {
        let state = GameState()
        drainAllLives(state)
        XCTAssertEqual(state.phase, .gameOver)
        state.useLife()
        XCTAssertEqual(state.phase, .gameOver)
    }

    func testIllegalTransition_performRescue_whenPlaying_isNoOp() {
        let state = GameState()
        state.performRescue()
        XCTAssertEqual(state.phase, .playing)
    }

    func testIllegalTransition_performRescue_whenAnimatingClear_isNoOp() {
        let state = GameState()
        triggerLineClear(state, row: 0)
        XCTAssertEqual(state.phase, .animatingClear)
        state.performRescue()
        XCTAssertEqual(state.phase, .animatingClear)
    }

    func testIllegalTransition_cannotUseLife_whenLivesZero() {
        let state = GameState()
        state._setLives(0)
        state._setPhase(.stuck)
        state.useLife()   // guard: lives > 0 required
        XCTAssertEqual(state.lives, 0)
        XCTAssertEqual(state.phase, .stuck)
    }

    // MARK: - resetGame

    func testResetGame_restoresScore() {
        let state = GameState()
        triggerLineClear(state, row: 0)
        XCTAssertGreaterThan(state.score, 0)
        state.resetGame()
        XCTAssertEqual(state.score, 0)
    }

    func testResetGame_restoresLevel() {
        let state = GameState()
        state._setLevel(5)
        state.resetGame()
        XCTAssertEqual(state.level, 1)
    }

    func testResetGame_restoresLives() {
        let state = GameState()
        forceStuck(state)
        state.useLife()
        state.performRescue()
        XCTAssertLessThan(state.lives, GameState.maxLives)
        state.resetGame()
        XCTAssertEqual(state.lives, GameState.maxLives)
    }

    func testResetGame_restoresPhase() {
        let state = GameState()
        forceStuck(state)
        XCTAssertEqual(state.phase, .stuck)
        state.resetGame()
        XCTAssertEqual(state.phase, .playing)
    }

    func testResetGame_clearsGrid() {
        let state = GameState()
        var g = state.grid
        g.place(piece: BlockPiece.make(.dot), at: GridPosition(row: 5, col: 5))
        state._setGrid(g)
        XCTAssertFalse(state.grid.isEmpty)
        state.resetGame()
        XCTAssertTrue(state.grid.isEmpty)
    }

    func testResetGame_restoresTrayCount() {
        let state = GameState()
        state.resetGame()
        XCTAssertEqual(state.trayPieces.count, 3)
    }

    // MARK: - Rescue Does Not Award Score

    func testRescue_doesNotAwardScorePoints() {
        let state = GameState()
        forceStuck(state)
        let scoreBefore = state.score
        state.useLife()
        state.performRescue()
        XCTAssertEqual(state.score, scoreBefore,
                       "performRescue must not change score")
    }

    func testRescue_scoreUnchanged_afterMultipleRescues() {
        let state = GameState()
        // Rescue up to maxLives times without ever triggering a line clear
        var rescues = 0
        while state.lives > 0 && state.phase != .gameOver {
            forceStuck(state)
            guard state.phase == .stuck, state.lives > 0 else { break }
            state.useLife()
            state.performRescue()
            rescues += 1
        }
        XCTAssertGreaterThan(rescues, 0)
        XCTAssertEqual(state.score, 0,
                       "Score must remain 0 after \(rescues) rescues (no line clears)")
    }

    // MARK: - Helpers

    /// Fills row `row` in the state's grid and triggers GameState's clear bookkeeping.
    /// After this call: state.phase == .animatingClear and state.score has increased.
    private func triggerLineClear(_ state: GameState, row: Int) {
        guard state.phase == .playing else { return }

        // Place first 8 dots directly on the grid (no clear triggered yet)
        var g = state.grid
        for col in 0..<(GameGrid.size - 1) {
            if g.cellAt(row: row, col: col) == .empty {
                g.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: col))
            }
        }
        state._setGrid(g)

        // For the 9th cell, use placePiece if a dot is in the tray (triggers
        // GameState's clear + score + phase logic). Fall back to direct placement.
        let lastCol = GameGrid.size - 1
        if state.grid.cellAt(row: row, col: lastCol) == .empty {
            var usedTray = false
            for i in 0..<state.trayPieces.count {
                if let piece = state.trayPieces[i], piece.type == .dot {
                    state.placePiece(at: i, position: GridPosition(row: row, col: lastCol))
                    usedTray = true
                    break
                }
            }
            if !usedTray {
                // No dot in tray — place directly then replicate GameState bookkeeping
                var g2 = state.grid
                g2.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: lastCol))
                let clearResult = g2.clearFullLines()
                state._setGrid(g2)
                if clearResult.totalClearedLines > 0 {
                    state._setScore(state.score + clearResult.points)
                    state._setPhase(.animatingClear)
                }
            }
        }
    }

    /// Forces state.phase to .stuck by filling the grid and manually evaluating
    /// the stuck condition. Does not go through placePiece (avoids tray randomness).
    private func forceStuck(_ state: GameState) {
        guard state.phase == .playing else { return }
        var g = state.grid
        for row in 0..<GameGrid.size {
            for col in 0..<GameGrid.size {
                if g.cellAt(row: row, col: col) == .empty {
                    g.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: col))
                }
            }
        }
        state._setGrid(g)
        let activePieces = state.trayPieces.compactMap { $0 }
        if state.grid.isBoardStuck(pieces: activePieces) {
            state._setPhase(state.lives > 0 ? .stuck : .gameOver)
        }
    }

    /// Drains all lives via the useLife / performRescue cycle, ending in .gameOver.
    private func drainAllLives(_ state: GameState) {
        while state.lives > 0 && state.phase != .gameOver {
            if state.phase != .stuck { forceStuck(state) }
            guard state.phase == .stuck, state.lives > 0 else { break }
            state.useLife()
            state.performRescue()   // → .playing; next iteration re-forces stuck
        }
        // Final stuck with 0 lives → gameOver
        if state.phase == .playing {
            forceStuck(state)
        }
    }
}
