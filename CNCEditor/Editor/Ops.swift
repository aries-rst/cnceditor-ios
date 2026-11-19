/* ЧПУ Редактор 2D — команды над векторами (как в ArtCAM). Каждая возвращает текст ошибки или nil. Порт Ops.kt */
import Foundation

final class Ops {
    let d: Doc
    init(_ d: Doc) { self.d = d }
    private func newG() -> String { "g" + Geom.uid() }

    // ---------- выравнивание (последний выбранный — базовый) ----------
    func align(_ c: String) -> String? {
        let U = d.selectedUnits()
        if c == "centerPage" { if U.isEmpty { return "Выберите векторы" }; let bb = Geom.bbox(d.selected()); let m = d.model; d.applyMatrix(Geom.M.move(m.x0 + m.w / 2 - bb.cx, m.y0 + m.h / 2 - bb.cy)); return nil }
        if U.count < 2 { return "Выберите не меньше двух векторов (последний — базовый)" }
        let base = Geom.bbox(U.last!); d.push()
        for u in U.dropLast() {
            let bb = Geom.bbox(u); var dx = 0.0, dy = 0.0
            switch c { case "alignL": dx = base.x1 - bb.x1; case "alignR": dx = base.x2 - bb.x2; case "alignT": dy = base.y2 - bb.y2; case "alignB": dy = base.y1 - bb.y1; default: break }
            if c == "centerV" || c == "centerC" { dx = base.cx - bb.cx }
            if c == "centerH" || c == "centerC" { dy = base.cy - bb.cy }
            u.forEach { Geom.transform($0, Geom.M.move(dx, dy)) }
        }
        d.changed(); return nil
    }
    func group() -> String? { let s = d.selected(); if s.isEmpty { return "Выберите векторы" }; d.push(); let g = newG(); s.forEach { $0.group = g }; d.changed(); return nil }
    func ungroup() -> String? { let s = d.selected(); if s.isEmpty { return "Выберите векторы" }; d.push(); s.forEach { $0.group = nil }; d.changed(); return nil }
    /// weld | intersect | subtract | xor
    func bool(_ c: String) -> String? {
        let s = d.selectedOrdered()
        if s.count < (c == "weld" ? 1 : 2) { return c == "weld" ? "Выберите векторы" : "Выберите не меньше двух векторов" }
        if s.contains(where: { !$0.closed }) { return "Объединять можно только замкнутые векторы" }
        let r: [VPath]
        switch c { case "weld": r = Geom.boolean("union", s, []); case "subtract": r = Geom.boolean("subtract", Array(s.dropLast()), [s.last!]); default: r = Geom.boolean(c == "xor" ? "xor" : "intersect", [s[0]], Array(s.dropFirst())) }
        if r.isEmpty { return "Результат пустой — векторы не пересекаются?" }
        d.replace(s, r); return nil
    }
    func reverse() -> String? { let s = d.selected(); if s.isEmpty { return "Выберите векторы" }; d.push(); s.forEach { Geom.reverse($0) }; d.changed(); return nil }
    /// closeLine | closeCurve | closeMove
    func close(_ c: String) -> String? {
        let op = d.selected().filter { !$0.closed && !$0.segs.isEmpty }; if op.isEmpty { return "Выберите открытые векторы" }; d.push()
        for p in op {
            let l = p.segs.last!
            switch c {
            case "closeLine": p.segs.append(LineSeg(p.x0, p.y0))
            case "closeMove": l.x = p.x0; l.y = p.y0
            default:
                let ex = l.x, ey = l.y, f = p.segs[0]
                let pv: P = (l as? BezSeg).map { P($0.x2, $0.y2) } ?? (p.segs.count > 1 ? P(p.segs[p.segs.count - 2].x, p.segs[p.segs.count - 2].y) : P(p.x0, p.y0))
                let tIn = P(ex - pv.x, ey - pv.y); let tOut = (f as? BezSeg).map { P($0.x1 - p.x0, $0.y1 - p.y0) } ?? P(f.x - p.x0, f.y - p.y0)
                let D = hypot(p.x0 - ex, p.y0 - ey) / 3
                func n(_ v: P) -> P { var L = hypot(v.x, v.y); if L == 0 { L = 1 }; return P(v.x / L * D, v.y / L * D) }
                let a = n(tIn), b = n(tOut); p.segs.append(BezSeg(ex + a.x, ey + a.y, p.x0 - b.x, p.y0 - b.y, p.x0, p.y0))
            }
            p.closed = true; p.shape = nil
        }
        d.changed(); return nil
    }
    /// joinLine | joinCurve | joinMove — два открытых вектора
    func join(_ c: String) -> String? {
        let op = d.selected().filter { !$0.closed }; if op.count != 2 { return "Выберите два открытых вектора" }
        let a = op[0].copy(), b = op[1].copy()
        let combos = [(false, false), (false, true), (true, false), (true, true)].map { (rx, ry) -> (Bool, Bool, Double) in
            let e = rx ? P(a.x0, a.y0) : P(a.endX, a.endY); let s = ry ? P(b.endX, b.endY) : P(b.x0, b.y0); return (rx, ry, hypot(e.x - s.x, e.y - s.y)) }.min { $0.2 < $1.2 }!
        if combos.0 { Geom.reverse(a) }; if combos.1 { Geom.reverse(b) }
        let e = P(a.endX, a.endY), s = P(b.x0, b.y0)
        switch c {
        case "joinLine": a.segs.append(LineSeg(s.x, s.y))
        case "joinMove": let mx = (e.x + s.x) / 2, my = (e.y + s.y) / 2; a.segs.last!.x = mx; a.segs.last!.y = my; b.x0 = mx; b.y0 = my
        default:
            let D = hypot(s.x - e.x, s.y - e.y) / 3; let l = a.segs.last!
            let pv: P = (l as? BezSeg).map { P($0.x2, $0.y2) } ?? (a.segs.count > 1 ? P(a.segs[a.segs.count - 2].x, a.segs[a.segs.count - 2].y) : P(a.x0, a.y0))
            let f = b.segs[0]; let nx = (f as? BezSeg).map { P($0.x1, $0.y1) } ?? P(f.x, f.y)
            let ux = e.x - pv.x, uy = e.y - pv.y, wx = nx.x - s.x, wy = nx.y - s.y
            var nu = hypot(ux, uy); if nu == 0 { nu = 1 }; var nw = hypot(wx, wy); if nw == 0 { nw = 1 }
            a.segs.append(BezSeg(e.x + ux / nu * D, e.y + uy / nu * D, s.x - wx / nw * D, s.y - wy / nw * D, s.x, s.y))
        }
        a.segs.append(contentsOf: b.segs); a.shape = nil; d.replace(op, [a]); return nil
    }
    func joinCoincident(_ tol: Double, _ apply: Bool) -> (Int, Int)? {
        let s = d.selected().filter { !$0.closed }; if s.isEmpty { return nil }
        let r = Geom.joinChains(s.map { $0.copy() }, tol); if apply { r.forEach { $0.layer = s[0].layer }; d.replace(s, r) }
        return (s.count, r.count)
    }

