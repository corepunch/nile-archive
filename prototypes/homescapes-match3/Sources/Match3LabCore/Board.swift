import Foundation

public enum Special: String {
    case horizontal, vertical, bomb, plane, rainbow

    public var sprite: String {
        switch self {
        case .horizontal: return "rocket-horizontal"
        case .vertical: return "rocket-vertical"
        case .rainbow: return "rainbow-ball"
        default: return rawValue
        }
    }
}

public enum Piece: Equatable {
    case gem(Int), special(Special), donut, cherry
    var canSwap: Bool {
        switch self {
        case .gem, .special: return true
        case .donut, .cherry: return false
        }
    }

    var color: Int? {
        if case .gem(let color) = self { return color }
        return nil
    }

    var power: Special? {
        if case .special(let special) = self { return special }
        return nil
    }
}

public struct Cell {
    public var piece: Piece?
    public var box = 0
    public var cookie = 0
    public var ice = 0
    public var chain = 0
    public var mirror = false
    public var carpet = false
    public var exit = false

    var solid: Bool { box > 0 || cookie > 0 }
    var held: Bool { ice > 0 || chain > 0 }
    var canFall: Bool { !solid && !held && piece != .cherry }

    public var artModels: [Attributes] {
        var models: [Attributes] = []
        if carpet { models.append(["modelId": "JELLY"]) }
        if box > 0 { models.append(["modelId": "BOX", "level": String(box)]) }
        if cookie > 0 { models.append(["modelId": "TRASH", "level": String(cookie)]) }
        if case .gem(let color) = piece { models.append(["modelId": "NORMAL", "color": String(color)]) }
        if piece == .donut { models.append(["modelId": "CARRY"]) }
        if piece == .cherry { models.append(["modelId": "CHERRY"]) }
        if ice > 0 { models.append(["modelId": "ICE", "level": String(ice)]) }
        if chain > 0 {
            models.append(["modelId": "LOCK", "level": String(chain), "mirror": mirror ? "true" : "false"])
        }
        return models
    }
}

public struct Progress {
    public let goal: Goal
    public var count: Int
}

struct Match {
    var cells: Set<Position>
    var longest: Int
    var straight: Special?
    var square: Bool
    var intersection: Bool

    var reward: Special? {
        if longest >= 5 { return .rainbow }
        if intersection && cells.count >= 5 { return .bomb }
        if longest == 4 { return straight }
        return square ? .plane : nil
    }
}

public struct Board {
    public let level: Level
    public private(set) var cells: [Position: Cell] = [:]
    public private(set) var remaining: Int
    public private(set) var goals: [Progress]
    public private(set) var stalled = false
    private var seed: UInt64
    private let positions: [Position]
    private let weights: [(color: Int, weight: Int)]

    public var won: Bool { goals.allSatisfy { $0.count >= $0.goal.maximum } }
    public var finished: Bool { won || remaining == 0 || stalled }

