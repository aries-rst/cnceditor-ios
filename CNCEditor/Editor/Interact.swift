/* Выбор, перемещение, масштаб, поворот, рамка выбора и редактирование узлов (порт Interact.kt; экран только передаёт касания). */
import Foundation

/// Выбор векторов пальцем: касание — выбрать, тянуть по выбранному — двигать, ручки — масштаб/поворот,
/// тянуть по пустому месту — рамка (слева→направо — целиком внутри, справа→налево — касающиеся).
final class SelectTool: CanvasTool {
    private enum M { case none, move, scale, rotate, band }
    let doc: Doc; let multi: () -> Bool
    private var m = M.none
    private var a = P(0, 0), cur = P(0, 0)
    private var orig: [(VPath, VPath)] = []
    private var bb0 = BBox(0, 0, 0, 0); private var handle = 0; private var pushed = false; private var tol = 1.0
    /// включённый режим «добавлять к выбору» после долгого нажатия
    var stickyMulti = false
    init(_ doc: Doc, _ multi: @escaping () -> Bool) { self.doc = doc; self.multi = multi }
    private func isMulti() -> Bool { multi() || stickyMulti }

    /// ручки рамки выбора: 0..3 углы (ЛН, ПН, ПВ, ЛВ), 4 — поворот
    func handles(_ tol: Double) -> [P] {
        let s = doc.selected(); if s.isEmpty { return [] }; let b = Geom.bbox(s)
        return [P(b.x1, b.y1), P(b.x2, b.y1), P(b.x2, b.y2), P(b.x1, b.y2), P(b.cx, b.y2 + tol * 4)]
    }
    func hit(_ x: Double, _ y: Double, _ tol: Double) -> VPath? {
        var best: VPath? = nil; var bd = tol
        for p in doc.paths.reversed() { if !doc.visible(p) { continue }; let d = Geom.distToPath(p, x, y, max(0.05, tol / 4)); if d <= bd { bd = d; best = p } }
        if best == nil { for p in doc.paths.reversed() where doc.visible(p) && p.closed && Geom.pointInPoly(x, y, Geom.flatten(p, tol / 2)) {
            let b = Geom.bbox(p); if b.w < 60 * tol && b.h < 60 * tol { return p } } }
        return best
    }
    func down(_ x: Double, _ y: Double, _ tol: Double) -> Bool {
        self.tol = tol; a = P(x, y); cur = a; pushed = false
        let hs = handles(tol)
        if !isMulti() { for (i, h) in hs.enumerated() where hypot(h.x - x, h.y - y) <= tol * 1.3 { start(i == 4 ? .rotate : .scale); handle = i; return true } }
        if let p = hit(x, y, tol) {
            if isMulti() { doc.selectPath(p, true); doc.changed(); m = .none; return true }
            if !doc.isSel(p.id) { doc.selectPath(p, false) }
            if !doc.editable(p) { m = .none; return true }
            start(.move); return true
        }
        m = .band; return true
    }
    private func start(_ mode: M) { m = mode; let s = doc.selected().filter { doc.editable($0) }; orig = s.map { ($0, $0.copy(newId: false)) }; bb0 = Geom.bbox(s) }
    func move(_ x: Double, _ y: Double) -> Bool {
        cur = P(x, y); if m == .none { return false }
        if m == .band { return true }
        if !pushed { if hypot(x - a.x, y - a.y) < tol * 0.3 { return false }; doc.push(); pushed = true }
        let mt: [Double]
        switch m {
        case .move: mt = Geom.M.move(x - a.x, y - a.y)
        case .scale:
            let o: P = [P(bb0.x2, bb0.y2), P(bb0.x1, bb0.y2), P(bb0.x1, bb0.y1), P(bb0.x2, bb0.y1)][min(handle, 3)]
            let c0: P = [P(bb0.x1, bb0.y1), P(bb0.x2, bb0.y1), P(bb0.x2, bb0.y2), P(bb0.x1, bb0.y2)][min(handle, 3)]
            let sx = abs(c0.x - o.x) < 1e-9 ? 1 : (x - o.x) / (c0.x - o.x); let sy = abs(c0.y - o.y) < 1e-9 ? 1 : (y - o.y) / (c0.y - o.y)
            let k = max(0.01, (abs(sx) + abs(sy)) / 2) // пропорционально
            mt = Geom.M.scale(k, k, o.x, o.y)
        case .rotate:
            let a0 = atan2(a.y - bb0.cy, a.x - bb0.cx), a1 = atan2(y - bb0.cy, x - bb0.cx); let deg = Double(kround(-(a1 - a0) * 180 / .pi)); mt = Geom.M.rotate(deg, bb0.cx, bb0.cy)
        default: return false
        }
        for (p, o) in orig { let c = o.copy(newId: false); Geom.transform(c, mt); p.x0 = c.x0; p.y0 = c.y0; p.segs = c.segs; p.shape = m == .move ? o.shape.map { moveShape($0, x - a.x, y - a.y) } : nil
            if m == .move { p.text = o.text.map { t in let n = t.copy(); n.x = t.x + x - a.x; n.y = t.y + y - a.y; return n } } }
        doc.changed(); return true
    }
    private func moveShape(_ s: Shape, _ dx: Double, _ dy: Double) -> Shape { var v = s.v; if let c = v["cx"] { v["cx"] = c + dx }; if let c = v["cy"] { v["cy"] = c + dy }; return Shape(s.type, v) }
    func up() {
        if m == .band {
            let x1 = min(a.x, cur.x), x2 = max(a.x, cur.x), y1 = min(a.y, cur.y), y2 = max(a.y, cur.y)
            if x2 - x1 < tol * 0.5 && y2 - y1 < tol * 0.5 { if !isMulti() { doc.clearSel() } }
            else {
                let crossing = cur.x < a.x
                if !isMulti() { doc.selClear() }
                for p in doc.paths { if !doc.editable(p) { continue }; let b = Geom.bbox(p)
                    let ok: Bool
                    if !crossing { ok = b.x1 >= x1 && b.x2 <= x2 && b.y1 >= y1 && b.y2 <= y2 }
                    else { ok = b.x2 >= x1 && b.x1 <= x2 && b.y2 >= y1 && b.y1 <= y2 && { let f = Geom.flatten(p, tol / 2); return f.contains { $0.x >= x1 && $0.x <= x2 && $0.y >= y1 && $0.y <= y2 } || crossesRect(f, x1, y1, x2, y2) }() }
                    if ok { doc.groupMembers(p).forEach { doc.selAdd($0.id) } } }
                doc.changed()
            }
        }
        m = .none; orig = []
    }
    private func crossesRect(_ f: [P], _ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> Bool {
        let e = [(P(x1, y1), P(x2, y1)), (P(x2, y1), P(x2, y2)), (P(x2, y2), P(x1, y2)), (P(x1, y2), P(x1, y1))]
        for i in 1..<f.count { for (p, q) in e where segX(f[i - 1], f[i], p, q) { return true } }; return false
    }
    private func segX(_ a: P, _ b: P, _ c: P, _ d: P) -> Bool { func cr(_ o: P, _ p: P, _ q: P) -> Double { (p.x - o.x) * (q.y - o.y) - (p.y - o.y) * (q.x - o.x) }
        let d1 = cr(c, d, a), d2 = cr(c, d, b), d3 = cr(a, b, c), d4 = cr(a, b, d); return d1 * d2 < 0 && d3 * d4 < 0 }
    /// долгое нажатие: включает выбор нескольких и добавляет вектор
    func longPress(_ x: Double, _ y: Double, _ tol: Double) -> Bool { guard let p = hit(x, y, tol) else { return false }; stickyMulti = true; doc.selectPath(p, true); doc.changed(); return true }
    func overlay() -> [Ov] {
        var o: [Ov] = []
        if m == .band { let crossing = cur.x < a.x; o.append(.poly(pts: [a, P(cur.x, a.y), cur, P(a.x, cur.y)], color: crossing ? 0xFF1F9A3A : 0xFF2A62B8, width: 1.2, dash: crossing, closed: true)) }
        return o
    }
    var hint: String { isMulti() ? "Касание добавляет или убирает вектор. Рамка добавляет к выбору." : "Касание — выбрать, тянуть — двигать; рамка: слева→направо — внутри, справа→налево — касающиеся" }
}

/// Редактирование узлов: тянуть точки и управляющие точки кривых; действия над узлом и участком.
final class NodeTool: CanvasTool {
    /// выбранный узел: путь, индекс (-1 — начальная точка, иначе конец участка i), ctrl 0 — сам узел, 1/2 — управляющие точки участка i
    struct NodeRef { let p: VPath; let i: Int; var ctrl = 0 }
    let doc: Doc
    var selNode: NodeRef? = nil; var selSeg: (VPath, Int)? = nil; var segAt: P? = nil
    private var drag: NodeRef? = nil; private var pushed = false; private var a = P(0, 0)
    init(_ doc: Doc) { self.doc = doc }
    private func segStart(_ p: VPath, _ i: Int) -> P { i == 0 ? P(p.x0, p.y0) : P(p.segs[i - 1].x, p.segs[i - 1].y) }
    func nodes(_ p: VPath) -> [(NodeRef, P)] { var r: [(NodeRef, P)] = [(NodeRef(p: p, i: -1), P(p.x0, p.y0))]
        for (i, s) in p.segs.enumerated() { if let b = s as? BezSeg { r.append((NodeRef(p: p, i: i, ctrl: 1), P(b.x1, b.y1))); r.append((NodeRef(p: p, i: i, ctrl: 2), P(b.x2, b.y2))) }
            if !(p.closed && i == p.segs.count - 1 && abs(s.x - p.x0) < 1e-9 && abs(s.y - p.y0) < 1e-9) { r.append((NodeRef(p: p, i: i), P(s.x, s.y))) } }
        return r }
    private func targets() -> [VPath] { doc.selected().filter { doc.editable($0) } }
    func hitNode(_ x: Double, _ y: Double, _ tol: Double) -> NodeRef? { var best: NodeRef? = nil; var bd = tol * 1.2
        for p in targets() { for (n, q) in nodes(p) { let d = hypot(q.x - x, q.y - y); if d < bd || (d <= bd && n.ctrl == 0) { bd = d; best = n } } }; return best }
    func hitSeg(_ x: Double, _ y: Double, _ tol: Double) -> (VPath, Int)? { for p in targets() { for (i, s) in p.segs.enumerated() { let st = segStart(p, i)
        let f = Geom.flatten(VPath(closed: false, x0: st.x, y0: st.y, segs: [s.copy()]), 0.05); for k in 1..<f.count where Geom.distSeg(x, y, f[k - 1], f[k]) <= tol { return (p, i) } } }; return nil }
    func down(_ x: Double, _ y: Double, _ tol: Double) -> Bool {
        a = P(x, y); pushed = false
        if let n = hitNode(x, y, tol) { drag = n; selNode = n; selSeg = nil; return true }
        if let s = hitSeg(x, y, tol) { selSeg = s; segAt = P(x, y); selNode = nil; doc.changed(); return true }
        var best: VPath? = nil; var bd = tol; for p in doc.paths where doc.editable(p) { let d = Geom.distToPath(p, x, y, 0.1); if d < bd { bd = d; best = p } }
        selNode = nil; selSeg = nil; if let b = best { doc.selectPath(b, false) } else { doc.clearSel() }; doc.changed(); return true
    }
    func move(_ x: Double, _ y: Double) -> Bool {
        guard let n = drag else { return false }; if !pushed { doc.push(); pushed = true }
        let p = n.p; p.shape = nil; p.text = nil
        if n.ctrl == 1, let b = p.segs[n.i] as? BezSeg { b.x1 = x; b.y1 = y }
        else if n.ctrl == 2, let b = p.segs[n.i] as? BezSeg { b.x2 = x; b.y2 = y }
        else {
            let old = n.i < 0 ? P(p.x0, p.y0) : P(p.segs[n.i].x, p.segs[n.i].y); let dx = x - old.x, dy = y - old.y
            func shiftNext(_ j: Int) { if let b = p.segs.getOrNull(j) as? BezSeg { b.x1 += dx; b.y1 += dy } }
            if n.i < 0 { p.x0 = x; p.y0 = y; shiftNext(0); if p.closed, let l = p.segs.last, abs(l.x - old.x) < 1e-9 && abs(l.y - old.y) < 1e-9 { l.x = x; l.y = y; if let b = l as? BezSeg { b.x2 += dx; b.y2 += dy } } }
            else { let s = p.segs[n.i]; s.x = x; s.y = y; if let b = s as? BezSeg { b.x2 += dx; b.y2 += dy }; shiftNext(n.i + 1)
                if let s = s as? ArcSeg { let st = segStart(p, n.i); let r = hypot(st.x - s.cx, st.y - s.cy); let mx = (st.x + x) / 2, my = (st.y + y) / 2; let L = hypot(x - st.x, y - st.y); if L > 1e-9 && r > L / 2 { let h = sqrt(r * r - L * L / 4); let side: Double = s.ccw ? 1 : -1; s.cx = mx - (y - st.y) / L * h * side; s.cy = my + (x - st.x) / L * h * side } }
                if let nx = p.segs.getOrNull(n.i + 1) as? ArcSeg { let r = hypot(old.x - nx.cx, old.y - nx.cy); let L = hypot(nx.x - x, nx.y - y); if L > 1e-9 && r > L / 2 { let h = sqrt(r * r - L * L / 4); let side: Double = nx.ccw ? 1 : -1; nx.cx = (x + nx.x) / 2 - (nx.y - y) / L * h * side; nx.cy = (y + nx.y) / 2 + (nx.x - x) / L * h * side } }
                if p.closed && n.i == p.segs.count - 1 && abs(old.x - p.x0) < 1e-9 && abs(old.y - p.y0) < 1e-9 { p.x0 = x; p.y0 = y } }
        }
        doc.changed(); return true
    }
    func up() { drag = nil }
    func overlay() -> [Ov] {
        var o: [Ov] = []
        for p in targets() { for (i, s) in p.segs.enumerated() { if let b = s as? BezSeg { let st = segStart(p, i); o.append(.poly(pts: [st, P(b.x1, b.y1)], color: 0xFF8A8A8A, width: 1)); o.append(.poly(pts: [P(b.x, b.y), P(b.x2, b.y2)], color: 0xFF8A8A8A, width: 1)) } }
            for (n, q) in nodes(p) { let isSel = selNode.map { $0.p === n.p && $0.i == n.i && $0.ctrl == n.ctrl } ?? false
                o.append(.mark(p: q, kind: n.ctrl == 0 ? "box" : "dot", color: isSel ? 0xFFE00000 : (n.i < 0 ? 0xFF1F9A3A : 0xFF2A62B8))) } }
        if let (p, i) = selSeg, i < p.segs.count { let st = segStart(p, i); o.append(.paths(paths: [VPath(x0: st.x, y0: st.y, segs: [p.segs[i].copy()])], color: 0xFFE00000, dash: false)) }
        return o
    }
    var hint: String { "Узлы: тяните точки. Долгое нажатие на точке или участке — меню действий" }

