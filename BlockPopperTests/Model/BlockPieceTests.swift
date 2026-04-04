import XCTest
@testable import BlockPopper

final class BlockPieceTests: XCTestCase {

    // MARK: - All 9 piece types exist

    func testAllNinePieceTypesExist() {
        XCTAssertEqual(PieceType.allCases.count, 9)
    }

    // MARK: - Cell counts: 1, 2, 2, 3, 4, 5, 4, 4, 4

    func testCellCount_dot() {
        XCTAssertEqual(BlockPiece.make(.dot).cellCount, 1)
    }

    func testCellCount_dominoH() {
        XCTAssertEqual(BlockPiece.make(.dominoH).cellCount, 2)
    }

    func testCellCount_dominoV() {
        XCTAssertEqual(BlockPiece.make(.dominoV).cellCount, 2)
    }

    func testCellCount_triominoH() {
        XCTAssertEqual(BlockPiece.make(.triominoH).cellCount, 3)
    }

    func testCellCount_tetrominoH() {
        XCTAssertEqual(BlockPiece.make(.tetrominoH).cellCount, 4)
    }

    func testCellCount_pentominoH() {
        XCTAssertEqual(BlockPiece.make(.pentominoH).cellCount, 5)
    }

    func testCellCount_square2x2() {
        XCTAssertEqual(BlockPiece.make(.square2x2).cellCount, 4)
    }

    func testCellCount_lShape() {
        XCTAssertEqual(BlockPiece.make(.lShape).cellCount, 4)
    }

    func testCellCount_pyramid() {
        XCTAssertEqual(BlockPiece.make(.pyramid).cellCount, 4)
    }

    func testCellCounts_allMatch_expectedSequence() {
        let expected: [PieceType: Int] = [
            .dot: 1,
            .dominoH: 2,
            .dominoV: 2,
            .triominoH: 3,
            .tetrominoH: 4,
            .pentominoH: 5,
            .square2x2: 4,
            .lShape: 4,
            .pyramid: 4
        ]
        for (type, count) in expected {
            XCTAssertEqual(BlockPiece.make(type).cellCount, count,
                           "\(type) should have \(count) cells")
        }
    }

    // MARK: - Correct offsets per piece

    func testOffsets_dot() {
        let piece = BlockPiece.make(.dot)
        XCTAssertEqual(piece.offsets.count, 1)
        XCTAssertEqual(piece.offsets[0].row, 0)
        XCTAssertEqual(piece.offsets[0].col, 0)
    }

    func testOffsets_dominoH() {
        let piece = BlockPiece.make(.dominoH)
        let rowCols = sorted(piece)
        XCTAssertEqual(rowCols, ["0,0", "0,1"])
    }

    func testOffsets_dominoV() {
        let piece = BlockPiece.make(.dominoV)
        let rowCols = sorted(piece)
        XCTAssertEqual(rowCols, ["0,0", "1,0"])
    }

    func testOffsets_triominoH() {
        let piece = BlockPiece.make(.triominoH)
        let rowCols = sorted(piece)
        XCTAssertEqual(rowCols, ["0,0", "0,1", "0,2"])
    }

    func testOffsets_tetrominoH() {
        let piece = BlockPiece.make(.tetrominoH)
        let rowCols = sorted(piece)
        XCTAssertEqual(rowCols, ["0,0", "0,1", "0,2", "0,3"])
    }

    func testOffsets_pentominoH() {
        let piece = BlockPiece.make(.pentominoH)
        let rowCols = sorted(piece)
        XCTAssertEqual(rowCols, ["0,0", "0,1", "0,2", "0,3", "0,4"])
    }

    func testOffsets_square2x2() {
        let piece = BlockPiece.make(.square2x2)
        let rowCols = sorted(piece)
        XCTAssertEqual(rowCols, ["0,0", "0,1", "1,0", "1,1"])
    }

    func testOffsets_lShape() {
        // X .
        // X .
        // X X
        let piece = BlockPiece.make(.lShape)
        let rowCols = sorted(piece)
        XCTAssertEqual(rowCols, ["0,0", "1,0", "2,0", "2,1"])
    }

    func testOffsets_pyramid() {
        // . X .
        // X X X
        let piece = BlockPiece.make(.pyramid)
        let rowCols = sorted(piece)
        XCTAssertEqual(rowCols, ["0,1", "1,0", "1,1", "1,2"])
    }

    // MARK: - Bounding box dimensions

