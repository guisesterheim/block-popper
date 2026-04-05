import SpriteKit

// MARK: - Drag-and-Drop Touch Handling

extension GameScene {

    func handleTouchBegan(_ touch: UITouch) {
        guard self.gameState.gamePhase == .playing || self.gameState.gamePhase == .animatingClear else { return }
        guard !self.gameState.isEraseMode else { return }

        let sceneLocation = touch.location(in: self)
        let touchPadding: CGFloat = 20

        for index in 0..<Constants.traySlotCount {
            guard let pieceNode = self.trayNode.pieceNode(at: index),
                  !pieceNode.isHidden else { continue }

            let localPoint = touch.location(in: pieceNode)

            // Check each cell with generous padding around it
            let hitDetected = pieceNode.children.contains { child in
                let expandedFrame = child.frame.insetBy(dx: -touchPadding, dy: -touchPadding)
                return expandedFrame.contains(localPoint)
            }

            // Also check the bounding box of the whole piece with padding
            let pieceBounds = pieceNode.calculateAccumulatedFrame()
            let expandedBounds = pieceBounds.insetBy(dx: -touchPadding, dy: -touchPadding)
            let scenePointInPiece = touch.location(in: pieceNode.parent ?? pieceNode)
            let boundsHit = expandedBounds.contains(scenePointInPiece)

            if hitDetected || boundsHit {
                SoundManager.shared.playPickup()
                beginDrag(trayIndex: index, touch: touch, sceneLocation: sceneLocation)
                return
            }
        }
    }

    func handleTouchMoved(_ touch: UITouch) {
        guard let pieceNode = self.draggedPieceNode else { return }

        let sceneLocation = touch.location(in: self)
        let displayLocation = CGPoint(
            x: sceneLocation.x + self.dragCenterOffset.x,
            y: sceneLocation.y + Constants.dragVerticalOffset + self.dragCenterOffset.y
        )
        pieceNode.position = displayLocation

        updateGhostPreview(for: pieceNode, at: displayLocation)
    }

    func handleTouchEnded(_ touch: UITouch) {
        guard let pieceNode = self.draggedPieceNode,
              let trayIndex = self.draggedTrayIndex else {
            cancelDrag()
            return
        }

        let sceneLocation = touch.location(in: self)
        let dropLocation = CGPoint(
            x: sceneLocation.x + self.dragCenterOffset.x,
            y: sceneLocation.y + Constants.dragVerticalOffset + self.dragCenterOffset.y
        )

        self.gridNode.hideGhost()

        let didPlace = attemptPlacement(pieceNode: pieceNode, trayIndex: trayIndex, at: dropLocation)
        if didPlace {
            SoundManager.shared.playValidDrop()
        } else {
            SoundManager.shared.playInvalidDrop()
        }
        endDrag()
    }

    // MARK: - Ghost Preview

    private func updateGhostPreview(for pieceNode: BlockPieceNode, at location: CGPoint) {
        guard let piece = pieceNode.piece,
              let snapPosition = self.gridNode.snapPosition(for: piece, near: location) else {
            self.gridNode.hideGhost()
            return
        }

        let isValidPlacement = self.gameState.canPlacePiece(
            at: self.draggedTrayIndex ?? 0,
            position: snapPosition
        )
        self.gridNode.showGhost(for: piece, at: snapPosition, valid: isValidPlacement)
    }

    // MARK: - Placement

    @discardableResult
    private func attemptPlacement(pieceNode: BlockPieceNode, trayIndex: Int, at dropLocation: CGPoint) -> Bool {
        guard let piece = pieceNode.piece,
              let snapPosition = self.gridNode.snapPosition(for: piece, near: dropLocation) else {
            return false
        }

        let clearResult = self.gameState.placePiece(at: trayIndex, position: snapPosition)
        guard clearResult != nil else { return false }

        updateDisplay()

        if let result = clearResult, result.totalClearedLines > 0 {
            playClearAnimation(result: result)
        } else {
            checkPhaseAfterPlacement()
        }

        return true
    }

    // MARK: - Drag Lifecycle

    func beginDrag(trayIndex: Int, touch: UITouch, sceneLocation: CGPoint) {
        guard let sourcePieceNode = self.trayNode.pieceNode(at: trayIndex),
              let piece = sourcePieceNode.piece else { return }

        self.draggedTrayIndex = trayIndex

        let floatingNode = BlockPieceNode()
        floatingNode.configure(
            piece: piece,
            cellSize: self.gridNode.cellSize,
            style: self.gameState.currentStyle
        )

        // Place the floating piece at the display position (above finger)
        let displayY = sceneLocation.y + Constants.dragVerticalOffset

        // Align the bottom-left corner of the piece's bounding box to the finger
        let cs = self.gridNode.cellSize
        let minCol = piece.offsets.map(\.col).min() ?? 0
        let maxRow = piece.offsets.map(\.row).max() ?? 0

        // Cell centers are at (col*cs, -row*cs). Bottom-left corner of bounding box:
        //   left edge  = minCol * cs - cs/2
        //   bottom edge = -maxRow * cs - cs/2
        // We want nodePos + edge = fingerPos, so offset = -edge
        let baseOffsetX = -(CGFloat(minCol) * cs - cs / 2)
        let baseOffsetY = CGFloat(maxRow) * cs + cs / 2

        // Nudge 20% of a cell size to the left and down
        let nudge = cs * 0.2
        self.dragCenterOffset = CGPoint(x: baseOffsetX - nudge, y: baseOffsetY - nudge)

        floatingNode.position = CGPoint(
            x: sceneLocation.x + self.dragCenterOffset.x,
            y: displayY + self.dragCenterOffset.y
        )
        floatingNode.setScale(Constants.dragScaleFactor)
        floatingNode.zPosition = 10
        addChild(floatingNode)
        self.draggedPieceNode = floatingNode

        sourcePieceNode.isHidden = true
    }

    func endDrag() {
        self.draggedPieceNode?.removeFromParent()
        self.draggedPieceNode = nil
        self.dragCenterOffset = .zero

        if let index = self.draggedTrayIndex {
            self.trayNode.pieceNode(at: index)?.isHidden = false
        }
        self.draggedTrayIndex = nil
        updateDisplay()
    }

    func cancelDrag() {
        self.draggedPieceNode?.removeFromParent()
        self.draggedPieceNode = nil
        self.dragCenterOffset = .zero

        if let index = self.draggedTrayIndex {
            self.trayNode.pieceNode(at: index)?.isHidden = false
        }
        self.draggedTrayIndex = nil
    }
}
