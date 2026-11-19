/* ЧПУ Редактор 2D — форматы: DXF (импорт / экспорт R12), SVG (импорт / экспорт со слоями Inkscape), PDF (экспорт 1:1). Порт Io.kt */
import Foundation

final class Imported {
    var paths: [VPath]; let layers: [String]; let width: Double; let height: Double
    init(_ paths: [VPath], _ layers: [String], _ width: Double = 0, _ height: Double = 0) { self.paths = paths; self.layers = layers; self.width = width; self.height = height }
}
struct IoError: Error, LocalizedError { let msg: String; var errorDescription: String? { msg } }

enum Io {
    private static let D2R = Double.pi / 180
    /// короткая запись числа с округлением до dec знаков
    static func num(_ v: Double, _ dec: Int = 6) -> String { fmtNum(v, dec) }

    // ================= DXF импорт =================
    private static func bulgeSeg(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double, _ b: Double) -> Seg {
        if abs(b) < 1e-12 { return LineSeg(x2, y2) }
        let dx = x2 - x1, dy = y2 - y1; let k = (1 - b * b) / (4 * b)
        return ArcSeg(x2, y2, (x1 + x2) / 2 - dy * k, (y1 + y2) / 2 + dx * k, b > 0)
    }
    private static func splinePts(_ deg: Int, _ knots0: [Double], _ ctrl: [P], _ weights: [Double]?) -> [P] {
        let n = ctrl.count; if n < 2 { return ctrl }
        let knots: [Double] = (knots0.isEmpty || knots0.count != n + deg + 1) ? (0..<(n + deg + 1)).map { Double($0 < deg + 1 ? 0 : ($0 > n - 1 ? n - deg : $0 - deg)) } : knots0
        let t0 = knots[deg], t1 = knots[n]; let steps = max(16, n * 12); var out: [P] = []
        for k in 0...steps {
            var t = t0 + (t1 - t0) * Double(k) / Double(steps); if k == steps { t -= 1e-10 }
            var s = deg; while s < n - 1 && t >= knots[s + 1] { s += 1 }
            var d: [[Double]] = (0...deg).map { j in let w = weights?[j + s - deg] ?? 1.0; let q = ctrl[j + s - deg]; return [q.x * w, q.y * w, w] }
            if deg >= 1 { for r in 1...deg { for j in stride(from: deg, through: r, by: -1) {
                let i = j + s - deg; let den = knots[i + deg - r + 1] - knots[i]; let a = (t - knots[i]) / (den == 0 ? 1 : den)
                d[j] = [(1 - a) * d[j - 1][0] + a * d[j][0], (1 - a) * d[j - 1][1] + a * d[j][1], (1 - a) * d[j - 1][2] + a * d[j][2]]
            } } }
            out.append(P(d[deg][0] / d[deg][2], d[deg][1] / d[deg][2]))
        }
        return out
    }
    typealias DP = (Int, String)
    private final class Ent { let type: String; var d: [DP] = []; var verts: [[DP]]? = nil; init(_ t: String) { type = t } }
    private final class Block { var name = ""; var bx = 0.0; var by = 0.0; var ents: [Ent] = [] }

    /// текст файла: UTF-8, если корректен, иначе Windows-1251 (старые DXF из ArtCAM/AutoCAD)
    static func decodeText(_ b: Data) -> String { String(data: b, encoding: .utf8) ?? String(data: b, encoding: .windowsCP1251) ?? String(decoding: b, as: UTF8.self) }

