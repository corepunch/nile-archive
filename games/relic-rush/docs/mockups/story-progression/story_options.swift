// Relic Rush concept reel. Run from the repository root on macOS:
// swiftc -O games/relic-rush/docs/mockups/story-progression/story_options.swift -o /tmp/story-options
// /tmp/story-options /tmp/relic-rush-story
import AppKit
import AVFoundation
import CoreText
import ImageIO
import UniformTypeIdentifiers

let width = 1440
let height = 900
let fps: Int32 = 24
let intro = 7.0
let segment = 14.0
let outro = 8.0
let starts = [0.0, 3.45, 7.4, 11.25]
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let game = URL(fileURLWithPath: "games/relic-rush", isDirectory: true)

func color(_ rgb: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(rgb >> 16 & 255) / 255, green: CGFloat(rgb >> 8 & 255) / 255,
            blue: CGFloat(rgb & 255) / 255, alpha: alpha)
}

struct Option {
    let title: String
    let question: String
    let premise: [String]
    let tint: UInt32
    let tradeoff: String
    let speaker: String
    let portrait: String
    let listener: String
    let replyName: String
    let reply: String
    let hook: [String]
    let action: String
    let asset: String
    let gate: String
    let payoff: String
    let next: String
    let stages: [(String, String)]
}

let options: [Option] = [
    .init(title: "Quest first", question: "What did Mara ask me to do?",
          premise: ["Give each quest a job someone on the island needs done.",
                    "Give every first clear a small story payoff of its own."],
          tint: 0xf0c777, tradeoff: "Strongest fit: a reason to play now and a reason to rebuild.",
          speaker: "Mara", portrait: "mara", listener: "elena", replyName: "Elena",
          reply: "Then someone is listening.",
          hook: ["That light blinked back."],
          action: "Restore the spring well", asset: "well",
          gate: "Quest complete", payoff: "A chart was tucked in the pump cover.", next: "The lower quay",
          stages: [("A light answers", "Mara reacts before the results screen."),
                   ("Finish Mara’s request", "Use the board payout to finish the spring well."),
                   ("Open the next scene", "The repair earns 4 points and reveals a hidden tide chart."),
                   ("Follow the chart", "A new quest starts at the lower quay.")]),
    .init(title: "Scene by scene", question: "Where does the evidence lead?",
          premise: ["Make each board a named location in the investigation.",
                    "The clue and decoration score open the next location."],
          tint: 0x84d9ce, tradeoff: "Clear trail of clues. A point check at every stop can slow it down.",
          speaker: "Elena", portrait: "elena", listener: "mara", replyName: "Mara",
          reply: "I can get us there at low tide.",
          hook: ["This chart marks a quay", "below the waterline."],
          action: "Restore the map room", asset: "map_room",
          gate: "Clue + 12 decoration points", payoff: "The next site appears on the chart.", next: "The lower quay",
          stages: [("A site yields a clue", "Elena identifies the next stop as soon as the board clears."),
                   ("Fund the next expedition", "Spend the payout restoring the map room."),
                   ("Check both requirements", "The clue is found and the island reaches 12 points."),
                   ("Travel to the next site", "The next investigation scene is the next playable board.")]),
    .init(title: "The living island", question: "What changes when I build here?",
          premise: ["Let the rebuilt island lead the investigation.",
                    "Choose what to restore; the next clue lives on the map."],
          tint: 0xaedc90, tradeoff: "Most freedom to build. Place key clues at fixed landmarks.",
          speaker: "Mara", portrait: "mara", listener: "elena", replyName: "Elena",
          reply: "Show me where you saw it.",
          hook: ["The light came from", "beneath our camp."],
          action: "Restore the camp", asset: "camp",
          gate: "New island hotspot", payoff: "A second flash lights the old stairs.", next: "The steps below camp",
          stages: [("A flash under camp", "Mara gives the player a place to look on the island."),
                   ("Choose what to restore", "The camp and the spring well both earn 4 points."),
                   ("The island answers", "At 12 points, tap the signal at a fixed landmark."),
                   ("Enter from the map", "The newly lit stairs lead straight to the next board.")]),
    .init(title: "The evidence table", question: "What do I want to inspect?",
          premise: ["Let the player handle one piece of evidence after a win.",
                    "Then use the rebuilt archive to compare it with the record."],
          tint: 0xeab48d, tradeoff: "More agency in the mystery. Save the evidence table for key reveals.",
          speaker: "Elena", portrait: "elena", listener: "tomas", replyName: "Tomas",
          reply: "That was stamped on the island.",
          hook: ["Tomas, this tag isn’t ours."],
          action: "Restore the archive", asset: "archive",
          gate: "Compare two records", payoff: "The stamp matches a missing boat.", next: "The missing boat",
          stages: [("Pick a detail to inspect", "Turn the tag over and ask Tomas about the stamp."),
                   ("Build a place for the record", "Use the payout to reopen the island archive."),
                   ("Put two clues together", "The points open a comparison with the dock register."),
                   ("Test the new theory", "The missing boat gives the next board its purpose.")]),
    .init(title: "People first", question: "Who do I trust with this?",
          premise: ["Let a character’s response change the expedition.",
                    "Choose who sees the clue first; both routes meet at the quay."],
          tint: 0xe8a4af, tradeoff: "Most character interaction. Keep the choices short and consequential.",
          speaker: "Adrian", portrait: "adrian", listener: "mara", replyName: "Mara",
          reply: "Then why were you hiding it?",
          hook: ["I’ve seen that signal before."],
          action: "Restore the lookout", asset: "map_room",
          gate: "Ask Mara or Adrian", payoff: "Mara offers to guide you below.", next: "The lower quay",
          stages: [("Adrian gives himself away", "Mara calls him on it before the reward screen."),
                   ("Give them a place to talk", "Spend the board payout restoring the lookout."),
                   ("Choose who to ask", "The scene opens at 12 points; pick who helps you."),
                   ("Take Mara with you", "Your choice changes the next scene’s companion.")])
]
let duration = intro + Double(options.count) * segment + outro

