import XCTest
@testable import BlockPopper

final class PieceGeneratorTests: XCTestCase {

    func testGeneratesPieces() {
        let generator = PieceGenerator()
        let piece = generator.nextPiece()
        XCTAssertTrue(PieceType.allCases.contains(piece.type))
    }

    func testNoThreeIdenticalInARow() {
        let generator = PieceGenerator()
        var lastTypes: [PieceType] = []

        for _ in 0..<1000 {
            let piece = generator.nextPiece()
            lastTypes.append(piece.type)

            if lastTypes.count >= 3 {
                let last3 = Array(lastTypes.suffix(3))
                let allSame = last3.allSatisfy { $0 == last3[0] }
                XCTAssertFalse(allSame,
                               "Generated 3 identical pieces in a row: \(last3[0])")
            }
        }
    }

    func testGeneratesVarietyOfPieces() {
        let generator = PieceGenerator()
        var seenTypes = Set<PieceType>()

        for _ in 0..<500 {
            let piece = generator.nextPiece()
            seenTypes.insert(piece.type)
        }

        // Over 500 pieces, we should see most of the 9 types
        XCTAssertGreaterThanOrEqual(seenTypes.count, 7,
                                     "Expected at least 7 of 9 piece types in 500 generations, got \(seenTypes.count)")
    }

    func testAllGeneratedPiecesAreValid() {
        let generator = PieceGenerator()

        for _ in 0..<200 {
            let piece = generator.nextPiece()
            XCTAssertGreaterThan(piece.cellCount, 0)
            XCTAssertLessThanOrEqual(piece.boundingRows, Constants.gridSize)
            XCTAssertLessThanOrEqual(piece.boundingCols, Constants.gridSize)
        }
    }
}