    public init(level: Level, seedOffset: UInt64 = 0) throws {
        self.level = level
        remaining = level.moves
        goals = level.goals.map { Progress(goal: $0, count: $0.initial) }
        seed = level.seed &+ seedOffset
        positions = level.cells.map(\.position).sorted()
        let weights = level.colors.isEmpty ? Dictionary(uniqueKeysWithValues: (0..<5).map { ($0, 100) }) : level.colors
        self.weights = weights.sorted(by: { $0.key < $1.key }).map { ($0.key, $0.value) }
        let allowedGoals: Set<String> = ["CHIPS", "CELL_JELLY", "BOX", "TRASH", "ICE", "LOCK", "CARRY", "COLLECT_PIGGY"]
        let unsupportedGoals = Set(level.goals.map(\.type)).subtracting(allowedGoals)
        if !unsupportedGoals.isEmpty { throw BoardError.unsupported(unsupportedGoals.sorted()) }

        var random: [Position: [Int]] = [:]
        for source in level.cells {
            var cell = Cell()
            for model in source.models {
                let strength = Int(model["level"] ?? "") ?? 1
                switch model["modelId"] {
                case "NORMAL":
                    if let color = model["color"].flatMap(Int.init), color >= 0 { cell.piece = .gem(color) }
                case "RANDOM_CHIP":
                    if let index = model["id"].flatMap(Int.init), level.patterns.indices.contains(index) {
                        random[source.position] = level.patterns[index]
                    }
                case "BOX": cell.box = strength
                case "TRASH": cell.cookie = strength
                case "ICE": cell.ice = strength
                case "LOCK": cell.chain = strength; cell.mirror = model["mirror"] == "true"
                case "JELLY": cell.carpet = true
                case "CARRY": cell.piece = .donut
                case "CARRY_EXIT": cell.exit = true
                case "CHERRY": cell.piece = .cherry
                case "BOMB": cell.piece = .special(.bomb)
                case "LINE": cell.piece = .special(model["line_orient"] == "0" ? .horizontal : .vertical)
                case "LIGHTNING": cell.piece = .special(.rainbow)
                case "BORN", "NONE_CHIP": break
                default: throw BoardError.unsupported([model["modelId"] ?? "(missing model ID)"])
                }
            }
            cells[source.position] = cell
        }
        for p in positions where cells[p]?.piece == nil && cells[p]?.solid == false {
            let color = nextColor(at: p, restricted: random[p], avoidMatch: true)
            cells[p]?.piece = .gem(color)
        }
        if !won && !hasMove() { stalled = true }
    }

    public mutating func swap(_ first: Position, _ second: Position) -> Bool {
        guard !finished, first.neighbors.contains(second),
              let a = cells[first], let b = cells[second], !a.held, !b.held,
              let left = a.piece, let right = b.piece, left.canSwap, right.canSwap else { return false }
        guard left != right || left.power != nil else { return false }
        cells[first]?.piece = right
        cells[second]?.piece = left
        let specialPositions = [first, second].filter { cells[$0]?.piece?.power != nil }
        let matches = groups().filter { $0.cells.contains(first) || $0.cells.contains(second) }
        if matches.isEmpty && specialPositions.isEmpty {
            cells[first]?.piece = left
            cells[second]?.piece = right
            return false
        }
        remaining -= 1
        if !specialPositions.isEmpty {
            let colors = [first: left.color, second: right.color]
            blast(Set(specialPositions), rainbowColors: colors.compactMapValues { $0 })
        } else {
            resolve(matches, preference: [second, first])
        }
        cascade()
        return true
    }

    public mutating func activate(_ p: Position) -> Bool {
        guard !finished, let cell = cells[p], !cell.held, cell.piece?.power != nil else { return false }
        remaining -= 1
        blast([p])
        cascade()
        return true
    }

    public func hint() -> (Position, Position)? {
        for p in positions {
            guard let a = cells[p], !a.held, let left = a.piece, left.canSwap else { continue }
            if left.power != nil { return (p, p) }
            for q in [p.offset(1, 0), p.offset(0, 1)] {
                guard let b = cells[q], !b.held, let right = b.piece, right.canSwap, left != right else { continue }
                if right.power != nil { return (q, q) }
                var trial = self
                trial.cells[p]?.piece = right
                trial.cells[q]?.piece = left
                if trial.matchesAt(p) || trial.matchesAt(q) { return (p, q) }
            }
        }
        return nil
    }

    private func hasMove() -> Bool { hint() != nil }

    private mutating func reshuffle() {
        let movable = positions.filter { cells[$0]?.held == false && cells[$0]?.piece?.color != nil }
        let old = cells
        for _ in 0..<24 {
            for p in movable { cells[p]?.piece = nil }
            for p in movable {
                let color = nextColor(at: p, avoidMatch: true)
                cells[p]?.piece = .gem(color)
            }
            if hasMove() { return }
        }
        cells = old
        stalled = true
    }

