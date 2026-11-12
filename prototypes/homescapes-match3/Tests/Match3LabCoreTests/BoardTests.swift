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

    func testPreservesUnimplementedSourceData() throws {
        let xml = """
        <root><Level movesLimitLocal="3"><Line><Cell x="1" y="2" extra="yes">
        <Model modelId="MYSTERY"><settings value="kept"/></Model></Cell></Line>
        <Targets/><ChipSet/><Unknown flag="1"><nested>hello</nested></Unknown>
        </Level></root>
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".xml")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data(xml.utf8).write(to: url)
        let level = try Level.load(url)
        XCTAssertEqual(level.sourceXML, Data(xml.utf8))
        let sourceLevel = try XCTUnwrap(level.source?.children.first)
        let unknown = try XCTUnwrap(sourceLevel.children.first { $0.name == "Unknown" })
        XCTAssertEqual(unknown.attributes["flag"], "1")
        XCTAssertEqual(unknown.children.first?.text, "hello")
        let cell = try XCTUnwrap(sourceLevel.children.first { $0.name == "Line" }?.children.first)
        XCTAssertEqual(cell.attributes["extra"], "yes")
        XCTAssertEqual(cell.children.first?.children.first?.attributes["value"], "kept")
        XCTAssertThrowsError(try Board(level: level))
    }

    func testAllBundledLevelsPreserveSource() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let directory = root.appendingPathComponent("reference/homescapes-analysis/decoded/match3levels/Match3/Levels")
        guard let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            throw XCTSkip("Local Homescapes levels unavailable")
        }
        let levels = files.compactMap { $0 as? URL }.filter { $0.pathExtension == "xml" }
        XCTAssertEqual(levels.count, 6184)
        for url in levels {
            let level = try Level.load(url)
            XCTAssertEqual(level.sourceXML, try Data(contentsOf: url), url.path)
            XCTAssertEqual(level.source?.name, "root", url.path)
        }
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
