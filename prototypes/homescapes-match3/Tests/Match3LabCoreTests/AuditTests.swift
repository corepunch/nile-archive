import Foundation
import XCTest
@testable import Match3LabCore

final class AuditTests: XCTestCase {
    func testGeneratorGapsAreReportedAlongsideUnrelatedBlockers() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let xml = """
        <root><Level movesLimitLocal="10"><Targets/><BornPatterns><pattern str="[Tmr]" isLooped="true"/></BornPatterns>
        <Line><Cell x="0" y="0"><Model modelId="UNKNOWN"/><Model modelId="ARTIFACT_GEN" id="0" pattern="[Tmr]" isLooped="1"/></Cell></Line></Level></root>
        """
        try Data(xml.utf8).write(to: directory.appendingPathComponent("unknown.xml"))
        let result = try XCTUnwrap(LevelAudit.run(directory: directory).entries.first)
        XCTAssertEqual(result.unknownModels, ["UNKNOWN"])
        XCTAssertEqual(result.unsupportedConfigurations, ["BornPatterns token [Tmr]"])
        XCTAssertNil(result.error)
        XCTAssertFalse(result.initialized)
    }

    func testAuditListsAllGapsAndParseFailures() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = """
        <root><Level movesLimitLocal="10"><Line><Cell x="0" y="0">
        <Model modelId="UNKNOWN_A"/><Model modelId="UNKNOWN_B"/></Cell></Line>
        <Targets><target type="UNKNOWN_GOAL" max="1"/></Targets><Generator/></Level></root>
        """
        try Data(source.utf8).write(to: directory.appendingPathComponent("unknown.xml"))
        try Data("broken".utf8).write(to: directory.appendingPathComponent("broken.xml"))
        let audit = try LevelAudit.run(directory: directory)
        XCTAssertEqual(audit.entries.count, 2)
        XCTAssertNotNil(audit.entries[0].error)
        XCTAssertEqual(audit.entries[1].unknownModels, ["UNKNOWN_A", "UNKNOWN_B"])
        XCTAssertEqual(audit.entries[1].unknownGoals, ["UNKNOWN_GOAL"])
        XCTAssertEqual(audit.configurations["Generator"], 1)
        XCTAssertEqual(audit.initialized, 0)
        XCTAssertFalse(audit.originalRuntimeVerified)
    }
}
