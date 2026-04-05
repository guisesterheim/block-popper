import SpriteKit

/// A bamboo-themed button with raised (normal) and recessed (selected) visual states.
class ActionButtonNode: SKNode {

    // MARK: - Properties

    private let background = SKShapeNode()
    private let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private var iconNode: SKNode?
    private var buttonWidth: CGFloat = 0
    private var buttonHeight: CGFloat = 0
    private(set) var isSelected: Bool = false
    private(set) var isEnabled: Bool = true

    var onTap: (() -> Void)?

    // MARK: - Colors

    private let raisedFill = UIColor(hex: 0x6B4A2E)
    private let raisedBorder = UIColor(hex: 0x8B6914).withAlphaComponent(0.6)
    private let raisedTopHighlight = UIColor.white.withAlphaComponent(0.12)
    private let raisedBottomShadow = UIColor.black.withAlphaComponent(0.2)

    private let recessedFill = UIColor(hex: 0x3D2818)
    private let recessedBorder = UIColor(hex: 0x2A1A0E).withAlphaComponent(0.6)
    private let recessedTopShadow = UIColor.black.withAlphaComponent(0.25)
    private let recessedBottomHighlight = UIColor.white.withAlphaComponent(0.06)

    private let disabledAlpha: CGFloat = 0.65

    // MARK: - Setup

    func configure(title: String, icon: IconType, width: CGFloat, height: CGFloat) {
        self.buttonWidth = width
        self.buttonHeight = height
        self.isUserInteractionEnabled = true

        // Background shape
        let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 6).cgPath
        background.path = path
        background.lineWidth = 1.5
        background.zPosition = 0
        if background.parent == nil { addChild(background) }

        let fontSize = max(12, min(height * 0.4, 16))
        let iconSize = fontSize * 1.1

        // Icon + label layout: icon to the left of text, both centered as a group
        let spacing: CGFloat = 5
        let textWidth = estimateTextWidth(title, fontSize: fontSize)
        let groupWidth = iconSize + spacing + textWidth
        let groupStartX = -groupWidth / 2

        // Icon
        iconNode?.removeFromParent()
        let newIcon = createIcon(icon, size: iconSize)
        newIcon.position = CGPoint(x: groupStartX + iconSize / 2, y: 0)
        newIcon.zPosition = 2
        addChild(newIcon)
        iconNode = newIcon

