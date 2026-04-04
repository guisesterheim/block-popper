import SpriteKit

/// Central factory for all SKAction animation sequences.
struct AnimationFactory {

    // MARK: - Line Clear (Particle Burst + Flash)

    static func lineClearAction(for cellNode: SKShapeNode, blockColor: UIColor) -> SKAction {
        let flash = SKAction.sequence([
            SKAction.colorize(with: ColorPalette.clearFlash, colorBlendFactor: 1.0,
                              duration: Constants.clearFlashDuration),
            SKAction.colorize(with: blockColor, colorBlendFactor: 1.0,
                              duration: Constants.clearFlashDuration)
        ])
        let shrinkAndFade = SKAction.group([
            SKAction.scale(to: 0, duration: Constants.clearCellFadeDuration),
            SKAction.fadeOut(withDuration: Constants.clearCellFadeDuration)
        ])
        return SKAction.sequence([flash, shrinkAndFade])
    }

    static func cascadeDelay(forLineIndex lineIndex: Int) -> TimeInterval {
        TimeInterval(lineIndex) * Constants.clearCascadeStagger
    }

    // MARK: - Drop Placement

    static func validDropAction() -> SKAction {
        let squash = SKAction.scaleX(to: Constants.dropSquashScaleX,
                                      y: Constants.dropSquashScaleY,
                                      duration: Constants.dropSquashDuration / 2)
        let restore = SKAction.scale(to: 1.0, duration: Constants.dropSquashDuration / 2)
        return SKAction.sequence([squash, restore])
    }

    static func invalidDropShakeAction() -> SKAction {
        let shakeDistance: CGFloat = 5
        let shakeDuration = Constants.invalidShakeDuration / 3
        return SKAction.sequence([
            SKAction.moveBy(x: shakeDistance, y: 0, duration: shakeDuration),
            SKAction.moveBy(x: -shakeDistance * 2, y: 0, duration: shakeDuration),
            SKAction.moveBy(x: shakeDistance, y: 0, duration: shakeDuration)
        ])
    }

    // MARK: - Rescue Sweep

    static func rescueSweepAction(gridWidth: CGFloat) -> SKAction {
        let moveAcross = SKAction.moveBy(x: gridWidth, y: 0, duration: Constants.rescueSweepDuration)
        moveAcross.timingMode = .easeInEaseOut
        return moveAcross
    }

    static func rescueCellFadeAction() -> SKAction {
        SKAction.group([
            SKAction.scale(to: 0, duration: Constants.rescueCellFadeDuration),
            SKAction.fadeOut(withDuration: Constants.rescueCellFadeDuration)
        ])
    }

    static func rescuePulseAction() -> SKAction {
        SKAction.sequence([
            SKAction.scale(to: 1.1, duration: Constants.rescuePulseDuration / 2),
            SKAction.scale(to: 1.0, duration: Constants.rescuePulseDuration / 2)
        ])
    }

    // MARK: - Style Transition Wave

    static func styleWaveDelay(forColumn column: Int) -> TimeInterval {
        let columnStagger = Constants.styleWaveDuration / TimeInterval(Constants.gridSize)
        return TimeInterval(column) * columnStagger
    }

    static func styleColumnCrossfadeAction(to newStyle: BlockStyle) -> SKAction {
        SKAction.colorize(with: newStyle.fillColor, colorBlendFactor: 1.0,
                          duration: Constants.styleColumnCrossfade)
    }

    static func styleCelebrationAction() -> SKAction {
        SKAction.sequence([
            SKAction.scale(to: 1.15, duration: Constants.styleCelebrationDuration / 2),
            SKAction.scale(to: 1.0, duration: Constants.styleCelebrationDuration / 2)
        ])
    }

    // MARK: - Level Up Banner

    static func levelBannerAction(sceneHeight: CGFloat) -> SKAction {
        let slideIn = SKAction.moveTo(y: sceneHeight * 0.6, duration: 0.3)
        slideIn.timingMode = .easeOut
        let hold = SKAction.wait(forDuration: Constants.levelBannerHoldDuration)
        let slideOut = SKAction.moveTo(y: sceneHeight + 50, duration: 0.3)
        slideOut.timingMode = .easeIn
        return SKAction.sequence([slideIn, hold, slideOut, SKAction.removeFromParent()])
    }

    // MARK: - Game Over & Score

    static func gameOverFadeInAction() -> SKAction {
        SKAction.fadeIn(withDuration: Constants.gameOverFadeDuration)
    }

    static func scorePulseAction() -> SKAction {
        SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
    }

    // MARK: - Life & Drag

    static func lifeUsedPulseAction() -> SKAction {
        SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.15),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.15)
        ])
    }

    static func dragPickupAction() -> SKAction {
        SKAction.scale(to: Constants.dragScaleFactor, duration: 0.08)
    }

    static func dragDropRestoreAction() -> SKAction {
        SKAction.scale(to: 1.0, duration: 0.08)
    }
}
