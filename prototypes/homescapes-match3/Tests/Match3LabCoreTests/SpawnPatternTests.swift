import Foundation
import XCTest
@testable import Match3LabCore

final class SpawnPatternTests: XCTestCase {
    private func level(_ sequence: String, loop: Bool = true, settings: String = "", extra: String = "",
                       modelExtra: String = "", cellExtra: String = "", empty: Bool = false) throws -> Level {
        let model = "<Model modelId=\"ARTIFACT_GEN\" id=\"0\" pattern=\"\(sequence)\" isLooped=\"\(loop ? 1 : 0)\" \(modelExtra)/>"
        let cells = (0..<2).flatMap { x in (0..<2).map { y in
            "<Cell x=\"\(x)\" y=\"\(y)\">\(empty ? "" : "<Model modelId=\"NORMAL\" color=\"\(x+y)\"/>")\(y == 1 ? model + cellExtra : "")</Cell>"
        }}.joined()
        let xml = """
        <root><Level movesLimitLocal="20"><Targets><target type="CHIPS" subtype="0" max="100"/></Targets>
        <ChipSet><chip number="0" probability="100"/><chip number="1" probability="100"/><chip number="2" probability="100"/></ChipSet>
        <BornPatterns><pattern str="\(sequence)" isLooped="\(loop)" showTexture="true" showChips="false">\(settings)</pattern></BornPatterns>
        \(extra)<Line>\(cells)</Line></Level></root>
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".xml")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data(xml.utf8).write(to: url)
        return try Level.load(url)
    }

    private func pattern(_ level: Level) throws -> SpawnPattern {
        try SpawnPattern.read(try XCTUnwrap(level.cells.flatMap(\.models).first { $0["modelId"] == "ARTIFACT_GEN" }), level: level)
    }

    func testTokenOutputsAndFiniteExhaustion() throws {
        var queue = try pattern(level("[c1][c6][b][f][z][lh][lv][l][t1][t2][t3][T1][T2][T3][c]", loop: false))
        let expected: [SpawnPattern.Output] = [.piece(.gem(0)), .piece(.gem(5)), .piece(.special(.bomb)),
            .piece(.special(.plane)), .piece(.special(.rainbow)), .piece(.special(.horizontal)),
            .piece(.special(.vertical)), .rocket, .piece(.cookie(1)), .piece(.cookie(2)), .piece(.cookie(3)),
            .piece(.hazelnut(1)), .piece(.hazelnut(2)), .piece(.hazelnut(3)), .colors(nil)]
        for output in expected { XCTAssertEqual(queue.next(), output) }
        XCTAssertNil(queue.next())
        XCTAssertNil(queue.next())
    }

    func testLoopAndIndependentSourcesPreserveExplicitInitialPieces() throws {
        var board = try Board(level: level("[c6][c5]"))
        XCTAssertEqual(board.cells[Position(0, 1)]?.piece, .gem(1))
        board.apply([Position(0, 0)], spread: [], isBlast: true)
        board.fallAndRefill()
        XCTAssertEqual(board.cells[Position(0, 0)]?.piece, .gem(1)) // Existing piece falls first.
        XCTAssertEqual(board.cells[Position(0, 1)]?.piece, .gem(5))
        board.apply([Position(1, 0), Position(1, 1)], spread: [], isBlast: true)
        board.fallAndRefill()
        XCTAssertEqual(board.cells[Position(1, 0)]?.piece, .gem(5))
        XCTAssertEqual(board.cells[Position(1, 1)]?.piece, .gem(4))
        board.apply([Position(0, 1), Position(1, 1)], spread: [], isBlast: true)
        board.fallAndRefill()
        XCTAssertEqual(board.cells[Position(0, 1)]?.piece, .gem(4))
        XCTAssertEqual(board.cells[Position(1, 1)]?.piece, .gem(5))
    }

    func testBlockedQueueWaitsUntilSourceOpens() throws {
        var board = try Board(level: level("[c6]", cellExtra: "<Model modelId=\"BOX\" level=\"2\"/>"))
        board.apply([Position(0, 0)], spread: [], isBlast: true)
        board.fallAndRefill()
        XCTAssertNotEqual(board.cells[Position(0, 0)]?.piece, .gem(5))
        for _ in 0..<3 { board.apply([Position(0, 1)], spread: [], isBlast: true) }
        board.fallAndRefill()
        XCTAssertEqual(board.cells[Position(0, 1)]?.piece, .gem(5))
    }

    func testEmptyInitialCellsUseQueueAndFiniteQueueFallsBack() throws {
        var board = try Board(level: level("[c6]", loop: false, empty: true))
        XCTAssertEqual(board.cells[Position(0, 0)]?.piece, .gem(5))
        XCTAssertNotEqual(board.cells[Position(0, 1)]?.piece, .gem(5))
        board.apply([Position(0, 0), Position(0, 1)], spread: [], isBlast: true)
        board.fallAndRefill()
        XCTAssertNotEqual(board.cells[Position(0, 0)]?.piece, .gem(5))
        XCTAssertNotEqual(board.cells[Position(0, 1)]?.piece, .gem(5))
    }

    func testPropertyCountsStrengthAndExplicitColorWeights() throws {
        let settings = """
        <settings><unitSettingsNode><propertyNode name="CountProperty" count="2"/>
        <propertyNode name="DropChanceProperty" value="100"/><propertyNode name="LevelProperty" levels="3" levelMax="3"/></unitSettingsNode>
        <unitSettingsNode><propertyNode name="CountProperty" count="1"/>
        <propertyNode name="ColorSetProperty" colorSetId="1" randomEverySpawn="0"/></unitSettingsNode></settings>
        """
        let sets = "<colorSets><colorSet name=\"c\"><set val=\"100,0,0,0,0,0\"/><set val=\"0,0,0,0,0,100\"/></colorSet></colorSets>"
        var queue = try pattern(level("[t1][c]", loop: false, settings: settings, extra: sets))
        XCTAssertEqual(queue.next(), .piece(.cookie(3)))
        XCTAssertEqual(queue.next(), .piece(.cookie(3)))
        XCTAssertEqual(queue.next(), .colors([5: 100]))
        XCTAssertNil(queue.next())
    }

    func testUnsupportedSyntaxPropertiesAndReferencesFailClosed() throws {
        for sequence in ["", "c", "[c]junk", "[c", "[]", "[[c]]", "[p]", "[t12]", "[Tmr]"] {
            XCTAssertThrowsError(try pattern(level(sequence)), sequence)
        }
        for property in ["<propertyNode name=\"RingProperty\"/>", "<propertyNode name=\"DropChanceProperty\" value=\"50\"/>",
                         "<propertyNode name=\"CountProperty\" count=\"0\"/>", "<propertyNode name=\"ColorSetProperty\" colorSetId=\"9\" randomEverySpawn=\"0\"/>"] {
            XCTAssertThrowsError(try pattern(level("[c]", settings: "<settings><unitSettingsNode>\(property)</unitSettingsNode></settings>")))
        }
        let source = try level("[c]")
        for model in [["modelId": "ARTIFACT_GEN", "id": "1", "pattern": "[c]", "isLooped": "1"],
                      ["modelId": "ARTIFACT_GEN", "id": "0", "pattern": "[b]", "isLooped": "1"],
                      ["modelId": "ARTIFACT_GEN", "id": "0", "pattern": "[c]", "isLooped": "0"]] {
            XCTAssertThrowsError(try SpawnPattern.read(model, level: source))
        }
    }

    func testOriginalQueueAndPaletteRecords() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("reference/homescapes-analysis/decoded/match3levels/Match3/Levels")
        guard FileManager.default.fileExists(atPath: root.path) else { throw XCTSkip("Original resources unavailable") }
        for name in ["base/st/st0001.xml", "base/st/st0065.xml", "base/st/st0111.xml", "base/st/st0037.xml"] {
            let source = try Level.load(root.appendingPathComponent(name))
            if name != "base/st/st0111.xml" { XCTAssertNoThrow(try Board(level: source), name) }
            for model in source.cells.flatMap(\.models) where model["modelId"] == "ARTIFACT_GEN" {
                XCTAssertNoThrow(try SpawnPattern.read(model, level: source), name)
            }
        }
        let source = try Level.load(root.appendingPathComponent("base/st/st0037.xml"))
        let model = try XCTUnwrap(source.cells.flatMap(\.models).first { $0["modelId"] == "PATTERN_COLOR_BORN" })
        XCTAssertEqual(try SpawnPattern.colors(model, level: source), [1, 2, 3])
        let conflict = try Level.load(root.appendingPathComponent("base/st/st0299.xml"))
        let bad = try XCTUnwrap(conflict.cells.flatMap(\.models).first { $0["modelId"] == "ARTIFACT_GEN" && $0["id"] == "2" })
        XCTAssertThrowsError(try SpawnPattern.read(bad, level: conflict))
    }

    func testColorSourceDoesNotLeakOutsideItsColumn() throws {
        let original = try level("[c]")
        let root = SourceElement(name: "root", attributes: [:], children: [SourceElement(name: "Level", attributes: [:], children: [
            SourceElement(name: "ColorChipsPattern", attributes: [:], children: [SourceElement(name: "pattern", attributes: ["str": "[Cs45]"])])])])
        let cells = original.cells.map { cell in SourceCell(position: cell.position, models: cell.models.filter { $0["modelId"] == "NORMAL" }
            + (cell.position == Position(0, 1) ? [["modelId": "PATTERN_COLOR_BORN", "id": "0", "pattern": "[Cs45]", "isLooped": "1"]] : [])) }
        var board = try Board(level: Level(id: "palette", seed: 7, moves: 20, cells: cells, goals: original.goals,
                                          colors: original.colors, patterns: [], source: root))
        board.apply(Set(cells.map(\.position)), spread: [], isBlast: true)
        board.fallAndRefill()
        for y in 0..<2 {
            XCTAssertTrue([4, 5].contains(try XCTUnwrap(board.cells[Position(0, y)]?.piece?.color)))
            XCTAssertTrue([0, 1, 2].contains(try XCTUnwrap(board.cells[Position(1, y)]?.piece?.color)))
        }
    }
}
