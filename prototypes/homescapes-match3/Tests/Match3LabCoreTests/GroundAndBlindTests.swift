import XCTest
@testable import Match3LabCore

final class GroundAndBlindTests: XCTestCase {
    private func board(_ extra: [Position: [Attributes]], goal: String) throws -> Board {
        let cells = (0..<4).flatMap { y in (0..<3).map { x in
            SourceCell(position: Position(x, y), models: [["modelId": "NORMAL", "color": String((x+y)%3)]] + (extra[Position(x, y)] ?? []))
        }}
        return try Board(level: Level(id: "layers", seed: 8, moves: 10, cells: cells,
            goals: [Goal(type: goal, subtype: "", initial: 0, maximum: 100)], colors: [0: 100, 1: 100, 2: 100], patterns: []))
    }

    func testTileRequiresBlastToCrackAndDirectMatchToFinish() throws {
        let p = Position(1, 1)
        var b = try board([p: [["modelId": "BUBBLE_MEMBRANE", "level": "2"]]], goal: "BUBBLE_MEMBRANE")
        XCTAssertFalse(try XCTUnwrap(b.cells[p]).held)
        b.apply([p], spread: [], isBlast: false)
        XCTAssertEqual(b.cells[p]?.tile, 2)
        b.apply([Position(0, 1)], spread: [], isBlast: true)
        XCTAssertEqual(b.cells[p]?.tile, 2)
        b.apply([p], spread: [], isBlast: true)
        XCTAssertEqual(b.cells[p]?.tile, 1)
        XCTAssertEqual(b.goals[0].count, 0)
        b.fallAndRefill()
        b.apply([p], spread: [], isBlast: false)
        XCTAssertEqual(b.cells[p]?.tile, 0)
        XCTAssertEqual(b.goals[0].count, 1)
    }

    func testCoverProtectsTileAndTileStaysWhenPieceFalls() throws {
        let p = Position(1, 2)
        var b = try board([p: [["modelId": "BUBBLE_MEMBRANE", "level": "1"], ["modelId": "ICE", "level": "1"]]], goal: "BUBBLE_MEMBRANE")
        b.apply([p], spread: [], isBlast: true)
        XCTAssertEqual(b.cells[p]?.tile, 1)
        XCTAssertEqual(b.cells[p]?.ice, 0)
        b.apply([Position(1, 0)], spread: [], isBlast: true)
        b.fallAndRefill()
        XCTAssertEqual(b.cells[p]?.tile, 1)
        XCTAssertEqual(b.cells[Position(1, 0)]?.tile, 0)
    }

    func testBlindRollsBottomUpOncePerResolutionAndReleasesCoveredPieces() throws {
        let anchor = Position(1, 3)
        var b = try board([anchor: [["modelId": "SHUTTERS", "shutterHeight": "3"]]], goal: "SHUTTERS")
        let hidden = b.cells[Position(1, 1)]?.piece
        XCTAssertNil(b.cells[Position(1, 1)]?.matchColor)
        b.apply([Position(0, 1), Position(0, 2), Position(0, 3)], spread: [], isBlast: false)
        XCTAssertEqual(b.blinds[anchor], 2)
        XCTAssertNil(b.cells[Position(1, 1)]?.blind)
        XCTAssertEqual(b.cells[Position(1, 1)]?.piece, hidden)
        XCTAssertEqual(b.goals[0].count, 0)
        b.apply([anchor, Position(1, 2)], spread: [], isBlast: true)
        XCTAssertEqual(b.blinds[anchor], 1)
        b.apply([anchor], spread: [], isBlast: true)
        XCTAssertNil(b.blinds[anchor])
        XCTAssertEqual(b.goals[0].count, 1)
        XCTAssertFalse(b.cells.values.contains { $0.blind != nil })
    }

    func testBlindRejectsMissingAndOutOfFootprintProxies() throws {
        XCTAssertThrowsError(try board([Position(0, 1): [["modelId": "SHUTTERS", "mainX": "1", "mainY": "3"]]], goal: "SHUTTERS"))
        XCTAssertThrowsError(try board([Position(1, 3): [["modelId": "SHUTTERS", "shutterHeight": "2"]],
            Position(0, 1): [["modelId": "SHUTTERS", "mainX": "1", "mainY": "3"]]], goal: "SHUTTERS"))
    }
}