    static func importDXF(_ text: String) -> Imported {
        let L = Rx.c("\\r?\\n").split(text); var pairs: [DP] = []
        var i = 0; while i + 1 < L.count { pairs.append((L[i].trimmed.toIntOrNull() ?? -999, L[i + 1].trimmed)); i += 2 }
        var scale = 1.0
        for k in pairs.indices where pairs[k].0 == 9 && pairs[k].1 == "$INSUNITS" && k + 1 < pairs.count { scale = [1: 25.4, 2: 304.8, 4: 1.0, 5: 10.0, 6: 1000.0][pairs[k + 1].1.toIntOrNull() ?? -1] ?? 1.0 }
        var blocks: [String: Block] = [:]; var layers: [String] = []
        func layerIdx(_ n0: String?) -> Int { let n = (n0 ?? "").isEmpty ? "0" : n0!; if let x = layers.firstIndex(of: n) { return x }; layers.append(n); return layers.count - 1 }
        i = 0; var ents: [Ent] = []; var sect: String? = nil; var curBlock: Block? = nil
        while i < pairs.count {
            let (c, v) = pairs[i]
            if c == 0 && v == "SECTION" { sect = pairs.getOrNull(i + 1)?.1; i += 2; continue }
            if c == 0 && v == "ENDSEC" { sect = nil; i += 1; continue }
            if sect == "BLOCKS" && c == 0 && v == "BLOCK" {
                let b = Block(); i += 1
                while i < pairs.count && pairs[i].0 != 0 { let (cc, vv) = pairs[i]; if cc == 2 { b.name = vv }; if cc == 10 { b.bx = vv.toDoubleOrNull() ?? 0 }; if cc == 20 { b.by = vv.toDoubleOrNull() ?? 0 }; i += 1 }
                blocks[b.name] = b; curBlock = b; continue
            }
            if sect == "BLOCKS" && c == 0 && v == "ENDBLK" { curBlock = nil; i += 1; while i < pairs.count && pairs[i].0 != 0 { i += 1 }; continue }
            if (sect == "ENTITIES" || (sect == "BLOCKS" && curBlock != nil)) && c == 0 {
                let e = Ent(v); i += 1
                while i < pairs.count && pairs[i].0 != 0 { e.d.append(pairs[i]); i += 1 }
                if v == "POLYLINE" {
                    var vs: [[DP]] = []
                    while i < pairs.count && pairs[i].1 == "VERTEX" { var vt: [DP] = []; i += 1; while i < pairs.count && pairs[i].0 != 0 { vt.append(pairs[i]); i += 1 }; vs.append(vt) }
                    e.verts = vs
                    if i < pairs.count && pairs[i].1 == "SEQEND" { i += 1; while i < pairs.count && pairs[i].0 != 0 { i += 1 } }
                }
                if let cb = curBlock { cb.ents.append(e) } else { ents.append(e) }
                continue
            }
            i += 1
        }
        func num(_ d: [DP], _ code: Int, _ def: Double) -> Double { d.first { $0.0 == code }?.1.toDoubleOrNull() ?? def }
        func all(_ d: [DP], _ code: Int) -> [Double] { d.filter { $0.0 == code }.compactMap { $0.1.toDoubleOrNull() } }
        func conv(_ e: Ent, _ layerOverride: String?) -> [VPath] {
            let lay = layerIdx(layerOverride ?? e.d.first { $0.0 == 8 }?.1 ?? "0"); var res: [VPath] = []
            switch e.type {
            case "LINE": res.append(Geom.makePath([P(num(e.d, 10, 0), num(e.d, 20, 0)), P(num(e.d, 11, 0), num(e.d, 21, 0))], false, lay))
            case "CIRCLE": let p = Geom.Shapes.circle(num(e.d, 10, 0), num(e.d, 20, 0), num(e.d, 40, 1)); p.layer = lay; res.append(p)
            case "ARC":
                let cx = num(e.d, 10, 0), cy = num(e.d, 20, 0), r = num(e.d, 40, 1), a0 = num(e.d, 50, 0) * D2R, a1 = num(e.d, 51, 0) * D2R
                res.append(VPath(layer: lay, closed: false, x0: cx + r * cos(a0), y0: cy + r * sin(a0), segs: [ArcSeg(cx + r * cos(a1), cy + r * sin(a1), cx, cy, true)]))
            case "LWPOLYLINE", "POLYLINE":
                let closed = (Int(num(e.d, 70, 0)) & 1) != 0
                var V: [[Double]] = []
                if e.type == "LWPOLYLINE" { for (cc, vv) in e.d { let f = vv.toDoubleOrNull() ?? 0; switch cc { case 10: V.append([f, 0, 0]); case 20: if !V.isEmpty { V[V.count - 1][1] = f }; case 42: if !V.isEmpty { V[V.count - 1][2] = f }; default: break } } }
                else { for it in e.verts ?? [] where (Int(num(it, 70, 0)) & 16) == 0 { V.append([num(it, 10, 0), num(it, 20, 0), num(it, 42, 0)]) } }
                if V.count >= 2 {
                    let p = VPath(layer: lay, closed: closed, x0: V[0][0], y0: V[0][1])
                    let n = closed ? V.count : V.count - 1
                    for k in 0..<n { let a = V[k], b = V[(k + 1) % V.count]; p.segs.append(bulgeSeg(a[0], a[1], b[0], b[1], a[2])) }
                    res.append(p)
                }
            case "ELLIPSE":
                let cx = num(e.d, 10, 0), cy = num(e.d, 20, 0), mx = num(e.d, 11, 1), my = num(e.d, 21, 0), ratio = num(e.d, 40, 1), t0 = num(e.d, 41, 0), t1 = num(e.d, 42, 2 * .pi)
                let a = hypot(mx, my), ang = atan2(my, mx), b = a * ratio; var pts: [P] = []; var sw = t1 - t0; if sw <= 0 { sw += 2 * .pi }
                let n = max(24, Int(ceil(sw / (2 * .pi) * 96)))
                for k in 0...n { let t = t0 + sw * Double(k) / Double(n); let x = a * cos(t), y = b * sin(t); pts.append(P(cx + x * cos(ang) - y * sin(ang), cy + x * sin(ang) + y * cos(ang))) }
                let full = abs(sw - 2 * .pi) < 1e-6; if full { pts.removeLast() }
                res.append(Geom.makePath(pts, full, lay))
            case "SPLINE":
                let deg = Int(num(e.d, 71, 3)); let knots = all(e.d, 40), xs = all(e.d, 10), ys = all(e.d, 20), ws = all(e.d, 41)
                let ctrl = xs.indices.filter { $0 < ys.count }.map { P(xs[$0], ys[$0]) }
                var pts: [P]
                if ctrl.count >= 2 { pts = splinePts(deg, knots, ctrl, ws.count == ctrl.count ? ws : nil) }
                else { let fx = all(e.d, 11), fy = all(e.d, 21); pts = fx.indices.filter { $0 < fy.count }.map { P(fx[$0], fy[$0]) } }
                if pts.count > 1 { let closed = (Int(num(e.d, 70, 0)) & 1) != 0; if closed { pts.removeLast() }; res.append(Geom.makePath(pts, closed, lay)) }
            case "INSERT":
                if let b = blocks[e.d.first { $0.0 == 2 }?.1 ?? ""] {
                    let ix = num(e.d, 10, 0), iy = num(e.d, 20, 0), sx = num(e.d, 41, 1), sy = num(e.d, 42, sx), rot = num(e.d, 50, 0) * D2R
                    let c = cos(rot), s = sin(rot)
                    let m = [c * sx, s * sx, -s * sy, c * sy, ix - (c * sx * b.bx - s * sy * b.by), iy - (s * sx * b.bx + c * sy * b.by)]
                    let layName = e.d.first { $0.0 == 8 }?.1 ?? "0"
                    for be in b.ents { for p in conv(be, layName) { res.append(Geom.transform(p, m)) } }
                }
            default: break
            }
            return res
        }
        var out: [VPath] = []
        for e in ents { out.append(contentsOf: conv(e, nil)) }
        if scale != 1 { out.forEach { Geom.transform($0, Geom.M.scale(scale, scale, 0, 0)) } }
        if layers.isEmpty { layers.append("0") }
        return Imported(Geom.joinChains(out, 0.001), layers)
    }