    // ---------- смещение, отражение, копирование ----------
    /// dir: out | in | both; corners: round | chamfer | sharp
    func offset(_ dist: Double, _ dir: String, _ corners: String, _ sharpPct: Double, _ delOriginal: Bool) -> String? {
        let s = d.selected(); if s.isEmpty { return "Выберите векторы" }
        var r: [VPath] = []
        if dir != "in" { r.append(contentsOf: Geom.offset(s, dist, corners, sharpPct)) }; if dir != "out" { r.append(contentsOf: Geom.offset(s, -dist, corners, sharpPct)) }
        if r.isEmpty { return "Смещение не дало контуров (слишком большое расстояние внутрь?)" }
        r.forEach { $0.layer = s[0].layer }
        if delOriginal { d.replace(s, r) } else { d.add(r) }
        return nil
    }
    /// mode: L, CH, R (по горизонтали), T, CV, B (по вертикали), line (последний — ось)
    func mirror(_ mode: String, _ copy: Bool) -> String? {
        let s = d.selectedOrdered(); if s.isEmpty { return "Выберите векторы" }
        if mode == "line" {
            if s.count < 2 { return "Выберите векторы, а последней — линию-ось" }
            let f = Geom.flatten(s.last!, 0.1); let a = f.first!, b = f.last!; let th = atan2(b.y - a.y, b.x - a.x); let c = cos(2 * th), sn = sin(2 * th)
            let m = [c, sn, sn, -c, a.x - c * a.x - sn * a.y, a.y - sn * a.x + c * a.y]
            let keep = s.last!.id; d.selRemove(keep); d.applyMatrix(m, copy); return nil
        }
        let bb = Geom.bbox(s)
        let m: [Double]
        switch mode { case "L": m = Geom.M.scale(-1, 1, bb.x1, 0); case "CH": m = Geom.M.scale(-1, 1, bb.cx, 0); case "R": m = Geom.M.scale(-1, 1, bb.x2, 0)
        case "T": m = Geom.M.scale(1, -1, 0, bb.y2); case "CV": m = Geom.M.scale(1, -1, 0, bb.cy); default: m = Geom.M.scale(1, -1, 0, bb.y1) }
        d.applyMatrix(m, copy); return nil
    }
    private func cloneSet(_ s: [VPath], _ m: [Double]) -> [VPath] { var gm: [String: String] = [:]; return s.map { p in let q = Geom.transform(p.copy(), m); q.group = p.group.map { g in if let n = gm[g] { return n }; let n = newG(); gm[g] = n; return n }; return q } }
    func blockCopy(_ gap: Bool, _ bx: Double, _ by: Double, _ cols: Int, _ rows: Int, _ right: Bool, _ up: Bool) -> String? {
        let s = d.selected(); if s.isEmpty { return "Выберите векторы" }; let bb = Geom.bbox(s); var out: [VPath] = []
        let sx = gap ? (bb.w + abs(bx)) * (right ? 1 : -1) : (bx == 0 ? 1 : (bx > 0 ? 1 : -1)) * (bb.w + abs(bx))
        let sy = gap ? (bb.h + abs(by)) * (up ? 1 : -1) : (by == 0 ? 1 : (by > 0 ? 1 : -1)) * (bb.h + abs(by))
        for r in 0..<max(0, rows) { for c in 0..<max(0, cols) { if r == 0 && c == 0 { continue }; out.append(contentsOf: cloneSet(s, Geom.M.move(Double(c) * sx, Double(r) * sy))) } }
        d.add(out, false); return nil
    }
    func rotateCopy(_ cx: Double, _ cy: Double, _ total: Bool, _ ang: Double, _ n0: Int) -> String? {
        let s = d.selected(); if s.isEmpty { return "Выберите векторы" }; let n = max(2, n0)
        let step = total ? ang / Double(abs(ang) >= 360 ? n : n - 1) : ang; var out: [VPath] = []
        for k in 1..<n { out.append(contentsOf: cloneSet(s, Geom.M.rotate(step * Double(k), cx, cy))) }
        d.add(out, false); return nil
    }
    func border(_ gx: Double, _ gy: Double) -> String? { let s = d.selected(); if s.isEmpty { return "Выберите векторы" }; let bb = Geom.bbox(s); d.addOnActive([Geom.Shapes.rect(bb.cx, bb.cy, bb.w + 2 * gx, bb.h + 2 * gy)]); return nil }
    func convert(_ circles: Bool, _ spec: Bool, _ dia: Double, _ w: Double, _ h: Double) -> String? {
        let U = d.selectedUnits(); if U.isEmpty { return "Выберите векторы" }
        let out = U.map { u -> VPath in let bb = Geom.bbox(u); if circles { return Geom.Shapes.circle(bb.cx, bb.cy, spec ? dia / 2 : max(bb.w, bb.h) / 2) }; return spec ? Geom.Shapes.rect(bb.cx, bb.cy, w, h) : Geom.Shapes.rect(bb.cx, bb.cy, bb.w, bb.h) }
        d.replace(d.selected(), out); return nil
    }

