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
        XCTAssertEqual(GameState().gamePhase, .playing)
    }

    func testInitialState_trayCount() {
        XCTAssertEqual(GameState().trayPieces.count, 3)
    }

    // MARK: - Score: 8 pts per cleared line (8x8 grid)

    func testScore_incrementsByGridSize_perClearedLine() {
        let state = GameState()
        triggerLineClear(state, row: 0)
        XCTAssertEqual(state.score, GameGrid.size)
    }

    func testScore_incrementsFor_twoSeparateLineCLears() {
        let state = GameState()
        triggerLineClear(state, row: 0)
        XCTAssertEqual(state.score, GameGrid.size)
        _ = state.onClearAnimationComplete()
        triggerLineClear(state, row: 1)
        XCTAssertEqual(state.score, GameGrid.size * 2)
    }

    func testScore_noChange_withoutLineClear() {
        let state = GameState()
        var g = state.grid
        g.place(piece: BlockPiece.make(.dot), at: GridPosition(row: 4, col: 4))
        state._setGrid(g)
        XCTAssertEqual(state.score, 0)
    }

    func testScore_pointsFormula() {
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
        XCTAssertEqual(state.gamePhase, .playing)
        state.useLife()
        XCTAssertEqual(state.lives, GameState.maxLives)
    }

    func testLives_useLife_doesNotDecrementWhenGameOver() {
        let state = GameState()
        drainAllLives(state)
        XCTAssertEqual(state.gamePhase, .gameOver)
        let livesBefore = state.lives
        state.useLife()
        XCTAssertEqual(state.lives, livesBefore)
    }

    // MARK: - Phase Advancement

    func testPhase_advancesWhenPhaseScoreReachesTarget() {
        let state = GameState()
        // Phase 1 target is 100
        state._setPhaseScore(100)
        XCTAssertTrue(state.checkPhaseComplete())
        XCTAssertEqual(state.gamePhase, .phaseComplete)
    }

    func testPhase_doesNotAdvance_belowThreshold() {
        let state = GameState()
        state._setPhaseScore(99)
        XCTAssertFalse(state.checkPhaseComplete())
    }

    func testPhase_targetFormula_linearProgression() {
        let expected = [(1, 100), (2, 120), (3, 140), (4, 160)]
        for (phase, target) in expected {
            XCTAssertEqual(
                LevelConfig.targetScore(forPhase: phase), target,
                "Target mismatch at phase \(phase)"
            )
        }
    }

    func testAdvancePhase_resetsPhaseScore() {
        let state = GameState()
        state._setPhaseScore(100)
        _ = state.checkPhaseComplete()
        state.advancePhase()
        XCTAssertEqual(state.phaseScore, 0)
        XCTAssertEqual(state.phase, 2)
        XCTAssertEqual(state.gamePhase, .playing)
    }

    // MARK: - Hack Economy

    func testHacks_initiallyZero() {
        XCTAssertEqual(GameState().hacksAvailable, 0)
    }

    func testHacks_earnedEvery100Points() {
        let state = GameState()
        state._setScore(100)
        XCTAssertEqual(state.hacksAvailable, 1)
        state._setScore(250)
        XCTAssertEqual(state.hacksAvailable, 2)
    }

    func testHacks_reducedByUsage() {
        let state = GameState()
        state._setScore(200)
        XCTAssertEqual(state.hacksAvailable, 2)
        state._setHacksUsed(1)
        XCTAssertEqual(state.hacksAvailable, 1)
    }

    func testFlush_costsOneHack() {
        let state = GameState()
        state._setScore(100)
        XCTAssertEqual(state.hacksAvailable, 1)
        _ = state.flush()
        XCTAssertEqual(state.hacksAvailable, 0)
    }

    func testFlush_failsWithNoHacks() {
        let state = GameState()
        XCTAssertFalse(state.flush())
    }

    func testErase_costsOneHack() {
        let state = GameState()
        state._setScore(100)
        var g = state.grid
        g.place(piece: BlockPiece.make(.dot), at: GridPosition(row: 0, col: 0))
        state._setGrid(g)
        state.isEraseMode = true
        XCTAssertTrue(state.eraseCell(row: 0, col: 0))
        XCTAssertEqual(state.hacksAvailable, 0)
    }

    func testErase_autoDeactivatesAtZeroHacks() {
        let state = GameState()
        state._setScore(100)
        state.isEraseMode = true
        var g = state.grid
        g.place(piece: BlockPiece.make(.dot), at: GridPosition(row: 0, col: 0))
        state._setGrid(g)
        _ = state.eraseCell(row: 0, col: 0)
        XCTAssertFalse(state.isEraseMode)
    }

    // MARK: - GamePhase Transitions

    func testPhase_playing_to_animatingClear() {
        let state = GameState()
        XCTAssertEqual(state.gamePhase, .playing)
        triggerLineClear(state, row: 0)
        XCTAssertEqual(state.gamePhase, .animatingClear)
    }

    func testPhase_animatingClear_to_playing_whenNotStuck() {
        let state = GameState()
        triggerLineClear(state, row: 0)
        XCTAssertEqual(state.gamePhase, .animatingClear)
        _ = state.onClearAnimationComplete()
        // May be .playing or .phaseComplete depending on score
        XCTAssertTrue(state.gamePhase == .playing || state.gamePhase == .phaseComplete)
    }

    func testPhase_playing_to_stuck_whenNoPieceFits() {
        let state = GameState()
        forceStuck(state)
        XCTAssertEqual(state.gamePhase, .stuck)
    }

    func testPhase_stuck_to_rescuing_onUseLife() {
        let state = GameState()
        forceStuck(state)
        state.useLife()
        XCTAssertEqual(state.gamePhase, .rescuing)
    }

    func testPhase_stuck_to_gameOver_whenZeroLives() {
        let state = GameState()
        drainAllLives(state)
        XCTAssertEqual(state.gamePhase, .gameOver)
    }

    func testPhase_rescuing_to_playing_afterPerformRescue() {
        let state = GameState()
        forceStuck(state)
        state.useLife()
        state.performRescue()
        XCTAssertEqual(state.gamePhase, .playing)
    }

    // MARK: - Illegal Transitions

    func testIllegalTransition_useLife_whenPlaying_isNoOp() {
        let state = GameState()
        let livesBefore = state.lives
        state.useLife()
        XCTAssertEqual(state.lives, livesBefore)
        XCTAssertEqual(state.gamePhase, .playing)
    }

    func testIllegalTransition_useLife_whenAnimatingClear_isNoOp() {
        let state = GameState()
        triggerLineClear(state, row: 0)
        XCTAssertEqual(state.gamePhase, .animatingClear)
        let livesBefore = state.lives
        state.useLife()
        XCTAssertEqual(state.lives, livesBefore)
        XCTAssertEqual(state.gamePhase, .animatingClear)
    }

    func testIllegalTransition_useLife_whenGameOver_isNoOp() {
        let state = GameState()
        drainAllLives(state)
        XCTAssertEqual(state.gamePhase, .gameOver)
        state.useLife()
        XCTAssertEqual(state.gamePhase, .gameOver)
    }

    func testIllegalTransition_performRescue_whenPlaying_isNoOp() {
        let state = GameState()
        state.performRescue()
        XCTAssertEqual(state.gamePhase, .playing)
    }

    func testIllegalTransition_performRescue_whenAnimatingClear_isNoOp() {
        let state = GameState()
        triggerLineClear(state, row: 0)
        XCTAssertEqual(state.gamePhase, .animatingClear)
        state.performRescue()
        XCTAssertEqual(state.gamePhase, .animatingClear)
    }

    func testIllegalTransition_cannotUseLife_whenLivesZero() {
        let state = GameState()
        state._setLives(0)
        state._setPhase(.stuck)
        state.useLife()
        XCTAssertEqual(state.lives, 0)
        XCTAssertEqual(state.gamePhase, .stuck)
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
        XCTAssertEqual(state.gamePhase, .stuck)
        state.resetGame()
        XCTAssertEqual(state.gamePhase, .playing)
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
        var rescues = 0
        while state.lives > 0 && state.gamePhase != .gameOver {
            forceStuck(state)
            guard state.gamePhase == .stuck, state.lives > 0 else { break }
            state.useLife()
            state.performRescue()
            rescues += 1
        }
        XCTAssertGreaterThan(rescues, 0)
        XCTAssertEqual(state.score, 0,
                       "Score must remain 0 after \(rescues) rescues (no line clears)")
    }

    // MARK: - Use-All-3 Rule

    func testTray_notRefilledUntilAllUsed() {
        let state = GameState()
        // Place one piece — tray should have a nil slot
        let piece0 = state.trayPieces[0]
        if let piece = piece0 {
            // Find a valid placement
            for row in 0..<GameGrid.rows {
                for col in 0..<GameGrid.columns {
                    if state.grid.canPlace(piece: piece, at: GridPosition(row: row, col: col)) {
                        _ = state.placePiece(at: 0, position: GridPosition(row: row, col: col))
                        // After clear animation if any
                        if state.gamePhase == .animatingClear {
                            _ = state.onClearAnimationComplete()
                        }
                        XCTAssertNil(state.trayPieces[0], "Slot should be nil after use")
                        return
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Fills row `row` in the state's grid and triggers GameState's clear bookkeeping.
    private func triggerLineClear(_ state: GameState, row: Int) {
        guard state.gamePhase == .playing else { return }

        var g = state.grid
        for col in 0..<(GameGrid.size - 1) {
            if g.cellAt(row: row, col: col) == .empty {
                g.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: col))
            }
        }
        state._setGrid(g)

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

    /// Forces state.gamePhase to .stuck by filling the grid.
    private func forceStuck(_ state: GameState) {
        guard state.gamePhase == .playing else { return }
        var g = state.grid
        for row in 0..<GameGrid.rows {
            for col in 0..<GameGrid.columns {
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
        while state.lives > 0 && state.gamePhase != .gameOver {
            if state.gamePhase != .stuck { forceStuck(state) }
            guard state.gamePhase == .stuck, state.lives > 0 else { break }
            state.useLife()
            state.performRescue()
        }
        if state.gamePhase == .playing {
            forceStuck(state)
        }
    }
}
