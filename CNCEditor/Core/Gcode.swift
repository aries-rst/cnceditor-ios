/* Импорт управляющих программ (G-код: .tap, .nc, .ngc, .gcode, .cnc) обратно в векторы. Порт Gcode.kt */
import Foundation

enum Gcode {
    /// comp: "none" — центр фрезы; "auto" — внешние контуры внутрь, отверстия наружу; "in" / "out" — все внутрь / наружу
    final class Opt { var toolDia = 0.0, comp = "none", mergePasses = true, layerPerTool = true, cutBelow = 0.0; init() {} }
    struct Result { let imp: Imported; let tools: [Int]; let moves: Int; let minZ: Double; let info: String }

    static func looksLikeGcode(_ text: String) -> Bool {
        var n = 0, ok = 0; var g01 = false
        let start = Rx.c("^(N\\d+\\s*)?([GMTXYZFSIJ]\\s*[-+]?\\d|%|\\(|;|O\\d)"), mv = Rx.c("G0?[0123](?![0-9])")
        for l in Rx.c("\\r?\\n").split(text).prefix(500) { let s = l.trimmed.uppercased(); if s.isEmpty { continue }; n += 1
            if start.test(s) { ok += 1 }; if mv.test(s) { g01 = true } }
        return n > 0 && g01 && ok * 10 >= n * 8
    }

    private final class Chain { let tool: Int; let z: Double; var segs: [Seg] = []; var x0 = 0.0, y0 = 0.0; init(_ t: Int, _ z: Double) { tool = t; self.z = z } }

