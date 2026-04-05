import SpriteKit

// MARK: - Line Clear Animation

extension GameScene {

    func playClearAnimation(result: ClearResult) {
        SoundManager.shared.playLineClear()

        var lineIndex = 0
        var totalAnimationDuration: TimeInterval = 0

        for row in result.clearedRows {
            let delay = AnimationFactory.cascadeDelay(forLineIndex: lineIndex)
            animateClearedRow(row, afterDelay: delay)
            totalAnimationDuration = delay + Constants.clearTotalDuration + sweepDuration
            lineIndex += 1
        }

        for col in result.clearedCols {
            let delay = AnimationFactory.cascadeDelay(forLineIndex: lineIndex)
            animateClearedCol(col, afterDelay: delay)
            totalAnimationDuration = delay + Constants.clearTotalDuration + sweepDuration
            lineIndex += 1
        }

        let completionDelay = totalAnimationDuration + 0.05
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: completionDelay),
            SKAction.run { [weak self] in
                guard let self else { return }
                let wasFullClear = self.gameState.onClearAnimationComplete()
                self.updateDisplay()
                self.checkPhaseAfterPlacement()
            }
        ]))
    }

    // MARK: - Sweep timing

    private var sweepDuration: TimeInterval { 0.25 }
    private var sweepCellStagger: TimeInterval { sweepDuration / TimeInterval(Constants.gridColumns) }

    // MARK: - Row Animation (sweep left → right, then fireworks)

    private func animateClearedRow(_ row: Int, afterDelay delay: TimeInterval) {
        let cellCount = Constants.gridColumns
        let stagger = sweepDuration / TimeInterval(cellCount)

        for col in 0..<cellCount {
            let cellPosition = self.gridNode.scenePosition(row: row, col: col)
            let sweepDelay = delay + stagger * TimeInterval(col)

            // White sweep glow passes through each cell
            spawnSweepGlow(at: cellPosition, afterDelay: sweepDelay)

            // Fireworks + cell disappear after sweep passes
            let fireworkDelay = delay + sweepDuration + stagger * TimeInterval(col)
            spawnClearEffect(at: cellPosition, afterDelay: fireworkDelay)
        }
    }

    // MARK: - Column Animation (sweep bottom → top)

    private func animateClearedCol(_ col: Int, afterDelay delay: TimeInterval) {
        let cellCount = Constants.gridRows
        let stagger = sweepDuration / TimeInterval(cellCount)

        for row in 0..<cellCount {
            let cellPosition = self.gridNode.scenePosition(row: row, col: col)
            // Bottom to top: row 7 (bottom) first → row 0 (top) last
            let reversedRow = cellCount - 1 - row
            let sweepDelay = delay + stagger * TimeInterval(reversedRow)

            spawnSweepGlow(at: cellPosition, afterDelay: sweepDelay)

            let fireworkDelay = delay + sweepDuration + stagger * TimeInterval(reversedRow)
            spawnClearEffect(at: cellPosition, afterDelay: fireworkDelay)
        }
    }

    // MARK: - White Sweep Glow

    private func spawnSweepGlow(at position: CGPoint, afterDelay delay: TimeInterval) {
        let cs = self.gridNode.cellSize
        let glowNode = SKShapeNode(rectOf: CGSize(width: cs + 4, height: cs + 4))
        glowNode.fillColor = UIColor.white.withAlphaComponent(0.5)
        glowNode.strokeColor = UIColor.white.withAlphaComponent(0.3)
        glowNode.lineWidth = 1
        glowNode.position = position
        glowNode.zPosition = 7
        glowNode.alpha = 0
        glowNode.setScale(0.8)
        addChild(glowNode)

        let glowDuration: TimeInterval = 0.15
        glowNode.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.group([
                SKAction.fadeAlpha(to: 0.7, duration: glowDuration * 0.3),
                SKAction.scale(to: 1.1, duration: glowDuration * 0.3)
            ]),
            SKAction.group([
                SKAction.fadeOut(withDuration: glowDuration * 0.7),
                SKAction.scale(to: 1.3, duration: glowDuration * 0.7)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Per-Cell Clear Effect (fireworks + disappear)

    private func spawnClearEffect(at position: CGPoint, afterDelay delay: TimeInterval) {
        let particles = createParticles(at: position)
        animateParticles(particles, afterDelay: delay)
    }

    private func createParticles(at position: CGPoint) -> [SKShapeNode] {
        var particles: [SKShapeNode] = []
        let fireworkParticleCount = 14

        let sparkColors: [UIColor] = [
            self.gameState.currentStyle.fillColor,
            ColorPalette.hudText,
            UIColor.orange,
            UIColor.yellow.withAlphaComponent(0.8)
        ]

        for i in 0..<fireworkParticleCount {
            let size = CGFloat.random(in: 2...6)
            let particle = SKShapeNode(rectOf: CGSize(width: size, height: size))
            let colorIndex = i % sparkColors.count
            particle.fillColor = sparkColors[colorIndex]
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 6
            particle.alpha = 0
            addChild(particle)
            particles.append(particle)
        }

        return particles
    }

    private func animateParticles(_ particles: [SKShapeNode], afterDelay delay: TimeInterval) {
        for (index, particle) in particles.enumerated() {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 25...65)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let particleDuration = Constants.clearParticleDuration + Double.random(in: 0...0.15)
            let startDelay = delay + Constants.clearFlashDuration + Double(index) * 0.01

            particle.run(SKAction.sequence([
                SKAction.wait(forDuration: startDelay),
                SKAction.fadeIn(withDuration: 0),
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: particleDuration),
                    SKAction.fadeOut(withDuration: particleDuration),
                    SKAction.scale(to: 0.1, duration: particleDuration),
                    SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: particleDuration)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
}
