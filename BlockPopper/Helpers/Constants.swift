import Foundation
import CoreGraphics

struct Constants {
    // Grid
    static let gridSize = 8

    // Layout proportions
    static let gridScreenRatio: CGFloat = 0.78
    static let trayScreenRatio: CGFloat = 0.18
    static let hudHeight: CGFloat = 44

    // Tray
    static let traySlotCount = 3

    // Lives
    static let maxLives = 3

    // Animation timing (seconds)
    static let clearFlashDuration: TimeInterval = 0.05
    static let clearParticleDuration: TimeInterval = 0.3
    static let clearCellFadeDuration: TimeInterval = 0.2
    static let clearTotalDuration: TimeInterval = 0.4
    static let clearCascadeStagger: TimeInterval = 0.1
    static let dropSquashDuration: TimeInterval = 0.1
    static let invalidShakeDuration: TimeInterval = 0.15
    static let rescueSweepDuration: TimeInterval = 0.5
    static let rescueCellFadeDuration: TimeInterval = 0.2
    static let rescuePulseDuration: TimeInterval = 0.2
    static let styleWaveDuration: TimeInterval = 0.6
    static let styleColumnCrossfade: TimeInterval = 0.1
    static let styleCelebrationDuration: TimeInterval = 0.3
    static let levelBannerHoldDuration: TimeInterval = 1.5
    static let gameOverFadeDuration: TimeInterval = 0.5

    // Drag
    static let dragScaleFactor: CGFloat = 1.15
    static let dragVerticalOffset: CGFloat = 50
    static let dropSquashScaleX: CGFloat = 1.1
    static let dropSquashScaleY: CGFloat = 0.9

    // Particles
    static let clearParticleCount = 7 // 6-8 per cell

    // Ad timeout
    static let adTimeoutSeconds: TimeInterval = 3.0
}