    // ================= DXF экспорт (R12) =================
    /// данные проекта внутри DXF — комментарии 999 перед EOF (другие программы их пропускают)
    static func embedProject(_ dxf: String, _ json: String) -> String {
        let b64 = Data(json.utf8).base64EncodedString(); var sb = ""
        let chars = Array(b64); var i = 0
        while i < chars.count { sb += "999\r\nCNC2D:" + String(chars[i..<min(chars.count, i + 240)]) + "\r\n"; i += 240 }
        return Rx.c("0\\r?\\nEOF\\s*$").replace(dxf, sb + "0\r\nEOF\r\n")
    }
    static func extractProject(_ text: String) -> String? {
        let L = Rx.c("\\r?\\n").split(text); var b = ""
        if L.count > 1 { for i in 0..<(L.count - 1) where L[i].trimmed == "999" && L[i + 1].hasPrefix("CNC2D:") { b += L[i + 1].sub(6).trimmed } }
        if b.isEmpty { return nil }
        guard let d = Data(base64Encoded: b) else { return nil }
        return String(data: d, encoding: .utf8)
    }
    static func exportDXF(_ paths: [VPath], _ layerNames: [String]) -> String {
        var o: [String] = []; func w(_ c: Int, _ v: Any) { o.append(String(c)); o.append("\(v)") }
        func f(_ n: Double) -> String { num(n, 6) }
        w(0, "SECTION"); w(2, "HEADER"); w(9, "$ACADVER"); w(1, "AC1009"); w(9, "$INSUNITS"); w(70, 4); w(0, "ENDSEC")
        w(0, "SECTION"); w(2, "TABLES"); w(0, "TABLE"); w(2, "LAYER"); w(70, layerNames.count)
        for (i, n) in layerNames.enumerated() { w(0, "LAYER"); w(2, n); w(70, 0); w(62, (i % 7) + 1); w(6, "CONTINUOUS") }
        w(0, "ENDTAB"); w(0, "ENDSEC")
        w(0, "SECTION"); w(2, "ENTITIES")
        for p in paths {
            let lay = layerNames.getOrNull(p.layer) ?? "0"
            if let sh = p.shape, sh.type == "circle" { w(0, "CIRCLE"); w(8, lay); w(10, f(sh.v["cx"]!)); w(20, f(sh.v["cy"]!)); w(30, 0); w(40, f(sh.v["r"]!)); continue }
            var V: [[Double]] = []; var px = p.x0, py = p.y0
            V.append([px, py, 0])
            for s in p.segs {
                if let a = s as? ArcSeg { let sw = Geom.arcAngles(px, py, a).sw; V[V.count - 1][2] = tan(sw / 4); V.append([s.x, s.y, 0]) }
                else if let b = s as? BezSeg { let fl = Geom.flatten(VPath(x0: px, y0: py, segs: [b]), 0.01); for k in 1..<fl.count { V.append([fl[k].x, fl[k].y, 0]) } }
                else { V.append([s.x, s.y, 0]) }
                px = s.x; py = s.y
            }
            if p.closed && V.count > 1 { let a = V[0], b = V.last!; if abs(a[0] - b[0]) < 1e-7 && abs(a[1] - b[1]) < 1e-7 { V.removeLast() } }
            w(0, "POLYLINE"); w(8, lay); w(66, 1); w(10, 0); w(20, 0); w(30, 0); w(70, p.closed ? 1 : 0)
            for v in V { w(0, "VERTEX"); w(8, lay); w(10, f(v[0])); w(20, f(v[1])); w(30, 0); if v[2] != 0 { w(42, f(v[2])) } }
            w(0, "SEQEND"); w(8, lay)
        }
        w(0, "ENDSEC"); w(0, "EOF")
        return o.joined(separator: "\r\n") + "\r\n"
    }