    static func parse(_ text: String, _ o: Opt = Opt()) -> Result {
        var x = 0.0, y = 0.0, z = 1e9; var mode = 0; var absM = true; var k = 1.0; var tool = 1; var moves = 0; var minZ = 1e9
        var tools: [Int] = []; var chains: [Chain] = []; var cur: Chain? = nil
        let word = Rx.c("([A-Z])\\s*([-+]?\\d*\\.?\\d+)")
        func endChain() { if let c = cur, !c.segs.isEmpty { chains.append(c) }; cur = nil }
        for raw in Rx.c("\\r?\\n").split(text) {
            var s = Rx.c("\\(.*?\\)").replace(raw.uppercased(), "")
            if let i = s.firstIndex(of: ";") { s = String(s[..<i]) }
            s = s.trimmed
            if s.isEmpty || s.hasPrefix("%") { continue }
            let w = word.all(s).map { ($0.gv(1), Double($0.gv(2)) ?? 0) }
            if w.isEmpty { continue }
            var nx: Double? = nil, ny: Double? = nil, nz: Double? = nil, ii: Double? = nil, jj: Double? = nil, rr: Double? = nil
            for (c, v) in w {
                switch c {
                case "G": switch Int(v) { case 0, 1, 2, 3: mode = Int(v); case 20: k = 25.4; case 21: k = 1; case 90: absM = true; case 91: absM = false; default: break }
                case "X": nx = v * k; case "Y": ny = v * k; case "Z": nz = v * k; case "I": ii = v * k; case "J": jj = v * k; case "R": rr = v * k
                case "T": let t = Int(v); if t != tool { endChain(); tool = t }
                default: break
                }
            }
            if nx == nil && ny == nil && nz == nil { continue }
            let tx = nx == nil ? x : (absM ? nx! : x + nx!)
            let ty = ny == nil ? y : (absM ? ny! : y + ny!)
            let tz = nz == nil ? z : (absM ? nz! : z + nz!)
            moves += 1
            let cutting = mode != 0 && tz < o.cutBelow - 1e-6 && z < 1e8
            let xyMove = hypot(tx - x, ty - y) > 1e-6
            if cutting && xyMove {
                if !tools.contains(tool) { tools.append(tool) }; minZ = min(minZ, tz)
                let c: Chain; if let cc = cur { c = cc } else { c = Chain(tool, tz); c.x0 = x; c.y0 = y; cur = c }
                if mode == 1 { c.segs.append(LineSeg(tx, ty)) }
                else {
                    var cx: Double, cy: Double
                    if ii != nil || jj != nil { cx = x + (ii ?? 0); cy = y + (jj ?? 0) }
                    else { let r = rr ?? 0; let dx = tx - x, dy = ty - y; let d = hypot(dx, dy); let h = sqrt(max(0, r * r - d * d / 4))
                        let ccw = mode == 3; let sgn = Double((ccw ? 1 : -1) * (r < 0 ? -1 : 1))
                        cx = (x + tx) / 2 - dy / d * h * sgn; cy = (y + ty) / 2 + dx / d * h * sgn }
                    let ccw = mode == 3
                    if hypot(tx - x, ty - y) < 1e-6 { let mx = 2 * cx - x, my = 2 * cy - y; c.segs.append(ArcSeg(mx, my, cx, cy, ccw)); c.segs.append(ArcSeg(tx, ty, cx, cy, ccw)) }
                    else { c.segs.append(ArcSeg(tx, ty, cx, cy, ccw)) }
                }
            } else if !cutting && (xyMove || tz >= o.cutBelow) { endChain() }
            x = tx; y = ty; z = tz
        }
        endChain()
        var paths = chains.map { c -> VPath in let p = VPath(closed: false, x0: c.x0, y0: c.y0, segs: c.segs); p.layer = c.tool; return p }
        paths = Geom.joinChains(paths, 0.02)
        for p in paths where !p.closed && !p.segs.isEmpty { let l = p.segs.last!; if hypot(l.x - p.x0, l.y - p.y0) < 0.02 { l.x = p.x0; l.y = p.y0; p.closed = true } }
        if o.mergePasses {
            var seen = Set<String>(); var out: [VPath] = []
            for p in paths { let key = sig(p); if seen.contains(key) { continue }; seen.insert(key); out.append(p) }
            paths = out
        }
        let r = o.toolDia / 2
        if r > 0 && o.comp != "none" {
            let closed = paths.filter { $0.closed }, open = paths.filter { !$0.closed }
            var res = open
            for p in closed {
                let dist: Double
                switch o.comp {
                case "in": dist = -r
                case "out": dist = r
                default:
                    let f = Geom.flatten(p, 0.1); let pt = f.first ?? P(p.x0, p.y0)
                    let depth = closed.filter { q in q !== p && Geom.pointInPoly(pt.x, pt.y, Geom.flatten(q, 0.1)) }.count
                    dist = depth % 2 == 0 ? -r : r
                }
                let off = Geom.offset([p], dist, "sharp", 100); off.forEach { $0.layer = p.layer }; res.append(contentsOf: off)
            }
            paths = res
        }
        let tl = tools.isEmpty ? [1] : tools
        let multi = o.layerPerTool && tl.count > 1
        let layers = multi ? tl.map { "T\($0)" } : ["G-code"]
        for p in paths { p.layer = multi ? max(0, tl.firstIndex(of: p.layer) ?? -1) : 0 }
        let info = "Ходов: \(moves), векторов: \(paths.count), инструментов: \(tl.count)" + (minZ < 1e8 ? ", глубина до \(String(format: "%.2f", -minZ)) мм" : "")
        return Result(imp: Imported(paths, layers), tools: tl, moves: moves, minZ: minZ < 1e8 ? minZ : 0, info: info)
    }

    private static func sig(_ p: VPath) -> String {
        let b = Geom.bbox(p); func r(_ v: Double) -> Int64 { Int64((v + 0.5).rounded(.down)) }
        return "\(p.closed)|\(r(b.x1 * 20)),\(r(b.y1 * 20)),\(r(b.x2 * 20)),\(r(b.y2 * 20))|\(r(Geom.length(p) * 5))"
    }
}
