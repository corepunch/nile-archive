import XCTest
@testable import Match3LabCore

final class CombinationTests: XCTestCase {
    private func board(_ first: Attributes, _ second: Attributes,
                       extra: [Position: Attributes] = [:]) throws -> Board {
        var models = extra
        models[Position(3, 4)] = first
        models[Position(4, 4)] = second
        let cells = (0..<9).flatMap { y in
            (0..<9).map { x in
                let p = Position(x, y)
                return SourceCell(position: p, models: [models[p] ?? ["modelId": "BOX", "level": "2"]])
            }
        }
        return try Board(level: Level(id: "combinations", seed: 1, moves: 10, cells: cells,
            goals: [Goal(type: "BOX", subtype: "", initial: 0, maximum: 81)], colors: [0: 1], patterns: []))
    }

    func testRocketsClearCrossRegardlessOfOrientation() throws {
        for a in ["0", "2", "-2"] {
            for b in ["0", "2", "-2"] {
                var board = try board(["modelId": "LINE", "line_orient": a],
                                      ["modelId": "LINE", "line_orient": b])
                XCTAssertTrue(board.combine(Position(3, 4), Position(4, 4)))
                for (p, cell) in board.cells where p != Position(3, 4) && p != Position(4, 4) {
                    XCTAssertEqual(cell.box, p.x == 4 || p.y == 4 ? 1 : 2, "\(a),\(b) at \(p)")
                }
                XCTAssertNil(board.cells[Position(3, 4)]?.piece)
                XCTAssertNil(board.cells[Position(4, 4)]?.piece)
            }
        }
    }

    func testBombRocketClearsThreeRowsAndColumnsInEitherOrder() throws {
        for orientation in ["0", "2", "-2"] {
            let rocket = ["modelId": "LINE", "line_orient": orientation]
            let bomb = ["modelId": "BOMB"]
            for pair in [(rocket, bomb), (bomb, rocket)] {
                var board = try board(pair.0, pair.1)
                XCTAssertTrue(board.combine(Position(3, 4), Position(4, 4)))
                for (p, cell) in board.cells where p != Position(3, 4) && p != Position(4, 4) {
                    let inside = abs(p.x - 4) <= 1 || abs(p.y - 4) <= 1
                    XCTAssertEqual(cell.box, inside ? 1 : 2, "at \(p)")
                }
            }
        }
    }

    func testCombinedBlastTriggersOtherPowerUpsOnce() throws {
        var board = try board(["modelId": "LINE", "line_orient": "0"],
                              ["modelId": "LINE", "line_orient": "0"],
                              extra: [Position(4, 0): ["modelId": "LINE", "line_orient": "0"]])
        XCTAssertTrue(board.combine(Position(3, 4), Position(4, 4)))
        XCTAssertEqual(board.cells[Position(0, 0)]?.box, 1)
        XCTAssertEqual(board.cells[Position(0, 1)]?.box, 2)
        XCTAssertEqual(board.cells[Position(4, 4)]?.box, 0)
        XCTAssertNil(board.cells[Position(4, 0)]?.piece)
    }

    func testSwapUsesCombinationAndConsumesOneMove() throws {
        var board = try board(["modelId": "LINE", "line_orient": "0"],
                              ["modelId": "LINE", "line_orient": "0"])
        XCTAssertTrue(board.swap(Position(3, 4), Position(4, 4)))
        XCTAssertEqual(board.remaining, 9)
        XCTAssertEqual(board.cells[Position(4, 0)]?.box, 1)
        XCTAssertEqual(board.cells[Position(3, 0)]?.box, 2)
    }

    func testUnsupportedPairDoesNotConsumeIngredients() throws {
        var board = try board(["modelId": "LIGHTNING"], ["modelId": "BOMB"])
        XCTAssertFalse(board.combine(Position(3, 4), Position(4, 4)))
        XCTAssertEqual(board.cells[Position(3, 4)]?.piece, .special(.rainbow))
        XCTAssertEqual(board.cells[Position(4, 4)]?.piece, .special(.bomb))
    }
}