    // ================= SVG импорт =================
    private static let UNIT: [String: Double] = ["mm": 1, "cm": 10, "in": 25.4, "pt": 25.4 / 72, "pc": 25.4 / 6, "px": 25.4 / 96, "": 25.4 / 96]
    private static func len(_ s: String?) -> Double? {
        guard let s = s, let m = Rx.c("^\\s*([-+\\d.eE]+)\\s*([a-z%]*)").first(s), let v = m.gv(1).toDoubleOrNull() else { return nil }
        return v * (UNIT[m.gv(2)] ?? 1)
    }
    final class XNode { let tag: String; var attrs: [String: String]; var kids: [XNode] = []; init(_ t: String, _ a: [String: String]) { tag = t; attrs = a } }
    static func parseXml(_ text0: String) -> XNode {
        let root = XNode("#root", [:]); var st: [XNode] = [root]
        var text = Rx.c("<!--[\\s\\S]*?-->").replace(text0, "")
        text = Rx.c("<!\\[CDATA\\[[\\s\\S]*?\\]\\]>").replace(text, "")
        text = Rx.c("<\\?[\\s\\S]*?\\?>").replace(text, "")
        text = Rx.c("(?i)<!DOCTYPE[\\s\\S]*?>").replace(text, "")
        let re = Rx.c("</?([A-Za-z_][\\w:.-]*)((?:\\s+[\\w:.-]+\\s*=\\s*(?:\"[^\"]*\"|'[^']*'))*)\\s*(/?)>")
        let ar = Rx.c("([\\w:.-]+)\\s*=\\s*(\"([^\"]*)\"|'([^']*)')")
        for m in re.all(text) {
            if m.value.ch(1) == "/" { if st.count > 1 { st.removeLast() }; continue }
            var attrs: [String: String] = [:]
            for a in ar.all(m.gv(2)) { attrs[a.gv(1)] = a.g(3) ?? a.gv(4) }
            if let st0 = attrs["style"] { for kv in st0.split(separator: ";") { let kvs = String(kv); if let ix = kvs.firstIndex(of: ":"), ix > kvs.startIndex { let k = String(kvs[..<ix]).trimmed; if attrs[k] == nil { attrs[k] = String(kvs[kvs.index(after: ix)...]).trimmed } } } }
            let node = XNode(m.gv(1).removePrefix("svg:"), attrs); st.last!.kids.append(node)
            if m.gv(3).isEmpty { st.append(node) }
        }
        return root
    }
    static func mul(_ a: [Double], _ b: [Double]) -> [Double] { [a[0] * b[0] + a[2] * b[1], a[1] * b[0] + a[3] * b[1], a[0] * b[2] + a[2] * b[3], a[1] * b[2] + a[3] * b[3], a[0] * b[4] + a[2] * b[5] + a[4], a[1] * b[4] + a[3] * b[5] + a[5]] }
    private static func parseTransform(_ s: String?) -> [Double] {
        var m: [Double] = [1, 0, 0, 1, 0, 0]; guard let s = s, !s.trimmed.isEmpty else { return m }
        for t in Rx.c("(matrix|translate|scale|rotate|skewX|skewY)\\s*\\(([^)]*)\\)").all(s) {
            let a = Rx.c("[\\s,]+").split(t.gv(2)).filter { !$0.isEmpty }.map { $0.toDoubleOrNull() ?? 0 }
            func ga(_ i: Int, _ d: Double) -> Double { i < a.count ? a[i] : d }
            let n: [Double]
            switch t.gv(1) {
            case "matrix": n = a.count >= 6 ? Array(a.prefix(6)) : [1, 0, 0, 1, 0, 0]
            case "translate": n = [1, 0, 0, 1, ga(0, 0), ga(1, 0)]
            case "scale": n = [ga(0, 1), 0, 0, ga(1, ga(0, 1)), 0, 0]
            case "rotate":
                let r = ga(0, 0) * D2R; let c = cos(r), s2 = sin(r); var n0: [Double] = [c, s2, -s2, c, 0, 0]
                if a.count > 2 { n0 = mul(mul([1, 0, 0, 1, a[1], a[2]], n0), [1, 0, 0, 1, -a[1], -a[2]]) }
                n = n0
            case "skewX": n = [1, 0, tan(ga(0, 0) * D2R), 1, 0, 0]
            default: n = [1, tan(ga(0, 0) * D2R), 0, 1, 0, 0]
            }
            m = mul(m, n)
        }
        return m
    }
    final class Contour { var x0: Double; var y0: Double; var segs: [Seg] = []; var closed = false; init(_ x: Double, _ y: Double) { x0 = x; y0 = y } }
    static func pathD(_ d: String) -> [Contour] {
        var toks = Rx.c("[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\\d*\\.\\d+|\\d+\\.?)(?:[eE][-+]?\\d+)?").all(d).map { $0.value }
        var res: [Contour] = []; var i = 0; var cmd = ""; var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0; var cur: Contour? = nil; var lq: P? = nil
        func n() -> Double { let v = toks.getOrNull(i)?.toDoubleOrNull() ?? 0; i += 1; return v }
        func flag() -> Int {
            guard let t = toks.getOrNull(i) else { return 0 }
            if t.count > 1 && (t.first == "0" || t.first == "1") { toks[i] = String(t.dropFirst()); return t.first == "1" ? 1 : 0 }
            i += 1; return Int(t.toDoubleOrNull() ?? 0)
        }
        func isLetter(_ s: String) -> Bool { s.first?.isLetter ?? false }
        while i < toks.count {
            if isLetter(toks[i]) { cmd = toks[i]; i += 1 }
            if cmd.isEmpty { i += 1; continue }
            let rel = cmd == cmd.lowercased(); let C = cmd.uppercased()
            if C == "Z" { if let c = cur { c.closed = true; if hypot(x - sx, y - sy) > 1e-9 { c.segs.append(LineSeg(sx, sy)) } }; x = sx; y = sy; cur = nil; lq = nil; if i < toks.count && !isLetter(toks[i]) { i += 1 }; continue }
            if C == "M" { x = (rel ? x : 0) + n(); y = (rel ? y : 0) + n(); sx = x; sy = y; let c = Contour(x, y); cur = c; res.append(c); cmd = rel ? "l" : "L"; lq = nil; continue }
            let c0: Contour
            if let c = cur { c0 = c } else { let c = Contour(x, y); res.append(c); cur = c; c0 = c }
            switch C {
            case "L": x = (rel ? x : 0) + n(); y = (rel ? y : 0) + n(); c0.segs.append(LineSeg(x, y)); lq = nil
            case "H": x = (rel ? x : 0) + n(); c0.segs.append(LineSeg(x, y)); lq = nil
            case "V": y = (rel ? y : 0) + n(); c0.segs.append(LineSeg(x, y)); lq = nil
            case "C", "S":
                let x1: Double, y1: Double
                if C == "C" { x1 = (rel ? x : 0) + n(); y1 = (rel ? y : 0) + n() } else { let l = c0.segs.last as? BezSeg; x1 = l != nil ? 2 * x - l!.x2 : x; y1 = l != nil ? 2 * y - l!.y2 : y }
                let x2 = (rel ? x : 0) + n(), y2 = (rel ? y : 0) + n(), ex = (rel ? x : 0) + n(), ey = (rel ? y : 0) + n()
                c0.segs.append(BezSeg(x1, y1, x2, y2, ex, ey)); x = ex; y = ey; lq = nil
            case "Q", "T":
                let qx: Double, qy: Double
                if C == "Q" { qx = (rel ? x : 0) + n(); qy = (rel ? y : 0) + n() } else { qx = lq != nil ? 2 * x - lq!.x : x; qy = lq != nil ? 2 * y - lq!.y : y }
                let ex = (rel ? x : 0) + n(), ey = (rel ? y : 0) + n()
                c0.segs.append(BezSeg(x + 2.0 / 3 * (qx - x), y + 2.0 / 3 * (qy - y), ex + 2.0 / 3 * (qx - ex), ey + 2.0 / 3 * (qy - ey), ex, ey)); x = ex; y = ey; lq = P(qx, qy)
            case "A":
                let rx = abs(n()), ry = abs(n()), phi = n() * D2R; let fa = flag(), fs = flag(); let ex = (rel ? x : 0) + n(), ey = (rel ? y : 0) + n()
                c0.segs.append(contentsOf: arcSvg(x, y, rx, ry, phi, fa, fs, ex, ey)); x = ex; y = ey; lq = nil
            default: i += 1
            }
        }
        return res
    }
    private static func arcSvg(_ x1: Double, _ y1: Double, _ rx0: Double, _ ry0: Double, _ phi: Double, _ fa: Int, _ fs: Int, _ x2: Double, _ y2: Double) -> [Seg] {
        var rx = rx0, ry = ry0
        if rx == 0 || ry == 0 { return [LineSeg(x2, y2)] }
        let c = cos(phi), s = sin(phi), dx = (x1 - x2) / 2, dy = (y1 - y2) / 2
        let xp = c * dx + s * dy, yp = -s * dx + c * dy; let L = xp * xp / (rx * rx) + yp * yp / (ry * ry); if L > 1 { rx *= sqrt(L); ry *= sqrt(L) }
        var k = sqrt(max(0, (rx * rx * ry * ry - rx * rx * yp * yp - ry * ry * xp * xp) / (rx * rx * yp * yp + ry * ry * xp * xp))); if fa == fs { k = -k }
        let cxp = k * rx * yp / ry, cyp = -k * ry * xp / rx; let cx = c * cxp - s * cyp + (x1 + x2) / 2, cy = s * cxp + c * cyp + (y1 + y2) / 2
        func ang(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double { atan2(ux * vy - uy * vx, ux * vx + uy * vy) }
        let t1 = ang(1, 0, (xp - cxp) / rx, (yp - cyp) / ry); var dt = ang((xp - cxp) / rx, (yp - cyp) / ry, (-xp - cxp) / rx, (-yp - cyp) / ry)
        if fs == 0 && dt > 0 { dt -= 2 * .pi } else if fs == 1 && dt < 0 { dt += 2 * .pi }
        let nseg = max(1, Int(ceil(abs(dt) / (.pi / 2)))); let d = dt / Double(nseg); let kk = 4.0 / 3 * tan(d / 4); var out: [Seg] = []
        func Pt(_ t: Double) -> P { P(cx + rx * cos(t) * c - ry * sin(t) * s, cy + rx * cos(t) * s + ry * sin(t) * c) }
        func Dv(_ t: Double) -> P { P(-rx * sin(t) * c - ry * cos(t) * s, -rx * sin(t) * s + ry * cos(t) * c) }
        for i in 0..<nseg { let a = t1 + d * Double(i); let b = a + d; let p0 = Pt(a), p3 = Pt(b), d0 = Dv(a), d3 = Dv(b); out.append(BezSeg(p0.x + kk * d0.x, p0.y + kk * d0.y, p3.x - kk * d3.x, p3.y - kk * d3.y, p3.x, p3.y)) }
        out.last!.x = x2; out.last!.y = y2; return out
    }
    static func importSVG(_ text: String) throws -> Imported {
        let root = parseXml(text)
        func find(_ n: XNode) -> XNode? { if n.tag == "svg" { return n }; for k in n.kids { if let r = find(k) { return r } }; return nil }
        guard let svg = find(root) else { throw IoError(msg: "SVG: нет элемента <svg>") }
        let vb = Rx.c("[\\s,]+").split(svg.attrs["viewBox"] ?? "").filter { !$0.isEmpty }.compactMap { $0.toDoubleOrNull() }
        var W = len(svg.attrs["width"]), H = len(svg.attrs["height"]); let px = UNIT["px"]!
        var base: [Double] = [px, 0, 0, px, 0, 0]
        if vb.count == 4 { if W == nil { W = vb[2] * px }; if H == nil { H = vb[3] * px }; base = [W! / vb[2], 0, 0, H! / vb[3], -vb[0] * W! / vb[2], -vb[1] * H! / vb[3]] }
        let Wd = W ?? 0, Hd = H ?? 0
        let flip: [Double] = [1, 0, 0, -1, 0, Hd]
        var layers = ["0"]; var paths: [VPath] = []
        func walk(_ n: XNode, _ m: [Double], _ lay0: Int) {
            var lay = lay0
            if n.attrs["display"] == "none" || ["defs", "clipPath", "mask", "symbol", "metadata"].contains(n.tag) { return }
            let mm = mul(m, parseTransform(n.attrs["transform"]))
            if n.tag == "g" && n.attrs["inkscape:groupmode"] == "layer" { layers.append(n.attrs["inkscape:label"] ?? n.attrs["id"] ?? ("Слой " + String(layers.count))); lay = layers.count - 1 }
            let A = n.attrs
            func nn(_ k: String) -> Double { guard let s = A[k], let m = Rx.c("^\\s*[-+\\d.eE]+").first(s) else { return 0 }; return m.value.trimmed.toDoubleOrNull() ?? 0 }
            func f(_ v: Double) -> String { "\(v)" }
            var contours: [Contour]? = nil
            switch n.tag {
            case "path": contours = pathD(A["d"] ?? "")
            case "rect":
                let x = nn("x"), y = nn("y"), w = nn("width"), h = nn("height"); var rx = A["rx"] != nil ? nn("rx") : (A["ry"] != nil ? nn("ry") : 0); var ry = A["ry"] != nil ? nn("ry") : rx; rx = min(rx, w / 2); ry = min(ry, h / 2)
                if rx > 0 || ry > 0 {
                    contours = pathD("M\(f(x + rx)),\(f(y))H\(f(x + w - rx))A\(f(rx)),\(f(ry)) 0 0 1 \(f(x + w)),\(f(y + ry))V\(f(y + h - ry))A\(f(rx)),\(f(ry)) 0 0 1 \(f(x + w - rx)),\(f(y + h))H\(f(x + rx))A\(f(rx)),\(f(ry)) 0 0 1 \(f(x)),\(f(y + h - ry))V\(f(y + ry))A\(f(rx)),\(f(ry)) 0 0 1 \(f(x + rx)),\(f(y))Z")
                } else { contours = pathD("M\(f(x)),\(f(y))H\(f(x + w))V\(f(y + h))H\(f(x))Z") }
            case "circle", "ellipse":
                let cx = nn("cx"), cy = nn("cy"); let rx = n.tag == "circle" ? nn("r") : nn("rx"); let ry = n.tag == "circle" ? nn("r") : nn("ry")
                contours = pathD("M\(f(cx + rx)),\(f(cy))A\(f(rx)),\(f(ry)) 0 0 1 \(f(cx)),\(f(cy + ry))A\(f(rx)),\(f(ry)) 0 0 1 \(f(cx - rx)),\(f(cy))A\(f(rx)),\(f(ry)) 0 0 1 \(f(cx)),\(f(cy - ry))A\(f(rx)),\(f(ry)) 0 0 1 \(f(cx + rx)),\(f(cy))Z")
            case "line": contours = pathD("M\(f(nn("x1"))),\(f(nn("y1")))L\(f(nn("x2"))),\(f(nn("y2")))")
            case "polyline", "polygon":
                let p = Rx.c("[\\s,]+").split((A["points"] ?? "").trimmed).compactMap { $0.toDoubleOrNull() }
                if p.count >= 4 { contours = pathD("M" + p.map { "\($0)" }.joined(separator: " ") + (n.tag == "polygon" ? "Z" : "")) }
            default: break
            }
            if let contours = contours {
                let T = mul(flip, mul(base, mm))
                for c in contours where !c.segs.isEmpty { paths.append(Geom.transform(VPath(layer: lay, closed: c.closed, x0: c.x0, y0: c.y0, segs: c.segs), T)) }
            }
            for k in n.kids { walk(k, mm, lay) }
        }
        walk(svg, [1, 0, 0, 1, 0, 0], 0)
        return Imported(paths, layers, Wd, Hd)
    }

    // ================= SVG экспорт =================
    private static func pathToD(_ p: VPath, _ H: Double) -> String {
        func f(_ n: Double) -> String { num(n, 3) }
        func Y(_ y: Double) -> String { f(H - y) }
        var d = "M\(f(p.x0)),\(Y(p.y0))"; var px = p.x0, py = p.y0
        for s in p.segs {
            if let b = s as? BezSeg { d += "C\(f(b.x1)),\(Y(b.y1)) \(f(b.x2)),\(Y(b.y2)) \(f(b.x)),\(Y(b.y))" }
            else if let a = s as? ArcSeg {
                let ai = Geom.arcAngles(px, py, a)
                if abs(abs(ai.sw) - 2 * .pi) < 1e-6 { for b in Geom.arcToBeziers(P(px, py), a) { d += "C\(f(b.x1)),\(Y(b.y1)) \(f(b.x2)),\(Y(b.y2)) \(f(b.x)),\(Y(b.y))" } }
                else { d += "A\(f(ai.r)),\(f(ai.r)) 0 \(abs(ai.sw) > .pi ? 1 : 0) \(a.ccw ? 0 : 1) \(f(a.x)),\(Y(a.y))" }
            } else { d += "L\(f(s.x)),\(Y(s.y))" }
            px = s.x; py = s.y
        }
        if p.closed { d += "Z" }; return d
    }
    static func exportSVG(_ paths: [VPath], _ layerNames: [String], _ W: Double, _ H: Double) -> String {
        func f(_ n: Double) -> String { num(n, 3) }
        var s = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:inkscape=\"http://www.inkscape.org/namespaces/inkscape\" width=\"\(f(W))mm\" height=\"\(f(H))mm\" viewBox=\"0 0 \(f(W)) \(f(H))\">\n"
        for (li, nm) in layerNames.enumerated() {
            let ps = paths.filter { $0.layer == li }; if ps.isEmpty { continue }
            s += "<g inkscape:groupmode=\"layer\" inkscape:label=\"\(Rx.c("[<&\"]").replace(nm, ""))\" fill=\"none\" stroke=\"#000\" stroke-width=\"0.2\">\n"
            for p in ps { s += "<path d=\"\(pathToD(p, H))\"/>\n" }
            s += "</g>\n"
        }
        s += "</svg>\n"; return s
    }

