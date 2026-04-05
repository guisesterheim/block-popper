import SpriteKit

/// Root SKScene controller-hybrid.
/// Owns GameState and all rendering sub-nodes.
/// Drag logic lives in GameScene+Drag.swift extension.
/// Clear animation lives in GameScene+ClearAnimation.swift extension.
class GameScene: SKScene {

    // MARK: - Model

    let gameState = GameState()

    // MARK: - Rendering Nodes

    let gridNode = GridNode()
    let trayNode = TrayNode()
    let hudNode = HUDNode()
    let stuckOverlay = StuckOverlayNode()
    let gameOverNode = GameOverNode()
    let flushButton = ActionButtonNode()
    let eraseButton = ActionButtonNode()

    // MARK: - Coordinate Conversion

    var coordinateConverter: GridCoordinateConverter?

    // MARK: - Drag State

    var draggedPieceNode: BlockPieceNode?
    var draggedTrayIndex: Int?
    var dragCenterOffset: CGPoint = .zero

    // MARK: - SKScene Lifecycle

    override func didMove(to view: SKView) {
        self.backgroundColor = ColorPalette.background
        setupNodes()
        setupOverlays()
        setupButtons()
        updateDisplay()
    }

    // MARK: - Layout

    private func setupNodes() {
        let sceneWidth = self.size.width
        let sceneHeight = self.size.height
        let topInset: CGFloat = 70

        // Dark bamboo background texture
        addBambooBackground(width: sceneWidth, height: sceneHeight)

        // Calculate total content height first to center everything
        let hudHeight = topInset + Constants.hudHeight
        let gridWidth = sceneWidth * 0.95
        let cellSize = gridWidth / CGFloat(GameGrid.columns)
        let gridHeight = cellSize * CGFloat(GameGrid.rows)
        let gridGap: CGFloat = 12
        let trayHeight = sceneHeight * 0.10
        let trayGap: CGFloat = 8
        let buttonHeight: CGFloat = 38
        let buttonGap: CGFloat = 12

        let totalContentHeight = hudHeight + gridGap + gridHeight + trayGap + trayHeight + buttonGap + buttonHeight
        let verticalOffset = (sceneHeight - totalContentHeight) / 2

        // HUD at top
        let hudCenterY = sceneHeight - verticalOffset - hudHeight / 2
        self.hudNode.position = CGPoint(x: sceneWidth / 2, y: hudCenterY)
        self.hudNode.layout(width: sceneWidth, height: hudHeight)
        self.hudNode.zPosition = 3
        addChild(self.hudNode)

        // Grid below HUD
        let gridTopY = hudCenterY - hudHeight / 2 - gridGap
        let gridBottomY = gridTopY - gridHeight
        let gridFrame = CGRect(
            x: sceneWidth / 2 - gridWidth / 2,
            y: gridBottomY,
            width: gridWidth,
            height: gridHeight
        )
        self.gridNode.position = .zero
        self.gridNode.setup(in: gridFrame)
        self.gridNode.zPosition = 2
        addChild(self.gridNode)

        self.coordinateConverter = self.gridNode.makeCoordinateConverter()

        // Bottom bamboo panel fills from grid bottom to screen bottom
        let gridToPanelGap: CGFloat = 8
        let bottomPanelTop = gridBottomY - gridToPanelGap
        let bottomPanelHeight = bottomPanelTop
        let bottomPanelCenterY = bottomPanelHeight / 2
        addBottomBambooPanel(centerX: sceneWidth / 2, centerY: bottomPanelCenterY,
                             width: sceneWidth, height: bottomPanelHeight)

        // Tray below grid
        let trayBoxCenterY = gridBottomY - trayGap - trayHeight / 2
        addTrayPanel(centerX: sceneWidth / 2, centerY: trayBoxCenterY,
                     width: gridWidth - 16, height: trayHeight)

        self.trayNode.position = CGPoint(x: sceneWidth / 2, y: trayBoxCenterY)
        self.trayNode.setup(width: gridWidth - 40, height: trayHeight * 0.85)
        self.trayNode.zPosition = 5
        addChild(self.trayNode)
    }

    // MARK: - Buttons

