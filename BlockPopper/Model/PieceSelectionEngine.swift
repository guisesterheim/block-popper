import Foundation

/// Intelligent piece selection engine that analyzes the board state
/// and picks pieces based on difficulty, variety, and fairness rules.
class PieceSelectionEngine {

    // MARK: - Scoring

    struct ScoredPiece {
        let type: PieceType
        let validPositions: Int
        let normalizedScore: Double  // validPositions / cellCount
        let cellCount: Int
    }

    // MARK: - Small Pieces (excluded when board is >50% free)

    private static let smallPieceTypes: Set<PieceType> = [
        .dot, .dominoH, .dominoV,
        .zRight, .zLeft, .zUp, .zDown
    ]

    // MARK: - Configuration

    /// Helpfulness from 0.0 (no help) to 1.0 (maximum help).
    /// Controls how much the engine favors easy-to-place pieces.
    static func helpfulness(forPhase phase: Int) -> Double {
        if isHardPhase(phase) {
            // Hard phases: less helpful
            return 0.35
        }
        // Normal phases: helpful, very slightly decreasing over time
        return max(0.6, 0.85 - Double(phase) * 0.005)
    }

    static func isHardPhase(_ phase: Int) -> Bool {
        phase > 1 && phase % 10 == 0
    }

    // MARK: - Piece Selection

    /// Select 3 pieces for the tray based on current board state and phase.
    static func selectPieces(for grid: GameGrid, phase: Int, isFlush: Bool = false) -> [BlockPiece] {
        var helpLevel = helpfulness(forPhase: phase)

        // Flush bonus: more generous since user spent a hack
        if isFlush {
            helpLevel = min(1.0, helpLevel + 0.2)
        }

        var scored = scoreAllPieces(on: grid)

        // When board has plenty of space (>50% free), exclude small pieces
        let totalCells = GameGrid.rows * GameGrid.columns
        let emptyCount = totalCells - grid.occupiedCount
        let freeRatio = Double(emptyCount) / Double(totalCells)
        if freeRatio > 0.5 {
            let filtered = scored.filter { !smallPieceTypes.contains($0.type) }
            if filtered.filter({ $0.validPositions > 0 }).count >= 3 {
                scored = filtered
            }
        }

        // Tilt toward bigger pieces when board is mostly free
        if freeRatio > 0.4 {
            // Bonus scales with how empty the board is (0 at 40%, max at 100%)
            let sizeBoostFactor = (freeRatio - 0.4) / 0.6  // 0.0 to 1.0
            scored = scored.map { sp in
                // Bigger pieces (more cells) get a proportional bonus
                let sizeBonus = Double(sp.cellCount) / 9.0 * sizeBoostFactor * sp.normalizedScore * 0.5
                return ScoredPiece(
                    type: sp.type,
                    validPositions: sp.validPositions,
                    normalizedScore: sp.normalizedScore + sizeBonus,
                    cellCount: sp.cellCount
                )
            }
        }

        let nearCompleteBonus = detectNearCompleteLines(on: grid)

        // Apply near-complete line bonus as tiebreaker
        let boosted = applyLineCompletionBonus(scored: scored, bonus: nearCompleteBonus, grid: grid)

        let isHard = isHardPhase(phase) && !isFlush
        let selected = pickThreePieces(from: boosted, helpfulness: helpLevel, isHard: isHard, grid: grid)

        return selected.map { BlockPiece.make($0) }
    }

    // MARK: - Board Analysis

    /// Score every piece type by how many valid positions it has, normalized by size.
    private static func scoreAllPieces(on grid: GameGrid) -> [ScoredPiece] {
        PieceType.allCases.map { type in
            let piece = BlockPiece.make(type)
            var validCount = 0

            for row in 0..<GameGrid.rows {
                for col in 0..<GameGrid.columns {
                    if grid.canPlace(piece: piece, at: GridPosition(row: row, col: col)) {
                        validCount += 1
                    }
                }
            }

            let normalized = piece.cellCount > 0
                ? Double(validCount) / Double(piece.cellCount)
                : 0

            return ScoredPiece(
                type: type,
                validPositions: validCount,
                normalizedScore: normalized,
                cellCount: piece.cellCount
            )
        }
    }

