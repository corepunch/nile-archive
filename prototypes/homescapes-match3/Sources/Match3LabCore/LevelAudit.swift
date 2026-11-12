import Foundation

/// Vocabulary acceptance is intentionally separate from original-runtime equivalence.
public struct LevelAudit: Codable {
    public struct Entry: Codable {
        public let path: String
        public let unknownModels: [String]
        public let unknownGoals: [String]
        public let error: String?
        public let initialized: Bool
    }
    public let entries: [Entry]
    public let models: [String: Int]
    public let goals: [String: Int]
    public let configurations: [String: Int]
    public let initialized: Int
    public let originalRuntimeVerified: Bool

    public static func run(directory: URL) throws -> Self {
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: directory.path])
        }
        let paths = enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "xml" }.sorted { $0.path < $1.path }
        guard !paths.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
        var entries: [Entry] = [], models: [String: Int] = [:], goals: [String: Int] = [:], configurations: [String: Int] = [:]
        for url in paths {
            let path = String(url.path.dropFirst(directory.path.count + 1))
            do {
                let level = try Level.load(url)
                let modelIDs = Set(level.cells.flatMap { $0.models.map { $0["modelId"] ?? "(missing)" } })
                let goalIDs = Set(level.goals.map(\.type))
                for id in modelIDs { models[id, default: 0] += 1 }
                for id in goalIDs { goals[id, default: 0] += 1 }
                let sections = Set(level.source?.children.first { $0.name == "Level" }?.children.map(\.name) ?? [])
                for section in sections { configurations[section, default: 0] += 1 }
                let unknownModels = modelIDs.subtracting(Board.supportedModels).sorted()
                let unknownGoals = goalIDs.subtracting(Board.supportedGoals).sorted()
                var error: String?, initialized = false
                if unknownModels.isEmpty && unknownGoals.isEmpty {
                    do { _ = try Board(level: level); initialized = true }
                    catch let failure { error = failure.localizedDescription }
                }
                entries.append(Entry(path: path, unknownModels: unknownModels, unknownGoals: unknownGoals,
                                     error: error, initialized: initialized))
            } catch {
                entries.append(Entry(path: path, unknownModels: [], unknownGoals: [], error: error.localizedDescription,
                                     initialized: false))
            }
        }
        return Self(entries: entries, models: models, goals: goals, configurations: configurations,
                    initialized: entries.filter(\.initialized).count, originalRuntimeVerified: false)
    }
}