func load(_ relative: String) throws -> CGImage {
    let url = game.appendingPathComponent(relative)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw ReelError.message("Could not read \(url.path). Run from the repository root.")
    }
    return image
}

enum ReelError: Error {
    case message(String)
}

struct Art {
    let island: CGImage
    let board: CGImage
    let town: CGImage
    let portraits: [String: CGImage]
    let buildings: [String: CGImage]
    init() throws {
        island = try load("data/island.jpg")
        board = try load("docs/screenshots/hex-first.jpg")
        town = try load("docs/screenshots/phone-island.jpg")
        portraits = try Dictionary(uniqueKeysWithValues: ["mara", "elena", "tomas", "adrian"].map {
            ($0, try load("data/characters/\($0).png"))
        })
        buildings = try Dictionary(uniqueKeysWithValues: ["well", "map_room", "camp", "archive"].map {
            ($0, try load("data/buildings/\($0).png"))
        })
    }
}

let ink: UInt32 = 0xf8f0df
let muted: UInt32 = 0xb3beb0
let gold: UInt32 = 0xf0c777
let panel: UInt32 = 0x172822
let dark: UInt32 = 0x0a1715
let light: UInt32 = 0xfff4da
let darkInk: UInt32 = 0x22332a

func unit(_ x: Double) -> Double { min(1, max(0, x)) }
func ease(_ x: Double) -> Double { let a = unit(x); return a * a * (3 - 2 * a) }
func ramp(_ t: Double, _ start: Double, _ duration: Double) -> Double {
    ease((t - start) / duration)
}

final class Canvas {
    let c: CGContext
    let art: Art
    init(_ c: CGContext, _ art: Art) {
        self.c = c
        self.art = art
        c.translateBy(x: 0, y: CGFloat(height))
        c.scaleBy(x: 1, y: -1)
    }

    func box(_ r: CGRect, _ rgb: UInt32, _ alpha: CGFloat = 1, radius: CGFloat = 0,
             border: UInt32? = nil, borderAlpha: CGFloat = 1) {
        let path = CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
        c.addPath(path)
        c.setFillColor(color(rgb, alpha))
        c.fillPath()
        if let border {
            c.addPath(path)
            c.setStrokeColor(color(border, borderAlpha))
            c.setLineWidth(1)
            c.strokePath()
        }
    }

    func line(_ a: CGPoint, _ b: CGPoint, _ rgb: UInt32, _ alpha: CGFloat = 1, _ w: CGFloat = 1) {
        c.setStrokeColor(color(rgb, alpha))
        c.setLineWidth(w)
        c.setLineCap(.round)
        c.move(to: a)
        c.addLine(to: b)
        c.strokePath()
    }

