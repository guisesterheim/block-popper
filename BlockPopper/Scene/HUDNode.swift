import SpriteKit

/// Bamboo panel HUD showing phase score, hacks, and phase number.
class HUDNode: SKNode {

    private let phaseScoreLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let hacksLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let phaseLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private var panelNode: SKShapeNode?

    override init() {
        super.init()
        setupLabels()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLabels()
    }

    private func setupLabels() {
        for label in [self.phaseScoreLabel, self.hacksLabel, self.phaseLabel] {
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.fontColor = ColorPalette.hudText
            label.zPosition = 4
            addChild(label)
        }
        self.phaseScoreLabel.text = "0/100"
        self.hacksLabel.text = "Hacks: 0"
        self.phaseLabel.text = "Phase 1"
    }

    // MARK: - Layout

    func layout(width: CGFloat, height: CGFloat) {
        let panelHeight = height
        let fontSize = max(13, min(height, 44) * 0.4)

        self.panelNode?.removeFromParent()

        let texture = SKTexture(imageNamed: "bambooPanel")
        let panelSprite = SKSpriteNode(texture: texture)
        panelSprite.size = CGSize(width: width, height: panelHeight)
        panelSprite.position = .zero
        panelSprite.zPosition = 0
        addChild(panelSprite)

        let borderRect = CGRect(x: -width / 2, y: -panelHeight / 2,
                                width: width, height: panelHeight)
        let border = SKShapeNode(path: CGPath(rect: borderRect, transform: nil))
        border.fillColor = .clear
        border.strokeColor = UIColor(hex: 0x8B6914).withAlphaComponent(0.4)
        border.lineWidth = 1.5
        border.zPosition = 1
        addChild(border)
        self.panelNode = border

        for label in [self.phaseScoreLabel, self.hacksLabel, self.phaseLabel] {
            label.fontSize = fontSize
        }

        // 3-column layout below notch
        let notchAreaHeight: CGFloat = 60
        let usableTop = panelHeight / 2 - notchAreaHeight
        let usableBottom = -panelHeight / 2
        let labelY = (usableTop + usableBottom) / 2
        let boxWidth = width * 0.28
        let boxHeight: CGFloat = 40
        let spacing = width / 3

        // Left: Phase Score
        let leftX = -spacing
        addInsetBox(at: CGPoint(x: leftX, y: labelY), width: boxWidth, height: boxHeight)
        self.phaseScoreLabel.position = CGPoint(x: leftX, y: labelY)

        // Center: Hacks
        let centerX: CGFloat = 0
        addInsetBox(at: CGPoint(x: centerX, y: labelY), width: boxWidth, height: boxHeight)
        self.hacksLabel.position = CGPoint(x: centerX, y: labelY)

        // Right: Phase
        let rightX = spacing
        addInsetBox(at: CGPoint(x: rightX, y: labelY), width: boxWidth, height: boxHeight)
        self.phaseLabel.position = CGPoint(x: rightX, y: labelY)
    }

    // MARK: - Inset Box

    private func addInsetBox(at position: CGPoint, width: CGFloat, height: CGFloat) {
        let boxRect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 6).cgPath

        let box = SKShapeNode(path: boxPath)
        box.fillColor = UIColor(hex: 0x3D2818)
        box.strokeColor = UIColor(hex: 0x2A1A0E).withAlphaComponent(0.6)
        box.lineWidth = 1
        box.position = position
        box.zPosition = 2
        addChild(box)

        // Top inner shadow
        let topShadow = SKShapeNode(path: CGPath(
            rect: CGRect(x: -width / 2 + 2, y: height / 2 - 5,
                         width: width - 4, height: 4), transform: nil))
        topShadow.fillColor = UIColor.black.withAlphaComponent(0.18)
        topShadow.strokeColor = .clear
        box.addChild(topShadow)

        // Left inner shadow
        let leftShadow = SKShapeNode(path: CGPath(
            rect: CGRect(x: -width / 2 + 1, y: -height / 2 + 2,
                         width: 3, height: height - 4), transform: nil))
        leftShadow.fillColor = UIColor.black.withAlphaComponent(0.12)
        leftShadow.strokeColor = .clear
        box.addChild(leftShadow)

        // Bottom highlight
        let bottomHighlight = SKShapeNode(path: CGPath(
            rect: CGRect(x: -width / 2 + 2, y: -height / 2 + 1,
                         width: width - 4, height: 3), transform: nil))
        bottomHighlight.fillColor = UIColor.white.withAlphaComponent(0.06)
        bottomHighlight.strokeColor = .clear
        box.addChild(bottomHighlight)

        // Right highlight
        let rightHighlight = SKShapeNode(path: CGPath(
            rect: CGRect(x: width / 2 - 4, y: -height / 2 + 2,
                         width: 3, height: height - 4), transform: nil))
        rightHighlight.fillColor = UIColor.white.withAlphaComponent(0.05)
        rightHighlight.strokeColor = .clear
        box.addChild(rightHighlight)
    }

    // MARK: - Update

    func updatePhaseScore(_ phaseScore: Int, target: Int) {
        self.phaseScoreLabel.text = "\(phaseScore)/\(target)"
    }

    func updateHacks(_ hacks: Int) {
        self.hacksLabel.text = "Hacks: \(hacks)"
    }

    func updatePhase(_ phase: Int) {
        self.phaseLabel.text = "Phase \(phase)"
    }

    // Legacy methods
    func updateScore(_ score: Int) {}
    func updateLevel(_ level: Int) {}
    func updateLives(_ lives: Int) {}
}