    // ---------- доктор векторов ----------
    func doctorFind(_ coincident: Bool, _ tol: Double, _ intersections: Bool) -> [P] {
        let ps = d.selected(); var mk: [P] = []
        if coincident {
            var ends: [(VPath, P)] = []; for p in ps where !p.closed { let f = Geom.flatten(p); ends.append((p, f.first!)); ends.append((p, f.last!)) }
            for i in ends.indices { for j in (i + 1)..<max(i + 1, ends.count) where ends[i].0 !== ends[j].0 && hypot(ends[i].1.x - ends[j].1.x, ends[i].1.y - ends[j].1.y) <= tol { mk.append(ends[i].1) } }
        }
        if intersections {
            let F = ps.map { Geom.flatten($0) }
            for a in F.indices { for b in a..<F.count { let A = F[a], B = F[b]
                for i in 1..<A.count { for j in 1..<B.count {
                    if a == b && abs(i - j) <= 1 { continue }
                    if a == b && ps[a].closed && ((i == 1 && j == B.count - 1) || (j == 1 && i == A.count - 1)) { continue }
                    if a == b && j < i { continue }
                    if let x = Geom.segX(A[i - 1], A[i], B[j - 1], B[j]), x.t > 1e-6 && x.t < 1 - 1e-6 { mk.append(P(x.x, x.y)) }
                } } } }
        }
        return mk
    }
    func doctorFix(_ removeLoops: Bool, _ pct: Double, _ layerName: String, _ keep: Bool) -> String? {
        if !removeLoops { return nil }
        let ps = d.selected().filter { $0.closed }; if ps.isEmpty { return "Выберите замкнутые векторы" }; var out: [VPath] = []
        for p in ps { var f = Geom.flatten(p); f.removeLast(); let area = abs(Geom.signedArea(f))
            for pl in Clip.simplifyPolygon(Geom.toC(f), .nonZero) { let pts = Geom.fromC(pl); if abs(Geom.signedArea(pts)) / (area == 0 ? 1 : area) * 100 >= pct { out.append(Geom.makePath(pts, true, p.layer)) } } }
        if !layerName.trimmed.isEmpty { var li = d.layers.firstIndex { $0.name == layerName } ?? -1; if li < 0 { d.layers.append(Layer(layerName, 0xFFD81F2A)); li = d.layers.count - 1 }; out.forEach { $0.layer = li } }
        if keep { d.add(out) } else { d.replace(ps, out) }; return nil
    }