    func ring(_ x: Double, _ y: Double, _ radius: Double, _ rgb: UInt32, _ alpha: Double) {
        c.setStrokeColor(color(rgb, alpha))
        c.setLineWidth(1.6)
        c.strokeEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
    }

    func gradient(_ rect: CGRect, _ top: CGColor, _ bottom: CGColor) {
        let g = CGGradient(colorsSpace: space, colors: [top, bottom] as CFArray, locations: [0, 1])!
        c.saveGState()
        c.clip(to: rect)
        c.drawLinearGradient(g, start: CGPoint(x: rect.midX, y: rect.minY),
                             end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
        c.restoreGState()
    }

    func label(_ s: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat,
               _ rgb: UInt32 = ink, font: String = "HelveticaNeue-Medium", align: Double = 0,
               tracking: CGFloat = 0, alpha: CGFloat = 1) {
        let attr = NSAttributedString(string: s, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName(font as CFString, size, nil),
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color(rgb, alpha),
            .kern: tracking
        ])
        let l = CTLineCreateWithAttributedString(attr)
        let w = CTLineGetTypographicBounds(l, nil, nil, nil)
        c.saveGState()
        c.translateBy(x: x - w * align, y: y + size)
        c.scaleBy(x: 1, y: -1)
        c.textMatrix = .identity
        c.textPosition = .zero
        CTLineDraw(l, c)
        c.restoreGState()
    }

    func kicker(_ s: String, _ x: Double, _ y: Double, _ rgb: UInt32 = gold, size: Double = 15) {
        label(s, x, y, size, rgb, font: "HelveticaNeue-Bold", tracking: 2.2)
    }

    func title(_ s: String, _ x: Double, _ y: Double, _ size: Double, _ rgb: UInt32 = ink) {
        label(s, x, y, size, rgb, font: "Georgia-Bold")
    }

    func picture(_ image: CGImage, _ rect: CGRect, fit: Bool = false, alpha: Double = 1) {
        let sx = rect.width / Double(image.width), sy = rect.height / Double(image.height)
        let scale = fit ? min(sx, sy) : max(sx, sy)
        let w = Double(image.width) * scale, h = Double(image.height) * scale
        c.saveGState()
        c.clip(to: rect)
        c.setAlpha(alpha)
        c.translateBy(x: rect.midX - w / 2, y: rect.midY + h / 2)
        c.scaleBy(x: 1, y: -1)
        c.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        c.restoreGState()
    }

    func backdrop(_ tint: UInt32, _ t: Double) {
        box(CGRect(x: 0, y: 0, width: width, height: height), dark)
        picture(art.island, CGRect(x: 706, y: -108, width: 760, height: 1120), alpha: 0.32)
        let veil = CGGradient(colorsSpace: space, colors: [color(dark), color(dark, 0.15)] as CFArray,
                              locations: [0.42, 1])!
        c.drawLinearGradient(veil, start: .zero, end: CGPoint(x: 1440, y: 0), options: [])
        gradient(CGRect(x: 0, y: 0, width: width, height: height), color(dark, 0.03), color(dark, 0.86))
        for n in 0..<5 {
            ring(1152, 440, 269 + Double(n) * 30, tint, 0.085)
        }
        kicker("RELIC RUSH", 76, 43, gold, size: 16)
        line(CGPoint(x: 222, y: 56), CGPoint(x: 252, y: 56), 0x718476)
        kicker("CAMPAIGN MOTION STUDY", 273, 44, muted, size: 13)
        line(CGPoint(x: 76, y: 833), CGPoint(x: 1364, y: 833), 0x718476, 0.45)
        line(CGPoint(x: 76, y: 833), CGPoint(x: 76 + 1288 * t / duration, y: 833), tint, 0.9, 2)
        kicker("THE LOST VALLEY   /   PROGRESSION CONCEPT", 76, 852, muted, size: 12)
        label("GAME ART  /  CONCEPT UI", 1364, 853, 12, muted, align: 1, tracking: 1.3)
    }

