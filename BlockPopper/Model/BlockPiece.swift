import Foundation

enum PieceType: String, CaseIterable {
    case dot           // 1x1
    case dominoH       // 1x2
    case dominoV       // 2x1
    case triominoH     // 1x3
    case tetrominoH    // 1x4
    case pentominoH    // 1x5
    case square2x2     // 2x2
    case lShape        // 3x2 L
    case pyramid       // 3x2 pyramid
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
        case .tetrominoH:
            return BlockPiece(type: type, offsets: [(0, 0), (0, 1), (0, 2), (0, 3)])
        case .pentominoH:
            return BlockPiece(type: type, offsets: [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)])
        case .square2x2:
            return BlockPiece(type: type, offsets: [(0, 0), (0, 1), (1, 0), (1, 1)])
        case .lShape:
            // 3x2 L-shape:
            // X .
            // X .
            // X X
            return BlockPiece(type: type, offsets: [(0, 0), (1, 0), (2, 0), (2, 1)])
        case .pyramid:
            // 3x2 pyramid:
            // . X .
            // X X X
            return BlockPiece(type: type, offsets: [(0, 1), (1, 0), (1, 1), (1, 2)])
        }
    }

    static let allPieces: [BlockPiece] = PieceType.allCases.map { make($0) }
}
