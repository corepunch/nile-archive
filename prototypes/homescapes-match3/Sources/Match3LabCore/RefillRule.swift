import Foundation

struct RefillRule {
    let goal: String
    let piece: Piece
    let chance: Int
    let maximum: Int
    let limited: Bool
    let sources: Set<Position>

    func matches(_ other: Piece?) -> Bool {
        switch (piece, other) {
        case (.donut, .donut), (.cookie, .cookie), (.hazelnut, .hazelnut): return true
        default: return false
        }
    }

    static func read(_ level: Level) throws -> [Self] {
        guard let source = level.source?.children.first(where: { $0.name == "Level" }) else { return [] }
        let targets = source.children.first { $0.name == "Targets" }?.children ?? []
        var result: [Self] = []
        for (section, goal) in [("CarryChips", "CARRY"), ("TrashChips", "TRASH"), ("TrashStoneChips", "TRASHSTONE")] {
            guard let config = source.children.first(where: { $0.name == section }) else { continue }
            var attributes = config.attributes
            if let target = targets.first(where: { $0.attributes["type"] == goal }) {
                for param in target.children where param.name == "param" {
                    if param.attributes["name"] == "chance_born" { attributes["chance"] = param.attributes["value"] }
                    if param.attributes["name"] == "max_on_field" { attributes["max"] = param.attributes["value"] }
                }
            }
            let initialDonuts = level.cells.filter { $0.models.contains { $0["modelId"] == "CARRY" } }.count
            // The XML omits these defaults in legacy CarryChips records; retain the starting population.
            let defaultChance = section == "CarryChips" ? 100 : 0
            let defaultMax = section == "CarryChips" ? max(1, initialDonuts) : 0
            guard let chance = Int(attributes["chance"] ?? String(defaultChance)), (0...100).contains(chance),
                  let maximum = Int(attributes["max"] ?? String(defaultMax)), maximum >= 0,
                  let strength = Int(attributes["level"] ?? "1"), (1...3).contains(strength) else {
                throw BoardError.unsupported([section + " refill configuration"])
            }
            let piece: Piece = section == "CarryChips" ? .donut : section == "TrashChips" ? .cookie(strength) : .hazelnut(strength)
            var sources = Set<Position>()
            for point in config.children where point.name == "b" {
                guard let x = point.attributes["x"].flatMap(Int.init), let y = point.attributes["y"].flatMap(Int.init) else {
                    throw BoardError.unsupported([section + " source coordinate"])
                }
                sources.insert(Position(x, y))
            }
            result.append(Self(goal: goal, piece: piece, chance: chance, maximum: maximum,
                               limited: attributes["gen_limitation"] == "true", sources: sources))
        }
        return result
    }
}
