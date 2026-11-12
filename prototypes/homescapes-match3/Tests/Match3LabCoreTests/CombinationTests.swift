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

    func testDoubleBombDoublesLabRadius() throws {
        var board = try board(["modelId": "BOMB"], ["modelId": "BOMB"])
        XCTAssertTrue(board.combine(Position(3, 4), Position(4, 4)))
        for (p, cell) in board.cells where cell.box > 0 {
            XCTAssertEqual(cell.box, abs(p.x - 4) <= 2 && abs(p.y - 4) <= 2 ? 1 : 2)
        }
    }

    func testDoubleRainbowHitsEveryObstacleOnce() throws {
        var board = try board(["modelId": "LIGHTNING"], ["modelId": "LIGHTNING"])
        XCTAssertTrue(board.combine(Position(3, 4), Position(4, 4)))
        XCTAssertTrue(board.cells.values.filter { $0.box > 0 }.allSatisfy { $0.box == 1 })
    }

    func testRainbowConvertsMostCommonColorAndDetonatesIt() throws {
        for payload in ["BOMB", "LINE"] {
            var board = try board(["modelId": "LIGHTNING"], ["modelId": payload, "line_orient": "2"],
                extra: [Position(0, 0): ["modelId": "NORMAL", "color": "0"],
                        Position(0, 2): ["modelId": "NORMAL", "color": "0"],
                        Position(8, 8): ["modelId": "NORMAL", "color": "1"]])
            XCTAssertTrue(board.combine(Position(3, 4), Position(4, 4)))
            XCTAssertNil(board.cells[Position(0, 0)]?.piece)
            XCTAssertNil(board.cells[Position(0, 2)]?.piece)
            XCTAssertEqual(board.cells[Position(8, 8)]?.piece, .gem(1))
            XCTAssertEqual(board.cells[Position(0, 1)]?.box, 1)
            XCTAssertEqual(board.cells[Position(7, 7)]?.box, 2)
        }
    }

    func testDoublePlaneTargetsThreeDifferentCells() throws {
        var board = try board(["modelId": "BOMB"], ["modelId": "BOMB"])
        board.resolveCombination(.plane, .plane, first: Position(3, 4), second: Position(4, 4))
        for x in 0..<3 { XCTAssertEqual(board.cells[Position(x, 0)]?.box, 1) }
        XCTAssertEqual(board.cells[Position(3, 0)]?.box, 2)
        XCTAssertEqual(board.cells.values.filter { $0.box == 1 }.count, 6)
    }

    func testPlaneCarriesPayloadInBothOrders() throws {
        for payload in [Special.bomb, .horizontal, .vertical] {
            for pair in [(Special.plane, payload), (payload, Special.plane)] {
                var board = try board(["modelId": "BOMB"], ["modelId": "BOMB"])
                board.resolveCombination(pair.0, pair.1, first: Position(3, 4), second: Position(4, 4))
                XCTAssertEqual(board.cells[Position(0, 0)]?.box, 1)
                let expected = payload == .horizontal ? Position(8, 0)
                    : payload == .vertical ? Position(0, 8) : Position(1, 1)
                XCTAssertEqual(board.cells[expected]?.box, 1)
                XCTAssertEqual(board.cells[Position(8, 8)]?.box, 2)
            }
        }
    }

    func testRainbowPlaneDispatchAndEmptyColorPool() throws {
        var board = try board(["modelId": "LIGHTNING"], ["modelId": "BOMB"],
                              extra: [Position(8, 8): ["modelId": "NORMAL", "color": "0"]])
        board.resolveCombination(.rainbow, .plane, first: Position(3, 4), second: Position(4, 4))
        XCTAssertNil(board.cells[Position(8, 8)]?.piece)
        XCTAssertEqual(board.cells[Position(0, 0)]?.box, 1)
        var empty = try self.board(["modelId": "LIGHTNING"], ["modelId": "BOMB"])
        XCTAssertTrue(empty.combine(Position(3, 4), Position(4, 4)))
        XCTAssertEqual(empty.cells[Position(0, 0)]?.box, 2)
    }

    func testNonSpecialPairDoesNotConsumeIngredients() throws {
        var board = try board(["modelId": "NORMAL", "color": "0"], ["modelId": "BOMB"])
        XCTAssertFalse(board.combine(Position(3, 4), Position(4, 4)))
        XCTAssertEqual(board.cells[Position(3, 4)]?.piece, .gem(0))
        XCTAssertEqual(board.cells[Position(4, 4)]?.piece, .special(.bomb))
    }
}
