import XCTest
@testable import BlockPopper

final class LevelConfigTests: XCTestCase {

    // MARK: - Specified thresholds

    func testLevel0ReturnsZero() {
        XCTAssertEqual(LevelConfig.targetScore(forLevel: 0), 0)
    }

    func testLevel1() {
        XCTAssertEqual(LevelConfig.targetScore(forLevel: 1), 100)
    }

    func testLevel2() {
        XCTAssertEqual(LevelConfig.targetScore(forLevel: 2), 300)
    }

    func testLevel3() {
        XCTAssertEqual(LevelConfig.targetScore(forLevel: 3), 600)
    }

    func testLevel4() {
        XCTAssertEqual(LevelConfig.targetScore(forLevel: 4), 1000)
    }

    // MARK: - Edge cases

    func testNegativeLevel_returnsZero() {
        XCTAssertEqual(LevelConfig.targetScore(forLevel: -1), 0)
        XCTAssertEqual(LevelConfig.targetScore(forLevel: -99), 0)
    }

    // MARK: - Formula: 100*level + 50*level*(level-1) for levels 1–10

    func testFormulaForLevels1Through10() {
        let expected = [
            1: 100,
            2: 300,
            3: 600,
            4: 1000,
            5: 1500,
            6: 2100,
            7: 2800,
            8: 3600,
            9: 4500,
            10: 5500
        ]
        for (level, expectedScore) in expected {
            let actual = LevelConfig.targetScore(forLevel: level)
            XCTAssertEqual(actual, expectedScore,
                           "Level \(level): expected \(expectedScore), got \(actual)")
        }
    }

    func testFormula_matchesExpressionDirectly_levels1Through10() {
        for level in 1...10 {
            let formulaResult = 100 * level + 50 * level * (level - 1)
            XCTAssertEqual(
                LevelConfig.targetScore(forLevel: level),
                formulaResult,
                "Formula mismatch at level \(level)"
            )
        }
    }

    // MARK: - Monotonically increasing

    func testScoresAreMonotonicallyIncreasing() {
        var previous = 0
        for level in 1...20 {
            let score = LevelConfig.targetScore(forLevel: level)
            XCTAssertGreaterThan(score, previous,
                                 "Level \(level) score (\(score)) should be > level \(level-1) score (\(previous))")
            previous = score
        }
    }

    // MARK: - Spot checks for levels 5–10

    func testLevel5_is1500() {
        // 100*5 + 50*5*4 = 500 + 1000 = 1500
        XCTAssertEqual(LevelConfig.targetScore(forLevel: 5), 1500)
    }

    func testLevel6_is2100() {
        // 100*6 + 50*6*5 = 600 + 1500 = 2100
        XCTAssertEqual(LevelConfig.targetScore(forLevel: 6), 2100)
    }

    func testLevel7_is2800() {
        // 100*7 + 50*7*6 = 700 + 2100 = 2800
        XCTAssertEqual(LevelConfig.targetScore(forLevel: 7), 2800)
    }

    func testLevel8_is3600() {
        // 100*8 + 50*8*7 = 800 + 2800 = 3600
        XCTAssertEqual(LevelConfig.targetScore(forLevel: 8), 3600)
    }

    func testLevel9_is4500() {
        // 100*9 + 50*9*8 = 900 + 3600 = 4500
        XCTAssertEqual(LevelConfig.targetScore(forLevel: 9), 4500)
    }

    func testLevel10_is5500() {
        // 100*10 + 50*10*9 = 1000 + 4500 = 5500
        XCTAssertEqual(LevelConfig.targetScore(forLevel: 10), 5500)
    }
}
