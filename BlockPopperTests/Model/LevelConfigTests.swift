import XCTest
@testable import BlockPopper

final class LevelConfigTests: XCTestCase {

    // MARK: - Edge cases

    func testPhase0ReturnsDefault() {
        XCTAssertEqual(LevelConfig.targetScore(forPhase: 0), 100)
    }

    func testNegativePhase_returnsDefault() {
        XCTAssertEqual(LevelConfig.targetScore(forPhase: -1), 100)
        XCTAssertEqual(LevelConfig.targetScore(forPhase: -99), 100)
    }

    // MARK: - Specified thresholds (linear: 100 + (phase-1) * 20)

    func testPhase1() {
        XCTAssertEqual(LevelConfig.targetScore(forPhase: 1), 100)
    }

    func testPhase2() {
        XCTAssertEqual(LevelConfig.targetScore(forPhase: 2), 120)
    }

    func testPhase3() {
        XCTAssertEqual(LevelConfig.targetScore(forPhase: 3), 140)
    }

    func testPhase4() {
        XCTAssertEqual(LevelConfig.targetScore(forPhase: 4), 160)
    }

    func testPhase5() {
        XCTAssertEqual(LevelConfig.targetScore(forPhase: 5), 180)
    }

    // MARK: - Formula: 100 + (phase-1) * 20 for phases 1–10

    func testFormulaForPhases1Through10() {
        let expected = [
            1: 100, 2: 120, 3: 140, 4: 160, 5: 180,
            6: 200, 7: 220, 8: 240, 9: 260, 10: 280
        ]
        for (phase, expectedScore) in expected {
            let actual = LevelConfig.targetScore(forPhase: phase)
            XCTAssertEqual(actual, expectedScore,
                           "Phase \(phase): expected \(expectedScore), got \(actual)")
        }
    }

    func testFormula_matchesExpressionDirectly() {
        for phase in 1...10 {
            let formulaResult = 100 + (phase - 1) * 20
            XCTAssertEqual(
                LevelConfig.targetScore(forPhase: phase),
                formulaResult,
                "Formula mismatch at phase \(phase)"
            )
        }
    }

    // MARK: - Monotonically increasing

    func testScoresAreMonotonicallyIncreasing() {
        var previous = 0
        for phase in 1...20 {
            let score = LevelConfig.targetScore(forPhase: phase)
            XCTAssertGreaterThan(score, previous,
                                 "Phase \(phase) score (\(score)) should be > phase \(phase-1) score (\(previous))")
            previous = score
        }
    }

    // MARK: - Legacy API

    func testLegacyForLevel_matchesForPhase() {
        for i in 1...10 {
            XCTAssertEqual(LevelConfig.targetScore(forLevel: i),
                           LevelConfig.targetScore(forPhase: i))
        }
    }
}
