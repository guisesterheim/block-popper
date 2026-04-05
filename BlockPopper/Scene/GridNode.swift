import SpriteKit

/// Renders the 8x8 game grid as a flat array of SKShapeNode cells.
class GridNode: SKNode {

    // MARK: - Properties

    var cellSize: CGFloat = 0
    var gridOrigin: CGPoint = .zero
    var cellNodes: [[SKShapeNode]] = []
    private var ghostNodes: [SKShapeNode] = []

    // MARK: - Setup

    func setup(in frame: CGRect) {
        cellNodes.forEach { row in row.forEach { $0.removeFromParent() } }
        cellNodes.removeAll()
        ghostNodes.forEach { $0.removeFromParent() }
        ghostNodes.removeAll()
        setupGrid(in: frame)
    }

    // MARK: - Sync with model

    func updateFromGrid(_ grid: GameGrid, style: BlockStyle) {
        let numRows = GameGrid.rows
        let numCols = GameGrid.columns
        let gap: CGFloat = 1
        let innerSize = cellSize - gap * 2
        let radius = min(style.cornerRadius, innerSize / 2)
        let baseRect = CGRect(x: -innerSize / 2, y: -innerSize / 2,
                              width: innerSize, height: innerSize)

        for row in 0..<numRows {
            for col in 0..<numCols {
                let node = cellNodes[row][col]
                node.children.forEach { $0.removeFromParent() }

                switch grid.cellAt(row: row, col: col) {
                case .empty:
                    node.path = UIBezierPath(roundedRect: baseRect, cornerRadius: 2).cgPath
                    // Gradient: cells at top rows are brown, bottom rows trend to dark green
                    let rowProgress = CGFloat(row) / CGFloat(numRows - 1)
                    let topCellColor = ColorPalette.gridCellEmpty
                    let bottomCellColor = UIColor(hex: 0x4A6040)
                    node.fillColor = blendColors(from: topCellColor, to: bottomCellColor,
                                                 progress: rowProgress)
                    node.strokeColor = ColorPalette.gridCellBorder
                    node.lineWidth = 1.5
                    addInsetShadow(to: node, innerSize: innerSize)

                case .occupied:
                    node.path = UIBezierPath(roundedRect: baseRect, cornerRadius: radius).cgPath
                    node.fillColor = style.fillColor
                    node.strokeColor = style.borderColor
                    node.lineWidth = 1.5
                    addOccupiedCellTexture(to: node, innerSize: innerSize, radius: radius)
                }
            }
        }
    }

    private func addInsetShadow(to node: SKShapeNode, innerSize: CGFloat) {
        // Top inner shadow — light comes from above, so top edge is darkened
        let topShadow = SKShapeNode(path: CGPath(
            rect: CGRect(x: -innerSize / 2 + 1, y: innerSize / 2 - 5,
                         width: innerSize - 2, height: 4), transform: nil))
        topShadow.fillColor = UIColor.black.withAlphaComponent(0.15)
        topShadow.strokeColor = .clear
        node.addChild(topShadow)

        // Left inner shadow
        let leftShadow = SKShapeNode(path: CGPath(
            rect: CGRect(x: -innerSize / 2 + 1, y: -innerSize / 2 + 1,
                         width: 3, height: innerSize - 2), transform: nil))
        leftShadow.fillColor = UIColor.black.withAlphaComponent(0.10)
        leftShadow.strokeColor = .clear
        node.addChild(leftShadow)

        // Bottom highlight — opposite of shadow, lighter edge
        let bottomHighlight = SKShapeNode(path: CGPath(
            rect: CGRect(x: -innerSize / 2 + 1, y: -innerSize / 2 + 1,
                         width: innerSize - 2, height: 3), transform: nil))
        bottomHighlight.fillColor = UIColor.white.withAlphaComponent(0.05)
        bottomHighlight.strokeColor = .clear
        node.addChild(bottomHighlight)

        // Right highlight
        let rightHighlight = SKShapeNode(path: CGPath(
            rect: CGRect(x: innerSize / 2 - 4, y: -innerSize / 2 + 1,
                         width: 3, height: innerSize - 2), transform: nil))
        rightHighlight.fillColor = UIColor.white.withAlphaComponent(0.04)
        rightHighlight.strokeColor = .clear
        node.addChild(rightHighlight)
    }

    private func addOccupiedCellTexture(to node: SKShapeNode, innerSize: CGFloat, radius: CGFloat) {
        let highlightHeight = innerSize * 0.25
        let highlightRect = CGRect(x: -innerSize / 2 + 2, y: innerSize / 2 - highlightHeight,
                                   width: innerSize - 4, height: highlightHeight - 2)
        let highlight = SKShapeNode(path: UIBezierPath(
            roundedRect: highlightRect, cornerRadius: radius * 0.5).cgPath)
        highlight.fillColor = UIColor.white.withAlphaComponent(0.12)
        highlight.strokeColor = .clear
        node.addChild(highlight)

        let shadowHeight = innerSize * 0.2
        let shadowRect = CGRect(x: -innerSize / 2 + 2, y: -innerSize / 2 + 2,
                                width: innerSize - 4, height: shadowHeight)
        let shadow = SKShapeNode(path: UIBezierPath(
            roundedRect: shadowRect, cornerRadius: radius * 0.5).cgPath)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.1)
        shadow.strokeColor = .clear
        node.addChild(shadow)
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
            guard row >= 0, row < GameGrid.rows,
                  col >= 0, col < GameGrid.columns else { continue }

            let ghost = SKShapeNode(path: UIBezierPath(roundedRect: rect, cornerRadius: 2).cgPath)
            ghost.fillColor = color
            ghost.strokeColor = .clear
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

    func scenePosition(row: Int, col: Int) -> CGPoint {
        CGPoint(
            x: gridOrigin.x + CGFloat(col) * cellSize + cellSize / 2,
            y: gridOrigin.y - CGFloat(row) * cellSize - cellSize / 2
        )
    }

    func snapPosition(for piece: BlockPiece, near scenePoint: CGPoint) -> GridPosition? {
        let col = Int((scenePoint.x - gridOrigin.x) / cellSize)
        let row = Int((gridOrigin.y - scenePoint.y) / cellSize)
        guard row >= 0, row < GameGrid.rows,
              col >= 0, col < GameGrid.columns else { return nil }
        for offset in piece.offsets {
            let r = row + offset.row
            let c = col + offset.col
            guard r >= 0, r < GameGrid.rows,
                  c >= 0, c < GameGrid.columns else { return nil }
        }
        return GridPosition(row: row, col: col)
    }

    func makeCoordinateConverter() -> GridCoordinateConverter {
        GridCoordinateConverter(gridOrigin: gridOrigin, cellSize: cellSize)
    }
}
