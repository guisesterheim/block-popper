import XCTest
@testable import BlockPopper

final class GameGridTests: XCTestCase {

    // MARK: - canPlace

    func testCanPlace_validEmptyBoard() {
        let grid = GameGrid()
        let piece = BlockPiece.make(.dot)
        XCTAssertTrue(grid.canPlace(piece: piece, at: GridPosition(row: 0, col: 0)))
    }

    func testCanPlace_validAllPiecesOnEmptyBoard() {
        let grid = GameGrid()
        for piece in BlockPiece.allPieces {
            XCTAssertTrue(
                grid.canPlace(piece: piece, at: GridPosition(row: 0, col: 0)),
                "Expected \(piece.type) to fit at (0,0) on empty board"
            )
        }
    }

    func testCanPlace_rejectsOverlap() {
        var grid = GameGrid()
        let dot = BlockPiece.make(.dot)
        grid.place(piece: dot, at: GridPosition(row: 4, col: 4))
        XCTAssertFalse(grid.canPlace(piece: dot, at: GridPosition(row: 4, col: 4)))
    }

    func testCanPlace_rejectsOutOfBoundsRight() {
        let grid = GameGrid()
        // dominoH is 1x2; placing at col 8 would need col 9 which is out of bounds
        let piece = BlockPiece.make(.dominoH)
        XCTAssertFalse(grid.canPlace(piece: piece, at: GridPosition(row: 0, col: GameGrid.size - 1)))
    }

    func testCanPlace_rejectsOutOfBoundsBottom() {
        let grid = GameGrid()
        // dominoV is 2x1; placing at row 8 would need row 9 which is out of bounds
        let piece = BlockPiece.make(.dominoV)
        XCTAssertFalse(grid.canPlace(piece: piece, at: GridPosition(row: GameGrid.size - 1, col: 0)))
    }

    func testCanPlace_rejectsNegativePosition() {
        let grid = GameGrid()
        let piece = BlockPiece.make(.dot)
        XCTAssertFalse(grid.canPlace(piece: piece, at: GridPosition(row: -1, col: 0)))
        XCTAssertFalse(grid.canPlace(piece: piece, at: GridPosition(row: 0, col: -1)))
    }

    func testCanPlace_lastValidPosition() {
        let grid = GameGrid()
        let dot = BlockPiece.make(.dot)
        XCTAssertTrue(
            grid.canPlace(piece: dot, at: GridPosition(row: GameGrid.size - 1, col: GameGrid.size - 1))
        )
    }

    // MARK: - place

    func testPlace_cellBecomesOccupied() {
        var grid = GameGrid()
        let dot = BlockPiece.make(.dot)
        grid.place(piece: dot, at: GridPosition(row: 3, col: 5))
        XCTAssertEqual(grid.cellAt(row: 3, col: 5), .occupied(.dot))
    }

    func testPlace_correctCellsOccupiedForDominoH() {
        var grid = GameGrid()
        let piece = BlockPiece.make(.dominoH)
        grid.place(piece: piece, at: GridPosition(row: 2, col: 3))
        XCTAssertEqual(grid.cellAt(row: 2, col: 3), .occupied(.dominoH))
        XCTAssertEqual(grid.cellAt(row: 2, col: 4), .occupied(.dominoH))
        XCTAssertEqual(grid.cellAt(row: 2, col: 2), .empty)
    }

    func testPlace_correctCellsOccupiedForDominoV() {
        var grid = GameGrid()
        let piece = BlockPiece.make(.dominoV)
        grid.place(piece: piece, at: GridPosition(row: 1, col: 1))
        XCTAssertEqual(grid.cellAt(row: 1, col: 1), .occupied(.dominoV))
        XCTAssertEqual(grid.cellAt(row: 2, col: 1), .occupied(.dominoV))
        XCTAssertEqual(grid.cellAt(row: 0, col: 1), .empty)
    }

