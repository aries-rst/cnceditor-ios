/* ЧПУ Редактор 2D — векторный текст: собственный разбор TrueType (.ttf, контуры glyf) и однолинейный шрифт Hershey. Порт Text.kt */
import Foundation

typealias GPt = (Double, Double, Bool)

/// Разбор TrueType: cmap (4/12), glyf (простые и составные), hmtx, kern (формат 0), OS/2 высота заглавных
final class TtfFont {
    private let b: [UInt8]
    private var tables: [String: Int] = [:]
    private(set) var unitsPerEm = 0; private var locFmt = 0; private var numGlyphs = 0; private var numHMetrics = 0
    private var cmap: [Int: Int] = [:]; private var kern: [Int64: Int] = [:]
    private(set) var capHeight = 0
    private func u8(_ o: Int) -> Int { Int(b[o]) }
    private func u16(_ o: Int) -> Int { (u8(o) << 8) | u8(o + 1) }
    private func i16(_ o: Int) -> Int { Int(Int16(bitPattern: UInt16(u16(o)))) }
    private func u32(_ o: Int) -> Int { (u16(o) << 16) | u16(o + 2) }
    init(_ data: Data) throws {
        b = [UInt8](data)
        let n = u16(4)
        for i in 0..<n { let r = 12 + 16 * i; tables[String(bytes: b[r..<(r + 4)], encoding: .isoLatin1) ?? ""] = u32(r + 8) }
        if tables["glyf"] == nil { throw IoError(msg: "Поддерживаются шрифты TrueType (.ttf) с контурами glyf") }
        let head = tables["head"]!; unitsPerEm = u16(head + 18); locFmt = i16(head + 50)
        numGlyphs = u16(tables["maxp"]! + 4); numHMetrics = u16(tables["hhea"]! + 34)
        readCmap(); readKern()
        if let os2 = tables["OS/2"], u16(os2) >= 2, i16(os2 + 88) > 0 { capHeight = i16(os2 + 88) }
        else { capHeight = glyphBox(glyphIndex(72))?[3] ?? Int(Double(unitsPerEm) * 0.7) }
    }
    private func readCmap() {
        guard let c = tables["cmap"] else { return }; let n = u16(c + 2); var best = -1, bestFmt = 0
        for i in 0..<n { let pid = u16(c + 4 + 8 * i), eid = u16(c + 6 + 8 * i); let off = c + u32(c + 8 + 8 * i); let fmt = u16(off)
            if (pid == 3 && (eid == 1 || eid == 10)) || pid == 0 { if fmt == 12 || (fmt == 4 && bestFmt != 12) { best = off; bestFmt = fmt } } }
        if best < 0 { return }
        if bestFmt == 4 {
            let segX2 = u16(best + 6); let ends = best + 14; let starts = ends + segX2 + 2; let deltas = starts + segX2; let ranges = deltas + segX2
            for s in 0..<(segX2 / 2) {
                let end = u16(ends + 2 * s), start = u16(starts + 2 * s), delta = i16(deltas + 2 * s), ro = u16(ranges + 2 * s)
                if start == 0xFFFF || end < start { continue }
                for ch in start...end {
                    let g: Int
                    if ro == 0 { g = (ch + delta) & 0xFFFF } else { let gi = ranges + 2 * s + ro + 2 * (ch - start); let v = u16(gi); g = v == 0 ? 0 : (v + delta) & 0xFFFF }
                    if g != 0 { cmap[ch] = g }
                }
            }
        } else {
            let ng = u32(best + 12)
            for i in 0..<ng { let r = best + 16 + 12 * i; let s = u32(r), e = u32(r + 4), g0 = u32(r + 8); if e >= s { for ch in s...e { cmap[ch] = g0 + ch - s } } }
        }
    }
    private func readKern() {
        guard let k = tables["kern"] else { return }; let n = u16(k + 2); var off = k + 4
        for _ in 0..<n { let len = u16(off + 2), cov = u16(off + 4)
            if (cov >> 8) == 0 { let np = u16(off + 6); for i in 0..<np { let r = off + 14 + 6 * i; kern[(Int64(u16(r)) << 16) | Int64(u16(r + 2))] = i16(r + 4) } }
            off += len }
    }
    func glyphIndex(_ cp: Int) -> Int { cmap[cp] ?? 0 }
    func hasChar(_ cp: Int) -> Bool { cmap[cp] != nil }
    func advance(_ g: Int) -> Int { let h = tables["hmtx"]!; return g < numHMetrics ? u16(h + 4 * g) : u16(h + 4 * (numHMetrics - 1)) }
    func kerning(_ a: Int, _ c: Int) -> Int { kern[(Int64(a) << 16) | Int64(c)] ?? 0 }
    private func glyphOffset(_ g: Int) -> (Int, Int)? {
        if g >= numGlyphs { return nil }; let loca = tables["loca"]!, glyf = tables["glyf"]!
        let s: Int, e: Int
        if locFmt == 0 { s = u16(loca + 2 * g) * 2; e = u16(loca + 2 * g + 2) * 2 } else { s = u32(loca + 4 * g); e = u32(loca + 4 * g + 4) }
        return e > s ? (glyf + s, e - s) : nil
    }
    private func glyphBox(_ g: Int) -> [Int]? { guard let o = glyphOffset(g) else { return nil }; return [i16(o.0 + 2), i16(o.0 + 4), i16(o.0 + 6), i16(o.0 + 8)] }
    /// контуры глифа в единицах шрифта: списки точек (x, y, onCurve)
    func contours(_ g: Int, _ depth: Int = 0) -> [[GPt]] {
        guard let o = glyphOffset(g) else { return [] }; let p = o.0; let nc = i16(p)
        if nc >= 0 {
            let endPts = (0..<nc).map { u16(p + 10 + 2 * $0) }; let nPts = nc > 0 ? endPts.last! + 1 : 0
            var q = p + 10 + 2 * nc; let il = u16(q); q += 2 + il
            var flags = [Int](repeating: 0, count: nPts); var i = 0
            while i < nPts { let f = u8(q); q += 1; flags[i] = f; i += 1; if f & 8 != 0 { var r = u8(q); q += 1; while r > 0 && i < nPts { r -= 1; flags[i] = f; i += 1 } } }
            var xs = [Int](repeating: 0, count: nPts); var v = 0
            for k in 0..<nPts { let f = flags[k]; if f & 2 != 0 { let d = u8(q); q += 1; v += f & 16 != 0 ? d : -d } else if f & 16 == 0 { v += i16(q); q += 2 }; xs[k] = v }
            var ys = [Int](repeating: 0, count: nPts); v = 0
            for k in 0..<nPts { let f = flags[k]; if f & 4 != 0 { let d = u8(q); q += 1; v += f & 32 != 0 ? d : -d } else if f & 32 == 0 { v += i16(q); q += 2 }; ys[k] = v }
            var out: [[GPt]] = []; var s = 0
            for e in endPts { if e >= s { out.append((s...e).map { (Double(xs[$0]), Double(ys[$0]), flags[$0] & 1 != 0) }) } else { out.append([]) }; s = e + 1 }
            return out
        }
        if depth > 8 { return [] }
        var out: [[GPt]] = []; var q = p + 10
        while true {
            let f = u16(q), gi = u16(q + 2); q += 4
            let dx: Double, dy: Double
            if f & 1 != 0 { dx = Double(i16(q)); dy = Double(i16(q + 2)); q += 4 } else { dx = Double(Int8(bitPattern: b[q])); dy = Double(Int8(bitPattern: b[q + 1])); q += 2 }
            var a = 1.0, bb = 0.0, c = 0.0, d = 1.0
            func f2d(_ o: Int) -> Double { Double(i16(o)) / 16384.0 }
            if f & 8 != 0 { a = f2d(q); d = a; q += 2 } else if f & 64 != 0 { a = f2d(q); d = f2d(q + 2); q += 4 } else if f & 128 != 0 { a = f2d(q); bb = f2d(q + 2); c = f2d(q + 4); d = f2d(q + 6); q += 8 }
            for ct in contours(gi, depth + 1) { out.append(ct.map { (a * $0.0 + c * $0.1 + dx, bb * $0.0 + d * $0.1 + dy, $0.2) }) }
            if f & 32 == 0 { break }
        }
        return out
    }
}

