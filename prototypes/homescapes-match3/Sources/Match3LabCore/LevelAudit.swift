import Foundation

/// Vocabulary acceptance is intentionally separate from original-runtime equivalence.
public struct LevelAudit: Codable {
    public struct Entry: Codable {
        public let path: String
        public let unknownModels: [String]
        public let unknownGoals: [String]
        public let unsupportedConfigurations: [String]
        public let error: String?
        public let initialized: Bool
        public let turns: Int
        public let stalled: Bool
        public let goalProgress: Int
        public let patternSpawns: Int
        public let paletteSpawns: Int
    }
    public let entries: [Entry]
    public let models: [String: Int]
    public let goals: [String: Int]
    public let configurations: [String: Int]
    public let initialized: Int
    public let originalRuntimeVerified: Bool

    public static func run(directory: URL, turnLimit: Int = 0) throws -> Self {
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
                var gaps = Set<String>()
                // Inspect generator variants even on boards with unrelated unsupported blockers.
                for model in level.cells.flatMap(\.models) {
                    do {
                        if model["modelId"] == "ARTIFACT_GEN" { _ = try SpawnPattern.read(model, level: level) }
                        if model["modelId"] == "PATTERN_COLOR_BORN" { _ = try SpawnPattern.colors(model, level: level) }
                    } catch BoardError.unsupported(let reasons) { gaps.formUnion(reasons) }
                }
                var error: String?, initialized = false, turns = 0, stalled = false, goalProgress = 0, patternSpawns = 0, paletteSpawns = 0
                if unknownModels.isEmpty && unknownGoals.isEmpty && gaps.isEmpty {
                    do {
                        var board = try Board(level: level)
                        initialized = true
                        while turns < turnLimit && !board.finished, let (a, b) = board.hint() {
                            guard a == b ? board.activate(a) : board.swap(a, b) else {
                                throw NSError(domain: "HomescapesLab.Audit", code: 1,
                                    userInfo: [NSLocalizedDescriptionKey: "Hint could not be played"])
                            }
                            turns += 1
                        }
                        stalled = board.stalled
                        patternSpawns = board.patternSpawns.values.reduce(0, +)
                        paletteSpawns = board.paletteSpawns
                        goalProgress = board.goals.reduce(0) { $0 + $1.count - $1.goal.initial }
                    }
                    catch BoardError.unsupported(let reasons) { gaps.formUnion(reasons) }
                    catch let failure { error = failure.localizedDescription }
                }
                entries.append(Entry(path: path, unknownModels: unknownModels, unknownGoals: unknownGoals,
                                     unsupportedConfigurations: gaps.sorted(), error: error, initialized: initialized, turns: turns, stalled: stalled, goalProgress: goalProgress, patternSpawns: patternSpawns, paletteSpawns: paletteSpawns))
            } catch {
                entries.append(Entry(path: path, unknownModels: [], unknownGoals: [], unsupportedConfigurations: [], error: error.localizedDescription,
                                     initialized: false, turns: 0, stalled: false, goalProgress: 0, patternSpawns: 0, paletteSpawns: 0))
            }
        }
        return Self(entries: entries, models: models, goals: goals, configurations: configurations,
                    initialized: entries.filter(\.initialized).count, originalRuntimeVerified: false)
    }
}