    // ---------- обрезка, рассечение, обрезка по контуру ----------
    private func cutPoints(_ T: [P], _ cutters: [[P]], sameAs: Int? = nil) -> [Double] {
        var ts: [Double] = []
        for i in 1..<T.count { for (ci, C) in cutters.enumerated() { for j in 1..<C.count {
            if sameAs == ci && abs(i - j) <= 1 { continue }
            if let x = Geom.segX(T[i - 1], T[i], C[j - 1], C[j]) { ts.append(Double(i - 1) + x.t) } } } }
        return Array(Set(ts.map { Double(kroundL($0 * 1e7)) / 1e7 })).sorted()
    }
    private func splitPoly(_ T: [P], _ ts: [Double], _ closed: Bool) -> [[P]] {
        func at(_ t: Double) -> P { let i = min(T.count - 2, Int(floor(t))); let f = t - Double(i); return P(T[i].x + (T[i + 1].x - T[i].x) * f, T[i].y + (T[i + 1].y - T[i].y) * f) }
        let inner = ts.filter { $0 > 1e-6 && $0 < Double(T.count - 1) - 1e-6 }; if inner.isEmpty { return [T] }
        var pieces: [[P]] = []; var cur: [P] = [T[0]]; var k = 0
        for i in 1..<T.count { while k < inner.count && inner[k] <= Double(i) { let q = at(inner[k]); cur.append(q); pieces.append(cur); cur = [q]; k += 1 }; cur.append(T[i]) }
        pieces.append(cur)
        if closed && pieces.count > 1 { let last = pieces.removeLast(); pieces[0] = last + Array(pieces[0].dropFirst()) }
        return pieces.filter { $0.count > 1 }
    }
    private func midPt(_ f: [P]) -> P { let r = Geom.pointAt(f, Geom.polyLen(f) / 2); return P(r[0], r[1]) }
    func explode(_ all: Bool, _ keepOriginal: Bool) -> String? {
        let ps = all ? d.paths.filter { d.editable($0) } : d.selected(); if ps.isEmpty { return "Нет векторов" }
        let F = ps.map { Geom.flatten($0) }; var out: [VPath] = []
        for (k, p) in ps.enumerated() { for piece in splitPoly(F[k], cutPoints(F[k], F, sameAs: k), p.closed) { let np = Geom.makePath(piece, false, p.layer); if piece.count > 2 && hypot(piece[0].x - piece.last!.x, piece[0].y - piece.last!.y) < 1e-9 { np.closed = true }; out.append(np) } }
        if keepOriginal { d.add(out, false) } else { d.replace(ps, out) }; return nil
    }
    func joinOpen(_ all: Bool) -> String? { let op = (all ? d.paths.filter { d.editable($0) } : d.selected()).filter { !$0.closed }; if op.isEmpty { return "Нет открытых векторов" }; d.replace(op, Geom.joinChains(op.map { $0.copy() }, 0.01)); return nil }
    func scissors(_ p: VPath) { if !d.editable(p) { return }; d.push(); d.paths.removeAll { $0 === p }; d.selRemove(p.id); d.changed() }
    /// обрезка по контуру: граница — первый выбранный; keepIn; onBorder: trim | del | keep
    func clip(_ keepIn: Bool, _ onBorder: String) -> String? {
        let s = d.selectedOrdered(); if s.count < 2 { return "Выберите границу, затем векторы" }; let region = s[0]; if !region.closed { return "Граница должна быть замкнутой" }
        let RF = Geom.flatten(region); let targets = s.dropFirst().filter { !(region.group != nil && $0.group == region.group) }; var out: [VPath] = []
        func inside(_ v: P) -> Bool { Geom.pointInPoly(v.x, v.y, RF) }
        for p in targets { let f = Geom.flatten(p); let ts = cutPoints(f, [RF])
            if ts.isEmpty { if inside(f[0]) == keepIn { out.append(p.copy()) }; continue }
            if onBorder == "del" { continue }; if onBorder == "keep" { out.append(p.copy()); continue }
            if p.closed { let r = Geom.boolean(keepIn ? "intersect" : "subtract", [p], [region]); r.forEach { $0.layer = p.layer }; out.append(contentsOf: r) }
            else { for piece in splitPoly(f, ts, false) where inside(midPt(piece)) == keepIn { out.append(Geom.makePath(piece, false, p.layer)) } } }
        d.replace(Array(targets), out); return nil
    }
    /// рассечение: mode last | v | h; closeParts
    func slice(_ mode: String, _ coord: Double, _ closeParts: Bool) -> String? {
        var s = d.selectedOrdered(); let cutter: [P]
        if mode == "last" { if s.count < 2 { return "Выберите векторы и последним — режущий" }; cutter = Geom.flatten(s.last!); s = Array(s.dropLast()) }
        else { if s.isEmpty { return "Выберите векторы" }; let bb = Geom.bbox(s); let big = max(bb.w, bb.h) + 1000
            cutter = mode == "v" ? [P(coord, bb.y1 - big), P(coord, bb.y2 + big)] : [P(bb.x1 - big, coord), P(bb.x2 + big, coord)] }
        var out: [VPath] = []
        for p in s { let f = Geom.flatten(p)
            if p.closed && closeParts {
                let sol = Clip.offset([([Geom.toC(cutter)], .miter, .openButt)], 1.0)
                let knife = sol.map { Geom.makePath(Geom.fromC($0), true) }
                var parts = Geom.boolean("subtract", [p], knife); if parts.isEmpty { parts = [p.copy()] }; parts.forEach { $0.layer = p.layer }; out.append(contentsOf: parts)
            } else { for piece in splitPoly(f, cutPoints(f, [cutter]), p.closed) { out.append(Geom.makePath(piece, false, p.layer)) } } }
        d.replace(s, out); return nil
    }

