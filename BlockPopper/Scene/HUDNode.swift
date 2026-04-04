import SpriteKit

/// Heads-up display showing score, level, and lives at the top of the screen.
class HUDNode: SKNode {

    // MARK: - Child nodes

    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let levelLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let livesLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")

    // MARK: - Init

    override init() {
        super.init()
        setupLabels()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLabels()
    }

    // MARK: - Setup

    private func setupLabels() {
        for label in [scoreLabel, levelLabel, livesLabel] {
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.fontColor = ColorPalette.hudText
            addChild(label)
        }

        scoreLabel.text = "Score: 0"
        levelLabel.text = "Level: 1"
        livesLabel.text = "Lives: 3"
    }

    // MARK: - Layout

    /// Call after adding to the scene. `width` is the available HUD width; the HUD
    /// node itself should already be positioned at the desired vertical center.
    func layout(width: CGFloat, height: CGFloat) {
        let fontSize = max(14, height * 0.45)
        for label in [scoreLabel, levelLabel, livesLabel] {
            label.fontSize = fontSize
        }

        // Divide width into three equal thirds
        let third = width / 3
        scoreLabel.position = CGPoint(x: -third, y: 0)
        levelLabel.position = CGPoint(x: 0, y: 0)
        livesLabel.position = CGPoint(x: third, y: 0)
    }

    // MARK: - Update

    func updateScore(_ score: Int) {
        scoreLabel.text = "Score: \(score)"
    }

    func updateLevel(_ level: Int) {
        levelLabel.text = "Level: \(level)"
    }

    func updateLives(_ lives: Int) {
        livesLabel.text = "Lives: \(lives)"
    }
}