    private func setupButtons() {
        let sceneWidth = self.size.width
        let sceneHeight = self.size.height
        let topInset: CGFloat = 70

        // Recalculate the same centered layout
        let hudHeight = topInset + Constants.hudHeight
        let gridWidth = sceneWidth * 0.95
        let cellSize = gridWidth / CGFloat(GameGrid.columns)
        let gridHeight = cellSize * CGFloat(GameGrid.rows)
        let trayHeight = sceneHeight * 0.10
        let gridGap: CGFloat = 12
        let trayGap: CGFloat = 8
        let buttonGap: CGFloat = 12
        let buttonHeight: CGFloat = 38

        let totalContentHeight = hudHeight + gridGap + gridHeight + trayGap + trayHeight + buttonGap + buttonHeight
        let verticalOffset = (sceneHeight - totalContentHeight) / 2

        let hudCenterY = sceneHeight - verticalOffset - hudHeight / 2
        let gridTopY = hudCenterY - hudHeight / 2 - gridGap
        let gridBottomY = gridTopY - gridHeight
        let trayBoxCenterY = gridBottomY - trayGap - trayHeight / 2

        // Buttons below the tray — same total width as the tray box
        let trayBoxWidth = gridWidth - 16
        let buttonY = trayBoxCenterY - trayHeight / 2 - buttonGap - buttonHeight / 2
        let buttonSpacing: CGFloat = 12
        let buttonWidth = (trayBoxWidth - buttonSpacing) / 2

        self.flushButton.configure(title: "Flush", icon: .refreshArrows, width: buttonWidth, height: buttonHeight)
        self.flushButton.position = CGPoint(x: sceneWidth / 2 - buttonWidth / 2 - buttonSpacing / 2,
                                            y: buttonY)
        self.flushButton.zPosition = 5
        self.flushButton.onTap = { [weak self] in self?.handleFlushTap() }
        addChild(self.flushButton)

        self.eraseButton.configure(title: "Erase", icon: .squareX, width: buttonWidth, height: buttonHeight)
        self.eraseButton.position = CGPoint(x: sceneWidth / 2 + buttonWidth / 2 + buttonSpacing / 2,
                                            y: buttonY)
        self.eraseButton.zPosition = 5
        self.eraseButton.onTap = { [weak self] in self?.handleEraseTap() }
        addChild(self.eraseButton)
    }

    // Background and tray panel in GameScene+Background.swift

    private func setupOverlays() {
        let sceneSize = self.size

        self.stuckOverlay.configure(size: sceneSize)
        self.stuckOverlay.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        self.stuckOverlay.isHidden = true
        self.stuckOverlay.onUseLife = { [weak self] in self?.handleUseLife() }
        addChild(self.stuckOverlay)

        self.gameOverNode.configure(size: sceneSize)
        self.gameOverNode.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        self.gameOverNode.isHidden = true
        self.gameOverNode.onPlayAgain = { [weak self] in self?.handlePlayAgain() }
        addChild(self.gameOverNode)
    }

    // MARK: - Display Sync

    func updateDisplay() {
        self.gridNode.updateFromGrid(self.gameState.grid, style: self.gameState.currentStyle)
        self.trayNode.updatePieces(
            Array(self.gameState.trayPieces),
            style: self.gameState.currentStyle
        )
        self.hudNode.updatePhaseScore(self.gameState.phaseScore, target: self.gameState.phaseTarget)
        self.hudNode.updateHacks(self.gameState.hacksAvailable)
        self.hudNode.updatePhase(self.gameState.phase)

        // Update button states
        let hasHacks = self.gameState.hacksAvailable > 0
        self.flushButton.setEnabled(hasHacks)
        self.eraseButton.setEnabled(hasHacks || self.gameState.isEraseMode)
        self.eraseButton.setSelected(self.gameState.isEraseMode)
    }

    // MARK: - Phase Reactions

    func checkPhaseAfterPlacement() {
        switch self.gameState.gamePhase {
        case .phaseComplete:
            showPhaseBanner()
        case .stuck:
            self.stuckOverlay.show(livesRemaining: self.gameState.lives)
        case .gameOver:
            self.stuckOverlay.show(livesRemaining: 0)
        default:
            break
        }
    }

    // MARK: - Button Handlers

    private func handleFlushTap() {
        guard self.gameState.gamePhase == .playing else { return }
        guard self.gameState.hacksAvailable > 0 else { return }

        // Animate old pieces out, then flush
        playFlushAnimation { [weak self] in
            guard let self else { return }
            _ = self.gameState.flush()
            self.updateDisplay()
            self.playFlushInAnimation()
        }
    }

