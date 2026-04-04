import SpriteKit

/// A composite SKNode that renders a single BlockPiece as a grid of rounded-rect cells.
class BlockPieceNode: SKNode {

    // MARK: - Properties

    private(set) var piece: BlockPiece?
    private(set) var cellSize: CGFloat = 0
    private var cellNodes: [SKShapeNode] = []

    // MARK: - Configuration

    /// Removes all previous cell nodes and rebuilds the visual from the given piece.
    func configure(piece: BlockPiece, cellSize: CGFloat, style: BlockStyle) {
        self.piece = piece
        self.cellSize = cellSize

        cellNodes.forEach { $0.removeFromParent() }
        cellNodes.removeAll()

        let gap: CGFloat = 1
        let innerSize = cellSize - gap * 2
        let radius = min(style.cornerRadius, innerSize / 2)
        let rect = CGRect(
            x: -innerSize / 2,
            y: -innerSize / 2,
            width: innerSize,
            height: innerSize
        )

        for offset in piece.offsets {
            let node = SKShapeNode(
                path: UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
            )
            node.fillColor = style.fillColor
            node.strokeColor = style.borderColor
            node.lineWidth = 1
            // SpriteKit coordinate: row 0 is top, increasing downward
            // Convert: x = col * cellSize, y = -row * cellSize  (anchor at piece origin)
            node.position = CGPoint(
                x: CGFloat(offset.col) * cellSize,
                y: -CGFloat(offset.row) * cellSize
            )
            addChild(node)
            cellNodes.append(node)
        }
    }

    /// Updates fill/border colors when the style changes without recreating cell geometry.
    func applyStyle(_ style: BlockStyle) {
        for node in cellNodes {
            node.fillColor = style.fillColor
            node.strokeColor = style.borderColor
        }
    }

    /// Returns the scene-space bounding rect of this piece given a cell size, useful for
    /// centering the node inside a tray slot.
    func boundsForCellSize(_ size: CGFloat) -> CGRect {
        guard let piece else { return .zero }
        let minRow = piece.offsets.map(\.row).min() ?? 0
        let maxRow = piece.offsets.map(\.row).max() ?? 0
        let minCol = piece.offsets.map(\.col).min() ?? 0
        let maxCol = piece.offsets.map(\.col).max() ?? 0
        let w = CGFloat(maxCol - minCol + 1) * size
        let h = CGFloat(maxRow - minRow + 1) * size
        return CGRect(
            x: CGFloat(minCol) * size,
            y: -CGFloat(maxRow) * size,
            width: w,
            height: h
        )
    }
}
