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
            totalAnimationDuration = delay + Constants.clearTotalDuration
            lineIndex += 1
        }

        for col in result.clearedCols {
            let delay = AnimationFactory.cascadeDelay(forLineIndex: lineIndex)
            animateClearedCol(col, afterDelay: delay)
            totalAnimationDuration = delay + Constants.clearTotalDuration
            lineIndex += 1
        }

        let completionDelay = totalAnimationDuration + 0.05
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: completionDelay),
            SKAction.run { [weak self] in
                guard let self else { return }
                _ = self.gameState.onClearAnimationComplete()
                self.updateDisplay()
                self.checkPhaseAfterPlacement()
            }
        ]))
    }

    // MARK: - Row & Column Animation

    private func animateClearedRow(_ row: Int, afterDelay delay: TimeInterval) {
        for col in 0..<Constants.gridSize {
            let cellPosition = self.gridNode.scenePosition(row: row, col: col)
            spawnClearEffect(at: cellPosition, afterDelay: delay)
        }
    }

    private func animateClearedCol(_ col: Int, afterDelay delay: TimeInterval) {
        for row in 0..<Constants.gridSize {
            let cellPosition = self.gridNode.scenePosition(row: row, col: col)
            spawnClearEffect(at: cellPosition, afterDelay: delay)
        }
    }

    // MARK: - Per-Cell Clear Effect

    private func spawnClearEffect(at position: CGPoint, afterDelay delay: TimeInterval) {
        let flashNode = SKShapeNode(rectOf: CGSize(
            width: self.gridNode.cellSize - 2,
            height: self.gridNode.cellSize - 2
        ))
        flashNode.fillColor = ColorPalette.clearFlash
        flashNode.strokeColor = .clear
        flashNode.position = position
        flashNode.zPosition = 5
        flashNode.alpha = 0
        addChild(flashNode)

        let particles = createParticles(at: position)

        flashNode.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.fadeIn(withDuration: 0),
            SKAction.fadeAlpha(to: 0.9, duration: Constants.clearFlashDuration),
            SKAction.fadeOut(withDuration: Constants.clearFlashDuration),
            SKAction.removeFromParent()
        ]))

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
