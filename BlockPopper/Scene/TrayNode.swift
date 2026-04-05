import SpriteKit

/// Renders three piece-preview slots at the bottom of the screen.
class TrayNode: SKNode {

    // MARK: - Properties

    private var slotNodes: [BlockPieceNode] = []
    private var trayWidth: CGFloat = 0
    private var trayHeight: CGFloat = 0

    // MARK: - Setup

    /// Call once to size the tray. Origin is at the node's local (0,0); the parent
    /// is responsible for positioning TrayNode on screen.
    func setup(width: CGFloat, height: CGFloat) {
        trayWidth = width
        trayHeight = height

        // Remove any previous slot nodes
        slotNodes.forEach { $0.removeFromParent() }
        slotNodes.removeAll()

        for _ in 0..<Constants.traySlotCount {
            let slot = BlockPieceNode()
            addChild(slot)
            slotNodes.append(slot)
        }

        positionSlots()
    }

    // MARK: - Public API

    /// Refreshes all slot visuals from the given piece array.
    func updatePieces(_ pieces: [BlockPiece?], style: BlockStyle) {
        let cellSize = slotCellSize()

        for (index, pieceOpt) in pieces.prefix(Constants.traySlotCount).enumerated() {
            let slot = slotNodes[index]
            if let piece = pieceOpt {
                slot.configure(piece: piece, cellSize: cellSize, style: style)
                // Center the piece visually within its slot
                centerPieceNode(slot, at: index)
                slot.isHidden = false
            } else {
                slot.isHidden = true
            }
        }
    }

    func pieceNode(at index: Int) -> BlockPieceNode? {
        guard index >= 0, index < slotNodes.count else { return nil }
        return slotNodes[index]
    }

    /// Returns the tray slot index that contains `node`, or nil if not found.
    func trayIndex(for node: SKNode) -> Int? {
        for (index, slot) in slotNodes.enumerated() {
            if slot === node || node.inParentHierarchy(slot) {
                return index
            }
        }
        return nil
    }

    // MARK: - Layout helpers

    private func positionSlots() {
        let slotWidth = trayWidth / CGFloat(Constants.traySlotCount)
        for (index, slot) in slotNodes.enumerated() {
            let centerX = -trayWidth / 2 + slotWidth * (CGFloat(index) + 0.5)
            slot.position = CGPoint(x: centerX, y: 0)
        }
    }

    private func centerPieceNode(_ node: BlockPieceNode, at index: Int) {
        let slotWidth = trayWidth / CGFloat(Constants.traySlotCount)
        let centerX = -trayWidth / 2 + slotWidth * (CGFloat(index) + 0.5)

        guard let piece = node.piece else {
            node.position = CGPoint(x: centerX, y: 0)
            return
        }

        let cs = slotCellSize()
        let minCol = piece.offsets.map(\.col).min() ?? 0
        let maxCol = piece.offsets.map(\.col).max() ?? 0
        let minRow = piece.offsets.map(\.row).min() ?? 0
        let maxRow = piece.offsets.map(\.row).max() ?? 0

        let pieceWidth  = CGFloat(maxCol - minCol + 1) * cs
        let pieceHeight = CGFloat(maxRow - minRow + 1) * cs

        // Center piece horizontally in slot, vertically in tray
        let offsetX = centerX - CGFloat(minCol) * cs - pieceWidth / 2
        // Piece cells are at y = -row * cs, so visual center sits below the anchor.
        // Shift node up by half the row span to vertically center the piece.
        let visualCenterY = -CGFloat(minRow + maxRow) * cs / 2.0
        let offsetY = -visualCenterY

        node.position = CGPoint(x: offsetX, y: offsetY)
    }

    /// Cell size that fits the largest standard piece (5 cells wide) in a slot.
    private func slotCellSize() -> CGFloat {
        let slotWidth = trayWidth / CGFloat(Constants.traySlotCount)
        let maxCells: CGFloat = 5
        let usableFraction: CGFloat = 0.95
        return min(slotWidth * usableFraction / maxCells, trayHeight * 0.95 / maxCells)
    }
}
