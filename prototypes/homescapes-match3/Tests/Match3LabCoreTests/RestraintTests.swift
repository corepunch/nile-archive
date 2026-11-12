import XCTest
@testable import Match3LabCore

final class RestraintTests: XCTestCase {
    func testStackedDonutsSettleThroughExitBeforeRefill() throws {
        let cells = [
            SourceCell(position: Position(0, 0), models: [["modelId": "NORMAL", "color": "0"], ["modelId": "CARRY_EXIT"]]),
            SourceCell(position: Position(0, 1), models: [["modelId": "CARRY"]]),
            SourceCell(position: Position(0, 2), models: [["modelId": "CARRY"]]),
            SourceCell(position: Position(0, 3), models: [["modelId": "LINE", "line_orient": "2"]])
        ]
        var board = try Board(level: Level(id: "donuts", seed: 1, moves: 5, cells: cells,
            goals: [Goal(type: "CARRY", subtype: "", initial: 0, maximum: 2)], colors: [0: 1, 1: 1, 2: 1], patterns: []))
        XCTAssertTrue(board.activate(Position(0, 3)))
        XCTAssertEqual(board.goals[0].count, 2)
        XCTAssertFalse(board.cells.values.contains { $0.piece == .donut })
        XCTAssertEqual(board.remaining, 4)
    }

    func testBlastRemovesRestraintBeforeCookie() throws {
        for restraint in ["ICE", "LOCK"] {
            let cells = [
                SourceCell(position: Position(0, 0), models: [["modelId": "LINE", "line_orient": "0"]]),
                SourceCell(position: Position(1, 0), models: [["modelId": "TRASH", "level": "2"],
                                                            ["modelId": restraint, "level": "1"]])
            ]
            var board = try Board(level: Level(id: "restraint", seed: 1, moves: 5, cells: cells,
                goals: [Goal(type: restraint, subtype: "", initial: 0, maximum: 1)], colors: [0: 1], patterns: []))
            XCTAssertTrue(board.activate(Position(0, 0)))
            XCTAssertEqual(board.cells[Position(1, 0)]?.cookie, 2)
            XCTAssertEqual(board.cells[Position(1, 0)]?.ice, 0)
            XCTAssertEqual(board.cells[Position(1, 0)]?.chain, 0)
            XCTAssertEqual(board.goals[0].count, 1)
        }
    }
}
