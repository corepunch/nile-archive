// Ten mockups for the build shop and the level select, drawn with SwiftUI.
// Run: swift docs/mockups/ui_variants.swift <out-dir>   (from games/christmas-market)
import SwiftUI
import AppKit

let cream = Color(red: 1, green: 0.93, blue: 0.75)
let paper = Color(red: 1, green: 0.96, blue: 0.84)
let green = Color(red: 0.12, green: 0.33, blue: 0.27)
let green2 = Color(red: 0.17, green: 0.42, blue: 0.33)
let red = Color(red: 0.72, green: 0.24, blue: 0.24)
let gold = Color(red: 0.95, green: 0.72, blue: 0.25)
let brown = Color(red: 0.30, green: 0.22, blue: 0.12)
let grey = Color(red: 0.55, green: 0.60, blue: 0.54)

func art(_ name: String) -> Image {
    let p = "data/buildings/\(name).png"
    if let i = NSImage(contentsOfFile: p) { return Image(nsImage: i) }
    return Image(systemName: "house.fill")
}
func f(_ s: CGFloat, _ w: Font.Weight = .heavy) -> Font { .system(size: s, weight: w, design: .rounded) }

struct Item { let key, name, size: String; let cost: Int; let state: Int }   // 0 built, 1 buy, 2 poor, 3 locked
let items: [Item] = [
    .init(key: "arch", name: "Welcome arch", size: "3×3", cost: 60, state: 0),
    .init(key: "lumber", name: "Lumber workshop", size: "3×3", cost: 80, state: 0),
    .init(key: "bakery", name: "Gingerbread bakery", size: "3×3", cost: 100, state: 1),
    .init(key: "cocoa", name: "Hot cocoa kiosk", size: "3×3", cost: 140, state: 1),
    .init(key: "carousel", name: "Reindeer carousel", size: "4×4", cost: 200, state: 2),
    .init(key: "rink", name: "Ice rink", size: "4×3", cost: 260, state: 2),
    .init(key: "chapel", name: "Little chapel", size: "3×4", cost: 320, state: 3),
    .init(key: "santa_workshop", name: "Santa's workshop", size: "4×4", cost: 500, state: 3),
]

// MARK: shared pieces
struct Backdrop: View {
    var body: some View {
        LinearGradient(colors: [Color(red: 0.10, green: 0.18, blue: 0.34), Color(red: 0.20, green: 0.30, blue: 0.50)], startPoint: .top, endPoint: .bottom)
            .overlay(Color.black.opacity(0.25))
    }
}
struct Wallet: View {
    var body: some View {
        HStack(spacing: 8) {
            pill("🔔", "340"); pill("⭐️", "27"); pill("❤️", "5")
            Spacer()
        }.padding(.horizontal, 16).padding(.top, 14)
    }
    func pill(_ i: String, _ v: String) -> some View {
        HStack(spacing: 4) { Text(i).font(f(16)); Text(v).font(f(15)).foregroundColor(.white) }
            .padding(.horizontal, 10).padding(.vertical, 5).background(green.opacity(0.9)).clipShape(Capsule())
    }
}
struct Sheet<C: View>: View {
    let title: String; var sub: String? = nil; let content: C
    init(_ t: String, sub: String? = nil, @ViewBuilder _ c: () -> C) { title = t; self.sub = sub; content = c() }
    var body: some View {
        ZStack(alignment: .top) {
            Backdrop(); VStack { Wallet(); Spacer() }
            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(title).font(f(30)).foregroundColor(gold).shadow(color: brown, radius: 0, x: 0, y: 2)
                    if let s = sub { Text(s).font(f(13, .bold)).foregroundColor(brown.opacity(0.75)) }
                }.padding(.top, 16).padding(.bottom, 10)
                content
                Spacer(minLength: 0)
                Text("BACK").font(f(18)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 46)
                    .background(red).clipShape(RoundedRectangle(cornerRadius: 14)).padding(14)
            }
            .background(paper).clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(red: 0.8, green: 0.6, blue: 0.3), lineWidth: 3))
            .padding(.horizontal, 20).padding(.top, 66).padding(.bottom, 70)
        }.frame(width: 480, height: 900)
    }
}
struct Price: View {
    let it: Item
    var body: some View {
        switch it.state {
        case 0: Label("Built", systemImage: "checkmark").font(f(12)).foregroundColor(green).padding(.horizontal, 9).padding(.vertical, 4).background(green.opacity(0.15)).clipShape(Capsule())
        case 3: Label("12 ⭐️", systemImage: "lock.fill").font(f(12)).foregroundColor(grey).padding(.horizontal, 9).padding(.vertical, 4).background(grey.opacity(0.18)).clipShape(Capsule())
        default: Text("🔔 \(it.cost)").font(f(13)).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 5)
                .background(it.state == 1 ? red : grey).clipShape(Capsule())
        }
    }
}
struct Bar: View { let p: Double
    var body: some View { GeometryReader { g in ZStack(alignment: .leading) { Capsule().fill(brown.opacity(0.15)); Capsule().fill(gold).frame(width: g.size.width * p) } }.frame(height: 8) } }
