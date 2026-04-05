import SpriteKit

/// A composite SKNode that renders a single BlockPiece with textured cells.
class BlockPieceNode: SKNode {

    // MARK: - Properties

    private(set) var piece: BlockPiece?
    private(set) var cellSize: CGFloat = 0
    private var cellNodes: [SKNode] = []

    // MARK: - Configuration

    func configure(piece: BlockPiece, cellSize: CGFloat, style: BlockStyle) {
        self.piece = piece
        self.cellSize = cellSize

        self.cellNodes.forEach { $0.removeFromParent() }
        self.cellNodes.removeAll()

        for offset in piece.offsets {
            let cellContainer = createTexturedCell(style: style, size: cellSize)
            cellContainer.position = CGPoint(
                x: CGFloat(offset.col) * cellSize,
                y: -CGFloat(offset.row) * cellSize
            )
            addChild(cellContainer)
            self.cellNodes.append(cellContainer)
        }
    }

    func applyStyle(_ style: BlockStyle) {
        self.cellNodes.forEach { $0.removeFromParent() }
        self.cellNodes.removeAll()

        guard let piece = self.piece else { return }
        for offset in piece.offsets {
            let cellContainer = createTexturedCell(style: style, size: self.cellSize)
            cellContainer.position = CGPoint(
                x: CGFloat(offset.col) * self.cellSize,
                y: -CGFloat(offset.row) * self.cellSize
            )
            addChild(cellContainer)
            self.cellNodes.append(cellContainer)
        }
    }

    // MARK: - Textured Cell Builder

    private func createTexturedCell(style: BlockStyle, size: CGFloat) -> SKNode {
        let container = SKNode()
        let gap: CGFloat = 1
        let innerSize = size - gap * 2
        let radius = min(style.cornerRadius, innerSize / 2)

        let baseRect = CGRect(x: -innerSize / 2, y: -innerSize / 2,
                              width: innerSize, height: innerSize)

        // Base fill
        let base = SKShapeNode(path: UIBezierPath(
            roundedRect: baseRect, cornerRadius: radius).cgPath)
        base.fillColor = style.fillColor
        base.strokeColor = style.borderColor
        base.lineWidth = 1.5
        container.addChild(base)

        // Top highlight (lighter strip)
        let highlightHeight = innerSize * 0.25
        let highlightRect = CGRect(x: -innerSize / 2 + 2, y: innerSize / 2 - highlightHeight,
                                   width: innerSize - 4, height: highlightHeight - 2)
        let highlight = SKShapeNode(path: UIBezierPath(
            roundedRect: highlightRect, cornerRadius: radius * 0.5).cgPath)
        highlight.fillColor = UIColor.white.withAlphaComponent(0.12)
        highlight.strokeColor = .clear
        container.addChild(highlight)

        // Bottom shadow (darker strip)
        let shadowHeight = innerSize * 0.2
        let shadowRect = CGRect(x: -innerSize / 2 + 2, y: -innerSize / 2 + 2,
                                width: innerSize - 4, height: shadowHeight)
        let shadow = SKShapeNode(path: UIBezierPath(
            roundedRect: shadowRect, cornerRadius: radius * 0.5).cgPath)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.1)
        shadow.strokeColor = .clear
        container.addChild(shadow)

        return container
    }

    func boundsForCellSize(_ size: CGFloat) -> CGRect {
        guard let piece else { return .zero }
        let minRow = piece.offsets.map(\.row).min() ?? 0
        let maxRow = piece.offsets.map(\.row).max() ?? 0
        let minCol = piece.offsets.map(\.col).min() ?? 0
        let maxCol = piece.offsets.map(\.col).max() ?? 0
        return CGRect(
            x: CGFloat(minCol) * size,
            y: -CGFloat(maxRow) * size,
            width: CGFloat(maxCol - minCol + 1) * size,
            height: CGFloat(maxRow - minRow + 1) * size
        )
    }
}
