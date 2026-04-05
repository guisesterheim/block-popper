import SpriteKit

// MARK: - Wood Background, Bottom Bamboo Panel & Tray Box

extension GameScene {

    func addBambooBackground(width: CGFloat, height: CGFloat) {
        let texture = SKTexture(imageNamed: "bambooPanel")
        let backgroundSprite = SKSpriteNode(texture: texture)
        backgroundSprite.size = CGSize(width: width, height: height)
        backgroundSprite.position = CGPoint(x: width / 2, y: height / 2)
        backgroundSprite.zPosition = -2
        addChild(backgroundSprite)
    }

    // MARK: - Bottom Bamboo Panel (mirrors top HUD panel)

    func addBottomBambooPanel(centerX: CGFloat, centerY: CGFloat,
                              width: CGFloat, height: CGFloat) {
        let texture = SKTexture(imageNamed: "bambooPanel")
        let panelSprite = SKSpriteNode(texture: texture)
        panelSprite.size = CGSize(width: width, height: height)
        panelSprite.position = CGPoint(x: centerX, y: centerY)
        panelSprite.zPosition = 1
        addChild(panelSprite)

        // Border at top edge
        let borderRect = CGRect(x: -width / 2, y: -height / 2,
                                width: width, height: height)
        let border = SKShapeNode(path: CGPath(rect: borderRect, transform: nil))
        border.fillColor = .clear
        border.strokeColor = UIColor(hex: 0x8B6914).withAlphaComponent(0.4)
        border.lineWidth = 1.5
        border.position = CGPoint(x: centerX, y: centerY)
        border.zPosition = 2
        addChild(border)
    }

    // MARK: - Dark Recessed Tray Box (like Score/Level boxes)

    func addTrayPanel(centerX: CGFloat, centerY: CGFloat,
                      width: CGFloat, height: CGFloat) {
        let boxRect = CGRect(x: -width / 2, y: -height / 2,
                             width: width, height: height)
        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 10).cgPath
        let position = CGPoint(x: centerX, y: centerY)

        // Dark recessed box
        let box = SKShapeNode(path: boxPath)
        box.fillColor = UIColor(hex: 0x3D2818)
        box.strokeColor = UIColor(hex: 0x2A1A0E).withAlphaComponent(0.6)
        box.lineWidth = 1.5
        box.position = position
        box.zPosition = 3
        addChild(box)

        // Top inner shadow
        let topShadow = SKShapeNode(path: CGPath(
            rect: CGRect(x: -width / 2 + 3, y: height / 2 - 7,
                         width: width - 6, height: 6), transform: nil))
        topShadow.fillColor = UIColor.black.withAlphaComponent(0.22)
        topShadow.strokeColor = .clear
        box.addChild(topShadow)

        // Left inner shadow
        let leftShadow = SKShapeNode(path: CGPath(
            rect: CGRect(x: -width / 2 + 1, y: -height / 2 + 3,
                         width: 5, height: height - 6), transform: nil))
        leftShadow.fillColor = UIColor.black.withAlphaComponent(0.15)
        leftShadow.strokeColor = .clear
        box.addChild(leftShadow)

        // Bottom highlight
        let bottomHL = SKShapeNode(path: CGPath(
            rect: CGRect(x: -width / 2 + 3, y: -height / 2 + 1,
                         width: width - 6, height: 4), transform: nil))
        bottomHL.fillColor = UIColor.white.withAlphaComponent(0.07)
        bottomHL.strokeColor = .clear
        box.addChild(bottomHL)

        // Right highlight
        let rightHL = SKShapeNode(path: CGPath(
            rect: CGRect(x: width / 2 - 6, y: -height / 2 + 3,
                         width: 5, height: height - 6), transform: nil))
        rightHL.fillColor = UIColor.white.withAlphaComponent(0.05)
        rightHL.strokeColor = .clear
        box.addChild(rightHL)
    }
}