    // MARK: - Near-Complete Line Detection

    struct LineBonus {
        var rowGaps: [Int: Int] = [:]  // row -> empty cell count (1-2 means near complete)
        var colGaps: [Int: Int] = [:]  // col -> empty cell count
    }

    private static func detectNearCompleteLines(on grid: GameGrid) -> LineBonus {
        var bonus = LineBonus()

        for row in 0..<GameGrid.rows {
            var emptyCount = 0
            for col in 0..<GameGrid.columns {
                if grid.cellAt(row: row, col: col) == .empty { emptyCount += 1 }
            }
            if emptyCount >= 1 && emptyCount <= 2 {
                bonus.rowGaps[row] = emptyCount
            }
        }

        for col in 0..<GameGrid.columns {
            var emptyCount = 0
            for row in 0..<GameGrid.rows {
                if grid.cellAt(row: row, col: col) == .empty { emptyCount += 1 }
            }
            if emptyCount >= 1 && emptyCount <= 2 {
                bonus.colGaps[col] = emptyCount
            }
        }

        return bonus
    }

    /// Boost scores for pieces that could complete near-full lines (tiebreaker only).
    private static func applyLineCompletionBonus(scored: [ScoredPiece], bonus: LineBonus, grid: GameGrid) -> [ScoredPiece] {
        guard !bonus.rowGaps.isEmpty || !bonus.colGaps.isEmpty else { return scored }

        return scored.map { sp in
            let piece = BlockPiece.make(sp.type)
            var completionBoost = 0.0

            // Check if placing this piece could fill a near-complete line
            for row in 0..<GameGrid.rows {
                for col in 0..<GameGrid.columns {
                    if grid.canPlace(piece: piece, at: GridPosition(row: row, col: col)) {
                        // Check which near-complete rows/cols this placement touches
                        for offset in piece.offsets {
                            let r = row + offset.row
                            let c = col + offset.col
                            if bonus.rowGaps[r] != nil { completionBoost += 0.5 }
                            if bonus.colGaps[c] != nil { completionBoost += 0.5 }
                        }
                    }
                }
            }

            // Small tiebreaker: cap it so it doesn't dominate the main score
            let cappedBoost = min(completionBoost * 0.01, sp.normalizedScore * 0.15)

            return ScoredPiece(
                type: sp.type,
                validPositions: sp.validPositions,
                normalizedScore: sp.normalizedScore + cappedBoost,
                cellCount: sp.cellCount
            )
        }
    }

    // MARK: - Piece Picking

    private static func pickThreePieces(from scored: [ScoredPiece], helpfulness: Double, isHard: Bool, grid: GameGrid) -> [PieceType] {
        let fittable = scored.filter { $0.validPositions > 0 }
        let unfittable = scored.filter { $0.validPositions == 0 }

        // Safety: if fewer than 1 piece fits, return whatever we can
        guard !fittable.isEmpty else {
            // Extremely rare: nothing fits at all
            let fallback = PieceType.allCases.shuffled().prefix(3)
            return Array(fallback)
        }

        var selected: [PieceType] = []

        if isHard {
            selected = pickHardTray(fittable: fittable, unfittable: unfittable, helpfulness: helpfulness, grid: grid)
        } else {
            selected = pickNormalTray(fittable: fittable, helpfulness: helpfulness)
        }

        // ABSOLUTE RULE: at least 1 piece must fit on the board
        let atLeastOneFits = selected.contains { type in
            let piece = BlockPiece.make(type)
            for row in 0..<GameGrid.rows {
                for col in 0..<GameGrid.columns {
                    if grid.canPlace(piece: piece, at: GridPosition(row: row, col: col)) {
                        return true
                    }
                }
            }
            return false
        }

        if !atLeastOneFits, let safePick = fittable.max(by: { $0.normalizedScore < $1.normalizedScore }) {
            selected[0] = safePick.type
        }

        return selected
    }

    // MARK: - Normal Tray

    private static func pickNormalTray(fittable: [ScoredPiece], helpfulness: Double) -> [PieceType] {
        var result: [PieceType] = []

        for _ in 0..<3 {
            if let pick = weightedRandomPick(from: fittable, helpfulness: helpfulness, excluding: result) {
                result.append(pick)
            }
        }

        // Enforce variety: no 3 large pieces (cellCount >= 5)
        enforceVariety(&result, fittable: fittable, helpfulness: helpfulness)

        return result
    }