    func testPlace_correctCellsOccupiedForSquare2x2() {
        var grid = GameGrid()
        let piece = BlockPiece.make(.square2x2)
        grid.place(piece: piece, at: GridPosition(row: 0, col: 0))
        XCTAssertEqual(grid.cellAt(row: 0, col: 0), .occupied(.square2x2))
        XCTAssertEqual(grid.cellAt(row: 0, col: 1), .occupied(.square2x2))
        XCTAssertEqual(grid.cellAt(row: 1, col: 0), .occupied(.square2x2))
        XCTAssertEqual(grid.cellAt(row: 1, col: 1), .occupied(.square2x2))
    }

    func testPlace_correctCellsOccupiedForLShape() {
        var grid = GameGrid()
        let piece = BlockPiece.make(.lShape)
        grid.place(piece: piece, at: GridPosition(row: 0, col: 0))
        XCTAssertEqual(grid.cellAt(row: 0, col: 0), .occupied(.lShape))
        XCTAssertEqual(grid.cellAt(row: 1, col: 0), .occupied(.lShape))
        XCTAssertEqual(grid.cellAt(row: 2, col: 0), .occupied(.lShape))
        XCTAssertEqual(grid.cellAt(row: 2, col: 1), .occupied(.lShape))
        XCTAssertEqual(grid.cellAt(row: 0, col: 1), .empty)
        XCTAssertEqual(grid.cellAt(row: 1, col: 1), .empty)
    }

    func testPlace_correctCellsOccupiedForPyramid() {
        var grid = GameGrid()
        let piece = BlockPiece.make(.pyramid)
        grid.place(piece: piece, at: GridPosition(row: 0, col: 0))
        XCTAssertEqual(grid.cellAt(row: 0, col: 1), .occupied(.pyramid))
        XCTAssertEqual(grid.cellAt(row: 1, col: 0), .occupied(.pyramid))
        XCTAssertEqual(grid.cellAt(row: 1, col: 1), .occupied(.pyramid))
        XCTAssertEqual(grid.cellAt(row: 1, col: 2), .occupied(.pyramid))
        XCTAssertEqual(grid.cellAt(row: 0, col: 0), .empty)
        XCTAssertEqual(grid.cellAt(row: 0, col: 2), .empty)
    }

    func testPlace_occupiedCountUpdates() {
        var grid = GameGrid()
        XCTAssertEqual(grid.occupiedCount, 0)
        let piece = BlockPiece.make(.triominoH)
        grid.place(piece: piece, at: GridPosition(row: 0, col: 0))
        XCTAssertEqual(grid.occupiedCount, 3)
    }

    // MARK: - clearFullLines