    // The same 480×900 phone coordinate space is used for every state.
    func phone(_ body: () -> Void) {
        let frame = CGRect(x: 945, y: 66, width: 400, height: 748)
        c.saveGState()
        c.setShadow(offset: CGSize(width: 0, height: -16), blur: 44, color: color(0x000000, 0.75))
        box(frame, 0x091410, 1, radius: 40, border: 0xd0ba85, borderAlpha: 0.9)
        c.restoreGState()
        c.saveGState()
        c.translateBy(x: 953, y: 74)
        c.scaleBy(x: 0.8, y: 0.8)
        c.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: 480, height: 915),
                         cornerWidth: 40, cornerHeight: 40, transform: nil))
        c.clip()
        body()
        c.restoreGState()
    }

    var phoneArea: CGRect { CGRect(x: 0, y: 0, width: 480, height: 915) }

    func phoneBackdrop(_ image: CGImage, shade: Double, zoom: Double = 0) {
        picture(image, phoneArea.insetBy(dx: -zoom, dy: -zoom))
        box(phoneArea, dark, shade)
        gradient(phoneArea, color(dark, 0.22), color(dark, 0.72))
    }

    func phoneTag(_ s: String, _ tint: UInt32) {
        box(CGRect(x: 26, y: 28, width: 428, height: 50), dark, 0.94,
            radius: 14, border: tint, borderAlpha: 0.65)
        label(s, 240, 42, 16, tint, font: "HelveticaNeue-Bold", align: 0.5, tracking: 1.7)
    }

    func button(_ s: String, y: Double, _ tint: UInt32, pulse: Double = 0) {
        box(CGRect(x: 32 - pulse, y: y - pulse, width: 416 + pulse * 2, height: 64 + pulse * 2),
            tint, 1, radius: 17)
        label(s, 240, y + 18, 22, darkInk, font: "HelveticaNeue-Bold", align: 0.5)
    }

    func meter(_ progress: Double, _ tint: UInt32, y: Double) {
        let points = 8 + Int((4 * progress).rounded())
        box(CGRect(x: 31, y: y, width: 418, height: 96), dark, 0.96, radius: 18,
            border: tint, borderAlpha: 0.5)
        kicker("DECORATION POINTS", 51, y + 14, tint, size: 13)
        label("\(points) / 12", 427, y + 10, 21, ink, font: "HelveticaNeue-Bold", align: 1)
        box(CGRect(x: 51, y: y + 51, width: 378, height: 12), 0x32493e, 1, radius: 6)
        box(CGRect(x: 51, y: y + 51, width: 378 * (8 + 4 * progress) / 12, height: 12), tint, 1, radius: 6)
        label("Next scene at 12", 51, y + 69, 15, muted)
    }

    func clearBoard(_ t: Double, _ tint: UInt32) {
        picture(art.board, phoneArea)
        let spark = ramp(t, 0.21, 0.43)
        let fade = 1 - ramp(t, 0.58, 0.4)
        line(CGPoint(x: 135, y: 459), CGPoint(x: 135 + 164 * spark, y: 459 - 102 * spark),
             tint, 0.85 * fade, 6)
        for n in 0..<16 {
            let a = Double(n) * Double.pi / 8
            let d = 34 + 88 * spark
            let x = 226 + cos(a) * d, y = 410 + sin(a) * d
            box(CGRect(x: x, y: y, width: 4, height: 4), tint, fade * spark, radius: 2)
        }
        let win = ramp(t, 0.42, 0.34)
        box(CGRect(x: 67, y: 352 + 14 * (1 - win), width: 346, height: 118),
            dark, 0.94 * win, radius: 22, border: tint, borderAlpha: win * 0.65)
        label("BOARD 03", 240, 375, 15, tint, align: 0.5, tracking: 2.5, alpha: win)
        label("First clear", 240, 400, 39, ink, font: "Georgia-Bold", align: 0.5, alpha: win)
    }

    func dialogue(_ o: Option, _ t: Double, index: Int) {
        phoneBackdrop(art.island, shade: 0.25, zoom: 5 + 10 * ramp(t, 0, 2))
        phoneTag("CHAPTER 01   /   A LIGHT BELOW", o.tint)
        let slide = (1 - ramp(t, 0.0, 0.43)) * 60
        picture(art.portraits[o.listener]!, CGRect(x: 258 + slide, y: 334, width: 211, height: 260), fit: true)
        picture(art.portraits[o.portrait]!, CGRect(x: 13 - slide, y: 296, width: 255, height: 314), fit: true)
        box(CGRect(x: 25, y: 580, width: 430, height: 218), light, 1, radius: 23,
            border: gold)
        kicker(o.speaker.uppercased(), 48, 601, 0x806238, size: 14)
        for (j, s) in o.hook.enumerated() {
            label(s, 48, 625 + Double(j) * 30, 25, darkInk, font: "HelveticaNeue-Bold")
        }
        let reply = ramp(t, index == 3 ? 1.05 : 0.54, 0.35)
        label(o.replyName.uppercased(), 48, 704, 14, 0x806238, tracking: 1.6, alpha: reply)
        label(o.reply, 48, 726, 21, darkInk, alpha: reply)
        if index == 3 {
            let flipped = ramp(t, 0.65, 0.47)
            box(CGRect(x: 158, y: 137 - 5 * flipped, width: 164, height: 86),
                light, 1, radius: 15, border: o.tint)
            label(flipped < 0.5 ? "BRASS TAG" : "ISLAND STAMP", 240, 166, 15, darkInk,
                  font: "HelveticaNeue-Bold", align: 0.5, tracking: 1)
            button(flipped < 0.5 ? "Turn the tag over" : "＋ 100 coins", y: 824, o.tint,
                   pulse: exp(-pow((t - 0.67) / 0.13, 2)) * 3)
        } else {
            label("＋ 100 coins", 240, 831, 24, o.tint, font: "HelveticaNeue-Bold", align: 0.5, alpha: reply)
        }
    }

    func restore(_ o: Option, _ t: Double, index: Int) {
        let built = ramp(t, 1.5, 0.75)
        phoneBackdrop(art.town, shade: 0.34, zoom: 22 + 24 * built)
        phoneTag("COINS   \(100 - Int((80 * built).rounded()))", o.tint)
        meter(built, o.tint, y: 104)
        let rise = (1 - built) * 20
        picture(art.buildings[o.asset]!, CGRect(x: 112, y: 293 + rise, width: 256, height: 246),
                fit: true, alpha: 0.45 + 0.55 * built)
        if built > 0 {
            ring(241, 487, 72 + 73 * built, o.tint, (1 - built) * 0.9)
            let amount = ramp(t, 1.6, 0.3)
            box(CGRect(x: 175, y: 245 - 15 * amount, width: 130, height: 49), dark, amount, radius: 16)
            label("+4 points", 240, 254 - 15 * amount, 22, o.tint, align: 0.5, alpha: amount)
        }
        box(CGRect(x: 25, y: 609, width: 430, height: 279), dark, 0.96, radius: 22,
            border: o.tint, borderAlpha: 0.6)
        kicker(index == 2 ? "CHOOSE A RESTORATION" : "ISLAND RESTORATION", 47, 630, o.tint, size: 14)
        label(o.action, 47, 656, 27, ink, font: "Georgia-Bold")
        label("80 coins   •   +4 decoration points", 47, 704, 20, muted)
        if index == 2 {
            label("Spring well also available   •   +4", 47, 746, 17, muted)
        }
        let tap = exp(-pow((t - 1.52) / 0.15, 2)) * 4
        button(built > 0.55 ? "Restored" : "Confirm placement", y: 804, o.tint, pulse: tap)
    }

    func payoff(_ o: Option, _ t: Double, index: Int) {
        phoneBackdrop(art.island, shade: 0.34, zoom: 15 + 16 * ramp(t, 0, 3))
        phoneTag("SCENE OPEN   /   12 OF 12 POINTS", o.tint)
        let slide = 30 * (1 - ramp(t, 0, 0.38))
        c.saveGState()
        c.translateBy(x: 0, y: slide)
        switch index {
        case 0:
            picture(art.buildings["well"]!, CGRect(x: 98, y: 244, width: 284, height: 295), fit: true)
            box(CGRect(x: 121, y: 176, width: 238, height: 112), light, 1, radius: 17, border: gold)
            kicker("RECOVERED", 142, 191, 0x806238, size: 12)
            title("Tide chart", 142, 215, 33, darkInk)
        case 1:
            for (n, title) in ["03  ·  The signal", "04  ·  The lower quay"].enumerated() {
                let y = 254 + Double(n) * 125
                box(CGRect(x: 36, y: y, width: 408, height: 103), n == 0 ? panel : light, 1,
                    radius: 18, border: o.tint)
                kicker(n == 0 ? "CLUE FOUND" : "NEW PLAYABLE SITE", 58, y + 15, n == 0 ? o.tint : 0x806238, size: 13)
                self.title(title, 58, y + 39, 24, n == 0 ? ink : darkInk)
            }
        case 2:
            let glow = (sin(t * 5) + 1) / 2
            let inspected = ramp(t, 1.1, 0.42)
            ring(244, 369, 48 + 23 * glow, o.tint, 0.9 - glow * 0.4)
            ring(244, 369, 27, o.tint, 0.9)
            box(CGRect(x: 138, y: 400, width: 212, height: 45), dark, 0.9, radius: 14)
            label(inspected > 0.5 ? "Old stairs uncovered" : "Inspect signal", 244, 409, 19, o.tint, align: 0.5)
        case 3:
            let x = 72 + 30 * ramp(t, 0.1, 0.7)
            for (n, name) in ["Brass tag", "Dock register"].enumerated() {
                let xx = n == 0 ? x - 63 : 259 - 30 * ramp(t, 0.1, 0.7)
                box(CGRect(x: xx, y: 280, width: 204, height: 125), light, 1, radius: 17, border: o.tint)
                kicker(n == 0 ? "STAMP" : "ENTRY", xx + 15, 299, 0x806238, size: 12)
                title(name, xx + 15, 329, 22, darkInk)
            }
            let joined = ramp(t, 0.7, 0.5)
            box(CGRect(x: 140, y: 439, width: 200, height: 47), dark, joined, radius: 16)
            label("Same boat", 240, 450, 19, o.tint, align: 0.5, alpha: joined)
        default:
            for (n, key) in ["mara", "adrian"].enumerated() {
                let x = 28 + Double(n) * 219
                picture(art.portraits[key]!, CGRect(x: x, y: 251, width: 202, height: 249), fit: true)
                box(CGRect(x: x, y: 483, width: 201, height: 60), n == 0 && t > 1.3 ? o.tint : dark,
                    1, radius: 15, border: o.tint)
                label("Ask \(key.capitalized)", x + 100, 500, 19,
                      n == 0 && t > 1.3 ? darkInk : ink, align: 0.5)
            }
        }
        c.restoreGState()
        box(CGRect(x: 25, y: 614, width: 430, height: 248), dark, 0.97, radius: 22,
            border: o.tint, borderAlpha: 0.58)
        kicker("STORY PAYOFF", 47, 638, o.tint, size: 14)
        title(o.gate, 47, 672, o.gate.count > 23 ? 24 : 29)
        label(o.payoff, 47, 736, 20, ink)
        label("Continue  →", 427, 806, 22, o.tint, font: "HelveticaNeue-Bold", align: 1)
    }

    func nextBoard(_ name: String, _ tint: UInt32, _ t: Double, companion: Bool = false) {
        phoneBackdrop(art.board, shade: 0.55, zoom: 21 * ramp(t, 0, 2))
        phoneTag("CHAPTER 01   /   A LIGHT BELOW", tint)
        let y = 409 + (1 - ramp(t, 0, 0.4)) * 37
        if companion {
            picture(art.portraits["mara"]!, CGRect(x: 145, y: y - 200, width: 190, height: 231), fit: true)
            box(CGRect(x: 119, y: y + 244, width: 242, height: 46), dark, 0.95, radius: 12, border: tint)
            label("Guide: Mara Bell", 240, y + 255, 18, tint, align: 0.5)
        }
        box(CGRect(x: 25, y: y, width: 430, height: 232), dark, 0.96, radius: 23, border: tint)
        kicker("BOARD 04 UNLOCKED", 48, y + 24, tint, size: 14)
        title(name, 48, y + 64, name.count > 19 ? 33 : 38)
        button("Play next board  →", y: y + 145, tint)
    }

    func opening(_ t: Double) {
        kicker("FIVE WAYS TO TELL THE STORY", 76, 152)
        title("What happens", 72, 186, 86)
        title("after the win?", 72, 277, 86)
        label("An island mystery told through boards, quests and rebuilding.", 76, 403, 23, muted)
        let rows = [("01", "Clear a board", "A clue and a character’s reaction."),
                    ("02", "Rebuild the island", "Spend coins to earn decoration points."),
                    ("03", "Open the next scene", "See where the trail takes you.")]
        for (i, row) in rows.enumerated() {
            let a = ramp(t, 0.22 + Double(i) * 0.42, 0.48)
            let y = 499 + Double(i) * 89 + 12 * (1 - a)
            c.saveGState()
            c.setAlpha(a)
            box(CGRect(x: 76, y: y, width: 747, height: 73), panel, 0.9, radius: 13,
                border: 0x718476, borderAlpha: 0.35)
            kicker(row.0, 94, y + 25)
            label(row.1, 144, y + 21, 23, ink, font: "HelveticaNeue-Bold")
            label(row.2, 427, y + 25, 18, muted)
            c.restoreGState()
        }
        phone {
            if t < 2.05 {
                clearBoard(max(0, t - 1.04), gold)
            } else if t < 4.55 {
                dialogue(options[0], t - 2.05, index: 0)
            } else {
                restore(options[0], t - 4.55, index: 0)
            }
        }
    }

    func study(_ i: Int, _ t: Double) {
        let o = options[i]
        let stage = starts.lastIndex { $0 <= t }!
        let elapsed = t - starts[stage]
        kicker(String(format: "OPTION %02d  /  05", i + 1), 76, 151, o.tint)
        title(o.title, 72, 186, 70)
        label(o.question, 76, 276, 33, o.tint, font: "Georgia-Italic")
        for (j, s) in o.premise.enumerated() { label(s, 76, 336 + Double(j) * 33, 23, ink) }
        let steps = ["First clear", "Restore", "Scene opens", "Next board"]
        for (j, s) in steps.enumerated() {
            let x = 76 + Double(j) * 191
            box(CGRect(x: x, y: 437, width: 174, height: 48), j == stage ? o.tint : panel,
                1, radius: 12, border: o.tint, borderAlpha: 0.4)
            label(s, x + 87, 449, 17, j == stage ? darkInk : muted, align: 0.5)
        }
        let enter = ramp(elapsed, 0.0, 0.26)
        let y = 524 + 16 * (1 - enter)
        box(CGRect(x: 76, y: y, width: 747, height: 161), panel, 1, radius: 17,
            border: o.tint, borderAlpha: 0.39)
        box(CGRect(x: 93, y: y + 23, width: 3, height: 112), o.tint, 0.8, radius: 1.5)
        kicker("ON SCREEN   /   0\(stage + 1)", 112, y + 24, o.tint, size: 12)
        title(o.stages[stage].0, 112, y + 48, 31)
        label(o.stages[stage].1, 112, y + 107, 20, muted)
        kicker("DESIGN TRADEOFF", 76, 726, o.tint, size: 12)
        label(o.tradeoff, 76, 751, 21, ink)
        phone {
            switch stage {
            case 0:
                if elapsed < 0.95 { clearBoard(elapsed, o.tint) }
                else { dialogue(o, elapsed - 0.95, index: i) }
            case 1: restore(o, elapsed, index: i)
            case 2: payoff(o, elapsed, index: i)
            default: nextBoard(o.next, o.tint, elapsed, companion: i == 4)
            }
            let shutter = 1 - ramp(elapsed, 0, 0.19)
            if stage > 0 && shutter > 0 { box(phoneArea, o.tint, shutter * 0.3) }
        }
    }

    func closing(_ t: Double) {
        kicker("RECOMMENDED DIRECTION", 76, 151)
        title("Quests lead.", 72, 185, 73)
        title("Wins reveal.", 72, 263, 73, gold)
        label("Let the first clear answer a question. Let the island open the next one.", 76, 376, 23, muted)
        kicker("CHAPTER 01   /   A LIGHT BELOW", 76, 455)
        let quests = [("01–03", "Get the camp talking", "Clear rubble, set camp, restore the well."),
                      ("04–06", "Find the lower quay", "Trace the chart, mark the route, light the stairs."),
                      ("07–09", "Open the tide room", "Search the quay, align the marks, open the door.")]
        for (i, q) in quests.enumerated() {
            let a = ramp(t, 0.2 + Double(i) * 0.5, 0.45)
            let y = 498 + Double(i) * 79 + 9 * (1 - a)
            c.saveGState()
            c.setAlpha(a)
            box(CGRect(x: 76, y: y, width: 747, height: 66), panel, 1, radius: 12)
            label(q.0, 96, y + 20, 19, gold, font: "HelveticaNeue-Bold")
            label(q.1, 180, y + 19, 22, ink, font: "HelveticaNeue-Bold")
            label(q.2, 423, y + 22, 17, muted)
            c.restoreGState()
        }
        label("Use points at quest boundaries. Fund each required build with first clears.", 76, 758, 21, ink)
        phone {
            if t < 3.65 { payoff(options[0], t, index: 0) }
            else { nextBoard("The lower quay", gold, t - 3.65) }
        }
    }

    func draw(_ t: Double) {
        if t < intro {
            backdrop(gold, t)
            opening(t)
        } else if t < duration - outro {
            let i = Int((t - intro) / segment)
            let elapsed = t - intro - Double(i) * segment
            backdrop(options[i].tint, t)
            study(i, elapsed)
            let transition = 1 - ramp(elapsed, 0, 0.24)
            if transition > 0 {
                box(CGRect(x: 60, y: 115, width: 791, height: 674), dark, transition)
            }
        } else {
            backdrop(gold, t)
            closing(t - (duration - outro))
        }
    }
}