    // MARK: - Hard Tray

    private static func pickHardTray(fittable: [ScoredPiece], unfittable: [ScoredPiece], helpfulness: Double, grid: GameGrid) -> [PieceType] {
        var result: [PieceType] = []

        // 1-2 harder pieces: pick from the bottom of the fittable list (fewer positions)
        let hardCount = Bool.random() ? 1 : 2
        let sortedByDifficulty = fittable.sorted { $0.normalizedScore < $1.normalizedScore }
        let hardCandidates = Array(sortedByDifficulty.prefix(max(5, sortedByDifficulty.count / 3)))

        for _ in 0..<hardCount {
            if let pick = weightedRandomPick(from: hardCandidates, helpfulness: 0.2, excluding: result) {
                result.append(pick)
            }
        }

        // Neutral piece: pick from the middle of the distribution
        let midStart = fittable.count / 4
        let midEnd = fittable.count * 3 / 4
        let sortedByScore = fittable.sorted { $0.normalizedScore < $1.normalizedScore }
        if midStart < midEnd {
            let midCandidates = Array(sortedByScore[midStart..<midEnd])
            if let pick = weightedRandomPick(from: midCandidates, helpfulness: 0.5, excluding: result) {
                result.append(pick)
            }
        }

        // Fill remaining slots if needed
        while result.count < 3 {
            if let pick = weightedRandomPick(from: fittable, helpfulness: helpfulness, excluding: result) {
                result.append(pick)
            } else {
                // Absolute fallback
                result.append(fittable.randomElement()!.type)
            }
        }

        enforceVariety(&result, fittable: fittable, helpfulness: helpfulness)
        return result
    }

    // MARK: - Weighted Random Selection

    /// Picks a piece type using weighted randomness.
    /// Higher helpfulness = stronger bias toward high-scoring (easy) pieces.
    /// Lower helpfulness = more uniform random.
    private static func weightedRandomPick(from candidates: [ScoredPiece], helpfulness: Double, excluding: [PieceType]) -> PieceType? {
        let available = candidates.filter { !excluding.contains($0.type) }
        guard !available.isEmpty else { return nil }

        let maxScore = available.map(\.normalizedScore).max() ?? 1
        guard maxScore > 0 else { return available.randomElement()?.type }

        // Weight = base + helpfulness * normalizedScore
        // At helpfulness 0: all weights equal (pure random)
        // At helpfulness 1: strongly favors high scores
        let weights = available.map { sp -> Double in
            let base = 1.0
            let scoreBonus = (sp.normalizedScore / maxScore) * helpfulness * 4.0
            return base + scoreBonus
        }

        let totalWeight = weights.reduce(0, +)
        var roll = Double.random(in: 0..<totalWeight)

        for (index, weight) in weights.enumerated() {
            roll -= weight
            if roll <= 0 {
                return available[index].type
            }
        }

        return available.last?.type
    }

    // MARK: - Variety Enforcement

    /// No duplicates, no 3 large pieces at once.
    private static func enforceVariety(_ pieces: inout [PieceType], fittable: [ScoredPiece], helpfulness: Double) {
        // Remove duplicates
        var seen = Set<PieceType>()
        for i in 0..<pieces.count {
            if seen.contains(pieces[i]) {
                if let replacement = weightedRandomPick(from: fittable, helpfulness: helpfulness, excluding: Array(seen)) {
                    pieces[i] = replacement
                }
            }
            seen.insert(pieces[i])
        }

        // No 3 large pieces (cellCount >= 5)
        let largePieceIndices = pieces.enumerated().compactMap { (i, type) -> Int? in
            BlockPiece.make(type).cellCount >= 5 ? i : nil
        }
        if largePieceIndices.count >= 3 {
            // Replace the last large piece with a smaller one
            let smallCandidates = fittable.filter { $0.cellCount < 5 }
            if let replacement = weightedRandomPick(from: smallCandidates, helpfulness: helpfulness, excluding: pieces) {
                pieces[largePieceIndices.last!] = replacement
            }
        }
    }
}
