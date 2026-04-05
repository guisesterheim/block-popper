import SpriteKit

// MARK: - Flush & Erase Animations

extension GameScene {

    // MARK: - Flush Animation (pieces fly out, then new pieces fade in)

    func playFlushAnimation(completion: @escaping () -> Void) {
        var animationNodes: [SKNode] = []

        for i in 0..<Constants.traySlotCount {
            guard let pieceNode = self.trayNode.pieceNode(at: i),
                  !pieceNode.isHidden else { continue }

            // Create a snapshot of the piece for animation
            let snapshot = pieceNode.copy() as! BlockPieceNode
            snapshot.position = pieceNode.convert(.zero, to: self)
            snapshot.zPosition = 15
            addChild(snapshot)
            animationNodes.append(snapshot)

            pieceNode.isHidden = true

            // Fly out with spin
            let angle = CGFloat.random(in: -0.5...0.5)
            let flyOut = SKAction.group([
                SKAction.moveBy(x: CGFloat.random(in: -80...80),
                                y: -200, duration: 0.35),
                SKAction.rotate(byAngle: angle * .pi, duration: 0.35),
                SKAction.fadeOut(withDuration: 0.35),
                SKAction.scale(to: 0.3, duration: 0.35)
            ])
            flyOut.timingMode = .easeIn
            snapshot.run(flyOut)
        }

        self.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.run {
                animationNodes.forEach { $0.removeFromParent() }
                completion()
            }
        ]))
    }

    func playFlushInAnimation() {
        for i in 0..<Constants.traySlotCount {
            guard let pieceNode = self.trayNode.pieceNode(at: i),
                  !pieceNode.isHidden else { continue }

            let originalScale = pieceNode.xScale
            pieceNode.setScale(0)
            pieceNode.alpha = 0

            let delay = TimeInterval(i) * 0.08
            pieceNode.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: originalScale, duration: 0.25),
                    SKAction.fadeIn(withDuration: 0.25)
                ])
            ]))
        }
    }

    // MARK: - Erase Cell Animation

    func playEraseCellAnimation(at position: CGPoint) {
        let cellSz = self.gridNode.cellSize - 2

        // Flash the cell
        let flashNode = SKShapeNode(rectOf: CGSize(width: cellSz, height: cellSz))
        flashNode.fillColor = UIColor.red.withAlphaComponent(0.6)
        flashNode.strokeColor = .clear
        flashNode.position = position
        flashNode.zPosition = 8
        addChild(flashNode)

        // Particle burst (smaller than line clear)
        let particleCount = 8
        var particles: [SKShapeNode] = []
        let sparkColors: [UIColor] = [
            UIColor.red.withAlphaComponent(0.8),
            UIColor.orange,
            ColorPalette.hudText
        ]

        for i in 0..<particleCount {
            let size = CGFloat.random(in: 2...5)
            let particle = SKShapeNode(rectOf: CGSize(width: size, height: size))
            particle.fillColor = sparkColors[i % sparkColors.count]
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 9
            particle.alpha = 0
            addChild(particle)
            particles.append(particle)
        }

        // Flash animation
        flashNode.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 0.05),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 1.3, duration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))

        // Particles
        for (index, particle) in particles.enumerated() {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 15...40)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let dur = 0.25 + Double.random(in: 0...0.1)
            let startDelay = 0.03 + Double(index) * 0.01

            particle.run(SKAction.sequence([
                SKAction.wait(forDuration: startDelay),
                SKAction.fadeIn(withDuration: 0),
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: dur),
                    SKAction.fadeOut(withDuration: dur),
                    SKAction.scale(to: 0.1, duration: dur)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
}
