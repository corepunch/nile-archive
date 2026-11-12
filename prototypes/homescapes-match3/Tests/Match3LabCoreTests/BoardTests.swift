import Foundation
import XCTest
@testable import Match3LabCore

final class BoardTests: XCTestCase {
    private func fixture(_ rows: [[Int]], extra: [Position: [Attributes]] = [:]) throws -> Board {
        let cells = rows.enumerated().flatMap { y, row in
            row.enumerated().map { x, color in
                let position = Position(x, y)
                return SourceCell(position: position, models: [["modelId": "NORMAL", "color": String(color)]]
                                  + (extra[position] ?? []))
            }
        }
        let level = Level(id: "test", seed: 3, moves: 10, cells: cells,
                          goals: [Goal(type: "CHIPS", subtype: "0", initial: 0, maximum: 100)],
                          colors: [0: 1, 1: 1, 2: 1, 3: 1], patterns: [])
        return try Board(level: level)
    }

    func testSpecialsFromFourShapes() throws {
        let scenarios: [([[Int]], Position, Position, Special)] = [
            ([[0, 0, 1], [0, 1, 0], [1, 2, 2]], Position(1, 1), Position(2, 1), .plane),
            ([[0, 0, 1, 0], [2, 1, 0, 2], [1, 2, 2, 1]], Position(2, 1), Position(2, 0), .horizontal),
            ([[0, 1, 0, 0], [2, 0, 1, 2], [1, 0, 2, 1]], Position(0, 0), Position(1, 0), .bomb),
            ([[0, 0, 1, 0, 0], [2, 1, 0, 2, 1], [1, 2, 2, 1, 2]], Position(2, 1), Position(2, 0), .rainbow)
        ]
        for (rows, first, second, special) in scenarios {
            var board = try fixture(rows)
            XCTAssertTrue(board.swap(first, second), special.rawValue)
            XCTAssertEqual(board.remaining, 9)
            XCTAssertTrue(board.cells.values.contains { $0.piece == .special(special) }, special.rawValue)
        }
    }

    func testHeldPieceRejectsSwapAndLosesOneLayerOnMatch() throws {
        let held = Position(0, 0)
        var board = try fixture([[0, 0, 1, 2], [2, 1, 0, 3], [1, 2, 3, 1]],
                                extra: [held: [["modelId": "ICE", "level": "2"]]])
        XCTAssertFalse(board.swap(held, Position(0, 1)))
        XCTAssertEqual(board.remaining, 10)
        XCTAssertTrue(board.swap(Position(2, 1), Position(2, 0)))
        XCTAssertEqual(board.cells[held]?.ice, 1)
        XCTAssertEqual(board.cells[held]?.piece, .gem(0))
        XCTAssertGreaterThanOrEqual(board.goals[0].count, 2)
    }
}