func dim(_ it: Item) -> Double { it.state == 3 ? 0.4 : 1 }

// MARK: shop variants
struct Shop1: View {   // two-column shelf of cards, small price pill
    var body: some View {
        Sheet("Build your market", sub: "340 Gold · 27 Stars") {
            VStack(spacing: 10) { Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(0..<4, id: \.self) { row in GridRow { ForEach(items[row*2..<row*2+2], id: \.key) { it in
                    VStack(spacing: 4) {
                        art(it.key).resizable().scaledToFit().frame(height: 74).saturation(it.state == 3 ? 0 : 1).opacity(dim(it))
                        Text(it.name).font(f(14)).foregroundColor(brown).lineLimit(1)
                        Text(it.size + " tiles").font(f(11, .bold)).foregroundColor(brown.opacity(0.6))
                        Price(it: it)
                    }.padding(10).frame(maxWidth: .infinity).background(cream).clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(gold.opacity(0.6), lineWidth: 2))
                } } }
            }.padding(.horizontal, 14) }
        }
    }
}
struct Shop2: View {   // dense rows, one small round action on the right
    var body: some View {
        Sheet("Build your market") {
            VStack(spacing: 8) {
                ForEach(items.prefix(7), id: \.key) { it in
                    HStack(spacing: 10) {
                        art(it.key).resizable().scaledToFit().frame(width: 64, height: 56).saturation(it.state == 3 ? 0 : 1).opacity(dim(it))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(it.name).font(f(16)).foregroundColor(brown)
                            Text(it.size + " tiles").font(f(12, .bold)).foregroundColor(brown.opacity(0.6))
                        }
                        Spacer()
                        Price(it: it)
                    }.padding(.horizontal, 12).padding(.vertical, 4).background(cream.opacity(0.8)).clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }.padding(.horizontal, 14)
        }
    }
}
struct Shop3: View {   // category tabs, three-up tiles, one detail panel with the single Build button
    var body: some View {
        Sheet("Build your market") {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    ForEach(["Wonders", "Stalls", "Trees", "Fun"], id: \.self) { t in
                        Text(t).font(f(14)).foregroundColor(t == "Stalls" ? .white : brown).frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(t == "Stalls" ? green2 : cream).clipShape(Capsule())
                    }
                }.padding(.horizontal, 14)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(items.prefix(6), id: \.key) { it in
                        VStack(spacing: 2) {
                            art(it.key).resizable().scaledToFit().frame(height: 70).saturation(it.state == 3 ? 0 : 1)
                            Text("🔔\(it.cost)").font(f(12)).foregroundColor(brown)
                        }.padding(6).frame(maxWidth: .infinity).background(it.key == "bakery" ? gold.opacity(0.35) : cream).clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(it.key == "bakery" ? gold : .clear, lineWidth: 3))
                    }
                }.padding(.horizontal, 14)
                VStack(spacing: 6) {
                    HStack { art("bakery").resizable().scaledToFit().frame(width: 100, height: 90)
                        VStack(alignment: .leading) { Text("Gingerbread bakery").font(f(20)).foregroundColor(brown)
                            Text("3×3 tiles · +8 gold / hour").font(f(13, .bold)).foregroundColor(brown.opacity(0.7)) }; Spacer() }
                    Text("BUILD  🔔 100").font(f(20)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 50).background(red).clipShape(RoundedRectangle(cornerRadius: 14))
                }.padding(12).background(cream).clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal, 14)
            }
        }
    }
}
struct Shop4: View {   // hero preview with swipe strip
    var body: some View {
        Sheet("Build your market") {
            VStack(spacing: 10) {
                ZStack { RoundedRectangle(cornerRadius: 18).fill(LinearGradient(colors: [Color(red: 0.8, green: 0.9, blue: 1), Color(red: 0.95, green: 0.97, blue: 1)], startPoint: .top, endPoint: .bottom))
                    art("cocoa").resizable().scaledToFit().padding(20)
                    VStack { HStack { Image(systemName: "chevron.left.circle.fill"); Spacer(); Image(systemName: "chevron.right.circle.fill") }.font(.system(size: 30)).foregroundColor(red); Spacer() }.padding(10).offset(y: 120)
                }.frame(height: 270).padding(.horizontal, 14)
                Text("Hot cocoa kiosk").font(f(24)).foregroundColor(brown)
                Text("Warms every visitor. 3×3 tiles · +10 gold per hour").font(f(13, .bold)).foregroundColor(brown.opacity(0.7))
                Text("BUILD  🔔 140").font(f(22)).foregroundColor(.white).frame(width: 280, height: 54).background(red).clipShape(Capsule())
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) {
                    ForEach(items, id: \.key) { it in
                        art(it.key).resizable().scaledToFit().frame(width: 62, height: 58).padding(5).saturation(it.state == 3 ? 0 : 1)
                            .background(it.key == "cocoa" ? gold.opacity(0.5) : cream).clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(alignment: .topTrailing) { if it.state == 0 { Image(systemName: "checkmark.circle.fill").foregroundColor(green2).background(Circle().fill(.white)) } }
                    } }.padding(.horizontal, 14) }.frame(height: 76)
            }
        }
    }
}
struct Shop5: View {   // zones with star progress, compact four-up tiles
    var body: some View {
        Sheet("Build your market") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach([("Welcome Square", "Open", 0.0), ("Lantern Lane", "Unlocks at 12 ⭐️  ·  27/12", 0.0), ("Gingerbread Green", "Unlocks at 40 ⭐️", 0.67)], id: \.0) { z in
                    HStack { Text(z.0).font(f(17)).foregroundColor(brown); Spacer(); Text(z.1).font(f(11, .bold)).foregroundColor(brown.opacity(0.6)) }
                    if z.2 > 0 { Bar(p: z.2) }
                    HStack(spacing: 8) {
                        ForEach(items.shuffled().prefix(4), id: \.key) { it in
                            VStack(spacing: 2) { art(it.key).resizable().scaledToFit().frame(height: 52).saturation(z.2 > 0 ? 0 : 1).opacity(z.2 > 0 ? 0.45 : 1)
                                Text(it.state == 0 ? "✓" : "\(it.cost)").font(f(12)).foregroundColor(brown) }
                                .padding(5).frame(maxWidth: .infinity).background(cream).clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }.padding(.horizontal, 14)
        }
    }
}

// MARK: level variants
let names = ["Welcome Lights", "Cocoa Corner", "Mittens & Muffins", "Snowbound Lane", "Candle Row", "Sleigh Bells", "Under the Big Fir", "Carols and Crumbs", "Word from Fenwick", "Gingerbread Dawn"]
func stars(_ n: Int, _ s: CGFloat = 12) -> some View {
    HStack(spacing: 1) { ForEach(0..<3, id: \.self) { Image(systemName: "star.fill").font(.system(size: s)).foregroundColor($0 < n ? gold : brown.opacity(0.2)) } }
}
func medal(_ n: Int, _ st: Int, size: CGFloat = 54) -> some View {   // st: 0..3 stars, -1 locked, -2 current
    ZStack {
        Circle().fill(st == -1 ? grey.opacity(0.5) : st == -2 ? red : green2).frame(width: size, height: size)
        Circle().stroke(st == -2 ? gold : cream, lineWidth: 3).frame(width: size - 4, height: size - 4)
        if st == -1 { Image(systemName: "lock.fill").foregroundColor(.white.opacity(0.8)) } else { Text("\(n)").font(f(size * 0.4)).foregroundColor(.white) }
    }
}
struct Level1: View {   // winding path
    var body: some View {
        Sheet("Winter wishes", sub: "Chapter 2 · Lantern Lane") {
            ZStack {
                Path { p in p.move(to: CGPoint(x: 120, y: 640)); p.addCurve(to: CGPoint(x: 330, y: 480), control1: CGPoint(x: 300, y: 620), control2: CGPoint(x: 150, y: 520))
                    p.addCurve(to: CGPoint(x: 140, y: 330), control1: CGPoint(x: 480, y: 440), control2: CGPoint(x: 320, y: 360))
                    p.addCurve(to: CGPoint(x: 300, y: 170), control1: CGPoint(x: -20, y: 290), control2: CGPoint(x: 120, y: 220))
                    p.addLine(to: CGPoint(x: 300, y: 80)) }
                    .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 10, lineCap: .round, dash: [1, 16])).offset(x: -10, y: -40)
                node(10, 3, 110, 600); node(11, 2, 320, 450); node(12, -2, 130, 300); node(13, -1, 290, 140)
            }.frame(height: 590).background(LinearGradient(colors: [Color(red: 0.85, green: 0.93, blue: 1), Color.white], startPoint: .top, endPoint: .bottom)).clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal, 14)
        }
    }
    func node(_ n: Int, _ s: Int, _ x: CGFloat, _ y: CGFloat) -> some View {
        VStack(spacing: 2) { if s == -2 { Text("PLAY").font(f(13)).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 4).background(red).clipShape(Capsule()) }
            medal(n, s, size: s == -2 ? 74 : 58); if s >= 0 { stars(s) } }.position(x: x, y: y - 40)
    }
}
struct Level2: View {   // chapter grid of medallions
    var body: some View {
        Sheet("Winter wishes") {
            VStack(spacing: 12) {
                ForEach([("Welcome Square", 1), ("Lantern Lane", 2)], id: \.0) { ch in
                    HStack { Text(ch.0).font(f(17)).foregroundColor(brown); Spacer(); Text(ch.1 == 1 ? "15/15 ⭐️" : "7/15 ⭐️").font(f(13)).foregroundColor(brown.opacity(0.7)) }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                        ForEach(0..<10, id: \.self) { i in
                            let n = (ch.1 - 1) * 10 + i + 1
                            let st = ch.1 == 1 ? 3 - (i % 3 == 0 ? 1 : 0) : (i < 5 ? 3 - i % 2 : i == 5 ? -2 : -1)
                            VStack(spacing: 1) { medal(n, st, size: 52); if st >= 0 { stars(st, 9) } else { Spacer().frame(height: 9) } }
                        }
                    }
                }
            }.padding(.horizontal, 14)
        }
    }
}
struct Level3: View {   // chapter cards, only the current has an action
    var body: some View {
        Sheet("Winter wishes") {
            VStack(spacing: 10) {
                card("1  Welcome Square", "15 / 15 ⭐️", 1.0, "gingerbread_house", nil)
                card("2  Lantern Lane", "7 / 15 ⭐️", 0.5, "lamp_post", "CONTINUE · WISH 12")
                card("3  Gingerbread Green", "Needs 30 ⭐️", 0, "bakery", nil)
                card("4  Carolers Court", "Needs 45 ⭐️", 0, "chapel", nil)
            }.padding(.horizontal, 14)
        }
    }
    func card(_ t: String, _ s: String, _ p: Double, _ a: String, _ cta: String?) -> some View {
        VStack(spacing: 6) {
            HStack { art(a).resizable().scaledToFit().frame(width: 84, height: 76).saturation(p == 0 ? 0 : 1).opacity(p == 0 ? 0.5 : 1)
                VStack(alignment: .leading, spacing: 4) { Text(t).font(f(18)).foregroundColor(brown); Text(s).font(f(13)).foregroundColor(brown.opacity(0.7)); Bar(p: p) }
                if p == 0 { Image(systemName: "lock.fill").foregroundColor(grey) } else if p == 1 { Image(systemName: "checkmark.seal.fill").foregroundColor(green2).font(.system(size: 26)) } }
            if let c = cta { Text(c).font(f(16)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 40).background(red).clipShape(RoundedRectangle(cornerRadius: 12)) }
        }.padding(10).background(cream).clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
struct Level4: View {   // slim list, button only on the next wish
    var body: some View {
        Sheet("Winter wishes") {
            VStack(spacing: 6) {
                ForEach(Array(names.enumerated()), id: \.offset) { i, n in
                    let st = i < 5 ? 3 - i % 2 : i == 5 ? -2 : -1
                    HStack(spacing: 10) {
                        medal(i + 1, st, size: 38)
                        Text(n).font(f(15)).foregroundColor(st == -1 ? brown.opacity(0.4) : brown)
                        Spacer()
                        if st >= 0 { stars(st, 14) }
                        else if st == -2 { Text("PLAY").font(f(14)).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 6).background(red).clipShape(Capsule()) }
                    }.padding(.horizontal, 10).padding(.vertical, 5).background(st == -2 ? gold.opacity(0.35) : cream.opacity(0.8)).clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }.padding(.horizontal, 14)
        }
    }
}
struct Level5: View {   // hero for the next wish and a compact strip of the rest
    var body: some View {
        Sheet("Winter wishes") {
            VStack(spacing: 12) {
                VStack(spacing: 6) {
                    Text("NEXT WISH").font(f(12)).foregroundColor(red)
                    Text("12. Word from Fenwick").font(f(22)).foregroundColor(brown)
                    HStack { art("post_office").resizable().scaledToFit().frame(width: 120, height: 100)
                        VStack(alignment: .leading, spacing: 6) { Text("Goal: 4200 points").font(f(14)).foregroundColor(brown); Text("Reward: 80–120 🔔 · 3 ⭐️").font(f(14)).foregroundColor(brown)
                            Text("Unlocks: Post office").font(f(13, .bold)).foregroundColor(green2) } }
                    Text("PLAY").font(f(24)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 56).background(red).clipShape(RoundedRectangle(cornerRadius: 16))
                }.padding(14).background(cream).clipShape(RoundedRectangle(cornerRadius: 18)).padding(.horizontal, 14)
                HStack { Text("Replay for gold").font(f(15)).foregroundColor(brown); Spacer() }.padding(.horizontal, 18)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                    ForEach(1..<12, id: \.self) { n in VStack(spacing: 1) { medal(n, 3 - n % 2, size: 40); stars(3 - n % 2, 8) } }
                }.padding(.horizontal, 14)
            }
        }
    }
}


// MARK: S1 compact-card variants
func chip(_ t: String) -> some View { Text(t).font(f(10)).foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 2).background(brown.opacity(0.65)).clipShape(Capsule()) }
func tile<C: View>(_ it: Item, _ pad: CGFloat = 8, @ViewBuilder _ c: () -> C) -> some View {
    c().padding(pad).frame(maxWidth: .infinity).background(it.state == 3 ? cream.opacity(0.6) : cream).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(gold.opacity(it.state == 1 ? 0.9 : 0.4), lineWidth: 2))
}
func rows(_ n: Int, _ list: [Item], _ spacing: CGFloat = 8, _ cell: @escaping (Item) -> some View) -> some View {
    VStack(spacing: spacing) { ForEach(0..<((list.count + n - 1) / n), id: \.self) { r in
        HStack(spacing: spacing) { ForEach(0..<n, id: \.self) { c in
            let i = r * n + c
            if i < list.count { cell(list[i]) } else { Color.clear.frame(maxWidth: .infinity) } } } } }.padding(.horizontal, 14)
}
func shelf(_ it: Item) -> Item { it }
let many: [Item] = items + [
    .init(key: "gingerbread_house", name: "Gingerbread house", size: "3×3", cost: 120, state: 1), .init(key: "igloo", name: "Igloo", size: "2×2", cost: 70, state: 1),
    .init(key: "post_office", name: "Post office", size: "3×3", cost: 180, state: 2), .init(key: "log_cabin", name: "Log cabin", size: "3×4", cost: 220, state: 2),
    .init(key: "reindeer_stable", name: "Reindeer stable", size: "4×3", cost: 300, state: 3), .init(key: "toys", name: "Toy stall", size: "2×2", cost: 90, state: 1)]
