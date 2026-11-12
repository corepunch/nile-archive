import AppKit
import SpriteKit
import Match3LabCore

let sampleIDs = ["st0004", "st0008", "st0011", "st0016", "st0022", "st0031", "st0131", "st0136"]

struct LabFiles {
    let root: URL
    let mappings: [String: SpriteMapping]
    let levels: [Level]

    init(root: URL) throws {
        self.root = root
        let mapURL = root.appendingPathComponent("tools/homescapes-reference/model_sprites.json")
        mappings = try JSONDecoder().decode([String: SpriteMapping].self, from: Data(contentsOf: mapURL))
        let directory = root.appendingPathComponent("reference/homescapes-analysis/decoded/match3levels/Match3/Levels/base/st")
        levels = try sampleIDs.map { try Level.load(directory.appendingPathComponent($0 + ".xml")) }
    }

    func spriteURL(_ id: String) -> URL {
        root.appendingPathComponent("reference/homescapes-analysis/board-art/sprites/\(id).png")
    }
}

final class BoardScene: SKScene {
    var board: Board
    let files: LabFiles
    var onChange: (() -> Void)?
    var selected: Position?
    var suggestion: Set<Position> = []
    private var downAt: Position?
    private var tile: CGFloat = 48
    private var origin = CGPoint.zero
    private var textures: [String: SKTexture] = [:]

    init(board: Board, files: LabFiles) {
        self.board = board
        self.files = files
        super.init(size: CGSize(width: 720, height: 590))
        scaleMode = .resizeFill
        backgroundColor = NSColor(red: 0.13, green: 0.16, blue: 0.23, alpha: 1)
    }

    required init?(coder: NSCoder) { nil }

    override func didMove(to view: SKView) { drawBoard() }
    override func didChangeSize(_ oldSize: CGSize) { drawBoard() }

    func reset(to board: Board) {
        self.board = board
        selected = nil
        suggestion = []
        drawBoard()
        onChange?()
    }

    func showHint() {
        if let (first, second) = board.hint() { suggestion = [first, second] }
        drawBoard()
    }

    override func mouseDown(with event: NSEvent) {
        downAt = position(at: event.location(in: self))
    }

    override func mouseUp(with event: NSEvent) {
        defer { downAt = nil }
        guard let first = downAt, let second = position(at: event.location(in: self)), !board.finished else {
            return
        }
        suggestion = []
        if first != second {
            _ = board.swap(first, second)
            selected = nil
        } else if let previous = selected {
            if previous == second {
                _ = board.activate(second)
                selected = nil
            } else {
                let valid = board.swap(previous, second)
                selected = valid ? nil : second
            }
        } else {
            selected = second
        }
        drawBoard()
        onChange?()
    }

    private func position(at point: CGPoint) -> Position? {
        let p = Position(Int(floor((point.x - origin.x) / tile)), Int(floor((point.y - origin.y) / tile)))
        return board.cells[p] == nil ? nil : p
    }

    private func addSprite(_ id: String, at point: CGPoint, layer: String) {
        let texture: SKTexture
        if let cached = textures[id] {
            texture = cached
        } else if let image = NSImage(contentsOf: files.spriteURL(id)) {
            texture = SKTexture(image: image)
            textures[id] = texture
        } else {
            let marker = SKLabelNode(text: "?")
            marker.position = point
            marker.verticalAlignmentMode = .center
            marker.zPosition = 2
            addChild(marker)
            return
        }
        let node = SKSpriteNode(texture: texture)
        let width = tile * (layer == "piece" ? 0.87 : 0.99)
        let source = texture.size()
        let scale = min(width / source.width, width / source.height)
        node.size = CGSize(width: source.width * scale, height: source.height * scale)
        node.position = point
        if id == "ice-1" { node.position.y -= tile * 0.14 }
        node.zPosition = layer == "ground" ? 1 : layer == "overlay" ? 3 : 2
        addChild(node)
    }

