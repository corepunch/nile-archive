import Foundation

/// A queue belongs to a board position, never to the shared XML pattern ID.
struct SpawnPattern {
    enum Output: Equatable {
        case colors([Int: Int]?)
        case piece(Piece)
        case rocket
    }
    struct Unit {
        var output: Output
        var count = 1
    }
    let units: [Unit]
    let looped: Bool
    private(set) var cursor = 0
    private var emitted = 0

    mutating func next() -> Output? {
        guard cursor < units.count else { return nil }
        let unit = units[cursor]
        emitted += 1
        if emitted == unit.count {
            emitted = 0
            cursor += 1
            if cursor == units.count && looped { cursor = 0 }
        }
        return unit.output
    }

    static func tokens(_ string: String) throws -> [String] {
        var rest = string[...], result: [String] = []
        while !rest.isEmpty {
            guard rest.first == "[", let end = rest.firstIndex(of: "]") else {
                throw BoardError.unsupported(["BornPatterns malformed sequence \(string)"])
            }
            let token = String(rest[rest.index(after: rest.startIndex)..<end])
            guard !token.isEmpty, !token.contains("[") else {
                throw BoardError.unsupported(["BornPatterns empty/nested token"])
            }
            result.append(token)
            rest = rest[rest.index(after: end)...]
        }
        guard !result.isEmpty else { throw BoardError.unsupported(["BornPatterns empty sequence"]) }
        return result
    }

    static func reference(_ model: Attributes, level: Level, section: String) throws -> SourceElement {
        let patterns = level.source?.children.first { $0.name == "Level" }?
            .children.first { $0.name == section }?.children.filter { $0.name == "pattern" } ?? []
        guard let index = model["id"].flatMap(Int.init), patterns.indices.contains(index),
              let string = model["pattern"], patterns[index].attributes["str"] == string else {
            throw BoardError.unsupported(["\(section) missing/conflicting reference id=\(model["id"] ?? "nil")"])
        }
        return patterns[index]
    }

    static func read(_ model: Attributes, level: Level) throws -> Self {
        let pattern = try reference(model, level: level, section: "BornPatterns")
        let attrs = pattern.attributes
        guard ["true", "false"].contains(attrs["isLooped"] ?? ""),
              model["isLooped"] == (attrs["isLooped"] == "true" ? "1" : "0"),
              attrs["loopedCount"] == nil || attrs["loopedCount"] == "0" else {
            throw BoardError.unsupported(["BornPatterns loop configuration"])
        }
        let tokens = try tokens(attrs["str"] ?? "")
        let settings = pattern.children.first { $0.name == "settings" }?.children ?? []
        guard settings.isEmpty || settings.count == tokens.count else {
            throw BoardError.unsupported(["BornPatterns property count"])
        }
        var units: [Unit] = []
        for (index, token) in tokens.enumerated() {
            var output: Output
            switch token {
            case "c": output = .colors(nil)
            case "c1", "c2", "c3", "c4", "c5", "c6": output = .piece(.gem(Int(token.dropFirst())! - 1))
            case "b": output = .piece(.special(.bomb))
            case "f": output = .piece(.special(.plane))
            case "z": output = .piece(.special(.rainbow))
            case "l": output = .rocket
            case "lh": output = .piece(.special(.horizontal))
            case "lv": output = .piece(.special(.vertical))
            case "t1", "t2", "t3": output = .piece(.cookie(Int(token.dropFirst())!))
            case "T1", "T2", "T3": output = .piece(.hazelnut(Int(token.dropFirst())!))
            default: throw BoardError.unsupported(["BornPatterns token [\(token)]"])
            }
            var count = 1, seen = Set<String>()
            for property in settings.isEmpty ? [] : settings[index].children {
                let a = property.attributes, name = a["name"] ?? ""
                guard property.name == "propertyNode", seen.insert(name).inserted else {
                    throw BoardError.unsupported(["BornPatterns duplicate/unknown property"])
                }
                switch name {
                case "CountProperty":
                    guard let n = a["count"].flatMap(Int.init), (1...10000).contains(n) else {
                        throw BoardError.unsupported(["BornPatterns CountProperty"])
                    }
                    count = n
                case "DropChanceProperty":
                    // All bundled properties are 100%; retry/skip semantics for other values are unknown.
                    guard a["value"] == "100" else { throw BoardError.unsupported(["BornPatterns DropChanceProperty"]) }
                case "LevelProperty":
                    guard let n = a["levels"].flatMap(Int.init), (1...3).contains(n),
                          let maximum = a["levelMax"].flatMap(Int.init), n <= maximum else {
                        throw BoardError.unsupported(["BornPatterns LevelProperty"])
                    }
                    switch output {
                    case .piece(.cookie): output = .piece(.cookie(n))
                    case .piece(.hazelnut): output = .piece(.hazelnut(n))
                    default: throw BoardError.unsupported(["BornPatterns LevelProperty for [\(token)]"])
                    }
                case "ColorSetProperty":
                    guard token == "c", a["randomEverySpawn"] == "0",
                          let id = a["colorSetId"].flatMap(Int.init),
                          let set = level.source?.children.first(where: { $0.name == "Level" })?
                            .children.first(where: { $0.name == "colorSets" })?
                            .children.first(where: { $0.attributes["name"] == token }), set.children.indices.contains(id),
                          let value = set.children[id].attributes["val"] else {
                        throw BoardError.unsupported(["BornPatterns ColorSetProperty"])
                    }
                    let values = value.split(separator: ",", omittingEmptySubsequences: false).compactMap { Int($0) }
                    guard values.count == 6, values.allSatisfy({ (0...100).contains($0) }), values.contains(where: { $0 > 0 }) else {
                        throw BoardError.unsupported(["BornPatterns colorSet weights"])
                    }
                    output = .colors(Dictionary(uniqueKeysWithValues: values.enumerated().filter { $0.element > 0 }.map { ($0.offset, $0.element) }))
                default: throw BoardError.unsupported(["BornPatterns property \(name)"])
                }
            }
            units.append(Unit(output: output, count: count))
        }
        return Self(units: units, looped: attrs["isLooped"] == "true")
    }

    static func colors(_ model: Attributes, level: Level) throws -> [Int] {
        let pattern = try reference(model, level: level, section: "ColorChipsPattern")
        let tokens = try tokens(pattern.attributes["str"] ?? "")
        guard model["isLooped"] == "1", tokens.count == 1, tokens[0].hasPrefix("Cs") else {
            throw BoardError.unsupported(["ColorChipsPattern format"])
        }
        let digits = tokens[0].dropFirst(2)
        let colors = digits.compactMap { $0.wholeNumberValue }
        guard colors.count == digits.count, !colors.isEmpty, colors.allSatisfy({ (0...5).contains($0) }), Set(colors).count == colors.count else {
            throw BoardError.unsupported(["ColorChipsPattern palette"])
        }
        return colors
    }
}
