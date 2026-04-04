import Foundation

enum CellState: Equatable {
    case empty
    case occupied(PieceType)
}

struct ClearResult {
    let clearedRows: [Int]
    let clearedCols: [Int]
    var totalClearedLines: Int { clearedRows.count + clearedCols.count }
    var points: Int { totalClearedLines * Constants.gridSize }
    var isBoardEmpty: Bool = false
}

struct GridPosition: Equatable {
    let row: Int
    let col: Int
}

struct GameGrid {
    static let size = Constants.gridSize

    var cells: [[CellState]]

    var occupiedCount: Int {
        cells.flatMap { $0 }.filter { $0 != .empty }.count
    }

    var isEmpty: Bool {
        occupiedCount == 0
    }

    init() {
        cells = Array(
            repeating: Array(repeating: CellState.empty, count: GameGrid.size),
            count: GameGrid.size
        )
    }

    // MARK: - Placement

    func canPlace(piece: BlockPiece, at position: GridPosition) -> Bool {
        for offset in piece.offsets {
            let targetRow = position.row + offset.row
            let targetCol = position.col + offset.col
            guard targetRow >= 0, targetRow < GameGrid.size,
                  targetCol >= 0, targetCol < GameGrid.size else {
                return false
            }
            if cells[targetRow][targetCol] != .empty {
                return false
            }
        }
        return true
    }

    mutating func place(piece: BlockPiece, at position: GridPosition) {
        for offset in piece.offsets {
            let targetRow = position.row + offset.row
            let targetCol = position.col + offset.col
            cells[targetRow][targetCol] = .occupied(piece.type)
        }
    }

    // MARK: - Line Clearing

    mutating func clearFullLines() -> ClearResult {
        var clearedRows: [Int] = []
        var clearedCols: [Int] = []

        for row in 0..<GameGrid.size {
            if cells[row].allSatisfy({ $0 != .empty }) {
                clearedRows.append(row)
            }
        }

        for col in 0..<GameGrid.size {
            let isColumnFull = (0..<GameGrid.size).allSatisfy { cells[$0][col] != .empty }
            if isColumnFull {
                clearedCols.append(col)
            }
        }

        for row in clearedRows { clearRow(row) }
        for col in clearedCols { clearCol(col) }

        var result = ClearResult(clearedRows: clearedRows, clearedCols: clearedCols)
        result.isBoardEmpty = isEmpty
        return result
    }

    // MARK: - Stuck Detection

    func isBoardStuck(pieces: [BlockPiece]) -> Bool {
        for piece in pieces {
            for row in 0..<GameGrid.size {
                for col in 0..<GameGrid.size {
                    if canPlace(piece: piece, at: GridPosition(row: row, col: col)) {
                        return false
                    }
                }
            }
        }
        return true
    }

    // MARK: - Query

    func cellAt(row: Int, col: Int) -> CellState {
        guard row >= 0, row < GameGrid.size, col >= 0, col < GameGrid.size else {
            return .empty
        }
        return cells[row][col]
    }
}