    private mutating func nextColor(at p: Position, restricted: [Int]? = nil, avoidMatch: Bool = false) -> Int {
        let allowed = weights.filter { restricted?.contains($0.color) ?? true }
        let choices = allowed.isEmpty ? weights : allowed
        let legal = avoidMatch ? choices.filter { !matchesAt(p, placing: $0.color) } : choices
        let pool = legal.isEmpty ? choices : legal
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        var value = Int((seed >> 32) % UInt64(pool.reduce(0) { $0 + $1.weight }))
        for option in pool {
            if value < option.weight { return option.color }
            value -= option.weight
        }
        return pool[0].color
    }

    private func matchesAt(_ p: Position, placing color: Int? = nil) -> Bool {
        guard let color = color ?? cells[p]?.piece?.color else { return false }
        for (dx, dy) in [(1, 0), (0, 1)] {
            var count = 1
            for sign in [-1, 1] {
                var q = p.offset(dx * sign, dy * sign)
                while cells[q]?.piece?.color == color {
                    count += 1
                    q = q.offset(dx * sign, dy * sign)
                }
            }
            if count >= 3 { return true }
        }
        for dx in [-1, 1] {
            for dy in [-1, 1] where [p.offset(dx, 0), p.offset(0, dy), p.offset(dx, dy)]
                .allSatisfy({ cells[$0]?.piece?.color == color }) { return true }
        }
        return false
    }

    private func groups() -> [Match] {
        var groups: [Match] = []
        func add(_ match: Match) {
            var merged = match
            let overlaps = groups.filter { !$0.cells.isDisjoint(with: match.cells) }
            groups.removeAll { !$0.cells.isDisjoint(with: match.cells) }
            for other in overlaps {
                if let a = merged.straight, let b = other.straight, a != b { merged.intersection = true }
                merged.intersection = merged.intersection || other.intersection
                if other.longest > merged.longest {
                    merged.longest = other.longest
                    merged.straight = other.straight
                }
                merged.cells.formUnion(other.cells)
                merged.square = merged.square || other.square
            }
            groups.append(merged)
        }

        for p in positions {
            guard let color = cells[p]?.piece?.color else { continue }
            for (dx, dy, special) in [(1, 0, Special.horizontal), (0, 1, .vertical)] {
                if cells[p.offset(-dx, -dy)]?.piece?.color == color { continue }
                var q = p.offset(dx, dy), line: Set<Position> = [p]
                while cells[q]?.piece?.color == color {
                    line.insert(q)
                    q = q.offset(dx, dy)
                }
                if line.count >= 3 {
                    add(Match(cells: line, longest: line.count, straight: special, square: false, intersection: false))
                }
            }
            let square = [p.offset(1, 0), p.offset(0, 1), p.offset(1, 1)]
            if square.allSatisfy({ cells[$0]?.piece?.color == color }) {
                add(Match(cells: Set(square + [p]), longest: 0, straight: nil, square: true, intersection: false))
            }
        }
        return groups
    }

    private mutating func cascade() {
        for _ in 0..<64 {
            fallAndRefill()
            if won { return }
            let next = groups()
            if next.isEmpty {
                if remaining > 0 && !hasMove() { reshuffle() }
                return
            }
            resolve(next)
        }
        stalled = true
    }

    private mutating func resolve(_ matches: [Match], preference: [Position] = []) {
        var hits = Set<Position>(), rewards: [Position: Special] = [:], spread = Set<Position>()
        for match in matches {
            hits.formUnion(match.cells)
            if match.cells.contains(where: { cells[$0]?.carpet == true }) { spread.formUnion(match.cells) }
            guard let reward = match.reward else { continue }
            let candidates = preference + match.cells.sorted()
            if let p = candidates.first(where: { match.cells.contains($0) && cells[$0]?.held == false }) {
                rewards[p] = reward
            }
        }
        apply(hits, spread: spread, isBlast: false)
        for (p, reward) in rewards where cells[p]?.piece == nil { cells[p]?.piece = .special(reward) }
    }

