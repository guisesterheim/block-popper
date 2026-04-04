import SpriteKit

extension CGPoint {
    func adding(_ vector: CGVector) -> CGPoint {
        CGPoint(x: x + vector.dx, y: y + vector.dy)
    }

    func subtracting(_ other: CGPoint) -> CGVector {
        CGVector(dx: x - other.x, dy: y - other.y)
    }
}

extension CGVector {
    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }
}

struct GridCoordinateConverter {
    let gridOrigin: CGPoint
    let cellSize: CGFloat

    func scenePosition(for gridPos: GridPosition) -> CGPoint {
        CGPoint(
            x: gridOrigin.x + CGFloat(gridPos.col) * cellSize + cellSize / 2,
            y: gridOrigin.y - CGFloat(gridPos.row) * cellSize - cellSize / 2
        )
    }

    func gridPosition(for scenePoint: CGPoint) -> GridPosition? {
        let col = Int((scenePoint.x - gridOrigin.x) / cellSize)
        let row = Int((gridOrigin.y - scenePoint.y) / cellSize)

        guard row >= 0, row < Constants.gridSize,
              col >= 0, col < Constants.gridSize else {
            return nil
        }

        return GridPosition(row: row, col: col)
    }

    func snapToGrid(_ scenePoint: CGPoint, for piece: BlockPiece) -> GridPosition? {
        // Find the grid cell closest to the center of the piece
        guard let basePos = gridPosition(for: scenePoint) else { return nil }

        // Adjust so the piece anchor aligns properly
        let adjustedRow = basePos.row
        let adjustedCol = basePos.col

        // Verify all cells of the piece would be in bounds
        for offset in piece.offsets {
            let r = adjustedRow + offset.row
            let c = adjustedCol + offset.col
            guard r >= 0, r < Constants.gridSize, c >= 0, c < Constants.gridSize else {
                return nil
            }
        }

        return GridPosition(row: adjustedRow, col: adjustedCol)
    }
}
