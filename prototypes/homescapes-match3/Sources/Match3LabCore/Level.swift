import Foundation

public struct Position: Hashable, Comparable {
    public let x: Int
    public let y: Int

    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.y, lhs.x) < (rhs.y, rhs.x)
    }

    public func offset(_ dx: Int, _ dy: Int) -> Self { Self(x + dx, y + dy) }

    var neighbors: [Self] {
        [offset(-1, 0), offset(1, 0), offset(0, -1), offset(0, 1)]
    }
}

public typealias Attributes = [String: String]

public struct SourceCell {
    public let position: Position
    public let models: [Attributes]
}

public struct Goal {
    public let type: String
    public let subtype: String
    public let initial: Int
    public let maximum: Int
}

public struct Level {
    public let id: String
    public let seed: UInt64
    public let moves: Int
    public let cells: [SourceCell]
    public let goals: [Goal]
    public let colors: [Int: Int]
    public let patterns: [[Int]]

    public static func load(_ url: URL) throws -> Self {
        let parser = XMLParser(data: try Data(contentsOf: url))
        let reader = LevelReader()
        parser.delegate = reader
        guard parser.parse(), let attrs = reader.level, let moves = attrs["movesLimitLocal"].flatMap(Int.init),
              moves > 0, !reader.cells.isEmpty,
              Set(reader.cells.map(\.position)).count == reader.cells.count else {
            throw LevelError.invalid(url.lastPathComponent)
        }
        return Self(id: url.deletingPathExtension().lastPathComponent,
                    seed: UInt64(attrs["LevelLocalSeed"] ?? "") ?? 0, moves: moves,
                    cells: reader.cells, goals: reader.goals, colors: reader.colors, patterns: reader.patterns)
    }
}

enum LevelError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        switch self {
        case .invalid(let name): return "Cannot read the board definition in \(name)."
        }
    }
}

private final class LevelReader: NSObject, XMLParserDelegate {
    var level: Attributes?
    var cells: [SourceCell] = []
    var goals: [Goal] = []
    var colors: [Int: Int] = [:]
    var patterns: [[Int]] = []
    private var cell: Position?
    private var models: [Attributes] = []
    private var stack: [String] = []

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                qualifiedName: String?, attributes: Attributes) {
        let parent = stack.last
        stack.append(name)
        switch (parent, name) {
        case ("root", "Level"): level = attributes
        case ("Line", "Cell"):
            if let x = attributes["x"].flatMap(Int.init), let y = attributes["y"].flatMap(Int.init) {
                cell = Position(x, y)
            }
        case ("Cell", "Model"): models.append(attributes)
        case ("Targets", "target"):
            if let type = attributes["type"], let maximum = attributes["max"].flatMap(Int.init) {
                goals.append(Goal(type: type, subtype: attributes["subtype"] ?? "",
                                  initial: attributes["current"].flatMap(Int.init) ?? 0, maximum: maximum))
            }
        case ("ChipSet", "chip"):
            if let number = attributes["number"].flatMap(Int.init),
               let weight = attributes["probability"].flatMap(Int.init), weight > 0 {
                colors[number] = weight
            }
        case ("RandomChips", "pattern"): patterns.append([])
        case ("pattern", "color"):
            if !patterns.isEmpty, let color = attributes["id"].flatMap(Int.init) {
                patterns[patterns.count - 1].append(color)
            }
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        if name == "Cell" {
            if let cell { cells.append(SourceCell(position: cell, models: models)) }
            cell = nil
            models.removeAll(keepingCapacity: true)
        }
        stack.removeLast()
    }
}

public struct SpriteMapping: Decodable {
    public let layer: String
    public let status: String?
    private let field: String?
    private let variants: [String: String]?
    private let sprite: String?

    public func resolve(_ model: Attributes) -> String? {
        guard let field, let value = model[field] else { return sprite }
        if model["mirror"] == "true", let mirrored = variants?[value + ":mirror"] { return mirrored }
        return variants?[value] ?? sprite
    }
}