    func testBoundingBox_dot() {
        let p = BlockPiece.make(.dot)
        XCTAssertEqual(p.boundingRows, 1)
        XCTAssertEqual(p.boundingCols, 1)
    }

    func testBoundingBox_dominoH() {
        let p = BlockPiece.make(.dominoH)
        XCTAssertEqual(p.boundingRows, 1)
        XCTAssertEqual(p.boundingCols, 2)
    }

    func testBoundingBox_dominoV() {
        let p = BlockPiece.make(.dominoV)
        XCTAssertEqual(p.boundingRows, 2)
        XCTAssertEqual(p.boundingCols, 1)
    }

    func testBoundingBox_triominoH() {
        let p = BlockPiece.make(.triominoH)
        XCTAssertEqual(p.boundingRows, 1)
        XCTAssertEqual(p.boundingCols, 3)
    }

    func testBoundingBox_tetrominoH() {
        let p = BlockPiece.make(.tetrominoH)
        XCTAssertEqual(p.boundingRows, 1)
        XCTAssertEqual(p.boundingCols, 4)
    }

    func testBoundingBox_pentominoH() {
        let p = BlockPiece.make(.pentominoH)
        XCTAssertEqual(p.boundingRows, 1)
        XCTAssertEqual(p.boundingCols, 5)
    }

    func testBoundingBox_square2x2() {
        let p = BlockPiece.make(.square2x2)
        XCTAssertEqual(p.boundingRows, 2)
        XCTAssertEqual(p.boundingCols, 2)
    }

    func testBoundingBox_lShape() {
        let p = BlockPiece.make(.lShape)
        XCTAssertEqual(p.boundingRows, 3)
        XCTAssertEqual(p.boundingCols, 2)
    }

    func testBoundingBox_pyramid() {
        let p = BlockPiece.make(.pyramid)
        XCTAssertEqual(p.boundingRows, 2)
        XCTAssertEqual(p.boundingCols, 3)
    }

    // MARK: - allPieces factory

    func testAllPiecesArrayContainsAllTypes() {
        let allPieces = BlockPiece.allPieces
        XCTAssertEqual(allPieces.count, 9)
        let types = Set(allPieces.map(\.type))
        XCTAssertEqual(types.count, 9)
    }

    // MARK: - Structural invariants

    func testAllOffsetsAreNonNegative() {
        for type in PieceType.allCases {
            let piece = BlockPiece.make(type)
            for offset in piece.offsets {
                XCTAssertGreaterThanOrEqual(offset.row, 0, "Piece \(type) has negative row offset")
                XCTAssertGreaterThanOrEqual(offset.col, 0, "Piece \(type) has negative col offset")
            }
        }
    }

    func testOffsets_noDuplicates_forAllPieces() {
        for piece in BlockPiece.allPieces {
            let keys = piece.offsets.map { "\($0.row),\($0.col)" }
            XCTAssertEqual(keys.count, Set(keys).count,
                           "\(piece.type) has duplicate offsets")
        }
    }

    func testOffsets_minimumRowIsZero_forAllPieces() {
        for piece in BlockPiece.allPieces {
            let minRow = piece.offsets.map(\.row).min() ?? -1
            XCTAssertEqual(minRow, 0, "\(piece.type) minimum row offset should be 0")
        }
    }

    func testOffsets_minimumColIsZero_forAllPieces() {
        for piece in BlockPiece.allPieces {
            let minCol = piece.offsets.map(\.col).min() ?? -1
            XCTAssertEqual(minCol, 0, "\(piece.type) minimum col offset should be 0")
        }
    }

    func testAllPiecesFitOnGrid() {
        for type in PieceType.allCases {
            let piece = BlockPiece.make(type)
            XCTAssertLessThanOrEqual(piece.boundingRows, Constants.gridSize,
                                     "Piece \(type) too tall for grid")
            XCTAssertLessThanOrEqual(piece.boundingCols, Constants.gridSize,
                                     "Piece \(type) too wide for grid")
        }
    }

    func testType_isSetCorrectly_forAllPieces() {
        for type in PieceType.allCases {
            XCTAssertEqual(BlockPiece.make(type).type, type,
                           "BlockPiece.make(\(type)).type should equal \(type)")
        }
    }

    // MARK: - Helper

    private func sorted(_ piece: BlockPiece) -> [String] {
        piece.offsets.map { "\($0.row),\($0.col)" }.sorted()
    }
}
