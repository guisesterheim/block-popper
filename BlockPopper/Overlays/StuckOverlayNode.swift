import SpriteKit

/// Overlay shown when the player is stuck and can't place any piece.
class StuckOverlayNode: SKNode {

    private let backgroundNode = SKShapeNode()
    private let messageLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let descriptionLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
    private let livesInfoLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let watchAdButton = SKShapeNode()
    private let watchAdLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")

    var onUseLife: (() -> Void)?

    func configure(size: CGSize) {
        self.isUserInteractionEnabled = true
        self.zPosition = 50

        self.backgroundNode.path = CGPath(
            rect: CGRect(x: -size.width / 2, y: -size.height / 2,
                         width: size.width, height: size.height),
            transform: nil
        )
        self.backgroundNode.fillColor = UIColor.black.withAlphaComponent(0.6)
        self.backgroundNode.strokeColor = .clear
        addChild(self.backgroundNode)

        self.messageLabel.text = "You're Stuck!"
        self.messageLabel.fontSize = size.width * 0.08
        self.messageLabel.fontColor = ColorPalette.hudText
        self.messageLabel.position = CGPoint(x: 0, y: size.height * 0.10)
        self.messageLabel.verticalAlignmentMode = .center
        addChild(self.messageLabel)

        self.descriptionLabel.text = "Clear two lines and two rows to continue?"
        self.descriptionLabel.fontSize = size.width * 0.04
        self.descriptionLabel.fontColor = ColorPalette.hudTextSecondary
        self.descriptionLabel.position = CGPoint(x: 0, y: size.height * 0.05)
        self.descriptionLabel.verticalAlignmentMode = .center
        addChild(self.descriptionLabel)

        self.livesInfoLabel.fontSize = size.width * 0.04
        self.livesInfoLabel.fontColor = ColorPalette.hudTextSecondary
        self.livesInfoLabel.position = CGPoint(x: 0, y: size.height * 0.01)
        self.livesInfoLabel.verticalAlignmentMode = .center
        addChild(self.livesInfoLabel)

        let buttonWidth = size.width * 0.55
        let buttonHeight = size.height * 0.06
        self.watchAdButton.path = CGPath(
            roundedRect: CGRect(x: -buttonWidth / 2, y: -buttonHeight / 2,
                                width: buttonWidth, height: buttonHeight),
            cornerWidth: 10, cornerHeight: 10, transform: nil
        )
        self.watchAdButton.fillColor = BlockStyle.terracotta.fillColor
        self.watchAdButton.strokeColor = BlockStyle.terracotta.borderColor
        self.watchAdButton.lineWidth = 2
        self.watchAdButton.position = CGPoint(x: 0, y: -size.height * 0.05)
        addChild(self.watchAdButton)

        self.watchAdLabel.text = "▶  Watch Ad"
        self.watchAdLabel.fontSize = size.width * 0.05
        self.watchAdLabel.fontColor = ColorPalette.hudText
        self.watchAdLabel.verticalAlignmentMode = .center
        self.watchAdButton.addChild(self.watchAdLabel)
    }

    func show(livesRemaining: Int) {
        self.watchAdButton.isHidden = false
        self.watchAdLabel.isHidden = false
        self.messageLabel.text = "You're Stuck!"
        self.descriptionLabel.text = "Clear two lines and two rows to continue?"
        self.livesInfoLabel.text = ""

        self.alpha = 0
        self.isHidden = false
        self.run(SKAction.fadeIn(withDuration: 0.25))
    }

    func hide() {
        self.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.run { self.isHidden = true }
        ]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if self.watchAdButton.contains(location) && !self.watchAdButton.isHidden {
            self.watchAdButton.run(SKAction.sequence([
                SKAction.scale(to: 0.95, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ]))
            self.onUseLife?()
        }
    }
}
