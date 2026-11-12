import Foundation
import XCTest
@testable import Match3LabCore

final class BlockerTests: XCTestCase {
    private func board(_ models: [Position: [Attributes]], goal: String = "CHIPS") throws -> Board {
        try Board(level: Level(id: "blockers", seed: 3, moves: 10,
            cells: models.map { SourceCell(position: $0.key, models: $0.value) },
            goals: [Goal(type: goal, subtype: "", initial: 0, maximum: 100)], colors: [0: 1, 1: 1, 2: 1], patterns: []))
    }

    func testJellyBlocksMatchSwapAndFallAndReleasesCherryOnLastHit() throws {
        for strength in 1...6 {
            let target = Position(0, 0), neighbor = Position(1, 0)
            var b = try board([target: [["modelId": "CHERRY"], ["modelId": "HONEY", "level": String(strength)]],
                               neighbor: [["modelId": "NORMAL", "color": "0"]]], goal: "COLLECT_PIGGY")
            XCTAssertTrue(b.cells[target]!.held)
            XCTAssertFalse(b.cells[target]!.canFall)
            XCTAssertNil(b.cells[target]!.matchColor)
            for layer in stride(from: strength, through: 1, by: -1) {
                b.apply([neighbor], spread: [], isBlast: false)
                XCTAssertEqual(b.cells[target]?.jelly, layer - 1)
                XCTAssertEqual(b.goals[0].count, layer == 1 ? 1 : 0)
            }
            XCTAssertNil(b.cells[target]?.piece)
        }
    }

    func testJellyTakesNearbyBlastButNormalBoxDoesNot() throws {
        var b = try board([Position(0, 0): [["modelId": "BOMB"]],
                           Position(1, 0): [["modelId": "HONEY", "level": "2"]],
                           Position(0, 1): [["modelId": "BOX", "level": "2"]]])
        b.apply([Position(0, 0)], spread: [], isBlast: true)
        XCTAssertEqual(b.cells[Position(1, 0)]?.jelly, 1)
        XCTAssertEqual(b.cells[Position(0, 1)]?.box, 2)
    }

    func testColoredBoxesRequireTheirColorOrExplosion() throws {
        for color in 0...5 {
            let target = Position(0, 0), match = Position(1, 0)
            for matching in [false, true] {
                var b = try board([target: [["modelId": "COLOR_BOX", "color": String(color), "level": "2"]],
                    match: [["modelId": "NORMAL", "color": String(matching ? color : (color + 1) % 6)]]], goal: "COLOR_BOX")
                b.apply([match], spread: [], isBlast: false)
                XCTAssertEqual(b.cells[target]?.box, matching ? 1 : 2)
                b.apply([target], spread: [], isBlast: true)
                XCTAssertEqual(b.cells[target]?.box, matching ? 0 : 1)
                XCTAssertEqual(b.goals[0].count, matching ? 1 : 0)
            }
        }
    }

    func testHazelnutsOnlyTakeExplosionDamageAndCreditOnce() throws {
        for strength in 1...3 {
            let target = Position(0, 0)
            var b = try board([target: [["modelId": "TRASH_STONE", "level": String(strength)]],
                               Position(1, 0): [["modelId": "NORMAL", "color": "0"]]], goal: "TRASHSTONE")
            XCTAssertTrue(b.cells[target]!.canFall)
            XCTAssertTrue(b.cells[target]!.piece!.canSwap)
            b.apply([Position(1, 0)], spread: [], isBlast: false)
            XCTAssertEqual(b.cells[target]?.piece, .hazelnut(strength))
            for _ in 0..<strength { b.apply([target], spread: [], isBlast: true) }
            XCTAssertNil(b.cells[target]?.piece)
            XCTAssertEqual(b.goals[0].count, 1)
        }
    }

    func testApplePlatterSharesFourCellsAndOneHitPerMatch() throws {
        let anchor = Position(0, 1)
        var b = try board([anchor: [["modelId": "TARGET_GEN", "level": "2"]],
            Position(1, 1): [], Position(0, 0): [], Position(1, 0): [],
            Position(2, 0): [["modelId": "NORMAL", "color": "0"]]], goal: "TARGET_GENERATOR")
        XCTAssertEqual(b.cells.values.filter { $0.platter == anchor }.count, 4)
        b.apply([anchor, Position(1, 1), Position(0, 0), Position(1, 0)], spread: [], isBlast: true)
        XCTAssertEqual(b.platters[anchor], 1)
        XCTAssertEqual(b.goals[0].count, 1)
        b.apply([Position(2, 0)], spread: [], isBlast: false)
        XCTAssertTrue(b.platters.isEmpty)
        XCTAssertFalse(b.cells.values.contains { $0.platter != nil })
        XCTAssertEqual(b.goals[0].count, 2)
    }

