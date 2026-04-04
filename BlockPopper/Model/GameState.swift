import Foundation

enum GamePhase {
    case playing
    case animatingClear
    case stuck
    case rescuing
    case gameOver
}

class GameState {

    var grid: GameGrid
    var score: Int
    var level: Int
    var lives: Int
    var trayPieces: [BlockPiece?]
    var phase: GamePhase
    var currentStyle: BlockStyle
    private let pieceGenerator: PieceGenerator

    static let maxLives = 3

    init() {
        self.grid = GameGrid()
        self.score = 0
        self.level = 1
        self.lives = GameState.maxLives
        self.phase = .playing
        self.currentStyle = .stone
        self.pieceGenerator = PieceGenerator()
        self.trayPieces = [
            self.pieceGenerator.nextPiece(),
            self.pieceGenerator.nextPiece(),
            self.pieceGenerator.nextPiece()
        ]
    }

    // MARK: - Piece Placement

    func canPlacePiece(at trayIndex: Int, position: GridPosition) -> Bool {
        guard self.phase == .playing,
              let piece = self.trayPieces[trayIndex] else { return false }
        return self.grid.canPlace(piece: piece, at: position)
    }

    @discardableResult
    func placePiece(at trayIndex: Int, position: GridPosition) -> ClearResult? {
        guard self.phase == .playing,
              let piece = self.trayPieces[trayIndex] else { return nil }
        guard self.grid.canPlace(piece: piece, at: position) else { return nil }

        self.grid.place(piece: piece, at: position)
        self.trayPieces[trayIndex] = self.pieceGenerator.nextPiece()

        let clearResult = self.grid.clearFullLines()

        if clearResult.totalClearedLines > 0 {
            self.score += clearResult.points
            self.phase = .animatingClear
            return clearResult
        }

        checkStuckState()
        return clearResult
    }

    // MARK: - Post-Animation

    func onClearAnimationComplete() -> Bool {
        let wasFullBoardClear = self.grid.isEmpty

        if wasFullBoardClear {
            self.currentStyle = self.currentStyle.next()
        }

        checkStuckState()

        if case .stuck = self.phase { } else if case .gameOver = self.phase { } else {
            checkLevelUp()
            self.phase = .playing
        }

        return wasFullBoardClear
    }

    // MARK: - Life & Rescue

    func useLife() {
        guard self.phase == .stuck, self.lives > 0 else { return }
        self.lives -= 1
        self.phase = .rescuing
    }

    func performRescue() {
        guard self.phase == .rescuing else { return }
        let activePieces = self.trayPieces.compactMap { $0 }
        self.grid.rescueBoard(pieces: activePieces)
        self.phase = .playing
    }

    // MARK: - Level

    func checkLevelUp() {
        let targetScore = LevelConfig.targetScore(forLevel: self.level)
        if self.score >= targetScore {
            self.level += 1
        }
    }

    // MARK: - Reset

    func resetGame() {
        self.grid = GameGrid()
        self.score = 0
        self.level = 1
        self.lives = GameState.maxLives
        self.phase = .playing
        self.currentStyle = .stone
        self.trayPieces = [
            self.pieceGenerator.nextPiece(),
            self.pieceGenerator.nextPiece(),
            self.pieceGenerator.nextPiece()
        ]
    }

    // MARK: - Stuck Check

    private func checkStuckState() {
        let activePieces = self.trayPieces.compactMap { $0 }
        if self.grid.isBoardStuck(pieces: activePieces) {
            self.phase = self.lives > 0 ? .stuck : .gameOver
        }
    }
}
