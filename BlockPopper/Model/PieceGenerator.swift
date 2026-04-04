import Foundation

class PieceGenerator {
    private var recentPieces: [PieceType] = []
    private let maxRecentDuplicates = 2

    func nextPiece() -> BlockPiece {
        var type: PieceType

        repeat {
            type = PieceType.allCases.randomElement()!
        } while recentPieces.suffix(maxRecentDuplicates).allSatisfy({ $0 == type })
            && recentPieces.count >= maxRecentDuplicates

        recentPieces.append(type)
        if recentPieces.count > 10 {
            recentPieces.removeFirst()
        }

        return BlockPiece.make(type)
    }
}