    // ================= PDF экспорт (вектор, 1:1) =================
    static func exportPDF(_ paths: [VPath], _ W: Double, _ H: Double, _ frame: Bool = false) -> Data {
        let k = 72 / 25.4; func f(_ n: Double) -> String { num(n * k, 3) }
        var c = "0.5 w 0 0 0 RG 1 J 1 j\n"
        if frame { c += "0.3 w 0.6 0.6 0.6 RG 0 0 \(f(W)) \(f(H)) re S 0.5 w 0 0 0 RG\n" }
        for p in paths {
            var px = p.x0, py = p.y0; c += "\(f(px)) \(f(py)) m\n"
            for s in p.segs {
                if let b = s as? BezSeg { c += "\(f(b.x1)) \(f(b.y1)) \(f(b.x2)) \(f(b.y2)) \(f(b.x)) \(f(b.y)) c\n" }
                else if let a = s as? ArcSeg { for b in Geom.arcToBeziers(P(px, py), a) { c += "\(f(b.x1)) \(f(b.y1)) \(f(b.x2)) \(f(b.y2)) \(f(b.x)) \(f(b.y)) c\n" } }
                else { c += "\(f(s.x)) \(f(s.y)) l\n" }
                px = s.x; py = s.y
            }
            c += p.closed ? "h S\n" : "S\n"
        }
        let objs = ["<< /Type /Catalog /Pages 2 0 R >>", "<< /Type /Pages /Kids [3 0 R] /Count 1 >>", "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 \(f(W)) \(f(H))] /Contents 4 0 R >>", "<< /Length \(c.utf8.count) >>\nstream\n\(c)endstream"]
        var pdf = "%PDF-1.4\n"; var offs: [Int] = []
        for (i, o) in objs.enumerated() { offs.append(pdf.utf8.count); pdf += "\(i + 1) 0 obj\n\(o)\nendobj\n" }
        let x = pdf.utf8.count
        pdf += "xref\n0 \(objs.count + 1)\n0000000000 65535 f \n"; for o in offs { pdf += String(o).padStart(10, "0") + " 00000 n \n" }
        pdf += "trailer\n<< /Size \(objs.count + 1) /Root 1 0 R >>\nstartxref\n\(x)\n%%EOF\n"
        return pdf.data(using: .isoLatin1) ?? Data(pdf.utf8)
    }
}