    // ---------- действия ----------
    @discardableResult private func splitSeg(_ p: VPath, _ i: Int, _ at: P) -> Int {
        let s = p.segs[i]; let a = segStart(p, i)
        if let s = s as? ArcSeg {
            let r = hypot(a.x - s.cx, a.y - s.cy); let a0 = atan2(a.y - s.cy, a.x - s.cx); let a1 = atan2(s.y - s.cy, s.x - s.cx); var sw = a1 - a0
            if s.ccw && sw <= 0 { sw += 2 * .pi }; if !s.ccw && sw >= 0 { sw -= 2 * .pi }
            var best = 0.5, bd = Double.greatestFiniteMagnitude; for k in 1..<100 { let an = a0 + sw * Double(k) / 100; let d = hypot(s.cx + r * cos(an) - at.x, s.cy + r * sin(an) - at.y); if d < bd { bd = d; best = Double(k) / 100 } }
            let an = a0 + sw * best; p.segs.insert(ArcSeg(s.cx + r * cos(an), s.cy + r * sin(an), s.cx, s.cy, s.ccw), at: i)
        } else if let s = s as? BezSeg {
            var best = 0.5, bd = Double.greatestFiniteMagnitude; for k in 1..<100 { let q = Geom.bezPt(a, s, Double(k) / 100); let d = hypot(q.x - at.x, q.y - at.y); if d < bd { bd = d; best = Double(k) / 100 } }
            let t = best; func l(_ u: P, _ v: P) -> P { P(u.x + (v.x - u.x) * t, u.y + (v.y - u.y) * t) }
            let p1 = P(s.x1, s.y1), p2 = P(s.x2, s.y2), p3 = P(s.x, s.y); let a1 = l(a, p1), b1 = l(p1, p2), c1 = l(p2, p3), a2 = l(a1, b1), b2 = l(b1, c1), m = l(a2, b2)
            p.segs[i] = BezSeg(a1.x, a1.y, a2.x, a2.y, m.x, m.y); p.segs.insert(BezSeg(b2.x, b2.y, c1.x, c1.y, p3.x, p3.y), at: i + 1)
        } else {
            let dx = s.x - a.x, dy = s.y - a.y; let L = dx * dx + dy * dy; let t = L > 0 ? ((at.x - a.x) * dx + (at.y - a.y) * dy) / L : 0.5; let tt = clamp(t, 0.01, 0.99); p.segs.insert(LineSeg(a.x + dx * tt, a.y + dy * tt), at: i)
        }
        p.shape = nil; p.text = nil; return i
    }
    private func makeStart(_ p: VPath, _ nodeIdx: Int) { if !p.closed || nodeIdx < 0 { return }; let k = nodeIdx + 1; let segs = Array(p.segs[k...] + p.segs[..<k]); let n = p.segs[nodeIdx]; p.x0 = n.x; p.y0 = n.y; p.segs = segs; p.shape = nil }
    /// line | arc | bez | insert | insertStart | remove (участок); delpt | smooth | start (точка)
    func action(_ a: String) -> String? {
        doc.push()
        if ["line", "arc", "bez", "insert", "insertStart", "remove"].contains(a) {
            guard let (p, i) = selSeg, i < p.segs.count else { return "Выберите участок" }; p.shape = nil; p.text = nil; let s = p.segs[i]; let st = segStart(p, i)
            switch a {
            case "line": p.segs[i] = LineSeg(s.x, s.y)
            case "bez": if let arc = s as? ArcSeg { p.segs.remove(at: i); p.segs.insert(contentsOf: Geom.arcToBeziers(st, arc) as [Seg], at: i) } else { p.segs[i] = BezSeg(st.x + (s.x - st.x) / 3, st.y + (s.y - st.y) / 3, st.x + (s.x - st.x) * 2 / 3, st.y + (s.y - st.y) * 2 / 3, s.x, s.y) }
            case "arc":
                let f = Geom.flatten(VPath(x0: st.x, y0: st.y, segs: [s.copy()]), 0.01); var m = f[f.count / 2]; let dx = s.x - st.x, dy = s.y - st.y
                if f.count <= 2 { m = P((st.x + s.x) / 2 - dy * 0.15, (st.y + s.y) / 2 + dx * 0.15) }
                let arc = Geom.Shapes.arc3(st.x, st.y, m.x, m.y, s.x, s.y); if let first = arc.segs.first { if arc.segs.count == 1 { p.segs[i] = first } else { p.segs.remove(at: i); p.segs.insert(contentsOf: arc.segs, at: i) } }
            case "insert": splitSeg(p, i, segAt ?? P(s.x, s.y))
            case "insertStart": let k = splitSeg(p, i, segAt ?? P(s.x, s.y)); if p.closed { makeStart(p, k) }
            default: // remove
                if p.closed { let segs = Array(p.segs[(i + 1)...] + p.segs[..<i]); p.x0 = s.x; p.y0 = s.y; p.segs = segs; p.closed = false }
                else if i == 0 { p.x0 = s.x; p.y0 = s.y; p.segs.remove(at: 0) } else if i == p.segs.count - 1 { p.segs.remove(at: i) }
                else { let q = VPath(layer: p.layer, closed: false, x0: s.x, y0: s.y, segs: Array(p.segs[(i + 1)...])); p.segs = Array(p.segs[..<i]); doc.paths.append(q) }
                if p.segs.isEmpty { doc.paths.removeAll { $0 === p } }
            }
        } else {
            guard let n = selNode else { return "Выберите точку" }; let p = n.p; p.shape = nil; p.text = nil
            switch a {
            case "delpt":
                if p.segs.count < 2 { return "Слишком мало точек" }; var i = n.i
                if i == -1 { if !p.closed { p.x0 = p.segs[0].x; p.y0 = p.segs[0].y; p.segs.remove(at: 0) } else { makeStart(p, 0); i = p.segs.count - 1; mergeAt(p, i) } }
                else if i == p.segs.count - 1 && !p.closed { p.segs.remove(at: i) } else { mergeAt(p, i) }
            case "smooth":
                let i = n.i
                if i >= 0 && (i + 1 < p.segs.count || p.closed) { let j = (i + 1) % p.segs.count; let pt = P(p.segs[i].x, p.segs[i].y); let a0 = segStart(p, i); let b0 = P(p.segs[j].x, p.segs[j].y)
                    let tx = b0.x - a0.x, ty = b0.y - a0.y; var L = hypot(tx, ty); if !(L > 0) { L = 1 }; let d1 = hypot(pt.x - a0.x, pt.y - a0.y) / 3, d2 = hypot(b0.x - pt.x, b0.y - pt.y) / 3; let s1 = p.segs[i], s2 = p.segs[j]
                    let b1 = s1 as? BezSeg, b2 = s2 as? BezSeg
                    p.segs[i] = BezSeg(b1?.x1 ?? a0.x + (pt.x - a0.x) / 3, b1?.y1 ?? a0.y + (pt.y - a0.y) / 3, pt.x - tx / L * d1, pt.y - ty / L * d1, pt.x, pt.y)
                    p.segs[j] = BezSeg(pt.x + tx / L * d2, pt.y + ty / L * d2, b2?.x2 ?? b0.x - (b0.x - pt.x) / 3, b2?.y2 ?? b0.y - (b0.y - pt.y) / 3, b0.x, b0.y) }
            case "start": if p.closed { makeStart(p, n.i) } else if n.i == p.segs.count - 1 { Geom.reverse(p) }
            default: break
            }
        }
        selNode = nil; selSeg = nil; doc.changed(); return nil
    }
    private func mergeAt(_ p: VPath, _ i: Int) { let j = (i + 1) % p.segs.count; let s1 = p.segs[i], s2 = p.segs[j]; let st = segStart(p, i)
        let b1 = s1 as? BezSeg, b2 = s2 as? BezSeg
        let m: Seg = (b1 != nil || b2 != nil) ? BezSeg(b1?.x1 ?? st.x, b1?.y1 ?? st.y, b2?.x2 ?? s2.x, b2?.y2 ?? s2.y, s2.x, s2.y) : LineSeg(s2.x, s2.y)
        if j == 0 { p.segs.remove(at: i); p.segs[0] = m; p.x0 = p.segs.last!.x; p.y0 = p.segs.last!.y } else { p.segs[i] = m; p.segs.remove(at: j) } }
    /// точка: задать координаты
    func setPoint(_ x: Double, _ y: Double) { guard let n = selNode else { return }; drag = n; pushed = false; _ = move(x, y); drag = nil; selNode = nil }
}