    // ---------- скругление и продление ----------
    /// скругление угла между двумя прямыми участками в узле nodeIdx (индекс точки: 0 = x0)
    func fillet(_ p: VPath, _ nodeIdx: Int, _ r: Double) -> String? {
        var i = nodeIdx - 1
        if i == -1 { if !p.closed { return "Это конец открытого вектора — скругление невозможно" }; i = p.segs.count - 1 }
        if i == p.segs.count - 1 && !p.closed { return "Это конец открытого вектора" }
        let j = (i + 1) % p.segs.count; let s1 = p.segs[i], s2 = p.segs[j]
        if !(s1 is LineSeg) || !(s2 is LineSeg) { return "Скругление ставится между двумя прямыми участками" }
        let Pp = P(s1.x, s1.y); let A = i > 0 ? P(p.segs[i - 1].x, p.segs[i - 1].y) : P(p.x0, p.y0); let Bq = P(s2.x, s2.y)
        var uax = A.x - Pp.x, uay = A.y - Pp.y, ubx = Bq.x - Pp.x, uby = Bq.y - Pp.y; let la = hypot(uax, uay), lb = hypot(ubx, uby)
        uax /= la; uay /= la; ubx /= lb; uby /= lb
        let th = acos(clamp(uax * ubx + uay * uby, -1, 1)); if th < 1e-3 || abs(th - .pi) < 1e-3 { return "Участки на одной прямой" }
        let dd = r / tan(th / 2); if dd > la - 1e-6 || dd > lb - 1e-6 { return "Радиус слишком большой для этого угла" }
        let T1 = P(Pp.x + uax * dd, Pp.y + uay * dd), T2 = P(Pp.x + ubx * dd, Pp.y + uby * dd)
        let bx = uax + ubx, by = uay + uby; let lbis = hypot(bx, by); let h = r / sin(th / 2)
        let c = P(Pp.x + bx / lbis * h, Pp.y + by / lbis * h); let ccw = ((T1.x - c.x) * (T2.y - c.y) - (T1.y - c.y) * (T2.x - c.x)) > 0
        d.push(); p.shape = nil; s1.x = T1.x; s1.y = T1.y
        let arc = ArcSeg(T2.x, T2.y, c.x, c.y, ccw)
        if p.closed && i == p.segs.count - 1 && j == 0 { p.segs.insert(arc, at: 0); p.x0 = T1.x; p.y0 = T1.y } else { p.segs.insert(arc, at: i + 1) }
        d.changed(); return nil
    }
    /// продлить/обрезать два прямых конца до пересечения; atStart — конец у начала вектора
    func extendToIntersection(_ pa: VPath, _ aStart: Bool, _ pb: VPath, _ bStart: Bool) -> String? {
        func endSeg(_ p: VPath, _ st: Bool) -> (P, P)? { guard let s = st ? p.segs.first : p.segs.last, s is LineSeg else { return nil }
            let far = st ? P(s.x, s.y) : (p.segs.count > 1 ? P(p.segs[p.segs.count - 2].x, p.segs[p.segs.count - 2].y) : P(p.x0, p.y0))
            return (far, st ? P(p.x0, p.y0) : P(s.x, s.y)) }
        guard let ea = endSeg(pa, aStart), let eb = endSeg(pb, bStart) else { return "Концы должны быть прямыми участками" }
        let d1x = ea.1.x - ea.0.x, d1y = ea.1.y - ea.0.y, d2x = eb.1.x - eb.0.x, d2y = eb.1.y - eb.0.y
        let den = d1x * d2y - d1y * d2x; if abs(den) < 1e-12 { return "Линии параллельны" }
        let t = ((eb.0.x - ea.0.x) * d2y - (eb.0.y - ea.0.y) * d2x) / den; let X = P(ea.0.x + d1x * t, ea.0.y + d1y * t)
        d.push()
        func setEnd(_ p: VPath, _ st: Bool) { p.shape = nil; if st { p.x0 = X.x; p.y0 = X.y } else { p.segs.last!.x = X.x; p.segs.last!.y = X.y } }
        setEnd(pa, aStart); setEnd(pb, bStart)
        if pa === pb { pa.closed = true }
        else { if aStart { Geom.reverse(pa) }; if !bStart { Geom.reverse(pb) }; pa.segs.append(contentsOf: pb.segs); d.paths.removeAll { $0 === pb }; d.selClear(); d.selAdd(pa.id) }
        d.changed(); return nil
    }

