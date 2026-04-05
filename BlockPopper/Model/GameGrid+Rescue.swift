import Foundation

// MARK: - Rescue Algorithm & Helpers

extension GameGrid {

    mutating func rescueBoard(pieces: [BlockPiece]) {
        // Step 1: Clear the 2 most-filled rows + 2 most-filled columns
        let sortedRows = rowsByFillCount()
        let sortedCols = colsByFillCount()

        let rowsToClear = Array(sortedRows.prefix(2))
        let colsToClear = Array(sortedCols.prefix(2))

        for row in rowsToClear {
            clearRow(row)
        }
        for col in colsToClear {
            clearCol(col)
        }
        // Row and column clears are independent. If a cell sits at the intersection
        // of a cleared row and a cleared column, the second clear is a no-op.

        // Step 2: Iteratively clear more lines until all pieces fit
        var clearedRowSet = Set(rowsToClear)
        var clearedColSet = Set(colsToClear)
        var remainingLines = buildRemainingLines(
            excludingRows: clearedRowSet,
            excludingCols: clearedColSet
        )

        while isBoardStuck(pieces: pieces) {
            guard let nextLine = remainingLines.first else { break }
            remainingLines.removeFirst()

            switch nextLine {
            case .row(let rowIndex):
                clearRow(rowIndex)
                clearedRowSet.insert(rowIndex)
            case .col(let colIndex):
                clearCol(colIndex)
                clearedColSet.insert(colIndex)
            }

            if isEmpty { break } // guaranteed termination backstop
        }

        // Postcondition: all 3 pieces can be placed on the grid
        // IMPORTANT: rescue clears do NOT award score points
    }

    // MARK: - Fill Count Queries

    func rowsByFillCount() -> [Int] {
        (0..<GameGrid.rows).sorted { firstRow, secondRow in
            filledCountInRow(firstRow) > filledCountInRow(secondRow)
        }
    }

    func colsByFillCount() -> [Int] {
        (0..<GameGrid.columns).sorted { firstCol, secondCol in
            filledCountInCol(firstCol) > filledCountInCol(secondCol)
        }
    }

    func filledCountInRow(_ row: Int) -> Int {
        cells[row].filter { $0 != .empty }.count
    }

    func filledCountInCol(_ col: Int) -> Int {
        (0..<GameGrid.rows).filter { cells[$0][col] != .empty }.count
    }

    // MARK: - Line Clearing Primitives

    mutating func clearRow(_ row: Int) {
        for col in 0..<GameGrid.columns {
            cells[row][col] = .empty
        }
    }

    mutating func clearCol(_ col: Int) {
        for row in 0..<GameGrid.rows {
            cells[row][col] = .empty
        }
    }

    // MARK: - Remaining Lines Builder

    enum GridLine {
        case row(Int)
        case col(Int)
    }

    func buildRemainingLines(excludingRows: Set<Int>, excludingCols: Set<Int>) -> [GridLine] {
        var lines: [(line: GridLine, count: Int)] = []

        for row in 0..<GameGrid.rows where !excludingRows.contains(row) {
            lines.append((.row(row), filledCountInRow(row)))
        }
        for col in 0..<GameGrid.columns where !excludingCols.contains(col) {
            lines.append((.col(col), filledCountInCol(col)))
        }

        lines.sort { $0.count > $1.count }
        return lines.map(\.line)
    }
}