struct A1: View {   // 3 columns: size is a corner tag, name and price share the card
    var body: some View { Sheet("Build your market") { rows(3, many.prefix(12).map { $0 }) { it in tile(it, 6) {
        VStack(spacing: 2) {
            ZStack(alignment: .topLeading) { art(it.key).resizable().scaledToFit().frame(height: 62).saturation(it.state == 3 ? 0 : 1).opacity(dim(it)).frame(maxWidth: .infinity); chip(it.size) }
            Text(it.name).font(f(11)).foregroundColor(brown).lineLimit(1).minimumScaleFactor(0.8)
            Price(it: it).scaleEffect(0.9)
        } } } } }
}
struct A2: View {   // 2 columns, horizontal mini-card: icon left, name + price right
    var body: some View { Sheet("Build your market") { rows(2, many.prefix(12).map { $0 }) { it in tile(it, 6) {
        HStack(spacing: 6) {
            art(it.key).resizable().scaledToFit().frame(width: 58, height: 56).saturation(it.state == 3 ? 0 : 1).opacity(dim(it))
            VStack(alignment: .leading, spacing: 4) { Text(it.name).font(f(12)).foregroundColor(brown).lineLimit(2).fixedSize(horizontal: false, vertical: true); Price(it: it).scaleEffect(0.9, anchor: .leading) }
            Spacer(minLength: 0)
        } } } } }
}
struct A3: View {   // 3 columns, icon + price only; name appears for the selected card in a strip at the bottom
    var body: some View { Sheet("Build your market") { VStack(spacing: 10) {
        rows(3, many.prefix(12).map { $0 }) { it in tile(it, 5) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 2) { art(it.key).resizable().scaledToFit().frame(height: 66).saturation(it.state == 3 ? 0 : 1).opacity(dim(it)).frame(maxWidth: .infinity); Price(it: it).scaleEffect(0.9) }
                if it.state == 0 { Image(systemName: "checkmark.circle.fill").foregroundColor(green2).background(Circle().fill(.white)) }
            } } .overlay(RoundedRectangle(cornerRadius: 14).stroke(it.key == "cocoa" ? red : .clear, lineWidth: 3)) }
        HStack { Text("Hot cocoa kiosk").font(f(17)).foregroundColor(brown); Text("3×3 tiles").font(f(12, .bold)).foregroundColor(brown.opacity(0.6)); Spacer(); Text("BUILD").font(f(16)).foregroundColor(.white).padding(.horizontal, 22).padding(.vertical, 9).background(red).clipShape(Capsule()) }
            .padding(12).background(gold.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 14)).padding(.horizontal, 14)
    } } }
}
struct A4: View {   // 4 columns of icon tiles with a floating price pill
    var body: some View { Sheet("Build your market") { rows(4, many.prefix(16).map { $0 } + Array(many.prefix(4)), 6) { it in tile(it, 4) {
        VStack(spacing: 0) { art(it.key).resizable().scaledToFit().frame(height: 52).saturation(it.state == 3 ? 0 : 1).opacity(dim(it))
            Text(it.state == 0 ? "✓" : it.state == 3 ? "🔒" : "\(it.cost)").font(f(12)).foregroundColor(it.state == 0 ? green2 : brown) } } } } }
}
struct A5: View {   // 2 columns, price ribbon fused to the card's bottom edge, size chip on the art
    var body: some View { Sheet("Build your market") { rows(2, many.prefix(8).map { $0 }, 10) { it in
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) { art(it.key).resizable().scaledToFit().frame(height: 84).saturation(it.state == 3 ? 0 : 1).opacity(dim(it)).frame(maxWidth: .infinity).padding(.top, 8); chip(it.size).padding(6) }
            Text(it.name).font(f(14)).foregroundColor(brown).padding(.bottom, 6)
            HStack { Spacer(); if it.state == 0 { Label("BUILT", systemImage: "checkmark") } else if it.state == 3 { Label("12 ⭐️", systemImage: "lock.fill") } else { Text("🔔 \(it.cost)") }; Spacer() }
                .font(f(14)).foregroundColor(.white).padding(.vertical, 7).background(it.state == 0 ? green2 : it.state == 1 ? red : grey)
        }.background(it.state == 3 ? cream.opacity(0.6) : cream).clipShape(RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(gold.opacity(0.6), lineWidth: 2)) } } }
}
struct A6: View {   // 3 columns, whole card is the button: state is a colour band, no pill
    var body: some View { Sheet("Build your market") { rows(3, many.prefix(12).map { $0 }) { it in
        VStack(spacing: 0) {
            VStack(spacing: 1) { art(it.key).resizable().scaledToFit().frame(height: 58).saturation(it.state == 3 ? 0 : 1).opacity(dim(it)); Text(it.name).font(f(11)).foregroundColor(brown).lineLimit(1).minimumScaleFactor(0.7) }.padding(.top, 6).padding(.horizontal, 4).padding(.bottom, 4)
            Text(it.state == 0 ? "Built" : it.state == 3 ? "🔒 12⭐️" : "🔔 \(it.cost)").font(f(12)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 4).background(it.state == 0 ? green2 : it.state == 1 ? red : grey)
        }.background(cream).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(gold.opacity(0.6), lineWidth: 2)) } } }
}