func context(_ buffer: CVPixelBuffer) throws -> CGContext {
    guard let cg = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
                             bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                             space: space, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue |
                                 CGBitmapInfo.byteOrder32Little.rawValue) else {
        throw ReelError.message("Could not create the frame context.")
    }
    cg.interpolationQuality = .high
    return cg
}

func render(_ art: Art, to url: URL) throws {
    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: width,
        AVVideoHeightKey: height,
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 2_600_000,
                                          AVVideoExpectedSourceFrameRateKey: fps]
    ])
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
        kCVPixelBufferCGImageCompatibilityKey as String: true
    ])
    writer.add(input)
    guard writer.startWriting() else { throw writer.error ?? ReelError.message("Video writer did not start.") }
    writer.startSession(atSourceTime: .zero)
    let count = Int(duration * Double(fps))
    let queue = DispatchQueue(label: "story-reel-encoder")
    let done = DispatchSemaphore(value: 0)
    var frameError: Error?
    var frame = 0
    input.requestMediaDataWhenReady(on: queue) {
        while input.isReadyForMoreMediaData && frame < count {
            do {
                try autoreleasepool {
                    var output: CVPixelBuffer?
                    guard let pool = adaptor.pixelBufferPool,
                          CVPixelBufferPoolCreatePixelBuffer(nil, pool, &output) == kCVReturnSuccess,
                          let buffer = output else { throw ReelError.message("Could not allocate video frame.") }
                    CVPixelBufferLockBaseAddress(buffer, [])
                    do {
                        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
                        Canvas(try context(buffer), art).draw(Double(frame) / Double(fps))
                    }
                    guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(frame), timescale: fps)) else {
                        throw writer.error ?? ReelError.message("Could not append video frame \(frame).")
                    }
                }
                frame += 1
            } catch {
                frameError = error
                input.markAsFinished()
                writer.cancelWriting()
                done.signal()
                return
            }
        }
        if frame == count {
            input.markAsFinished()
            writer.finishWriting { done.signal() }
        }
    }
    done.wait()
    if let frameError { throw frameError }
    guard writer.status == .completed else { throw writer.error ?? ReelError.message("Video did not finish.") }
}