        // Label
        label.text = title
        label.fontSize = fontSize
        label.fontColor = ColorPalette.hudText
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: groupStartX + iconSize + spacing, y: 0)
        label.zPosition = 2
        if label.parent == nil { addChild(label) }

        applyRaisedStyle()
    }

    /// Legacy configure without icon
    func configure(title: String, width: CGFloat, height: CGFloat) {
        configure(title: title, icon: .none, width: width, height: height)
    }

    // MARK: - Icon Types

    enum IconType {
        case refreshArrows
        case squareX
        case none
    }

    // MARK: - Icon Drawing

    private func createIcon(_ type: IconType, size: CGFloat) -> SKNode {
        let container = SKNode()
        let color = ColorPalette.hudText
        let lineWidth: CGFloat = 1.5

        switch type {
        case .refreshArrows:
            drawRefreshArrows(in: container, size: size, color: color, lineWidth: lineWidth)
        case .squareX:
            drawSquareX(in: container, size: size, color: color, lineWidth: lineWidth)
        case .none:
            break
        }

        return container
    }

    /// Two curved arrows forming a refresh/cycle loop
    private func drawRefreshArrows(in container: SKNode, size: CGFloat, color: UIColor, lineWidth: CGFloat) {
        let r = size * 0.38
        let arrowSize = size * 0.15

        // Top arc (right half, clockwise from top to bottom-right)
        let topArc = UIBezierPath(arcCenter: .zero, radius: r,
                                   startAngle: .pi * 0.8, endAngle: .pi * 0.1,
                                   clockwise: false)
        let topArcNode = SKShapeNode(path: topArc.cgPath)
        topArcNode.strokeColor = color
        topArcNode.fillColor = .clear
        topArcNode.lineWidth = lineWidth
        topArcNode.lineCap = .round
        container.addChild(topArcNode)

        // Arrowhead at end of top arc (pointing clockwise)
        let topArrowTip = CGPoint(x: r * cos(.pi * 0.1), y: r * sin(.pi * 0.1))
        let topArrow = UIBezierPath()
        topArrow.move(to: CGPoint(x: topArrowTip.x - arrowSize, y: topArrowTip.y + arrowSize * 1.2))
        topArrow.addLine(to: topArrowTip)
        topArrow.addLine(to: CGPoint(x: topArrowTip.x + arrowSize * 0.8, y: topArrowTip.y + arrowSize * 0.8))
        let topArrowNode = SKShapeNode(path: topArrow.cgPath)
        topArrowNode.strokeColor = color
        topArrowNode.fillColor = .clear
        topArrowNode.lineWidth = lineWidth
        topArrowNode.lineCap = .round
        topArrowNode.lineJoin = .round
        container.addChild(topArrowNode)

        // Bottom arc (left half)
        let bottomArc = UIBezierPath(arcCenter: .zero, radius: r,
                                      startAngle: -.pi * 0.2, endAngle: -.pi * 0.9,
                                      clockwise: false)
        let bottomArcNode = SKShapeNode(path: bottomArc.cgPath)
        bottomArcNode.strokeColor = color
        bottomArcNode.fillColor = .clear
        bottomArcNode.lineWidth = lineWidth
        bottomArcNode.lineCap = .round
        container.addChild(bottomArcNode)

        // Arrowhead at end of bottom arc
        let bottomArrowTip = CGPoint(x: r * cos(-.pi * 0.9), y: r * sin(-.pi * 0.9))
        let bottomArrow = UIBezierPath()
        bottomArrow.move(to: CGPoint(x: bottomArrowTip.x + arrowSize, y: bottomArrowTip.y - arrowSize * 1.2))
        bottomArrow.addLine(to: bottomArrowTip)
        bottomArrow.addLine(to: CGPoint(x: bottomArrowTip.x - arrowSize * 0.8, y: bottomArrowTip.y - arrowSize * 0.8))
        let bottomArrowNode = SKShapeNode(path: bottomArrow.cgPath)
        bottomArrowNode.strokeColor = color
        bottomArrowNode.fillColor = .clear
        bottomArrowNode.lineWidth = lineWidth
        bottomArrowNode.lineCap = .round
        bottomArrowNode.lineJoin = .round
        container.addChild(bottomArrowNode)
    }

    /// Small square with an X through it
    private func drawSquareX(in container: SKNode, size: CGFloat, color: UIColor, lineWidth: CGFloat) {
        let s = size * 0.35
        let squareRect = CGRect(x: -s, y: -s, width: s * 2, height: s * 2)
        let squareNode = SKShapeNode(path: UIBezierPath(roundedRect: squareRect, cornerRadius: s * 0.2).cgPath)
        squareNode.strokeColor = color
        squareNode.fillColor = .clear
        squareNode.lineWidth = lineWidth
        container.addChild(squareNode)

        // X inside the square
        let inset = s * 0.55
        let xPath = UIBezierPath()
        xPath.move(to: CGPoint(x: -inset, y: inset))
        xPath.addLine(to: CGPoint(x: inset, y: -inset))
        xPath.move(to: CGPoint(x: inset, y: inset))
        xPath.addLine(to: CGPoint(x: -inset, y: -inset))
        let xNode = SKShapeNode(path: xPath.cgPath)
        xNode.strokeColor = color
        xNode.fillColor = .clear
        xNode.lineWidth = lineWidth
        xNode.lineCap = .round
        container.addChild(xNode)
    }

    // MARK: - Text Width Estimate

    private func estimateTextWidth(_ text: String, fontSize: CGFloat) -> CGFloat {
        CGFloat(text.count) * fontSize * 0.6
    }

    // MARK: - State

    func setSelected(_ selected: Bool) {
        isSelected = selected
        if selected {
            applyRecessedStyle()
        } else {
            applyRaisedStyle()
        }
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        self.alpha = enabled ? 1.0 : disabledAlpha
    }

    // MARK: - Visual Styles

    private func applyRaisedStyle() {
        background.fillColor = raisedFill
        background.strokeColor = raisedBorder

        background.children.forEach { $0.removeFromParent() }

        let w = buttonWidth
        let h = buttonHeight

        let topHL = SKShapeNode(path: CGPath(
            rect: CGRect(x: -w / 2 + 2, y: h / 2 - 4, width: w - 4, height: 3),
            transform: nil))
        topHL.fillColor = raisedTopHighlight
        topHL.strokeColor = .clear
        background.addChild(topHL)

        let bottomSH = SKShapeNode(path: CGPath(
            rect: CGRect(x: -w / 2 + 2, y: -h / 2 + 1, width: w - 4, height: 3),
            transform: nil))
        bottomSH.fillColor = raisedBottomShadow
        bottomSH.strokeColor = .clear
        background.addChild(bottomSH)

        let leftHL = SKShapeNode(path: CGPath(
            rect: CGRect(x: -w / 2 + 1, y: -h / 2 + 2, width: 3, height: h - 4),
            transform: nil))
        leftHL.fillColor = raisedTopHighlight
        leftHL.strokeColor = .clear
        background.addChild(leftHL)

        let rightSH = SKShapeNode(path: CGPath(
            rect: CGRect(x: w / 2 - 4, y: -h / 2 + 2, width: 3, height: h - 4),
            transform: nil))
        rightSH.fillColor = raisedBottomShadow
        rightSH.strokeColor = .clear
        background.addChild(rightSH)
    }

    private func applyRecessedStyle() {
        background.fillColor = recessedFill
        background.strokeColor = recessedBorder

        background.children.forEach { $0.removeFromParent() }

        let w = buttonWidth
        let h = buttonHeight

        let topSH = SKShapeNode(path: CGPath(
            rect: CGRect(x: -w / 2 + 2, y: h / 2 - 5, width: w - 4, height: 4),
            transform: nil))
        topSH.fillColor = recessedTopShadow
        topSH.strokeColor = .clear
        background.addChild(topSH)

        let leftSH = SKShapeNode(path: CGPath(
            rect: CGRect(x: -w / 2 + 1, y: -h / 2 + 2, width: 3, height: h - 4),
            transform: nil))
        leftSH.fillColor = recessedTopShadow
        leftSH.strokeColor = .clear
        background.addChild(leftSH)

        let bottomHL = SKShapeNode(path: CGPath(
            rect: CGRect(x: -w / 2 + 2, y: -h / 2 + 1, width: w - 4, height: 3),
            transform: nil))
        bottomHL.fillColor = recessedBottomHighlight
        bottomHL.strokeColor = .clear
        background.addChild(bottomHL)

        let rightHL = SKShapeNode(path: CGPath(
            rect: CGRect(x: w / 2 - 4, y: -h / 2 + 2, width: 3, height: h - 4),
            transform: nil))
        rightHL.fillColor = recessedBottomHighlight
        rightHL.strokeColor = .clear
        background.addChild(rightHL)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled else { return }
        onTap?()
    }
}
