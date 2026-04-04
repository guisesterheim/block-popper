import SpriteKit

class GameOverNode: SKNode {

    private let overlayNode = SKShapeNode()
    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let playAgainLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let playAgainButton = SKShapeNode()

    var onPlayAgain: (() -> Void)?

    func configure(size: CGSize) {
        isUserInteractionEnabled = true
        zPosition = 100

        // Semi-transparent dark overlay
        overlayNode.path = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
        overlayNode.fillColor = UIColor.black.withAlphaComponent(0.7)
        overlayNode.strokeColor = .clear
        overlayNode.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
        addChild(overlayNode)

        // Title
        titleLabel.text = "Game Over"
        titleLabel.fontSize = size.width * 0.1
        titleLabel.fontColor = ColorPalette.hudText
        titleLabel.position = CGPoint(x: 0, y: size.height * 0.15)
        titleLabel.verticalAlignmentMode = .center
        addChild(titleLabel)

        // Score
        scoreLabel.fontSize = size.width * 0.06
        scoreLabel.fontColor = ColorPalette.hudTextSecondary
        scoreLabel.position = CGPoint(x: 0, y: size.height * 0.05)
        scoreLabel.verticalAlignmentMode = .center
        addChild(scoreLabel)

        // Level
        levelLabel.fontSize = size.width * 0.05
        levelLabel.fontColor = ColorPalette.hudTextSecondary
        levelLabel.position = CGPoint(x: 0, y: -size.height * 0.02)
        levelLabel.verticalAlignmentMode = .center
        addChild(levelLabel)

        // Play Again button
        let buttonSize = CGSize(width: size.width * 0.5, height: size.height * 0.06)
        playAgainButton.path = CGPath(
            roundedRect: CGRect(
                x: -buttonSize.width / 2,
                y: -buttonSize.height / 2,
                width: buttonSize.width,
                height: buttonSize.height
            ),
            cornerWidth: 8,
            cornerHeight: 8,
            transform: nil
        )
        playAgainButton.fillColor = BlockStyle.terracotta.fillColor
        playAgainButton.strokeColor = BlockStyle.terracotta.borderColor
        playAgainButton.lineWidth = 2
        playAgainButton.position = CGPoint(x: 0, y: -size.height * 0.12)
        addChild(playAgainButton)

        playAgainLabel.text = "Play Again"
        playAgainLabel.fontSize = size.width * 0.05
        playAgainLabel.fontColor = ColorPalette.hudText
        playAgainLabel.verticalAlignmentMode = .center
        playAgainButton.addChild(playAgainLabel)
    }

    func show(score: Int, level: Int) {
        scoreLabel.text = "Score: \(score)"
        levelLabel.text = "Level \(level)"
        alpha = 0
        run(SKAction.fadeIn(withDuration: Constants.gameOverFadeDuration))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if playAgainButton.contains(location) {
            playAgainButton.run(SKAction.sequence([
                SKAction.scale(to: 0.95, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ]))
            onPlayAgain?()
        }
    }
}