enum TextEngine {
    final class FontEntry { let id: String; let name: String; let single: Bool; let regular: TtfFont?; let bold: TtfFont?
        init(_ id: String, _ name: String, _ single: Bool, _ regular: TtfFont? = nil, _ bold: TtfFont? = nil) { self.id = id; self.name = name; self.single = single; self.regular = regular; self.bold = bold } }
    private static var fonts: [FontEntry] = []
    private static var hershey: [Character: (String, Int)] = [:]
    private static func put(_ f: FontEntry) { if let i = fonts.firstIndex(where: { $0.id == f.id }) { fonts[i] = f } else { fonts.append(f) } }
    private static func get(_ id: String) -> FontEntry? { fonts.first { $0.id == id } }
    static func registerTtf(_ id: String, _ name: String, _ regular: Data, _ bold: Data? = nil) throws { put(FontEntry(id, name, false, try TtfFont(regular), try bold.map { try TtfFont($0) })) }
    /// строки «символ<TAB>полуширина<TAB>путь SVG»
    static func registerHershey(_ data: String) {
        var m: [Character: (String, Int)] = [:]
        for l in data.components(separatedBy: "\n") { let p = l.components(separatedBy: "\t"); if p.count >= 3, let c = p[0].first { m[c] = (p[2], Int(p[1]) ?? 8) } }
        hershey = m; put(FontEntry("hershey", "Однолинейный (для гравировки)", true))
    }
    static func list() -> [(String, String, Bool)] { fonts.map { ($0.id, $0.name, $0.single) } }
    static func has(_ id: String) -> Bool { get(id) != nil }

