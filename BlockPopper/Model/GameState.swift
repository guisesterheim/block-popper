import Foundation

enum GamePhase {
    case playing
    case animatingClear
    case stuck
    case rescuing
    case gameOver
    case phaseComplete
}

class GameState {

    var grid: GameGrid
    var phaseScore: Int          // Score within current phase (resets each phase)
    var globalScore: Int         // Cumulative score across all phases
    var phase: Int               // Current phase number (1, 2, 3, ...)
    var hacksUsed: Int           // Total hacks consumed
    var lives: Int
    var trayPieces: [BlockPiece?]
    var gamePhase: GamePhase
    var currentStyle: BlockStyle
    var isEraseMode: Bool
    private let pieceGenerator: PieceGenerator

    static let maxLives = 3
    static let hackPointsCost = 100  // Every 100 global points = 1 hack

    /// Number of hack charges available
    var hacksAvailable: Int {
        max(0, globalScore / GameState.hackPointsCost - hacksUsed)
    }

    /// Target score for the current phase
    var phaseTarget: Int {
        LevelConfig.targetScore(forPhase: phase)
    }

    // Legacy accessors for compatibility
    var score: Int { globalScore }
    var level: Int { phase }

    init() {
        self.grid = GameGrid()
        self.phase = 1
        self.hacksUsed = 0
        self.lives = GameState.maxLives
        self.gamePhase = .playing
        self.currentStyle = .stone
        self.isEraseMode = false
        self.pieceGenerator = PieceGenerator()

        if DebugConfig.isTestEnvironment {
            self.globalScore = DebugConfig.startingGlobalScore
            self.phaseScore = DebugConfig.startingPhaseScore
        } else {
            self.globalScore = 0
            self.phaseScore = 0
        }

        let initialPieces = PieceSelectionEngine.selectPieces(for: self.grid, phase: 1)
        self.trayPieces = initialPieces.map { $0 as BlockPiece? }
    }

    // MARK: - Piece Placement

    func canPlacePiece(at trayIndex: Int, position: GridPosition) -> Bool {
        guard self.gamePhase == .playing || self.gamePhase == .animatingClear,
              !self.isEraseMode,
              let piece = self.trayPieces[trayIndex] else { return false }
        return self.grid.canPlace(piece: piece, at: position)
    }

    @discardableResult
    func placePiece(at trayIndex: Int, position: GridPosition) -> ClearResult? {
        guard self.gamePhase == .playing || self.gamePhase == .animatingClear,
              !self.isEraseMode,
              let piece = self.trayPieces[trayIndex] else { return nil }
        guard self.grid.canPlace(piece: piece, at: position) else { return nil }

        self.grid.place(piece: piece, at: position)
        self.trayPieces[trayIndex] = nil  // Don't auto-refill; wait for all 3 used

        let clearResult = self.grid.clearFullLines()

        if clearResult.totalClearedLines > 0 {
            addScore(clearResult.points)
            self.gamePhase = .animatingClear
            return clearResult
        }

        refillTrayIfNeeded()
        checkStuckState()
        return clearResult
    }

    // MARK: - Tray Refill (use-all-3 rule)

    /// Refills the tray only when all 3 slots are empty.
    func refillTrayIfNeeded() {
        let allUsed = trayPieces.allSatisfy { $0 == nil }
        if allUsed {
            let newPieces = PieceSelectionEngine.selectPieces(for: grid, phase: phase)
            for i in 0..<Constants.traySlotCount {
                trayPieces[i] = newPieces[i]
            }
        }
    }

    // MARK: - Score & Phase

    private func addScore(_ points: Int) {
        self.phaseScore += points
        self.globalScore += points
    }

    /// Check if the current phase is complete. Returns true if phase advanced.
    @discardableResult
    func checkPhaseComplete() -> Bool {
        if phaseScore >= phaseTarget {
            gamePhase = .phaseComplete
            return true
        }
        return false
    }

    /// Advance to the next phase. Call after showing the phase-complete banner.
    func advancePhase() {
        self.phase += 1
        self.phaseScore = 0
        self.grid = GameGrid()
        self.currentStyle = self.currentStyle.next()
        self.gamePhase = .playing
        // Refill tray for new phase using engine
        let newPieces = PieceSelectionEngine.selectPieces(for: grid, phase: phase)
        for i in 0..<Constants.traySlotCount {
            trayPieces[i] = newPieces[i]
        }
    }

    // MARK: - Post-Animation

    func onClearAnimationComplete() -> Bool {
        let wasFullBoardClear = self.grid.isEmpty

        if wasFullBoardClear {
            self.currentStyle = self.currentStyle.next()
        }

        // Check phase completion first
        if checkPhaseComplete() {
            return wasFullBoardClear
        }

        refillTrayIfNeeded()
        checkStuckState()

        if case .stuck = self.gamePhase { } else if case .gameOver = self.gamePhase { } else {
            self.gamePhase = .playing
        }

        return wasFullBoardClear
    }

    // MARK: - Hack Actions

    /// Flush: discard all current pieces, get 3 new ones. Costs 1 hack.
    func flush() -> Bool {
        guard hacksAvailable > 0 else { return false }
        hacksUsed += 1
        let newPieces = PieceSelectionEngine.selectPieces(for: grid, phase: phase, isFlush: true)
        for i in 0..<Constants.traySlotCount {
            trayPieces[i] = newPieces[i]
        }
        checkStuckState()
        return true
    }

    /// Erase a single cell. Costs 1 hack.
    func eraseCell(row: Int, col: Int) -> Bool {
        guard hacksAvailable > 0 else { return false }
        guard grid.eraseCell(row: row, col: col) else { return false }
        hacksUsed += 1

        // Auto-deactivate erase mode if no hacks left
        if hacksAvailable <= 0 {
            isEraseMode = false
        }

        checkStuckState()
        return true
    }

    /// Toggle erase mode. Only activates if hacks are available.
    func toggleEraseMode() -> Bool {
        if isEraseMode {
            isEraseMode = false
            return true
        }
        guard hacksAvailable > 0 else { return false }
        isEraseMode = true
        return true
    }

    // MARK: - Life & Rescue

    func useLife() {
        guard self.gamePhase == .stuck, self.lives > 0 else { return }
        self.lives -= 1
        self.gamePhase = .rescuing
    }

    func performRescue() {
        guard self.gamePhase == .rescuing else { return }
        let activePieces = self.trayPieces.compactMap { $0 }
        self.grid.rescueBoard(pieces: activePieces)
        self.gamePhase = .playing
    }

    // MARK: - Reset

    func resetGame() {
        self.grid = GameGrid()
        self.phaseScore = 0
        self.globalScore = 0
        self.phase = 1
        self.hacksUsed = 0
        self.lives = GameState.maxLives
        self.gamePhase = .playing
        self.currentStyle = .stone
        self.isEraseMode = false
        let newPieces = PieceSelectionEngine.selectPieces(for: self.grid, phase: 1)
        self.trayPieces = newPieces.map { $0 as BlockPiece? }
    }

    // MARK: - Stuck Check

    private func checkStuckState() {
        let activePieces = self.trayPieces.compactMap { $0 }
        if activePieces.isEmpty { return } // All pieces used, will refill
        if self.grid.isBoardStuck(pieces: activePieces) {
            self.gamePhase = .stuck
        }
    }
}