    // ---------- дуги вместо кривых ----------
    func fitArcs(_ tol: Double) -> String? {
        let s = d.selected(); if s.isEmpty { return "Выберите векторы" }; d.push()
        for p in s { var segs: [Seg] = []; var a = P(p.x0, p.y0); for sg in p.segs { if let b = sg as? BezSeg { fitBez(a, b, tol, &segs, 0) } else { segs.append(sg) }; a = P(sg.x, sg.y) }; p.segs = segs; p.shape = nil }
        d.changed(); return nil
    }
    private func fitBez(_ a: P, _ s: BezSeg, _ tol: Double, _ out: inout [Seg], _ depth: Int) {
        let end = P(s.x, s.y); let m = Geom.bezPt(a, s, 0.5); let samples = [0.12, 0.25, 0.37, 0.63, 0.75, 0.88].map { Geom.bezPt(a, s, $0) }
        var L = hypot(end.x - a.x, end.y - a.y); if L == 0 { L = 1e-9 }
        let chordDev = samples.map { abs(($0.x - a.x) * (end.y - a.y) - ($0.y - a.y) * (end.x - a.x)) / L }.max()!
        if chordDev <= tol { out.append(LineSeg(end.x, end.y)); return }
        if let c = Geom.circ3(a, m, end) { let r = hypot(a.x - c.x, a.y - c.y); if r < 1e5 && samples.map({ abs(hypot($0.x - c.x, $0.y - c.y) - r) }).max()! <= tol { out.append(ArcSeg(end.x, end.y, c.x, c.y, ((m.x - a.x) * (end.y - a.y) - (m.y - a.y) * (end.x - a.x)) > 0)); return } }
        if depth > 12 { out.append(LineSeg(end.x, end.y)); return }
        func l(_ u: P, _ w: P) -> P { P((u.x + w.x) / 2, (u.y + w.y) / 2) }
        let p1 = P(s.x1, s.y1), p2 = P(s.x2, s.y2); let a1 = l(a, p1), b1 = l(p1, p2), c1 = l(p2, end), a2 = l(a1, b1), b2 = l(b1, c1), mm = l(a2, b2)
        fitBez(a, BezSeg(a1.x, a1.y, a2.x, a2.y, mm.x, mm.y), tol, &out, depth + 1); fitBez(mm, BezSeg(b2.x, b2.y, c1.x, c1.y, end.x, end.y), tol, &out, depth + 1)
    }
    func segCounts(_ ps: [VPath]) -> [Int] { var c = [0, 0, 0, 0]; for p in ps { for s in p.segs { if s is BezSeg { c[1] += 1 } else if s is ArcSeg { c[2] += 1 } else { c[0] += 1 } }; c[3] += p.segs.count + (p.closed ? 0 : 1) }; return c }

    // ---------- вставка вдоль кривой ----------
    func pasteAlongCurve(_ byNumber: Bool, _ n0: Int, _ dist: Double, _ even: Bool, _ rotate: Bool) -> String? {
        let s = d.selectedOrdered(); if s.count < 2 { return "Выберите объект(ы) и последней — кривую" }
        let curve = s.last!; let objs = Array(s.dropLast()); let f = Geom.flatten(curve); let L = Geom.polyLen(f); let bb = Geom.bbox(objs)
        var n: Int; var step: Double
        if byNumber { n = max(1, n0); step = curve.closed ? L / Double(n) : (n > 1 ? L / Double(n - 1) : 0) }
        else { step = max(0.001, dist); n = Int(floor(L / step + 1e-9)) + (curve.closed ? 0 : 1); if even && n > 1 { step = curve.closed ? L / Double(n) : L / Double(n - 1) } }
        if n > 5000 { return "Слишком много копий" }
        var out: [VPath] = []
        for k in 0..<n { let pt = Geom.pointAt(f, Double(k) * step); var gm: [String: String] = [:]
            for o in objs { let c = o.copy(); Geom.transform(c, Geom.M.move(pt[0] - bb.cx, pt[1] - bb.cy)); if rotate { Geom.transform(c, Geom.M.rotate(-pt[2] * 180 / .pi, pt[0], pt[1])) }
                c.group = o.group.map { g in if let x = gm[g] { return x }; let x = newG(); gm[g] = x; return x }; out.append(c) } }
        d.add(out, false); return nil
    }