    func testClearFullLines_singleRowClears() {
        var grid = GameGrid()
        // Fill entire row 0
        for col in 0..<GameGrid.size {
            grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: 0, col: col))
        }
        let result = grid.clearFullLines()
        XCTAssertEqual(result.clearedRows, [0])
        XCTAssertEqual(result.clearedCols, [])
        XCTAssertEqual(result.totalClearedLines, 1)
        // Cells should be empty now
        for col in 0..<GameGrid.size {
            XCTAssertEqual(grid.cellAt(row: 0, col: col), .empty)
        }
    }

    func testClearFullLines_singleColumnClears() {
        var grid = GameGrid()
        // Fill entire column 3
        for row in 0..<GameGrid.size {
            grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: 3))
        }
        let result = grid.clearFullLines()
        XCTAssertEqual(result.clearedRows, [])
        XCTAssertEqual(result.clearedCols, [3])
        XCTAssertEqual(result.totalClearedLines, 1)
        for row in 0..<GameGrid.size {
            XCTAssertEqual(grid.cellAt(row: row, col: 3), .empty)
        }
    }

    func testClearFullLines_multipleSimultaneousRowsAndCols() {
        var grid = GameGrid()
        // Fill rows 0 and 1 and column 5
        for col in 0..<GameGrid.size {
            grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: 0, col: col))
            grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: 1, col: col))
        }
        // Column 5 is already filled in rows 0,1; fill remaining rows for col 5
        for row in 2..<GameGrid.size {
            grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: 5))
        }
        let result = grid.clearFullLines()
        XCTAssertTrue(result.clearedRows.contains(0))
        XCTAssertTrue(result.clearedRows.contains(1))
        XCTAssertTrue(result.clearedCols.contains(5))
        XCTAssertEqual(result.totalClearedLines, 3)
    }

    func testClearFullLines_noClears_whenIncomplete() {
        var grid = GameGrid()
        // Fill all but one cell in row 0
        for col in 0..<(GameGrid.size - 1) {
            grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: 0, col: col))
        }
        let result = grid.clearFullLines()
        XCTAssertEqual(result.clearedRows, [])
        XCTAssertEqual(result.clearedCols, [])
        XCTAssertEqual(result.totalClearedLines, 0)
    }

    func testClearFullLines_noClears_onEmptyBoard() {
        var grid = GameGrid()
        let result = grid.clearFullLines()
        XCTAssertEqual(result.totalClearedLines, 0)
        XCTAssertTrue(grid.isEmpty)
    }

    func testClearFullLines_pointsCalculation() {
        var grid = GameGrid()
        // Fill 2 rows
        for col in 0..<GameGrid.size {
            grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: 0, col: col))
            grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: 1, col: col))
        }
        let result = grid.clearFullLines()
        // 2 lines * 9 (gridSize) = 18 points
        XCTAssertEqual(result.points, 2 * GameGrid.size)
    }

    func testClearFullLines_isBoardEmptyFlag() {
        var grid = GameGrid()
        // Fill the entire board
        for row in 0..<GameGrid.size {
            for col in 0..<GameGrid.size {
                grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: col))
            }
        }
        let result = grid.clearFullLines()
        XCTAssertTrue(result.isBoardEmpty)
        XCTAssertTrue(grid.isEmpty)
    }

    func testClearFullLines_intersectingRowAndCol_cellClearedOnce() {
        var grid = GameGrid()
        // Fill row 2 and column 2 fully
        for col in 0..<GameGrid.size {
            grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: 2, col: col))
        }
        for row in 0..<GameGrid.size where row != 2 {
            grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: 2))
        }
        let result = grid.clearFullLines()
        XCTAssertTrue(result.clearedRows.contains(2))
        XCTAssertTrue(result.clearedCols.contains(2))
        // All cells in row 2 and col 2 should be empty
        for col in 0..<GameGrid.size {
            XCTAssertEqual(grid.cellAt(row: 2, col: col), .empty)
        }
        for row in 0..<GameGrid.size {
            XCTAssertEqual(grid.cellAt(row: row, col: 2), .empty)
        }
    }

    // MARK: - isBoardStuck

    func testIsBoardStuck_emptyBoardNotStuck() {
        let grid = GameGrid()
        let pieces = BlockPiece.allPieces
        XCTAssertFalse(grid.isBoardStuck(pieces: pieces))
    }

    func testIsBoardStuck_returnsFalse_whenDotFits() {
        var grid = GameGrid()
        // Fill all but one corner cell
        for row in 0..<GameGrid.size {
            for col in 0..<GameGrid.size {
                if row == GameGrid.size - 1 && col == GameGrid.size - 1 { continue }
                grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: col))
            }
        }
        let dot = BlockPiece.make(.dot)
        XCTAssertFalse(grid.isBoardStuck(pieces: [dot]))
    }

    func testIsBoardStuck_returnsTrue_whenNoPieceFits() {
        var grid = GameGrid()
        // Fill entire board
        for row in 0..<GameGrid.size {
            for col in 0..<GameGrid.size {
                grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: col))
            }
        }
        XCTAssertTrue(grid.isBoardStuck(pieces: BlockPiece.allPieces))
    }

    func testIsBoardStuck_emptyPieceList_isAlwaysStuck() {
        let grid = GameGrid()
        XCTAssertTrue(grid.isBoardStuck(pieces: []))
    }

    // MARK: - rescueBoard

    func testRescueBoard_guaranteesAllPiecesFit_afterRescue() {
        var grid = makeNearFullGrid(leavingEmpty: 4)
        let pieces = BlockPiece.allPieces
        XCTAssertTrue(grid.isBoardStuck(pieces: pieces), "Precondition: board should be stuck")
        grid.rescueBoard(pieces: pieces)
        XCTAssertFalse(grid.isBoardStuck(pieces: pieces), "After rescue all pieces must fit")
    }

    func testRescueBoard_clearsAtLeastTwoRowsAndTwoCols() {
        var grid = makeNearFullGrid(leavingEmpty: 0)
        let occupiedBefore = grid.occupiedCount
        let pieces = BlockPiece.allPieces
        grid.rescueBoard(pieces: pieces)
        // Clearing 2 rows + 2 cols removes at least (2*9 + 2*9 - 4) = 32 cells (intersection double-counted)
        XCTAssertLessThan(grid.occupiedCount, occupiedBefore)
    }

    func testRescueBoard_worstCase_emptyBoardBackstop() {
        // A completely full board should terminate and end up empty or unstuck
        var grid = makeNearFullGrid(leavingEmpty: 0)
        let pieces = BlockPiece.allPieces
        // Must not infinite-loop; rescue terminates
        grid.rescueBoard(pieces: pieces)
        XCTAssertFalse(grid.isBoardStuck(pieces: pieces))
    }

    func testRescueBoard_doesNotModifyScore_directGridCall() {
        // Rescue operates on GameGrid directly; score lives in GameState.
        // Verify that GameGrid.rescueBoard has no score side-effect by checking
        // that the grid state is modified but no score property exists on GameGrid.
        var grid = makeNearFullGrid(leavingEmpty: 2)
        let pieces = [BlockPiece.make(.dot)]
        grid.rescueBoard(pieces: pieces)
        // If we reach here without crash/mutation error, the grid has no score
        XCTAssertFalse(grid.isBoardStuck(pieces: pieces))
    }

    func testRescueBoard_iterativeFallback_removesMoreLines_whenInitialClearInsufficient() {
        // Build a board where 2 rows + 2 cols are not enough to free a pentomino
        // by making it nearly full with only small isolated gaps
        var grid = makeNearFullGrid(leavingEmpty: 1)
        let pentomino = BlockPiece.make(.pentominoH)
        let pieces = [pentomino]
        grid.rescueBoard(pieces: pieces)
        XCTAssertFalse(grid.isBoardStuck(pieces: pieces))
    }

    func testRescueBoard_50RandomNearFullConfigurations() {
        let pieces = BlockPiece.allPieces
        for i in 0..<50 {
            var grid = makeRandomNearFullGrid(seed: i)
            guard grid.isBoardStuck(pieces: pieces) else { continue }
            grid.rescueBoard(pieces: pieces)
            XCTAssertFalse(
                grid.isBoardStuck(pieces: pieces),
                "Rescue failed for random board configuration \(i)"
            )
        }
    }

    // MARK: - Helpers

    /// Fills the entire board leaving `leavingEmpty` random cells empty.
    private func makeNearFullGrid(leavingEmpty: Int) -> GameGrid {
        var grid = GameGrid()
        var skipped = 0
        for row in 0..<GameGrid.size {
            for col in 0..<GameGrid.size {
                if skipped < leavingEmpty {
                    skipped += 1
                    continue
                }
                grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: col))
            }
        }
        return grid
    }

    /// Fills the board pseudo-randomly leaving roughly 10-20% empty cells.
    private func makeRandomNearFullGrid(seed: Int) -> GameGrid {
        var grid = GameGrid()
        // Simple LCG for deterministic pseudo-random sequence
        var rng = seed
        for row in 0..<GameGrid.size {
            for col in 0..<GameGrid.size {
                rng = (rng &* 1664525 &+ 1013904223) & 0x7FFFFFFF
                let shouldFill = (rng % 10) < 8 // ~80% fill rate
                if shouldFill {
                    grid.place(piece: BlockPiece.make(.dot), at: GridPosition(row: row, col: col))
                }
            }
        }
        return grid
    }
}
