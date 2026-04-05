import Foundation

enum PieceType: String, CaseIterable {
    case dot           // 1x1
    case dominoH       // 1x2
    case dominoV       // 2x1
    case triominoH     // 1x3
    case triominoV     // 3x1
    case tetrominoH    // 1x4
    case tetrominoV    // 4x1
    case pentominoH    // 1x5
    case pentominoV    // 5x1
    case square2x2     // 2x2
    case square3x3     // 3x3
    case lShape        // 3x2 L (bottom-right)
    case lShapeUp      // 3x2 L upside down (top-left)
    case lShapeLeft    // 2x3 L (bottom-left)
    case lShapeRight   // 2x3 L (top-right)
    case pyramid       // 3x2 pyramid (point up)
    case pyramidLeft   // 2x3 pyramid (point left)
    case pyramidRight  // 2x3 pyramid (point right)
    case zRight        // Z shape (horizontal)
    case zLeft         // S shape (horizontal)
    case zUp           // Z shape (vertical)
    case zDown         // S shape (vertical)
}

struct BlockPiece {
    let type: PieceType
    let offsets: [(row: Int, col: Int)]

    var cellCount: Int { offsets.count }

    var boundingRows: Int {
        guard let maxRow = offsets.map(\.row).max(),
              let minRow = offsets.map(\.row).min() else { return 0 }
        return maxRow - minRow + 1
    }

    var boundingCols: Int {
        guard let maxCol = offsets.map(\.col).max(),
              let minCol = offsets.map(\.col).min() else { return 0 }
        return maxCol - minCol + 1
    }

    static func make(_ type: PieceType) -> BlockPiece {
        switch type {
        case .dot:
            return BlockPiece(type: type, offsets: [(0, 0)])
        case .dominoH:
            return BlockPiece(type: type, offsets: [(0, 0), (0, 1)])
        case .dominoV:
            return BlockPiece(type: type, offsets: [(0, 0), (1, 0)])
        case .triominoH:
            return BlockPiece(type: type, offsets: [(0, 0), (0, 1), (0, 2)])
        case .triominoV:
            return BlockPiece(type: type, offsets: [(0, 0), (1, 0), (2, 0)])
        case .tetrominoH:
            return BlockPiece(type: type, offsets: [(0, 0), (0, 1), (0, 2), (0, 3)])
        case .tetrominoV:
            return BlockPiece(type: type, offsets: [(0, 0), (1, 0), (2, 0), (3, 0)])
        case .pentominoH:
            return BlockPiece(type: type, offsets: [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)])
        case .pentominoV:
            return BlockPiece(type: type, offsets: [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0)])
        case .square2x2:
            return BlockPiece(type: type, offsets: [(0, 0), (0, 1), (1, 0), (1, 1)])
        case .square3x3:
            return BlockPiece(type: type, offsets: [
                (0, 0), (0, 1), (0, 2),
                (1, 0), (1, 1), (1, 2),
                (2, 0), (2, 1), (2, 2)
            ])
        case .lShape:
            // X .
            // X .
            // X X
            return BlockPiece(type: type, offsets: [(0, 0), (1, 0), (2, 0), (2, 1)])
        case .lShapeUp:
            // X X
            // . X
            // . X
            return BlockPiece(type: type, offsets: [(0, 0), (0, 1), (1, 1), (2, 1)])
        case .lShapeLeft:
            // X X X
            // X . .
            return BlockPiece(type: type, offsets: [(0, 0), (0, 1), (0, 2), (1, 0)])
        case .lShapeRight:
            // . . X
            // X X X
            return BlockPiece(type: type, offsets: [(0, 2), (1, 0), (1, 1), (1, 2)])
        case .pyramid:
            // . X .
            // X X X
            return BlockPiece(type: type, offsets: [(0, 1), (1, 0), (1, 1), (1, 2)])
        case .pyramidLeft:
            // X .
            // X X
            // X .
            return BlockPiece(type: type, offsets: [(0, 0), (1, 0), (1, 1), (2, 0)])
        case .pyramidRight:
            // . X
            // X X
            // . X
            return BlockPiece(type: type, offsets: [(0, 1), (1, 0), (1, 1), (2, 1)])
        case .zRight:
            // X X .
            // . X X
            return BlockPiece(type: type, offsets: [(0, 0), (0, 1), (1, 1), (1, 2)])
        case .zLeft:
            // . X X
            // X X .
            return BlockPiece(type: type, offsets: [(0, 1), (0, 2), (1, 0), (1, 1)])
        case .zUp:
            // . X
            // X X
            // X .
            return BlockPiece(type: type, offsets: [(0, 1), (1, 0), (1, 1), (2, 0)])
        case .zDown:
            // X .
            // X X
            // . X
            return BlockPiece(type: type, offsets: [(0, 0), (1, 0), (1, 1), (2, 1)])
        }
    }

    static let allPieces: [BlockPiece] = PieceType.allCases.map { make($0) }
}