    final class Item { let ch: Character; var paths: [VPath]; let x: Double; let adv: Double; init(_ ch: Character, _ paths: [VPath], _ x: Double, _ adv: Double) { self.ch = ch; self.paths = paths; self.x = x; self.adv = adv } }
    private static let FB: [Character: Character] = ["Ў": "У", "ў": "у", "Қ": "К", "қ": "к", "Ғ": "Г", "ғ": "г", "Ҳ": "Х", "ҳ": "х", "Ё": "Е", "ё": "е"]

    private static func ttfGlyph(_ font: TtfFont, _ g: Int, _ k: Double) -> [VPath] {
        var out: [VPath] = []
        for ct in font.contours(g) {
            if ct.count < 2 { continue }
            let n = ct.count
            let pts: [GPt]
            if let si = ct.firstIndex(where: { $0.2 }) { pts = (0..<n).map { ct[(si + $0) % n] } }
            else { let a = ct[0], b = ct[1]; pts = [((a.0 + b.0) / 2, (a.1 + b.1) / 2, true)] + Array(ct.dropFirst()) + [ct[0]] }
            let p = VPath(closed: true, x0: pts[0].0 * k, y0: pts[0].1 * k)
            var px = pts[0].0, py = pts[0].1; var i = 1
            let m = pts.count
            while i <= m {
                let cur = pts[i % m]
                if cur.2 { p.segs.append(LineSeg(cur.0 * k, cur.1 * k)); px = cur.0; py = cur.1; i += 1 }
                else {
                    let nx = pts[(i + 1) % m]; let ex: Double, ey: Double
                    if nx.2 { ex = nx.0; ey = nx.1; i += 2 } else { ex = (cur.0 + nx.0) / 2; ey = (cur.1 + nx.1) / 2; i += 1 }
                    let qx = cur.0, qy = cur.1
                    p.segs.append(BezSeg((px + 2.0 / 3 * (qx - px)) * k, (py + 2.0 / 3 * (qy - py)) * k, (ex + 2.0 / 3 * (qx - ex)) * k, (ey + 2.0 / 3 * (qy - ey)) * k, ex * k, ey * k))
                    px = ex; py = ey
                }
            }
            if let l = p.segs.last, abs(l.x - p.x0) > 1e-7 || abs(l.y - p.y0) > 1e-7 { p.segs.append(LineSeg(p.x0, p.y0)) }
            if p.segs.count > 1 { out.append(p) }
        }
        return out
    }
    private static func hersheyGlyph(_ d: String, _ k: Double) -> [VPath] {
        var out: [VPath] = []; var pts: [P]? = nil; var newPath = false
        func fin() { if let q = pts, q.count > 1 { let cl = q.count > 2 && hypot(q[0].x - q.last!.x, q[0].y - q.last!.y) < 1e-9; out.append(Geom.makePath(cl ? Array(q.dropLast()) : q, cl)) }; pts = nil }
        for m in Rx.c("([ML])|(-?\\d+(?:\\.\\d+)?),(-?\\d+(?:\\.\\d+)?)").all(d) {
            if m.gv(1) == "M" { fin(); newPath = true; continue }; if m.gv(1) == "L" { continue }
            let q = P((Double(m.gv(2)) ?? 0) * k, (22 - (Double(m.gv(3)) ?? 0)) * k)
            if newPath || pts == nil { fin(); pts = [q]; newPath = false } else { pts!.append(q) }
        }
        fin(); return out
    }
    private static func layoutLine(_ fe: FontEntry, _ line: String, _ t: TextParams) -> ([Item], Double) {
        var items: [Item] = []; var x = 0.0
        if fe.single {
            let k = t.size / 21, spAdv = 16 * k, extra = t.charSp / 100 * spAdv
            for ch in line { let g = hershey[ch] ?? FB[ch].flatMap { hershey[$0] }; let adv = (ch == " " || g == nil) ? spAdv : 2 * Double(g!.1) * k
                let ps = (g != nil && ch != " ") ? hersheyGlyph(g!.0, k) : []; ps.forEach { Geom.transform($0, Geom.M.move(x, 0)) }
                items.append(Item(ch, ps, x, adv)); x += adv + extra }
            return (items, max(0, x - extra))
        }
        let font = (t.bold && fe.bold != nil ? fe.bold : fe.regular)!; let fakeBold = t.bold && fe.bold == nil
        let k = t.size / Double(font.capHeight); let spAdv = Double(font.advance(font.glyphIndex(32))) * k; let extra = t.charSp / 100 * spAdv
        let cps = line.unicodeScalars.map { Int($0.value) }
        for (i, cp) in cps.enumerated() {
            let ch = Character(UnicodeScalar(UInt32(cp)) ?? " ")
            let c2 = font.hasChar(cp) ? cp : (FB[ch].flatMap { $0.unicodeScalars.first.map { Int($0.value) } } ?? cp)
            let g = font.glyphIndex(c2); var adv = Double(font.advance(g)) * k
            if t.kern && i + 1 < cps.count { adv += Double(font.kerning(g, font.glyphIndex(cps[i + 1]))) * k }
            var ps = ttfGlyph(font, g, k); if fakeBold && !ps.isEmpty { ps = Geom.offset(ps, t.size * 0.035, "round") }
            ps.forEach { Geom.transform($0, Geom.M.move(x, 0)) }
            items.append(Item(ch, ps, x, adv)); x += adv + extra
        }
        return (items, max(0, x - extra))
    }
    /// Построение текста. curve — точки кривой (для «текста по кривой»)
    static func build(_ t: TextParams, _ curve: [P]? = nil) -> [VPath] {
        guard let fe = get(t.font) ?? fonts.first(where: { !$0.single }) ?? fonts.first else { return [] }
        let lines = Rx.c("\\r?\\n").split(t.text); let lineH = t.lineSp > 0 ? t.lineSp : t.size * 1.6
        let sx = (t.sx != 0 ? t.sx : 100) / 100, sy = (t.sy != 0 ? t.sy : 100) / 100; let slant = t.slant + (t.italic ? 12 : 0)
        var all: [VPath] = []
        func local(_ p: VPath, _ dx: Double, _ dy: Double) { Geom.transform(p, Geom.M.move(dx, dy)); if slant != 0 { Geom.transform(p, Geom.M.shear(slant, 0, 0, 0)) }; if sx != 1 || sy != 1 { Geom.transform(p, Geom.M.scale(sx, sy, 0, 0)) } }
        if let curve = curve, curve.count > 1 {
            let f = t.cFlip ? Array(curve.reversed()) : curve; let L = Geom.polyLen(f); let (items, w) = layoutLine(fe, lines.first ?? "", t); let W = w * sx
            let s0 = (t.cPos == "center" ? (L - W) / 2 : t.cPos == "end" ? L - W : 0) + t.cStart
            for it in items { let c = it.x * sx + it.adv * sx / 2; let pt = Geom.pointAt(f, s0 + c); let deg = pt[2] * 180 / .pi
                for p in it.paths { local(p, -(it.x + it.adv / 2), t.cOff); Geom.transform(p, Geom.M.rotate(-deg, 0, 0)); Geom.transform(p, Geom.M.move(pt[0], pt[1])); all.append(p) } }
            return all
        }
        for (li, ln) in lines.enumerated() {
            let (items, w) = layoutLine(fe, ln, t); let dx = t.align == "center" ? -w / 2 : (t.align == "right" ? -w : 0)
            for it in items { for p in it.paths { local(p, dx, -Double(li) * lineH / sy); if t.rot != 0 { Geom.transform(p, Geom.M.rotate(t.rot, 0, 0)) }; Geom.transform(p, Geom.M.move(t.x, t.y)); all.append(p) } }
        }
        return all
    }
}