    func testStatueNeedsExplosionsAndStaysFixedUntilComplete() throws {
        let target = Position(0, 0)
        var b = try board([target: [["modelId": "STATUE", "level": "3"]],
                           Position(1, 0): [["modelId": "NORMAL", "color": "0"]]], goal: "STATUE")
        b.apply([Position(1, 0)], spread: [], isBlast: false)
        XCTAssertEqual(b.cells[target]?.statue, 3)
        XCTAssertFalse(b.cells[target]!.canFall)
        for _ in 0..<3 { b.apply([target], spread: [], isBlast: true) }
        XCTAssertEqual(b.cells[target]?.statue, 0)
        XCTAssertEqual(b.goals[0].count, 1)
    }

    func testCookieStackProducesThreeCookiesAfterThreeHits() throws {
        let target = Position(0, 0), neighbor = Position(1, 0)
        var b = try board([target: [["modelId": "COOKIE_BOX", "level": "3"]],
            neighbor: [["modelId": "NORMAL", "color": "0"]],
            Position(2, 0): [["modelId": "NORMAL", "color": "1"]],
            Position(3, 0): [["modelId": "NORMAL", "color": "2"]]], goal: "TRASH")
        for _ in 0..<2 { b.apply([neighbor], spread: [], isBlast: false) }
        b.releaseGeneratedPieces()
        XCTAssertFalse(b.cells.values.contains { $0.cookie > 0 })
        b.apply([neighbor], spread: [], isBlast: false)
        b.fallAndRefill()
        XCTAssertEqual(b.cells.values.filter { $0.cookie == 1 }.count, 3)
        XCTAssertEqual(b.goals[0].count, 0)
    }

    func testDonutMakerCountsSharedHitsAndUsesMarkedCells() throws {
        let anchor = Position(0, 1)
        var b = try board([anchor: [["modelId": "CARRY_GEN", "carryGenMax": "2", "carryGenActivatePer": "3"]],
            Position(1, 1): [], Position(0, 0): [], Position(1, 0): [],
            Position(2, 0): [["modelId": "NORMAL", "color": "0"], ["modelId": "CARRY_GEN_CELLS"]],
            Position(2, 1): [["modelId": "NORMAL", "color": "1"], ["modelId": "CARRY_GEN_CELLS"]],
            Position(3, 0): [["modelId": "NORMAL", "color": "2"]]], goal: "CARRY")
        let footprint: Set<Position> = [anchor, Position(1, 1), Position(0, 0), Position(1, 0)]
        for _ in 0..<2 { b.apply(footprint, spread: [], isBlast: true) }
        b.releaseGeneratedPieces()
        XCTAssertEqual(b.makers[anchor]?.hits, 2)
        XCTAssertFalse(b.cells.values.contains { $0.piece == .donut })
        b.apply(footprint, spread: [], isBlast: true)
        b.releaseGeneratedPieces()
        XCTAssertEqual(b.cells.values.filter { $0.piece == .donut }.count, 2)
        XCTAssertEqual(b.cells[Position(3, 0)]?.piece, .gem(2))
        XCTAssertEqual(b.makers[anchor]?.hits, 0)
    }

    func testCookieFallsWithItsStrengthAndStopsRocket() throws {
        var b = try board([Position(0, 0): [["modelId": "NORMAL", "color": "0"]],
                           Position(0, 1): [["modelId": "TRASH", "level": "3"]]])
        b.apply([Position(0, 0)], spread: [], isBlast: true)
        b.fallAndRefill()
        XCTAssertEqual(b.cells[Position(0, 0)]?.cookie, 3)
        XCTAssertEqual(b.cells[Position(0, 1)]?.cookie, 0)
        var rocket = try board([Position(0, 0): [["modelId": "LINE", "line_orient": "0"]],
            Position(1, 0): [["modelId": "TRASH", "level": "2"]],
            Position(2, 0): [["modelId": "BOX", "level": "2"]]])
        XCTAssertTrue(rocket.activate(Position(0, 0)))
        XCTAssertEqual(rocket.cells[Position(1, 0)]?.cookie, 1)
        XCTAssertEqual(rocket.cells[Position(2, 0)]?.box, 2)
    }
}