    // ---------- Multi-Plate ----------
    struct Plate { let paths: [VPath]; let ids: [String]; let bb: BBox }
    func plateLayout(_ t: Plate, _ W: Double, _ H: Double, _ gx: Double, _ gy: Double, _ bx: Double, _ by: Double) -> (Int, Int) {
        let w = W - 2 * bx, h = H - 2 * by
        return (max(0, Int(floor((w + gx) / (t.bb.w + gx)))), max(0, Int(floor((h + gy) / (t.bb.h + gy)))))
    }
    func multiPlate(_ t: Plate, _ N0: Int, _ lines: [String], _ first: Int, _ W: Double, _ gx: Double, _ gy: Double, _ bx: Double, _ by: Double, _ H: Double, _ delTemplate: Bool, _ textBuild: (TextParams) -> [VPath]) -> String? {
        let (cols, rows) = plateLayout(t, W, H, gx, gy, bx, by); let per = cols * rows; if per == 0 { return "Табличка не помещается на лист" }
        let hasText = t.paths.contains { $0.text != nil }; let N = (!lines.isEmpty && hasText) ? lines.count : max(1, N0); let m = d.model; var out: [VPath] = []
        for k in 0..<N {
            let sh = k / per, idx = k % per; var col = idx % cols, row = idx / cols
            if first == 2 || first == 4 { col = cols - 1 - col }; if first == 3 || first == 4 { row = rows - 1 - row }
            let ox = m.x0 + Double(sh) * (W + 100) + bx + Double(col) * (t.bb.w + gx); let oy = m.y0 + by + Double(row) * (t.bb.h + gy); let gid = newG()
            let dx = ox - t.bb.x1, dy = oy - t.bb.y1; var done = Set<String>()
            for p in t.paths {
                if let tp = p.text, !lines.isEmpty { let key = p.group ?? p.id; if !done.insert(key).inserted { continue }
                    let tt = tp.copy(); tt.text = lines[k % lines.count].replacingOccurrences(of: "|", with: "\n"); tt.curveId = nil
                    let np = textBuild(tt); let ob = Geom.bbox(t.paths.filter { ($0.group ?? $0.id) == key })
                    let nb: BBox? = np.isEmpty ? nil : Geom.bbox(np)
                    for q in np { if let nb = nb { Geom.transform(q, Geom.M.move(ob.cx - nb.cx + dx, ob.cy - nb.cy + dy)) }
                        let qt = tt.copy(); qt.x = tt.x + ob.cx - (nb?.cx ?? 0) + dx; qt.y = tt.y + ob.cy - (nb?.cy ?? 0) + dy; q.text = qt; q.group = gid; q.layer = p.layer; out.append(q) }
                    continue }
                let q = Geom.transform(p.copy(), Geom.M.move(dx, dy)); q.group = gid; out.append(q)
            }
        }
        d.push(); if delTemplate { let ids = Set(t.ids); d.paths.removeAll { ids.contains($0.id) } }
        d.paths.append(contentsOf: out); d.selClear(); out.forEach { d.selAdd($0.id) }; d.changed(); return nil
    }

