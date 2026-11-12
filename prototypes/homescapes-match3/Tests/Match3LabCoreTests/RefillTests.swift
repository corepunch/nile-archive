import Foundation
import XCTest
@testable import Match3LabCore

final class RefillTests: XCTestCase {
    private func load(_ section: String, goal: String, max: Int = 3, born: Bool = true) throws -> Level {
        let xml = """
        <root><Level movesLimitLocal="10"><Targets><target type="\(goal)" max="\(max)" current="0"/></Targets>
        <ChipSet><chip number="0" probability="100"/><chip number="1" probability="100"/><chip number="2" probability="100"/></ChipSet>
        \(section)<Line><Cell x="0" y="0"><Model modelId="NORMAL" color="0"/></Cell>
        <Cell x="0" y="1"><Model modelId="NORMAL" color="1"/>\(born ? "<Model modelId=\"BORN\" isLooped=\"1\"/>" : "")</Cell></Line></Level></root>
        """
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".xml")
        defer { try? FileManager.default.removeItem(at: path) }
        try Data(xml.utf8).write(to: path)
        return try Level.load(path)
    }

    func testRefillHonorsChanceCapacityStrengthAndBornPoint() throws {
        for (section, goal, piece) in [("TrashChips", "TRASH", Piece.cookie(2)),
                                       ("TrashStoneChips", "TRASHSTONE", Piece.hazelnut(2))] {
            for born in [false, true] {
                let level = try load("<\(section) chance=\"100\" max=\"1\" level=\"2\"/>", goal: goal, born: born)
                var b = try Board(level: level)
                b.apply([Position(0, 0), Position(0, 1)], spread: [], isBlast: true)
                b.fallAndRefill()
                XCTAssertEqual(b.cells.values.filter { $0.piece == piece }.count, born ? 1 : 0)
            }
            var zero = try Board(level: load("<\(section) chance=\"0\" max=\"9\" level=\"2\"/>", goal: goal))
            zero.apply([Position(0, 0), Position(0, 1)], spread: [], isBlast: true)
            zero.fallAndRefill()
            XCTAssertFalse(zero.cells.values.contains { $0.piece == piece })
        }
    }

    func testLimitedRefillCannotExceedRemainingGoal() throws {
        var b = try Board(level: load("<TrashStoneChips chance=\"100\" max=\"9\" level=\"1\" gen_limitation=\"true\"/>",
                                    goal: "TRASHSTONE", max: 1))
        b.apply([Position(0, 0), Position(0, 1)], spread: [], isBlast: true)
        b.fallAndRefill()
        XCTAssertEqual(b.cells.values.filter { $0.piece == .hazelnut(1) }.count, 1)
        let nut = try XCTUnwrap(b.cells.first { $0.value.piece == .hazelnut(1) }?.key)
        b.apply([nut], spread: [], isBlast: true)
        b.fallAndRefill()
        XCTAssertFalse(b.cells.values.contains { $0.piece == .hazelnut(1) })
    }

    func testExplicitSourceCoordinatesDoNotSpawnInOtherColumns() throws {
        for x in [0, 9] {
            var board = try Board(level: load("<TrashChips chance=\"100\" max=\"1\" level=\"2\"><b x=\"\(x)\" y=\"1\"/></TrashChips>", goal: "TRASH"))
            board.apply([Position(0, 0), Position(0, 1)], spread: [], isBlast: true)
            board.fallAndRefill()
            XCTAssertEqual(board.cells.values.filter { $0.piece == .cookie(2) }.count, x == 0 ? 1 : 0)
        }
    }

    func testInvalidConfigurationFailsInsteadOfSilentlyChangingRules() throws {
        XCTAssertThrowsError(try Board(level: load("<TrashChips chance=\"101\" max=\"1\"/>", goal: "TRASH")))
    }
}