// MARK: output
struct Labeled<V: View>: View {
    let label: String; let v: V
    var body: some View { VStack(spacing: 6) { v.clipShape(RoundedRectangle(cornerRadius: 24)); Text(label).font(f(22)).foregroundColor(.white) } }
}
@MainActor func render<V: View>(_ v: V, to path: String, scale: CGFloat) {
    let r = ImageRenderer(content: v); r.scale = scale
    guard let img = r.nsImage, let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) else { print("fail", path); return }
    try? png.write(to: URL(fileURLWithPath: path))
}
@MainActor func main() {
    let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
    try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
    if CommandLine.arguments.count > 2 {
        let a: [(String, AnyView)] = [("A1 3-up, size tag", AnyView(A1())), ("A2 2-up mini rows", AnyView(A2())), ("A3 icon + select", AnyView(A3()))]
        let b: [(String, AnyView)] = [("A4 4-up icons", AnyView(A4())), ("A5 price ribbon", AnyView(A5())), ("A6 colour-band card", AnyView(A6()))]
        for (n, set) in [("s1a", a), ("s1b", b)] {
            render(HStack(alignment: .top, spacing: 24) { ForEach(0..<set.count, id: \.self) { Labeled(label: set[$0].0, v: set[$0].1) } }.padding(24).background(Color(red: 0.07, green: 0.1, blue: 0.16)), to: "\(out)/\(n)-sheet.png", scale: 1)
        }
        return
    }
    let shop: [(String, AnyView)] = [("S1 Card shelf", AnyView(Shop1())), ("S2 Slim rows", AnyView(Shop2())), ("S3 Tabs + one Build button", AnyView(Shop3())), ("S4 Hero + strip", AnyView(Shop4())), ("S5 Zones by stars", AnyView(Shop5()))]
    let lv: [(String, AnyView)] = [("L1 Winding path", AnyView(Level1())), ("L2 Chapter medallions", AnyView(Level2())), ("L3 Chapter cards", AnyView(Level3())), ("L4 Slim list", AnyView(Level4())), ("L5 Next-wish hero", AnyView(Level5()))]
    for (name, set) in [("shop", shop), ("levels", lv)] {
        let sheet = HStack(alignment: .top, spacing: 24) { ForEach(0..<set.count, id: \.self) { Labeled(label: set[$0].0, v: set[$0].1) } }
            .padding(24).background(Color(red: 0.07, green: 0.1, blue: 0.16))
        render(sheet, to: "\(out)/\(name)-sheet.png", scale: 1)
        for (i, s) in set.enumerated() { render(s.1, to: "\(out)/\(name)-\(i + 1).png", scale: 1.5) }
    }
}
MainActor.assumeIsolated { main() }