    private func handleEraseTap() {
        guard self.gameState.gamePhase == .playing else { return }
        _ = self.gameState.toggleEraseMode()
        updateDisplay()
    }

    // MARK: - Erase Mode (grid tap)

    func handleEraseTapOnGrid(at scenePoint: CGPoint) {
        guard self.gameState.isEraseMode else { return }
        guard let gridPos = self.gridNode.snapPosition(
            for: BlockPiece.make(.dot), near: scenePoint) else { return }

        if self.gameState.eraseCell(row: gridPos.row, col: gridPos.col) {
            SoundManager.shared.playLineClear()
            let cellScenePos = self.gridNode.scenePosition(row: gridPos.row, col: gridPos.col)
            playEraseCellAnimation(at: cellScenePos)
            updateDisplay()
        }
    }

    // MARK: - Phase Banner

    private func showPhaseBanner() {
        let completedPhase = self.gameState.phase
        let nextPhase = completedPhase + 1
        let sceneSize = self.size
        let isNextHard = PieceSelectionEngine.isHardPhase(nextPhase)

        SoundManager.shared.playVictory()

        // Flag size: 50% of screen
        let flagWidth = sceneSize.width * 0.55
        let flagHeight = sceneSize.height * 0.28

        // Flag container
        let flagContainer = SKNode()
        flagContainer.zPosition = 50
        flagContainer.alpha = 0

        // Waving pennant shape (wavy right edge)
        let flagPath = UIBezierPath()
        let waveAmp = flagWidth * 0.04
        flagPath.move(to: CGPoint(x: -flagWidth / 2, y: flagHeight / 2))
        // Top edge
        flagPath.addLine(to: CGPoint(x: flagWidth / 2 - waveAmp, y: flagHeight / 2))
        // Wavy right edge (pennant tail)
        flagPath.addCurve(
            to: CGPoint(x: flagWidth / 2 + waveAmp, y: flagHeight * 0.15),
            controlPoint1: CGPoint(x: flagWidth / 2 + waveAmp * 2, y: flagHeight * 0.35),
            controlPoint2: CGPoint(x: flagWidth / 2 - waveAmp, y: flagHeight * 0.25)
        )
        flagPath.addCurve(
            to: CGPoint(x: flagWidth / 2 - waveAmp, y: -flagHeight * 0.15),
            controlPoint1: CGPoint(x: flagWidth / 2 + waveAmp * 2, y: 0),
            controlPoint2: CGPoint(x: flagWidth / 2 - waveAmp * 2, y: 0)
        )
        flagPath.addCurve(
            to: CGPoint(x: flagWidth / 2 + waveAmp, y: -flagHeight / 2),
            controlPoint1: CGPoint(x: flagWidth / 2 + waveAmp, y: -flagHeight * 0.25),
            controlPoint2: CGPoint(x: flagWidth / 2 - waveAmp, y: -flagHeight * 0.35)
        )
        // Bottom edge
        flagPath.addLine(to: CGPoint(x: -flagWidth / 2, y: -flagHeight / 2))
        flagPath.close()

        let flagColor = isNextHard
            ? UIColor(hex: 0x8B1A1A)
            : UIColor(hex: 0x1B5E20)
        let flagBorderColor = isNextHard
            ? UIColor(hex: 0xCC3333)
            : UIColor(hex: 0x2E7D32)

        let flagShape = SKShapeNode(path: flagPath.cgPath)
        flagShape.fillColor = flagColor.withAlphaComponent(0.93)
        flagShape.strokeColor = flagBorderColor
        flagShape.lineWidth = 3
        flagShape.zPosition = 0
        flagContainer.addChild(flagShape)

        // Inner glow border
        let innerInset: CGFloat = 5
        let innerShape = SKShapeNode(path: flagPath.cgPath)
        innerShape.fillColor = .clear
        innerShape.strokeColor = UIColor.white.withAlphaComponent(0.12)
        innerShape.lineWidth = 1.5
        innerShape.setScale((flagWidth - innerInset * 2) / flagWidth)
        innerShape.zPosition = 1
        flagContainer.addChild(innerShape)

        // Three stars at the top
        let starY = flagHeight * 0.28
        let starSpacing: CGFloat = 28
        for i in -1...1 {
            let star = createStar(size: 10)
            star.position = CGPoint(x: CGFloat(i) * starSpacing, y: starY)
            star.zPosition = 3
            flagContainer.addChild(star)
        }

        // Congratulations text with shadow
        let shadowOffset: CGFloat = 1.5
        let congratsShadow = SKLabelNode(fontNamed: "AvenirNext-Bold")
        congratsShadow.text = "Congratulations!"
        congratsShadow.fontSize = sceneSize.width * 0.058
        congratsShadow.fontColor = UIColor.black.withAlphaComponent(0.5)
        congratsShadow.verticalAlignmentMode = .center
        congratsShadow.horizontalAlignmentMode = .center
        congratsShadow.position = CGPoint(x: shadowOffset, y: flagHeight * 0.05 - shadowOffset)
        congratsShadow.zPosition = 2
        flagContainer.addChild(congratsShadow)

        let congratsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        congratsLabel.text = "Congratulations!"
        congratsLabel.fontSize = sceneSize.width * 0.058
        congratsLabel.fontColor = ColorPalette.hudText
        congratsLabel.verticalAlignmentMode = .center
        congratsLabel.horizontalAlignmentMode = .center
        congratsLabel.position = CGPoint(x: 0, y: flagHeight * 0.05)
        congratsLabel.zPosition = 3
        flagContainer.addChild(congratsLabel)

        // Phase text with shadow
        let phaseShadow = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        phaseShadow.text = "You finished phase \(completedPhase)!"
        phaseShadow.fontSize = sceneSize.width * 0.04
        phaseShadow.fontColor = UIColor.black.withAlphaComponent(0.5)
        phaseShadow.verticalAlignmentMode = .center
        phaseShadow.horizontalAlignmentMode = .center
        phaseShadow.position = CGPoint(x: shadowOffset, y: -flagHeight * 0.12 - shadowOffset)
        phaseShadow.zPosition = 2
        flagContainer.addChild(phaseShadow)

        let phaseLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        phaseLabel.text = "You finished phase \(completedPhase)!"
        phaseLabel.fontSize = sceneSize.width * 0.04
        phaseLabel.fontColor = ColorPalette.hudText.withAlphaComponent(0.9)
        phaseLabel.verticalAlignmentMode = .center
        phaseLabel.horizontalAlignmentMode = .center
        phaseLabel.position = CGPoint(x: 0, y: -flagHeight * 0.12)
        phaseLabel.zPosition = 3
        flagContainer.addChild(phaseLabel)

        // Position: start off-screen bottom-right
        let startPos = CGPoint(x: sceneSize.width + flagWidth,
                               y: sceneSize.height * 0.3)
        let centerPos = CGPoint(x: sceneSize.width / 2,
                                y: sceneSize.height / 2)

        flagContainer.position = startPos
        flagContainer.zRotation = -0.06
        addChild(flagContainer)

        // Continuous flapping animation
        let flap = SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleX(to: 1.02, y: 0.98, duration: 0.15),
            SKAction.scaleX(to: 0.98, y: 1.01, duration: 0.15),
            SKAction.scaleX(to: 1.01, y: 0.99, duration: 0.12),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        flagContainer.run(flap, withKey: "flap")

        // Wobble rotation while moving (wind effect)
        let wobble = SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(toAngle: -0.04, duration: 0.2),
            SKAction.rotate(toAngle: -0.08, duration: 0.25),
            SKAction.rotate(toAngle: -0.05, duration: 0.18)
        ]))
        flagContainer.run(wobble, withKey: "wobble")

        // Phase 1: Fade in + sweep to center (0.8s)
        let fadeIn = SKAction.fadeIn(withDuration: 0.4)
        let sweepIn = SKAction.move(to: centerPos, duration: 0.8)
        sweepIn.timingMode = .easeOut

        // Phase 2: Hold at center + fireworks (1.5s)
        let holdAndFireworks = SKAction.run { [weak self] in
            guard let self else { return }
            self.spawnVictoryFireworks(around: centerPos, count: 14)
        }

        // Phase 3: Dissolve out (0.7s)
        let dissolve = SKAction.group([
            SKAction.fadeOut(withDuration: 0.7),
            SKAction.scale(to: 1.15, duration: 0.7)
        ])

        flagContainer.run(SKAction.sequence([
            SKAction.group([fadeIn, sweepIn]),
            holdAndFireworks,
            SKAction.wait(forDuration: 1.5),
            dissolve,
            SKAction.run { flagContainer.removeAction(forKey: "flap") },
            SKAction.run { flagContainer.removeAction(forKey: "wobble") },
            SKAction.removeFromParent(),
            SKAction.run { [weak self] in
                guard let self else { return }
                self.gameState.advancePhase()
                self.updateDisplay()
            }
        ]))
    }

    // MARK: - Victory Fireworks

    private func spawnVictoryFireworks(around center: CGPoint, count: Int) {
        let sparkColors: [UIColor] = [
            UIColor.yellow, UIColor.orange, UIColor.white,
            UIColor(hex: 0x4CAF50), UIColor(hex: 0xFFD700)
        ]

        for i in 0..<count {
            let delay = Double(i) * 0.07
            let offsetX = CGFloat.random(in: -120...120)
            let offsetY = CGFloat.random(in: -80...80)
            let origin = CGPoint(x: center.x + offsetX, y: center.y + offsetY)

            // Each firework is a burst of 6-8 sparks
            let sparkCount = Int.random(in: 6...8)
            for j in 0..<sparkCount {
                let size = CGFloat.random(in: 2...5)
                let spark = SKShapeNode(rectOf: CGSize(width: size, height: size))
                spark.fillColor = sparkColors[(i + j) % sparkColors.count]
                spark.strokeColor = .clear
                spark.position = origin
                spark.zPosition = 55
                spark.alpha = 0
                addChild(spark)

                let angle = CGFloat.random(in: 0...(2 * .pi))
                let distance = CGFloat.random(in: 20...50)
                let dx = cos(angle) * distance
                let dy = sin(angle) * distance
                let dur = 0.3 + Double.random(in: 0...0.2)

                spark.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    SKAction.fadeIn(withDuration: 0),
                    SKAction.group([
                        SKAction.moveBy(x: dx, y: dy, duration: dur),
                        SKAction.fadeOut(withDuration: dur),
                        SKAction.scale(to: 0.1, duration: dur),
                        SKAction.rotate(byAngle: CGFloat.random(in: -2...2), duration: dur)
                    ]),
                    SKAction.removeFromParent()
                ]))
            }
        }
    }

    // MARK: - Star Shape

    private func createStar(size: CGFloat) -> SKShapeNode {
        let points = 5
        let outerR = size
        let innerR = size * 0.4
        let path = UIBezierPath()

        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let radius = i % 2 == 0 ? outerR : innerR
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()

        let star = SKShapeNode(path: path.cgPath)
        star.fillColor = UIColor(hex: 0xFFD700)
        star.strokeColor = UIColor(hex: 0xDAA520)
        star.lineWidth = 1
        return star
    }

    // MARK: - Life & Rescue

    private func handleUseLife() {
        self.stuckOverlay.hide()
        self.gameState.useLife()
        self.gameState.performRescue()
        updateDisplay()
    }

    private func handlePlayAgain() {
        self.gameOverNode.isHidden = true
        self.gameState.resetGame()
        updateDisplay()
    }

    // MARK: - Touch Forwarding

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        // If in erase mode, check if touching a tray piece first
        if self.gameState.isEraseMode {
            if isTouchOnTrayPiece(touch) {
                // Deactivate erase and start dragging
                self.gameState.isEraseMode = false
                updateDisplay()
                handleTouchBegan(touch)
                return
            }
            // Otherwise handle as erase tap on grid
            let sceneLocation = touch.location(in: self)
            handleEraseTapOnGrid(at: sceneLocation)
            return
        }

        handleTouchBegan(touch)
    }

    private func isTouchOnTrayPiece(_ touch: UITouch) -> Bool {
        let touchPadding: CGFloat = 20
        for index in 0..<Constants.traySlotCount {
            guard let pieceNode = self.trayNode.pieceNode(at: index),
                  !pieceNode.isHidden else { continue }
            let pieceBounds = pieceNode.calculateAccumulatedFrame()
            let expandedBounds = pieceBounds.insetBy(dx: -touchPadding, dy: -touchPadding)
            let scenePointInPiece = touch.location(in: pieceNode.parent ?? pieceNode)
            if expandedBounds.contains(scenePointInPiece) {
                return true
            }
        }
        return false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleTouchMoved(touch)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleTouchEnded(touch)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.gridNode.hideGhost()
        cancelDrag()
    }
}
