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
    case gem(Int), special(Special), donut, cherry, cookie(Int), hazelnut(Int)
    var canSwap: Bool {
        switch self {
        case .gem, .special, .donut, .cookie, .hazelnut: return true
        case .cherry: return false
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
    public var cookie: Int {
        get { if case .cookie(let strength) = piece { return strength }; return 0 }
        set { piece = newValue > 0 ? .cookie(newValue) : nil }
    }
    public var jelly = 0
    public var boxColor: Int?
    public var platter: Position?
    public var born = false
    public var statue = 0
    public var cookieStack = 0
    public var maker: Position?
    public var carrySpawn = false
    public var ice = 0
    public var chain = 0
    public var mirror = false
    public var carpet = false
    public var exit = false

    var solid: Bool { box > 0 || jelly > 0 || platter != nil || statue > 0 || cookieStack > 0 || maker != nil }
    var held: Bool { solid || ice > 0 || chain > 0 }
    var matchColor: Int? { solid ? nil : piece?.color }
    var canFall: Bool { !solid && !held && piece != .cherry }

    public var artModels: [Attributes] {
        var models: [Attributes] = []
        if carpet { models.append(["modelId": "JELLY"]) }

        if cookie > 0 { models.append(["modelId": "TRASH", "level": String(cookie)]) }
        if case .gem(let color) = piece { models.append(["modelId": "NORMAL", "color": String(color)]) }
        if piece == .donut { models.append(["modelId": "CARRY"]) }
        if piece == .cherry { models.append(["modelId": "CHERRY"]) }
        if case .hazelnut(let strength) = piece { models.append(["modelId": "TRASH_STONE", "level": String(strength)]) }
        if jelly > 0 { models.append(["modelId": "HONEY", "level": String(jelly)]) }
        if box > 0 {
            var model = ["modelId": boxColor == nil ? "BOX" : "COLOR_BOX", "level": String(box)]
            if let color = boxColor { model["color"] = String(color) }
            models.append(model)
        }
        if platter != nil { models.append(["modelId": "TARGET_GEN"]) }
        if maker != nil { models.append(["modelId": "CARRY_GEN"]) }
        if statue > 0 { models.append(["modelId": "STATUE", "level": String(statue)]) }
        if cookieStack > 0 { models.append(["modelId": "COOKIE_BOX", "level": String(cookieStack)]) }
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
    public static let supportedModels: Set<String> = ["NORMAL", "RANDOM_CHIP", "BOX", "TRASH", "ICE", "LOCK",
        "JELLY", "CARRY", "CARRY_EXIT", "CHERRY", "BOMB", "LINE", "LIGHTNING", "BORN", "NONE_CHIP", "FISH", "HONEY", "COLOR_BOX", "TRASH_STONE", "TARGET_GEN", "STATUE", "COOKIE_BOX", "CARRY_GEN", "CARRY_GEN_CELLS"]
    public static let supportedGoals: Set<String> = ["CHIPS", "CELL_JELLY", "BOX", "TRASH", "ICE", "LOCK", "CARRY", "COLLECT_PIGGY", "COLOR_BOX", "TRASHSTONE", "TARGET_GENERATOR", "STATUE"]

    public let level: Level
    public private(set) var cells: [Position: Cell] = [:]
    public private(set) var remaining: Int
    public private(set) var goals: [Progress]
    public private(set) var stalled = false
    public struct CarryMaker {
        public let period: Int
        public let batch: Int
        public var hits = 0
    }
    public private(set) var makers: [Position: CarryMaker] = [:]
    private var pendingCookies = 0
    public private(set) var platters: [Position: Int] = [:]
    private var refillRules: [RefillRule] = []
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
        let unsupportedGoals = Set(level.goals.map(\.type)).subtracting(Self.supportedGoals)
        if !unsupportedGoals.isEmpty { throw BoardError.unsupported(unsupportedGoals.sorted()) }

        refillRules = try RefillRule.read(level)
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
                case "COLOR_BOX":
                    guard let color = model["color"].flatMap(Int.init), (0...5).contains(color) else {
                        throw BoardError.unsupported(["COLOR_BOX color"])
                    }
                    cell.box = strength; cell.boxColor = color
                case "HONEY": cell.jelly = strength
                case "TRASH_STONE": cell.piece = .hazelnut(strength)
                case "STATUE": cell.statue = strength
                case "COOKIE_BOX": cell.cookieStack = strength
                case "CARRY_GEN_CELLS": cell.carrySpawn = true
                case "CARRY_GEN":
                    if let x = model["mainX"].flatMap(Int.init), let y = model["mainY"].flatMap(Int.init) {
                        cell.maker = Position(x, y)
                    } else {
                        guard let period = model["carryGenActivatePer"].flatMap(Int.init), period > 0,
                              let batch = model["carryGenMax"].flatMap(Int.init), batch > 0 else {
                            throw BoardError.unsupported(["CARRY_GEN configuration"])
                        }
                        cell.maker = source.position
                        makers[source.position] = CarryMaker(period: period, batch: batch)
                    }
                case "TARGET_GEN":
                    if let x = model["mainX"].flatMap(Int.init), let y = model["mainY"].flatMap(Int.init) {
                        cell.platter = Position(x, y)
                    } else {
                        cell.platter = source.position
                        platters[source.position] = strength
                    }
                case "FISH": cell.piece = .special(.plane)
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
                case "BORN": cell.born = true
                case "NONE_CHIP": break
                default: throw BoardError.unsupported([model["modelId"] ?? "(missing model ID)"])
                }
            }
            cells[source.position] = cell
        }
        // Legacy XML stores only the top-left anchor; newer files also name the other three cells.
        for anchor in platters.keys.sorted() {
            for p in [anchor, anchor.offset(1, 0), anchor.offset(0, -1), anchor.offset(1, -1)] {
                guard let cell = cells[p], cell.platter == nil || cell.platter == anchor,
                      cell.piece == nil, cell.box == 0, cell.jelly == 0 else {
                    throw BoardError.unsupported(["TARGET_GEN footprint at \(anchor.x),\(anchor.y)"])
                }
                cells[p]?.platter = anchor
            }
        }
        for cell in cells.values {
            if let anchor = cell.platter, platters[anchor] == nil {
                throw BoardError.unsupported(["TARGET_GEN missing anchor"])
            }
        }
        for anchor in makers.keys.sorted() {
            for p in [anchor, anchor.offset(1, 0), anchor.offset(0, -1), anchor.offset(1, -1)] {
                guard let cell = cells[p], cell.maker == nil || cell.maker == anchor,
                      cell.piece == nil, cell.box == 0, cell.jelly == 0, cell.platter == nil else {
                    throw BoardError.unsupported(["CARRY_GEN footprint"])
                }
                cells[p]?.maker = anchor
            }
        }
        if cells.values.contains(where: { cell in cell.maker.map { makers[$0] == nil } ?? false }) {
            throw BoardError.unsupported(["CARRY_GEN missing anchor"])
        }
        // Maker-controlled boards must not also create the same donuts through normal refill.
        if !makers.isEmpty { refillRules.removeAll { $0.goal == "CARRY" } }
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
        if combine(first, second) {
            // Both power-ups have been consumed by the combined effect.
        } else if !specialPositions.isEmpty {
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
        let movable = positions.filter { cells[$0]?.held == false && cells[$0]?.matchColor != nil }
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
        guard let color = color ?? cells[p]?.matchColor else { return false }
        for (dx, dy) in [(1, 0), (0, 1)] {
            var count = 1
            for sign in [-1, 1] {
                var q = p.offset(dx * sign, dy * sign)
                while cells[q]?.matchColor == color {
                    count += 1
                    q = q.offset(dx * sign, dy * sign)
                }
            }
            if count >= 3 { return true }
        }
        for dx in [-1, 1] {
            for dy in [-1, 1] where [p.offset(dx, 0), p.offset(0, dy), p.offset(dx, dy)]
                .allSatisfy({ cells[$0]?.matchColor == color }) { return true }
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
            guard let color = cells[p]?.matchColor else { continue }
            for (dx, dy, special) in [(1, 0, Special.horizontal), (0, 1, .vertical)] {
                if cells[p.offset(-dx, -dy)]?.matchColor == color { continue }
                var q = p.offset(dx, dy), line: Set<Position> = [p]
                while cells[q]?.matchColor == color {
                    line.insert(q)
                    q = q.offset(dx, dy)
                }
                if line.count >= 3 {
                    add(Match(cells: line, longest: line.count, straight: special, square: false, intersection: false))
                }
            }
            let square = [p.offset(1, 0), p.offset(0, 1), p.offset(1, 1)]
            if square.allSatisfy({ cells[$0]?.matchColor == color }) {
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

    /// Returns false unless both cells contain power-ups.
    /// The moved power-up's destination is the lab's combination centre.
    @discardableResult
    mutating func combine(_ first: Position, _ second: Position) -> Bool {
        guard let a = cells[first]?.piece?.power, let b = cells[second]?.piece?.power else { return false }
        resolveCombination(a, b, first: first, second: second)
        return true
    }

    // Separate dispatch lets rules tests exercise generated planes without inventing XML model IDs.
    mutating func resolveCombination(_ a: Special, _ b: Special, first: Position, second: Position) {
        let rockets: Set<Special> = [.horizontal, .vertical]
        let starts: Set<Position> = [first, second]
        let carriesCarpet = starts.contains { cells[$0]?.carpet == true }
        cells[first]?.piece = nil
        cells[second]?.piece = nil
        var footprint = starts
        if a == .rainbow && b == .rainbow {
            // One simultaneous hit per cell, not a sequence of individual explosions.
            apply(Set(positions), spread: carriesCarpet ? Set(positions) : [], isBlast: true)
            return
        } else if a == .rainbow || b == .rainbow {
            let replacement = a == .rainbow ? b : a
            if let color = mostCommonColor() {
                for p in positions where cells[p]?.matchColor == color && cells[p]?.held == false {
                    cells[p]?.piece = .special(replacement)
                    footprint.insert(p)
                }
            }
        } else if a == .plane || b == .plane {
            footprint.formUnion(second.neighbors.filter { cells[$0] != nil })
            let payload = a == .plane ? b : a
            let count = payload == .plane ? 3 : 1
            for _ in 0..<count {
                guard let target = planeTarget(excluding: footprint) else { break }
                footprint.insert(target)
                if payload != .plane {
                    footprint.formUnion(area(of: payload, at: target))
                }
            }
        } else if a == .bomb && b == .bomb {
            footprint.formUnion(positions.filter { abs($0.x - second.x) <= 2 && abs($0.y - second.y) <= 2 })
        } else {
            let width = rockets.contains(a) && rockets.contains(b) ? 0 : 1
            footprint.formUnion(positions.filter {
                abs($0.x - second.x) <= width || abs($0.y - second.y) <= width
            })
        }
        blast(starts, additionalHits: footprint)
    }

    private func mostCommonColor() -> Int? {
        let counts = Dictionary(grouping: cells.values.compactMap { $0.piece?.color }, by: { $0 })
        return counts.keys.sorted().max { counts[$0]!.count < counts[$1]!.count }
    }

    private func planeTarget(excluding excluded: Set<Position>) -> Position? {
        let available = positions.filter { !excluded.contains($0) }
        return available.first { cells[$0]?.solid == true || cells[$0]?.held == true || cells[$0]?.piece == .cherry }
            ?? available.first { cells[$0]?.piece != nil }
    }

    private func area(of special: Special, at p: Position) -> Set<Position> {
        switch special {
        case .horizontal, .vertical:
            let dx = special == .horizontal ? 1 : 0
            var hits: Set<Position> = [p]
            for sign in [-1, 1] {
                let line = positions.filter { q in dx == 1 ? q.y == p.y && (q.x - p.x) * sign > 0
                    : q.x == p.x && (q.y - p.y) * sign > 0 }
                    .sorted { abs($0.x - p.x) + abs($0.y - p.y) < abs($1.x - p.x) + abs($1.y - p.y) }
                for q in line {
                    hits.insert(q)
                    if cells[q]?.cookie ?? 0 > 0 { break }
                }
            }
            return hits
        case .bomb: return Set(positions.filter { abs($0.x - p.x) <= 1 && abs($0.y - p.y) <= 1 })
        default: return [p]
        }
    }

    private mutating func blast(_ starting: Set<Position>, rainbowColors: [Position: Int] = [:],
                                additionalHits: Set<Position> = []) {
        var hits = starting.union(additionalHits), fired = Set<Position>()
        while let p = hits.sorted().first(where: { !fired.contains($0) && cells[$0]?.held == false
                                                  && cells[$0]?.piece?.power != nil }) {
            fired.insert(p)
            guard let special = cells[p]?.piece?.power else { continue }
            switch special {
            case .horizontal, .vertical, .bomb: hits.formUnion(area(of: special, at: p))
            case .plane:
                hits.formUnion(p.neighbors.filter { cells[$0] != nil })
                let target = planeTarget(excluding: hits)
                if let target { hits.insert(target) }
            case .rainbow:
                if let color = rainbowColors[p] ?? mostCommonColor() {
                    hits.formUnion(positions.filter { cells[$0]?.matchColor == color })
                }
            }
        }
        let spread = starting.contains(where: { cells[$0]?.carpet == true }) ? hits : []
        apply(hits, spread: spread, isBlast: true)
    }

    mutating func apply(_ hits: Set<Position>, spread: Set<Position>, isBlast: Bool) {
        let adjacent = Set(hits.flatMap(\.neighbors))
        let matchingColors = Dictionary(uniqueKeysWithValues: hits.compactMap { p in
            cells[p]?.matchColor.map { (p, $0) }
        })
        var hitPlatters = Set<Position>(), hitMakers = Set<Position>()
        for p in hits.union(adjacent).sorted() {
            guard var cell = cells[p] else { continue }
            let direct = hits.contains(p)
            // Only jelly's original settings enable damage from a neighbouring explosion.
            if isBlast && !direct && cell.jelly == 0 { continue }
            if let anchor = cell.maker { hitMakers.insert(anchor); continue }
            if let anchor = cell.platter {
                hitPlatters.insert(anchor)
                continue
            }
            if cell.ice > 0 {
                if direct {
                    cell.ice -= 1
                    if cell.ice == 0 { credit("ICE") }
                }
            } else if cell.chain > 0 {
                if direct {
                    cell.chain -= 1
                    if cell.chain == 0 { credit("LOCK") }
                }
            } else if cell.jelly > 0 {
                cell.jelly -= 1
                if cell.jelly == 0 && cell.piece == .cherry {
                    cell.piece = nil
                    credit("COLLECT_PIGGY")
                }
            } else if cell.box > 0 {
                let matching = cell.boxColor == nil || p.neighbors.contains { matchingColors[$0] == cell.boxColor }
                if isBlast || matching {
                    cell.box -= 1
                    if cell.box == 0 { credit(cell.boxColor == nil ? "BOX" : "COLOR_BOX") }
                }
            } else if cell.statue > 0 {
                if isBlast && direct {
                    cell.statue -= 1
                    if cell.statue == 0 { credit("STATUE") }
                }
            } else if cell.cookieStack > 0 {
                cell.cookieStack -= 1
                if cell.cookieStack == 0 { pendingCookies += 3 }
            } else if cell.cookie > 0 {
                cell.cookie -= 1
                if cell.cookie == 0 { credit("TRASH") }
            } else if case .hazelnut(let strength) = cell.piece {
                if isBlast && direct {
                    cell.piece = strength > 1 ? .hazelnut(strength - 1) : nil
                    if strength == 1 { credit("TRASHSTONE") }
                }
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
        for anchor in hitMakers { makers[anchor]?.hits += 1 }
        for anchor in hitPlatters.sorted() {
            guard let count = platters[anchor], count > 0 else { continue }
            credit("TARGET_GENERATOR")
            if count == 1 {
                platters.removeValue(forKey: anchor)
                for p in positions where cells[p]?.platter == anchor { cells[p]?.platter = nil }
            } else { platters[anchor] = count - 1 }
        }
    }

    mutating func fallAndRefill() {
        // Exits empty a cell again: settle existing pieces before inserting random refill.
        // Every repeated pass collects at least one donut, so this loop is bounded by the board size.
        while true {
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
            let exiting = positions.filter {
                cells[$0]?.exit == true && cells[$0]?.piece == .donut && cells[$0]?.held == false
            }
            if exiting.isEmpty { break }
            for p in exiting {
                cells[p]?.piece = nil
                credit("CARRY")
            }
        }
        for p in positions where cells[p]?.canFall == true && cells[p]?.piece == nil {
            if let generated = generatedPiece(at: p) { cells[p]?.piece = generated }
            else { let color = nextColor(at: p); cells[p]?.piece = .gem(color) }
        }
        releaseGeneratedPieces()
    }

    mutating func releaseGeneratedPieces() {
        for p in positions where pendingCookies > 0 && cells[p]?.held == false && cells[p]?.piece?.color != nil {
            cells[p]?.piece = .cookie(1)
            pendingCookies -= 1
        }
        for anchor in makers.keys.sorted() {
            guard var maker = makers[anchor], maker.hits >= maker.period else { continue }
            let onBoard = cells.values.filter { $0.piece == .donut }.count
            let needed = goals.filter { $0.goal.type == "CARRY" }.reduce(0) { $0 + max(0, $1.goal.maximum - $1.count) } - onBoard
            let eligible = positions.filter { cells[$0]?.carrySpawn == true && cells[$0]?.held == false && cells[$0]?.piece?.color != nil }
            let count = min(maker.batch, max(0, needed), eligible.count)
            guard count > 0 else { continue }
            for p in eligible.prefix(count) { cells[p]?.piece = .donut }
            maker.hits = 0
            makers[anchor] = maker
        }
    }

    private mutating func generatedPiece(at p: Position) -> Piece? {
        var q = p
        var hasSource = false
        while let cell = cells[q], cell.canFall {
            if cell.born { hasSource = true; break }
            q = q.offset(0, 1)
        }
        guard hasSource else { return nil }
        for rule in refillRules {
            let onBoard = cells.values.filter { rule.matches($0.piece) }.count
            let remaining = goals.filter { $0.goal.type == rule.goal }.reduce(0) { $0 + max(0, $1.goal.maximum - $1.count) }
            guard onBoard < rule.maximum && (!rule.limited || onBoard < remaining) else { continue }
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            if Int((seed >> 32) % 100) < rule.chance { return rule.piece }
        }
        return nil
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