    // ---------- раскрой по габаритам ----------
    func autoGroupHoles(_ ps: [VPath]) {
        let cl = ps.filter { $0.closed && $0.group == nil }.map { p -> (VPath, [P], Double) in let f = Geom.flatten(p); return (p, f, abs(Geom.signedArea(f))) }.sorted { $0.2 > $1.2 }
        for inner in cl { for outer in cl { if outer.0 === inner.0 || outer.2 <= inner.2 { continue }
            if Geom.pointInPoly(inner.1[0].x, inner.1[0].y, outer.1) { let g = outer.0.group ?? { let x = newG(); outer.0.group = x; return x }(); inner.0.group = g; break } } }
    }
    struct NestOpt { let toolD: Double; let clear: Double; let edge: Double; let rotate: Bool; let from: String; let dirX: Bool; let groupHoles: Bool; let sheetIsModel: Bool; let groupSheets: Bool; let copies: Int; let maxSheets: Int }
    func nest(_ o: NestOpt) -> String {
        var ps = d.selected(); if ps.isEmpty { return "Выберите детали для раскроя" }
        d.push()
        let sheet: [Double]
        if o.sheetIsModel { let m = d.model; sheet = [m.x0, m.y0, m.w, m.h] }
        else { let sh = d.selectedOrdered()[0]; if !sh.closed { return "Первый выбранный вектор должен быть замкнутым (лист)" }; let b = Geom.bbox(sh); sheet = [b.x1, b.y1, b.w, b.h]; ps = ps.filter { $0 !== sh } }
        if o.groupHoles { autoGroupHoles(ps) }
        var unitKeys: [String] = []; var units: [String: [VPath]] = [:]
        for p in ps { let k = p.group ?? p.id; if units[k] == nil { unitKeys.append(k); units[k] = [] }; units[k]!.append(p) }
        let sp = o.toolD + o.clear, E = o.edge
        struct Part { let ps: [VPath]; let bb: BBox }
        var parts: [Part] = []
        for k in unitKeys { let u = units[k]!; for c in 0..<max(1, o.copies) { let ps2 = c > 0 ? u.map { $0.copy() } : u; if c > 0 { let g = newG(); ps2.forEach { $0.group = u.count > 1 ? g : nil; d.paths.append($0) } }; parts.append(Part(ps: ps2, bb: Geom.bbox(ps2))) } }
        parts = parts.enumerated().sorted { let a = $0.element.bb.w * $0.element.bb.h, b = $1.element.bb.w * $1.element.bb.h; return a != b ? a > b : $0.offset < $1.offset }.map { $0.element }
        let W = sheet[2] - 2 * E + sp, Hh = sheet[3] - 2 * E + sp
        struct Rect: Equatable { let x: Double, y: Double, w: Double, h: Double }
        struct Placed { let pt: Part; let r: Rect; let rot: Bool }
        final class SheetS { var free: [Rect]; var parts: [Placed] = []; init(_ f: [Rect]) { free = f } }
        var sheets: [SheetS] = []; var placed = 0, failed = 0
        func key(_ f: Rect) -> Double { o.dirX ? f.y * 1e6 + f.x : f.x * 1e6 + f.y }
        func split(_ free: [Rect], _ r: Rect) -> [Rect] {
            var out: [Rect] = []
            for f in free { if r.x >= f.x + f.w || r.x + r.w <= f.x || r.y >= f.y + f.h || r.y + r.h <= f.y { out.append(f); continue }
                if r.x > f.x { out.append(Rect(x: f.x, y: f.y, w: r.x - f.x, h: f.h)) }; if r.x + r.w < f.x + f.w { out.append(Rect(x: r.x + r.w, y: f.y, w: f.x + f.w - r.x - r.w, h: f.h)) }
                if r.y > f.y { out.append(Rect(x: f.x, y: f.y, w: f.w, h: r.y - f.y)) }; if r.y + r.h < f.y + f.h { out.append(Rect(x: f.x, y: r.y + r.h, w: f.w, h: f.y + f.h - r.y - r.h)) } }
            return out.enumerated().filter { (i, a) in !out.enumerated().contains { (j, b) in j != i && a.x >= b.x - 1e-9 && a.y >= b.y - 1e-9 && a.x + a.w <= b.x + b.w + 1e-9 && a.y + a.h <= b.y + b.h + 1e-9 && (j < i || a != b) } }.map { $0.element }
        }
        for pt in parts {
            var done = false; var si = 0
            while si <= sheets.count && si < o.maxSheets {
                if si == sheets.count { sheets.append(SheetS([Rect(x: 0, y: 0, w: W, h: Hh)])) }
                let s = sheets[si]; var opts = [(pt.bb.w + sp, pt.bb.h + sp, false)]; if o.rotate { opts.append((pt.bb.h + sp, pt.bb.w + sp, true)) }
                var best: (Rect, (Double, Double, Bool))? = nil; var bk = Double.greatestFiniteMagnitude
                for op in opts { let f = s.free.filter { $0.w >= op.0 - 1e-9 && $0.h >= op.1 - 1e-9 }.min { key($0) < key($1) }; if let f = f, key(f) < bk { bk = key(f); best = (f, op) } }
                if let b = best { let r = Rect(x: b.0.x, y: b.0.y, w: b.1.0, h: b.1.1); s.free = split(s.free, r); s.parts.append(Placed(pt: pt, r: r, rot: b.1.2)); done = true; break }
                si += 1
            }
            if done { placed += 1 } else { failed += 1 }
        }
        for (si, s) in sheets.enumerated() { let gid = newG(); let ox = sheet[0] + Double(si) * (sheet[2] + 100)
            if si > 0 { let r = Geom.Shapes.rect(ox + sheet[2] / 2, sheet[1] + sheet[3] / 2, sheet[2], sheet[3]); r.layer = d.active; d.paths.append(r) }
            for pl in s.parts { var x = pl.r.x, y = pl.r.y
                if o.from == "br" || o.from == "tr" { x = W - pl.r.x - pl.r.w }; if o.from == "tl" || o.from == "tr" { y = Hh - pl.r.y - pl.r.h }
                let tx = ox + E + x, ty = sheet[1] + E + y
                if pl.rot { pl.pt.ps.forEach { Geom.transform($0, Geom.M.rotate(90, pl.pt.bb.cx, pl.pt.bb.cy)) } }
                let nb = Geom.bbox(pl.pt.ps); pl.pt.ps.forEach { Geom.transform($0, Geom.M.move(tx - nb.x1, ty - nb.y1)); if o.groupSheets { $0.group = gid } } } }
        d.changed()
        return "Размещено деталей: \(placed)" + (failed > 0 ? ", не поместилось: \(failed)" : "") + "; листов: \(sheets.count)" + (sheets.count > 1 ? "\nСледующие листы — справа от модели (рамкой)." : "")
    }

    // ---------- трансформирование ----------
    func transformSel(_ m: [Double], _ copy: Bool) -> String? { if d.selected().isEmpty { return "Выберите векторы" }; d.applyMatrix(m, copy); return nil }

    // ---------- размер и положение модели ----------
    func setModelSize(_ w: Double, _ h: Double, _ anchor: String, _ thickness: Double) {
        d.push(); let m = d.model
        if anchor == "c" { m.x0 -= (w - m.w) / 2; m.y0 -= (h - m.h) / 2 } else if anchor == "tl" { m.y0 -= (h - m.h) }
        m.w = w; m.h = h; d.material.thickness = thickness; d.changed()
    }
    /// pos: bl tl c tr br custom — где ноль; модель и векторы сдвигаются вместе
    func setModelPos(_ pos: String, _ cx: Double, _ cy: Double) {
        let m = d.model; let nx: Double, ny: Double
        switch pos { case "tl": nx = 0; ny = -m.h; case "c": nx = -m.w / 2; ny = -m.h / 2; case "tr": nx = -m.w; ny = -m.h; case "br": nx = -m.w; ny = 0; case "custom": nx = cx; ny = cy; default: nx = 0; ny = 0 }
        let dx = nx - m.x0, dy = ny - m.y0; d.push(); m.x0 = nx; m.y0 = ny
        d.paths.forEach { Geom.transform($0, Geom.M.move(dx, dy)); $0.shape = nil }; if let im = d.image { im.x += dx; im.y += dy }; d.changed()
    }
}
