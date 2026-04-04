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

    // MARK: - Coordinate Conversion

    var coordinateConverter: GridCoordinateConverter?

    // MARK: - Drag State

    var draggedPieceNode: BlockPieceNode?
    var draggedTrayIndex: Int?

    // MARK: - SKScene Lifecycle

    override func didMove(to view: SKView) {
        self.backgroundColor = ColorPalette.background
        setupNodes()
        setupOverlays()
        updateDisplay()
    }

    // MARK: - Layout

    private func setupNodes() {
        let sceneWidth = self.size.width
        let sceneHeight = self.size.height
        let topInset: CGFloat = 70
        let bottomInset: CGFloat = 34

        let hudHeight = Constants.hudHeight
        let hudCenterY = sceneHeight - topInset - hudHeight / 2
        self.hudNode.position = CGPoint(x: sceneWidth / 2, y: hudCenterY)
        self.hudNode.layout(width: sceneWidth, height: hudHeight)
        addChild(self.hudNode)

        let trayHeight = sceneHeight * 0.12
        let trayCenterY = bottomInset + trayHeight / 2
        self.trayNode.position = CGPoint(x: sceneWidth / 2, y: trayCenterY)
        self.trayNode.setup(width: sceneWidth * 0.95, height: trayHeight)
        addChild(self.trayNode)

        let gridTopY = hudCenterY - hudHeight / 2 - 8
        let gridBottomY = trayCenterY + trayHeight / 2 + 8
        let gridAvailableHeight = gridTopY - gridBottomY
        let gridSide = min(sceneWidth * 0.95, gridAvailableHeight)
        let gridCenterY = gridBottomY + gridAvailableHeight / 2
        let gridFrame = CGRect(
            x: sceneWidth / 2 - gridSide / 2,
            y: gridCenterY - gridSide / 2,
            width: gridSide,
            height: gridSide
        )
        self.gridNode.position = .zero
        self.gridNode.setup(in: gridFrame)
        addChild(self.gridNode)

        self.coordinateConverter = self.gridNode.makeCoordinateConverter()
    }

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
        self.hudNode.updateScore(self.gameState.score)
        self.hudNode.updateLevel(self.gameState.level)
        self.hudNode.updateLives(self.gameState.lives)
    }

    // MARK: - Phase Reactions

    func checkPhaseAfterPlacement() {
        switch self.gameState.phase {
        case .stuck:
            self.stuckOverlay.show(livesRemaining: self.gameState.lives)
        case .gameOver:
            self.stuckOverlay.show(livesRemaining: 0)
        default:
            break
        }
    }

    // MARK: - Life & Rescue

    private func handleUseLife() {
        self.stuckOverlay.hide()
        self.gameState.useLife()
        self.gameState.performRescue()
        updateDisplay()
        self.hudNode.updateLives(self.gameState.lives)
    }

    private func handlePlayAgain() {
        self.gameOverNode.isHidden = true
        self.gameState.resetGame()
        updateDisplay()
    }

    // MARK: - Touch Forwarding

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleTouchBegan(touch)
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