func poster(_ art: Art, to url: URL) throws {
    guard let cg = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                             bytesPerRow: 0, space: space,
                             bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        throw ReelError.message("Could not create poster context.")
    }
    Canvas(cg, art).draw(duration - outro + 5.5)
    guard let image = cg.makeImage(),
          let file = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
        throw ReelError.message("Could not create poster.")
    }
    CGImageDestinationAddImage(file, image, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
    guard CGImageDestinationFinalize(file) else { throw ReelError.message("Could not save poster.") }
}

do {
    let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "/tmp/relic-rush-story",
                     isDirectory: true)
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    let art = try Art()
    try poster(art, to: output.appendingPathComponent("story-progression.jpg"))
    let target = output.appendingPathComponent("story-progression.mp4")
    // Encode to a unique temporary path so failed renders preserve the previous reel.
    let temp = output.appendingPathComponent(".\(UUID().uuidString).mp4")
    defer { try? FileManager.default.removeItem(at: temp) }
    try render(art, to: temp)
    if FileManager.default.fileExists(atPath: target.path) {
        _ = try FileManager.default.replaceItemAt(target, withItemAt: temp)
    } else {
        try FileManager.default.moveItem(at: temp, to: target)
    }
    print("Rendered \(Int(duration)) seconds at \(width)×\(height), \(fps) fps: \(target.path)")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
