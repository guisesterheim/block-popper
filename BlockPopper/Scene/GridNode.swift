import SpriteKit

/// Renders the 9x9 game grid as a flat array of SKShapeNode cells.
class GridNode: SKNode {

    // MARK: - Properties

    private(set) var cellSize: CGFloat = 0

    /// Bottom-left origin of the grid in the parent node's coordinate space.
    private(set) var gridOrigin: CGPoint = .zero

    private var cellNodes: [[SKShapeNode]] = []
    private var ghostNodes: [SKShapeNode] = []

    // MARK: - Setup

    /// Creates and lays out all 81 cell nodes inside `frame`.
    /// `frame` is expressed in the parent (scene) coordinate space and describes
    /// the square area the grid should fill.
    func setup(in frame: CGRect) {
        // Remove previous cells if any
        cellNodes.forEach { row in row.forEach { $0.removeFromParent() } }
        cellNodes.removeAll()
        ghostNodes.forEach { $0.removeFromParent() }
        ghostNodes.removeAll()

        let size = Int(GameGrid.size)
        cellSize = min(frame.width, frame.height) / CGFloat(size)

        // gridOrigin = top-left of the grid (SpriteKit y increases upward)
        let totalWidth  = cellSize * CGFloat(size)
        let totalHeight = cellSize * CGFloat(size)
        let originX = frame.midX - totalWidth  / 2
        let originY = frame.midY + totalHeight / 2
        gridOrigin = CGPoint(x: originX, y: originY)

        let gap: CGFloat = 1
        let innerSize = cellSize - gap * 2
        let rect = CGRect(x: -innerSize / 2, y: -innerSize / 2,
                          width: innerSize, height: innerSize)

        for row in 0..<size {
            var rowNodes: [SKShapeNode] = []
            for col in 0..<size {
                let node = SKShapeNode(
                    path: UIBezierPath(roundedRect: rect, cornerRadius: 2).cgPath
                )
                node.fillColor = ColorPalette.gridCellEmpty
                node.strokeColor = ColorPalette.gridCellBorder
                node.lineWidth = 1
                node.position = scenePosition(row: row, col: col)
                addChild(node)
                rowNodes.append(node)
            }
            cellNodes.append(rowNodes)
        }
    }

    // MARK: - Sync with model

    func updateFromGrid(_ grid: GameGrid, style: BlockStyle) {
        let size = Int(GameGrid.size)
        let gap: CGFloat = 1
        let innerSize = cellSize - gap * 2
        let radius = min(style.cornerRadius, innerSize / 2)
        let rect = CGRect(x: -innerSize / 2, y: -innerSize / 2,
                          width: innerSize, height: innerSize)

        for row in 0..<size {
            for col in 0..<size {
                let node = cellNodes[row][col]
                switch grid.cellAt(row: row, col: col) {
                case .empty:
                    node.path = UIBezierPath(roundedRect: rect, cornerRadius: 2).cgPath
                    node.fillColor = ColorPalette.gridCellEmpty
                    node.strokeColor = ColorPalette.gridCellBorder
                    node.lineWidth = 1
                case .occupied:
                    node.path = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
                    node.fillColor = style.fillColor
                    node.strokeColor = style.borderColor
                    node.lineWidth = 1
                }
            }
        }
    }

    // MARK: - Ghost preview

    func showGhost(for piece: BlockPiece, at position: GridPosition, valid: Bool) {
        hideGhost()

        let color = valid ? ColorPalette.ghostValid : ColorPalette.ghostInvalid
        let gap: CGFloat = 1
        let innerSize = cellSize - gap * 2
        let rect = CGRect(x: -innerSize / 2, y: -innerSize / 2,
                          width: innerSize, height: innerSize)

        for offset in piece.offsets {
            let row = position.row + offset.row
            let col = position.col + offset.col

            guard row >= 0, row < GameGrid.size,
                  col >= 0, col < GameGrid.size else { continue }

            let ghost = SKShapeNode(
                path: UIBezierPath(roundedRect: rect, cornerRadius: 2).cgPath
            )
            ghost.fillColor = color
            ghost.strokeColor = .clear
            ghost.lineWidth = 0
            ghost.zPosition = 1
            ghost.position = scenePosition(row: row, col: col)
            addChild(ghost)
            ghostNodes.append(ghost)
        }
    }

    func hideGhost() {
        ghostNodes.forEach { $0.removeFromParent() }
        ghostNodes.removeAll()
    }

    // MARK: - Coordinate helpers

    /// Returns the scene-space center of the cell at (row, col).
    func scenePosition(row: Int, col: Int) -> CGPoint {
        CGPoint(
            x: gridOrigin.x + CGFloat(col) * cellSize + cellSize / 2,
            y: gridOrigin.y - CGFloat(row) * cellSize - cellSize / 2
        )
    }

    /// Finds the nearest valid grid anchor position for `piece` given a scene-space point,
    /// returning nil if the point lies outside the grid area.
    func snapPosition(for piece: BlockPiece, near scenePoint: CGPoint) -> GridPosition? {
        let col = Int((scenePoint.x - gridOrigin.x) / cellSize)
        let row = Int((gridOrigin.y - scenePoint.y) / cellSize)

        guard row >= 0, row < GameGrid.size,
              col >= 0, col < GameGrid.size else { return nil }

        // Verify all cells of the piece would be in bounds
        for offset in piece.offsets {
            let r = row + offset.row
            let c = col + offset.col
            guard r >= 0, r < GameGrid.size,
                  c >= 0, c < GameGrid.size else { return nil }
        }

        return GridPosition(row: row, col: col)
    }

    /// Converts a scene-space point to a GridPosition without bounds-checking piece extents.
    func gridPosition(for scenePoint: CGPoint) -> GridPosition? {
        let col = Int((scenePoint.x - gridOrigin.x) / cellSize)
        let row = Int((gridOrigin.y - scenePoint.y) / cellSize)

        guard row >= 0, row < GameGrid.size,
              col >= 0, col < GameGrid.size else { return nil }

        return GridPosition(row: row, col: col)
    }

    /// Builds a GridCoordinateConverter that matches this node's current layout.
    func makeCoordinateConverter() -> GridCoordinateConverter {
        GridCoordinateConverter(gridOrigin: gridOrigin, cellSize: cellSize)
    }
}