    private mutating func blast(_ starting: Set<Position>, rainbowColors: [Position: Int] = [:]) {
        var hits = starting, fired = Set<Position>()
        while let p = hits.sorted().first(where: { !fired.contains($0) && cells[$0]?.held == false
                                                  && cells[$0]?.piece?.power != nil }) {
            fired.insert(p)
            guard let special = cells[p]?.piece?.power else { continue }
            switch special {
            case .horizontal: hits.formUnion(positions.filter { $0.y == p.y })
            case .vertical: hits.formUnion(positions.filter { $0.x == p.x })
            case .bomb: hits.formUnion(positions.filter { abs($0.x - p.x) <= 1 && abs($0.y - p.y) <= 1 })
            case .plane:
                hits.formUnion(p.neighbors.filter { cells[$0] != nil })
                let target = positions.first { q in
                    !hits.contains(q) && (cells[q]?.solid == true || cells[q]?.held == true || cells[q]?.piece == .cherry)
                } ?? positions.first { !hits.contains($0) && cells[$0]?.piece?.color != nil }
                if let target { hits.insert(target) }
            case .rainbow:
                let counts = Dictionary(grouping: cells.values.compactMap { $0.piece?.color }, by: { $0 })
                if let color = rainbowColors[p] ?? counts.keys.sorted().max(by: { counts[$0]!.count < counts[$1]!.count }) {
                    hits.formUnion(positions.filter { cells[$0]?.piece?.color == color })
                }
            }
        }
        let spread = starting.contains(where: { cells[$0]?.carpet == true }) ? hits : []
        apply(hits, spread: spread, isBlast: true)
    }

    private mutating func apply(_ hits: Set<Position>, spread: Set<Position>, isBlast: Bool) {
        let adjacent = Set(hits.flatMap(\.neighbors))
        for p in hits.union(adjacent).sorted() {
            guard var cell = cells[p] else { continue }
            let direct = hits.contains(p)
            if cell.box > 0 {
                cell.box -= 1
                if cell.box == 0 { credit("BOX") }
            } else if cell.cookie > 0 {
                cell.cookie -= 1
                if cell.cookie == 0 { credit("TRASH") }
            } else if cell.ice > 0 && (direct || isBlast) {
                cell.ice -= 1
                if cell.ice == 0 { credit("ICE") }
            } else if cell.chain > 0 && (direct || isBlast) {
                cell.chain -= 1
                if cell.chain == 0 { credit("LOCK") }
            } else if cell.piece == .cherry {
                cell.piece = nil
                credit("COLLECT_PIGGY")
            } else if direct && cell.piece != .donut {
                if let color = cell.piece?.color { credit("CHIPS", subtype: String(color)) }
                cell.piece = nil
            }
            if spread.contains(p) && !cell.carpet && !cell.solid {
                cell.carpet = true
                credit("CELL_JELLY")
            }
            cells[p] = cell
        }
    }

    private mutating func fallAndRefill() {
        // Iterate bottom first so every destination is resolved before its source.
        for p in positions {
            guard cells[p]?.canFall == true, cells[p]?.piece == nil else { continue }
            var q = p.offset(0, 1)
            while let source = cells[q], source.canFall {
                if let piece = source.piece {
                    cells[p]?.piece = piece
                    cells[q]?.piece = nil
                    break
                }
                q = q.offset(0, 1)
            }
        }
        for p in positions where cells[p]?.exit == true && cells[p]?.piece == .donut && cells[p]?.held == false {
            cells[p]?.piece = nil
            credit("CARRY")
        }
        for p in positions where cells[p]?.canFall == true && cells[p]?.piece == nil {
            let color = nextColor(at: p)
            cells[p]?.piece = .gem(color)
        }
    }

    private mutating func credit(_ type: String, subtype: String = "") {
        for i in goals.indices where goals[i].goal.type == type && goals[i].goal.subtype == subtype {
            goals[i].count = min(goals[i].goal.maximum, goals[i].count + 1)
        }
    }
}

enum BoardError: LocalizedError {
    case unsupported([String])
    var errorDescription: String? {
        switch self {
        case .unsupported(let ids): return "Rules unavailable for \(ids.joined(separator: ", "))."
        }
    }
}
