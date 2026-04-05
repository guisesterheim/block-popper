import SpriteKit

// MARK: - Grid Setup & Cell Rendering

extension GridNode {

    func setupGrid(in frame: CGRect) {
        let cols = GameGrid.columns
        let rows = GameGrid.rows
        self.cellSize = min(frame.width / CGFloat(cols), frame.height / CGFloat(rows))

        buildGradientBacking(frame: frame)
        calculateGridOrigin(frame: frame, cols: cols, rows: rows)
        buildCellNodes(cols: cols, rows: rows)
    }

    private func buildGradientBacking(frame: CGRect) {
        let padding: CGFloat = 2
        let backingRect = CGRect(x: frame.minX - padding, y: frame.minY - padding,
                                 width: frame.width + padding * 2,
                                 height: frame.height + padding * 2)
        let gradientSteps = 12
        let stepHeight = backingRect.height / CGFloat(gradientSteps)
        let topColor = ColorPalette.gridCellBorder
        let bottomColor = UIColor(hex: 0x2E4A28)

        for step in 0..<gradientSteps {
            let progress = CGFloat(step) / CGFloat(gradientSteps - 1)
            let color = blendColors(from: topColor, to: bottomColor, progress: progress)
            let stripY = backingRect.maxY - stepHeight * CGFloat(step + 1)
            let stripRect = CGRect(x: backingRect.minX, y: stripY,
                                   width: backingRect.width, height: stepHeight + 1)
            let strip = SKShapeNode(path: CGPath(rect: stripRect, transform: nil))
            strip.fillColor = color
            strip.strokeColor = .clear
            strip.zPosition = -0.5
            addChild(strip)
        }

        let borderPath = CGPath(roundedRect: backingRect,
                                cornerWidth: 4, cornerHeight: 4, transform: nil)
        let border = SKShapeNode(path: borderPath)
        border.fillColor = .clear
        border.strokeColor = UIColor(hex: 0x2A1E12)
        border.lineWidth = 2
        border.zPosition = -0.4
        addChild(border)
    }

    private func calculateGridOrigin(frame: CGRect, cols: Int, rows: Int) {
        let totalWidth = self.cellSize * CGFloat(cols)
        let totalHeight = self.cellSize * CGFloat(rows)
        let originX = frame.midX - totalWidth / 2
        let originY = frame.midY + totalHeight / 2
        self.gridOrigin = CGPoint(x: originX, y: originY)
    }

    private func buildCellNodes(cols: Int, rows: Int) {
        let gap: CGFloat = 1
        let innerSize = self.cellSize - gap * 2
        let cellRect = CGRect(x: -innerSize / 2, y: -innerSize / 2,
                              width: innerSize, height: innerSize)

        for row in 0..<rows {
            var rowNodes: [SKShapeNode] = []
            for col in 0..<cols {
                let cellPos = scenePosition(row: row, col: col)
                addCellShadow(at: cellPos, innerSize: innerSize)
                addCellHighlight(at: cellPos, innerSize: innerSize)

                let node = SKShapeNode(
                    path: UIBezierPath(roundedRect: cellRect, cornerRadius: 2).cgPath)
                node.fillColor = ColorPalette.gridCellEmpty
                node.strokeColor = ColorPalette.gridCellBorder
                node.lineWidth = 1.5
                node.position = cellPos
                node.zPosition = 0.5
                addChild(node)
                rowNodes.append(node)
            }
            self.cellNodes.append(rowNodes)
        }
    }

    private func addCellShadow(at position: CGPoint, innerSize: CGFloat) {
        let offset: CGFloat = 1.5
        let shadowRect = CGRect(x: -innerSize / 2 + offset, y: -innerSize / 2 - offset,
                                width: innerSize, height: innerSize)
        let shadowNode = SKShapeNode(path: UIBezierPath(
            roundedRect: shadowRect, cornerRadius: 2).cgPath)
        shadowNode.fillColor = UIColor.black.withAlphaComponent(0.2)
        shadowNode.strokeColor = .clear
        shadowNode.position = position
        shadowNode.zPosition = 0
        addChild(shadowNode)
    }

    private func addCellHighlight(at position: CGPoint, innerSize: CGFloat) {
        let highlightRect = CGRect(x: -innerSize / 2 - 0.5, y: -innerSize / 2 + 0.5,
                                   width: innerSize, height: innerSize)
        let highlightNode = SKShapeNode(path: UIBezierPath(
            roundedRect: highlightRect, cornerRadius: 2).cgPath)
        highlightNode.fillColor = UIColor.white.withAlphaComponent(0.06)
        highlightNode.strokeColor = .clear
        highlightNode.position = position
        highlightNode.zPosition = 0
        addChild(highlightNode)
    }

    func blendColors(from: UIColor, to: UIColor, progress: CGFloat) -> UIColor {
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        from.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        let clamped = max(0, min(1, progress))
        return UIColor(
            red: fromR + (toR - fromR) * clamped,
            green: fromG + (toG - fromG) * clamped,
            blue: fromB + (toB - fromB) * clamped,
            alpha: fromA + (toA - fromA) * clamped
        )
    }
}