    private func drawBoard() {
        removeAllChildren()
        let keys = board.cells.keys
        guard let minX = keys.map(\.x).min(), let maxX = keys.map(\.x).max(),
              let minY = keys.map(\.y).min(), let maxY = keys.map(\.y).max() else { return }
        let columns = CGFloat(maxX - minX + 1), rows = CGFloat(maxY - minY + 1)
        tile = max(1, min((size.width - 28) / columns, (size.height - 24) / rows))
        origin = CGPoint(x: (size.width - columns * tile) / 2 - CGFloat(minX) * tile,
                         y: (size.height - rows * tile) / 2 - CGFloat(minY) * tile)
        for p in keys.sorted() {
            guard let cell = board.cells[p] else { continue }
            let point = CGPoint(x: origin.x + (CGFloat(p.x) + 0.5) * tile,
                                y: origin.y + (CGFloat(p.y) + 0.5) * tile)
            let background = SKShapeNode(rectOf: CGSize(width: tile * 0.96, height: tile * 0.96),
                                         cornerRadius: tile * 0.10)
            background.position = point
            background.fillColor = NSColor(red: 0.29, green: 0.34, blue: 0.45, alpha: 1)
            background.strokeColor = .clear
            addChild(background)
            for model in cell.artModels {
                if let mapping = files.mappings[model["modelId"] ?? ""], let id = mapping.resolve(model) {
                    addSprite(id, at: point, layer: mapping.layer)
                }
            }
            if case .special(let special) = cell.piece { addSprite(special.sprite, at: point, layer: "piece") }
            if cell.exit {
                let arrow = SKLabelNode(text: "↓")
                arrow.fontSize = tile * 0.25
                arrow.fontColor = .white
                arrow.position = CGPoint(x: point.x, y: point.y - tile * 0.39)
                arrow.zPosition = 4
                addChild(arrow)
            }
            if selected == p || suggestion.contains(p) {
                let outline = SKShapeNode(rectOf: CGSize(width: tile * 0.92, height: tile * 0.92),
                                          cornerRadius: tile * 0.10)
                outline.position = point
                outline.strokeColor = selected == p ? .systemYellow : .systemTeal
                outline.lineWidth = 3
                outline.zPosition = 5
                addChild(outline)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let files: LabFiles
    let scene: BoardScene
    var window: NSWindow?
    let picker = NSPopUpButton()
    let moves = NSTextField(labelWithString: "")
    let objectives = NSTextField(wrappingLabelWithString: "")
    let message = NSTextField(labelWithString: "")
    var seedOffset: UInt64 = 0

    init(files: LabFiles) throws {
        self.files = files
        scene = BoardScene(board: try Board(level: files.levels[0]), files: files)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 760, height: 720),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "Homescapes Match-3 Lab"
        window.minSize = NSSize(width: 480, height: 510)
        window.center()

        picker.addItems(withTitles: files.levels.map(\.id))
        picker.target = self
        picker.action = #selector(changeLevel)
        let reset = NSButton(title: "Restart", target: self, action: #selector(resetBoard))
        let hint = NSButton(title: "Hint", target: self, action: #selector(showHint))
        let seed = NSButton(title: "New seed", target: self, action: #selector(changeSeed))
        moves.font = .monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        let toolbar = NSStackView(views: [picker, reset, seed, hint, moves])
        toolbar.spacing = 10
        toolbar.alignment = .centerY

        let skView = SKView()
        skView.presentScene(scene)
        skView.setContentHuggingPriority(.defaultLow, for: .vertical)
        skView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        objectives.font = .systemFont(ofSize: 13, weight: .medium)
        message.font = .systemFont(ofSize: 12)
        message.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [toolbar, objectives, skView, message])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        guard let content = window.contentView else { return }
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -14),
            objectives.widthAnchor.constraint(equalTo: stack.widthAnchor),
            skView.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        scene.onChange = { [weak self] in self?.refresh() }
        refresh()
        self.window = window
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Homescapes Lab", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)
        NSApp.mainMenu = menu
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    @objc private func changeLevel() { seedOffset = 0; resetBoard() }
    @objc private func changeSeed() { seedOffset &+= 1; resetBoard() }
    @objc private func showHint() { scene.showHint() }
    @objc private func resetBoard() {
        do {
            scene.reset(to: try Board(level: files.levels[picker.indexOfSelectedItem], seedOffset: seedOffset))
        } catch {
            message.stringValue = error.localizedDescription
        }
    }

    private func refresh() {
        let board = scene.board
        moves.stringValue = "\(board.remaining) moves"
        let names = ["CHIPS": "Gems", "CELL_JELLY": "Carpet", "CARRY": "Donuts", "TRASH": "Cookies",
                     "BOX": "Boxes", "ICE": "Ice", "LOCK": "Chains", "COLLECT_PIGGY": "Cherries"]
        let colors = ["Red", "Yellow", "Green", "Blue", "Pink", "Cyan"]
        objectives.stringValue = board.goals.map { progress in
            let goal = progress.goal
            var label = names[goal.type] ?? goal.type
            if goal.type == "CHIPS", let index = Int(goal.subtype), colors.indices.contains(index) {
                label = colors[index] + " gems"
            }
            return "\(label) \(progress.count)/\(goal.maximum)"
        }.joined(separator: "     •     ")
        if board.won { message.stringValue = "Goals complete. Choose another board or restart." }
        else if board.remaining == 0 { message.stringValue = "Out of moves. Restart or try a new seed." }
        else if board.stalled { message.stringValue = "No moves available. Try a new seed." }
        else { message.stringValue = "Drag or click two adjacent pieces. Click a special twice to fire it. Seed offset \(seedOffset)." }
    }
}

let arguments = CommandLine.arguments
let root = arguments.firstIndex(of: "--root").flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
    ?? FileManager.default.currentDirectoryPath
do {
    let files = try LabFiles(root: URL(fileURLWithPath: root, isDirectory: true))
    if arguments.contains("--check") {
        for level in files.levels {
            var board = try Board(level: level)
            for cell in board.cells.values {
                let ids = cell.artModels.compactMap { files.mappings[$0["modelId"] ?? ""]?.resolve($0) }
                for id in ids where NSImage(contentsOf: files.spriteURL(id)) == nil {
                    throw CocoaError(.fileReadCorruptFile, userInfo: [NSFilePathErrorKey: files.spriteURL(id).path])
                }
            }
            var turns = 0
            while turns < 12, !board.finished, let (a, b) = board.hint() {
                guard a == b ? board.activate(a) : board.swap(a, b) else {
                    throw CocoaError(.validationMultipleErrors, userInfo: [NSLocalizedDescriptionKey: "Invalid hint on \(level.id)"])
                }
                turns += 1
            }
            guard turns > 0 else {
                throw CocoaError(.validationMultipleErrors, userInfo: [NSLocalizedDescriptionKey: "No playable moves on \(level.id)"])
            }
            print("\(level.id)  \(level.cells.count) cells  \(turns) verified turns")
        }
    } else {
        let delegate = try AppDelegate(files: files)
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
} catch {
    fputs("Homescapes Match-3 Lab: \(error.localizedDescription)\n", stderr)
    exit(1)
}
