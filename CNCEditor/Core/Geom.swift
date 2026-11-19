/* ЧПУ Редактор 2D — геометрия векторов. Единицы — мм, ось Y вверх. (порт Geom.kt) */
import Foundation

struct P: Equatable { var x: Double; var y: Double; init(_ x: Double, _ y: Double) { self.x = x; self.y = y } }

class Seg {
    var x: Double; var y: Double
    init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    func copy() -> Seg { Seg(x, y) }
}
final class LineSeg: Seg { override func copy() -> Seg { LineSeg(x, y) } }
/// Дуга от предыдущей точки до (x,y) с центром (cx,cy)
final class ArcSeg: Seg {
    var cx: Double; var cy: Double; var ccw: Bool
    init(_ x: Double, _ y: Double, _ cx: Double, _ cy: Double, _ ccw: Bool) { self.cx = cx; self.cy = cy; self.ccw = ccw; super.init(x, y) }
    override func copy() -> Seg { ArcSeg(x, y, cx, cy, ccw) }
}
/// Кубическая Безье
final class BezSeg: Seg {
    var x1: Double; var y1: Double; var x2: Double; var y2: Double
    init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double, _ x: Double, _ y: Double) { self.x1 = x1; self.y1 = y1; self.x2 = x2; self.y2 = y2; super.init(x, y) }
    override func copy() -> Seg { BezSeg(x1, y1, x2, y2, x, y) }
}

/// Параметры фигуры для повторного редактирования (прямоугольник, окружность...)
struct Shape { let type: String; let v: [String: Double]; init(_ type: String, _ v: [String: Double]) { self.type = type; self.v = v } }

final class VPath {
    var id: String; var layer: Int; var closed: Bool
    var x0: Double; var y0: Double; var segs: [Seg]
    var group: String?; var shape: Shape?; var locked: Bool
    var text: TextParams?
    init(id: String = Geom.uid(), layer: Int = 0, closed: Bool = false, x0: Double = 0, y0: Double = 0, segs: [Seg] = [],
         group: String? = nil, shape: Shape? = nil, locked: Bool = false, text: TextParams? = nil) {
        self.id = id; self.layer = layer; self.closed = closed; self.x0 = x0; self.y0 = y0; self.segs = segs
        self.group = group; self.shape = shape; self.locked = locked; self.text = text
    }
    func copy(newId: Bool = true) -> VPath { VPath(id: newId ? Geom.uid() : id, layer: layer, closed: closed, x0: x0, y0: y0, segs: segs.map { $0.copy() }, group: group, shape: shape, locked: locked, text: text?.copy()) }
    var endX: Double { segs.isEmpty ? x0 : segs.last!.x }
    var endY: Double { segs.isEmpty ? y0 : segs.last!.y }
}

struct BBox {
    let x1: Double; let y1: Double; let x2: Double; let y2: Double
    init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) { self.x1 = x1; self.y1 = y1; self.x2 = x2; self.y2 = y2 }
    var w: Double { x2 - x1 }; var h: Double { y2 - y1 }; var cx: Double { (x1 + x2) / 2 }; var cy: Double { (y1 + y2) / 2 }
    var empty: Bool { x1 > x2 }
}
struct ArcInfo { let a0: Double; let sw: Double; let r: Double }
struct SegHit { let t: Double; let u: Double; let x: Double; let y: Double }

@inline(__always) func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double { min(max(v, a), b) }
@inline(__always) func clampI(_ v: Int, _ a: Int, _ b: Int) -> Int { min(max(v, a), b) }

enum Geom {
    private static var nextId = 1
    static func uid() -> String { let s = "v" + String(nextId); nextId += 1; return s }
    private static let EPS = 1e-9
    static let SC = 1000.0 // 1 мкм для Clipper

    static func makePath(_ pts: [P], _ closed: Bool, _ layer: Int = 0) -> VPath {
        let p = VPath(layer: layer, closed: closed, x0: pts[0].x, y0: pts[0].y)
        if pts.count > 1 { for i in 1..<pts.count { p.segs.append(LineSeg(pts[i].x, pts[i].y)) } }
        if closed, let l = p.segs.last { if abs(l.x - p.x0) > 1e-7 || abs(l.y - p.y0) > 1e-7 { p.segs.append(LineSeg(p.x0, p.y0)) } }
        return p
    }

    static func arcAngles(_ px: Double, _ py: Double, _ s: ArcSeg) -> ArcInfo {
        let a0 = atan2(py - s.cy, px - s.cx); let a1 = atan2(s.y - s.cy, s.x - s.cx)
        var sw = a1 - a0
        if s.ccw { while sw <= EPS { sw += 2 * .pi } } else { while sw >= -EPS { sw -= 2 * .pi } }
        return ArcInfo(a0: a0, sw: sw, r: hypot(px - s.cx, py - s.cy))
    }

    /// Разбиение на отрезки с допуском tol (стрелка прогиба)
    static func flatten(_ p: VPath, _ tol0: Double = 0.01) -> [P] {
        let tol = tol0 > 0 ? tol0 : 0.01
        var out: [P] = [P(p.x0, p.y0)]
        var px = p.x0; var py = p.y0
        for s in p.segs {
            if let s = s as? ArcSeg {
                let ai = arcAngles(px, py, s); let r = ai.r
                let st = r > tol ? 2 * acos(1 - tol / r) : .pi / 4
                let n = max(1, Int(ceil(abs(ai.sw) / st)))
                if n > 1 { for i in 1..<n { let a = ai.a0 + ai.sw * Double(i) / Double(n); out.append(P(s.cx + r * cos(a), s.cy + r * sin(a))) } }
                out.append(P(s.x, s.y))
            } else if let s = s as? BezSeg {
                bez(px, py, s.x1, s.y1, s.x2, s.y2, s.x, s.y, tol, &out, 0); out.append(P(s.x, s.y))
            } else { out.append(P(s.x, s.y)) }
            px = s.x; py = s.y
        }
        return out
    }
    private static func bez(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double, _ x3: Double, _ y3: Double, _ tol: Double, _ out: inout [P], _ d: Int) {
        let dx = x3 - x0; let dy = y3 - y0; var L = hypot(dx, dy); if L == 0 { L = 1e-12 }
        let d1 = abs((x1 - x3) * dy - (y1 - y3) * dx) / L; let d2 = abs((x2 - x3) * dy - (y2 - y3) * dx) / L
        if d > 16 || (d1 + d2) * 0.75 <= tol { return }
        let x01 = (x0 + x1) / 2, y01 = (y0 + y1) / 2, x12 = (x1 + x2) / 2, y12 = (y1 + y2) / 2, x23 = (x2 + x3) / 2, y23 = (y2 + y3) / 2
        let xa = (x01 + x12) / 2, ya = (y01 + y12) / 2, xb = (x12 + x23) / 2, yb = (y12 + y23) / 2, xm = (xa + xb) / 2, ym = (ya + yb) / 2
        bez(x0, y0, x01, y01, xa, ya, xm, ym, tol, &out, d + 1); out.append(P(xm, ym))
        bez(xm, ym, xb, yb, x23, y23, x3, y3, tol, &out, d + 1)
    }

    static func bbox(_ paths: [VPath]) -> BBox {
        var x1 = Double.infinity, y1 = Double.infinity, x2 = -Double.infinity, y2 = -Double.infinity
        for p in paths { for q in flatten(p, 0.05) { if q.x < x1 { x1 = q.x }; if q.x > x2 { x2 = q.x }; if q.y < y1 { y1 = q.y }; if q.y > y2 { y2 = q.y } } }
        return BBox(x1, y1, x2, y2)
    }
    static func bbox(_ p: VPath) -> BBox { bbox([p]) }

    /// Аффинная матрица [a,b,c,d,e,f]: x'=a*x+c*y+e, y'=b*x+d*y+f
    @discardableResult static func transform(_ p: VPath, _ m: [Double]) -> VPath {
        var px = p.x0, py = p.y0; var starts: [P] = []
        for s in p.segs { starts.append(P(px, py)); px = s.x; py = s.y }
        func tx(_ x: Double, _ y: Double) -> Double { m[0] * x + m[2] * y + m[4] }
        func ty(_ x: Double, _ y: Double) -> Double { m[1] * x + m[3] * y + m[5] }
        let det = m[0] * m[3] - m[1] * m[2]
        let uniform = abs(hypot(m[0], m[1]) - hypot(m[2], m[3])) < 1e-9 && abs(m[0] * m[2] + m[1] * m[3]) < 1e-9
        var segs: [Seg] = []
        for (i, s) in p.segs.enumerated() {
            if let s = s as? BezSeg { segs.append(BezSeg(tx(s.x1, s.y1), ty(s.x1, s.y1), tx(s.x2, s.y2), ty(s.x2, s.y2), tx(s.x, s.y), ty(s.x, s.y))) }
            else if let s = s as? ArcSeg {
                if uniform { segs.append(ArcSeg(tx(s.x, s.y), ty(s.x, s.y), tx(s.cx, s.cy), ty(s.cx, s.cy), det < 0 ? !s.ccw : s.ccw)) }
                else { for b in arcToBeziers(starts[i], s) { segs.append(BezSeg(tx(b.x1, b.y1), ty(b.x1, b.y1), tx(b.x2, b.y2), ty(b.x2, b.y2), tx(b.x, b.y), ty(b.x, b.y))) } }
            } else { segs.append(LineSeg(tx(s.x, s.y), ty(s.x, s.y))) }
        }
        let nx = tx(p.x0, p.y0), ny = ty(p.x0, p.y0); p.x0 = nx; p.y0 = ny
        p.segs = segs; p.shape = nil
        return p
    }
    static func arcToBeziers(_ start: P, _ s: ArcSeg) -> [BezSeg] {
        let ai = arcAngles(start.x, start.y, s); let r = ai.r
        let n = max(1, Int(ceil(abs(ai.sw) / (.pi / 2))))
        let da = ai.sw / Double(n); let k = 4.0 / 3 * tan(da / 4); var res: [BezSeg] = []
        for i in 0..<n {
            let a = ai.a0 + da * Double(i); let b = a + da
            let x0 = s.cx + r * cos(a), y0 = s.cy + r * sin(a), x3 = s.cx + r * cos(b), y3 = s.cy + r * sin(b)
            res.append(BezSeg(x0 - k * r * sin(a), y0 + k * r * cos(a), x3 + k * r * sin(b), y3 - k * r * cos(b), x3, y3))
        }
        return res
    }

    enum M {
        static func move(_ dx: Double, _ dy: Double) -> [Double] { [1, 0, 0, 1, dx, dy] }
        static func scale(_ sx: Double, _ sy: Double, _ ox: Double, _ oy: Double) -> [Double] { [sx, 0, 0, sy, ox - sx * ox, oy - sy * oy] }
        /// + = по часовой (как ArtCAM)
        static func rotate(_ deg: Double, _ ox: Double, _ oy: Double) -> [Double] { let a = -deg * .pi / 180; let c = cos(a), s = sin(a); return [c, s, -s, c, ox - c * ox + s * oy, oy - s * ox - c * oy] }
        static func shear(_ ax: Double, _ ay: Double, _ ox: Double, _ oy: Double) -> [Double] { let tx = tan(ax * .pi / 180), ty = tan(ay * .pi / 180); return [1, ty, tx, 1, -tx * oy, -ty * ox] }
        static func mirror(_ horizontal: Bool, _ o: Double) -> [Double] { horizontal ? [-1, 0, 0, 1, 2 * o, 0] : [1, 0, 0, -1, 0, 2 * o] }
    }

    @discardableResult static func reverse(_ p: VPath) -> VPath {
        var pts: [P] = [P(p.x0, p.y0)]; for s in p.segs { pts.append(P(s.x, s.y)) }
        var segs: [Seg] = []
        for i in stride(from: p.segs.count - 1, through: 0, by: -1) {
            let s = p.segs[i]; let to = pts[i]
            if let a = s as? ArcSeg { segs.append(ArcSeg(to.x, to.y, a.cx, a.cy, !a.ccw)) }
            else if let b = s as? BezSeg { segs.append(BezSeg(b.x2, b.y2, b.x1, b.y1, to.x, to.y)) }
            else { segs.append(LineSeg(to.x, to.y)) }
        }
        let last = pts.last!; p.x0 = last.x; p.y0 = last.y; p.segs = segs; return p
    }
    static func signedArea(_ pts: [P]) -> Double { var a = 0.0; let n = pts.count; for i in 0..<n { let p1 = pts[i], p2 = pts[(i + 1) % n]; a += p1.x * p2.y - p2.x * p1.y }; return a / 2 }
    static func isClockwise(_ p: VPath) -> Bool { signedArea(flatten(p, 0.1)) < 0 }
    static func length(_ p: VPath) -> Double { polyLen(flatten(p, 0.005)) }

    // ---------- фигуры (как в ArtCAM), угол + по часовой ----------
    fileprivate static func rotPts(_ pts: [P], _ deg: Double, _ cx: Double, _ cy: Double) -> [P] {
        if deg == 0 { return pts }; let m = M.rotate(deg, cx, cy); return pts.map { P(m[0] * $0.x + m[2] * $0.y + m[4], m[1] * $0.x + m[3] * $0.y + m[5]) }
    }
    enum Shapes {
        static func rect(_ cx: Double, _ cy: Double, _ w: Double, _ h: Double, _ r0: Double = 0, _ ang: Double = 0, _ inv: Bool = false) -> VPath {
            let r = max(0, min(r0, w / 2, h / 2))
            let x1 = cx - w / 2, x2 = cx + w / 2, y1 = cy - h / 2, y2 = cy + h / 2
            let p: VPath
            if r <= 0 { p = makePath([P(x2, y2), P(x1, y2), P(x1, y1), P(x2, y1)], true) } // от правого верхнего угла влево, как ArtCAM
            else {
                p = VPath(closed: true, x0: x1 + r, y0: y1, segs: [
                    LineSeg(x2 - r, y1), ArcSeg(x2, y1 + r, x2 - r, y1 + r, true),
                    LineSeg(x2, y2 - r), ArcSeg(x2 - r, y2, x2 - r, y2 - r, true),
                    LineSeg(x1 + r, y2), ArcSeg(x1, y2 - r, x1 + r, y2 - r, true),
                    LineSeg(x1, y1 + r), ArcSeg(x1 + r, y1, x1 + r, y1 + r, true)])
                if inv { let c = [P(x2, y1), P(x2, y2), P(x1, y2), P(x1, y1)]; var k = 0; for sg in p.segs { if let a = sg as? ArcSeg { a.cx = c[k].x; a.cy = c[k].y; a.ccw = false; k += 1 } } }
            }
            if ang != 0 { transform(p, M.rotate(ang, cx, cy)) }
            p.shape = Shape("rect", ["cx": cx, "cy": cy, "w": w, "h": h, "r": r, "ang": ang, "inv": inv ? 1 : 0])
            return p
        }
        static func circle(_ cx: Double, _ cy: Double, _ r: Double) -> VPath {
            let p = VPath(closed: true, x0: cx + r, y0: cy, segs: [ArcSeg(cx, cy + r, cx, cy, true), ArcSeg(cx - r, cy, cx, cy, true), ArcSeg(cx, cy - r, cx, cy, true), ArcSeg(cx + r, cy, cx, cy, true)])
            p.shape = Shape("circle", ["cx": cx, "cy": cy, "r": r]); return p
        }
        static func ellipse(_ cx: Double, _ cy: Double, _ w: Double, _ h: Double, _ ang: Double = 0) -> VPath {
            let p = circle(0, 0, 1); transform(p, M.scale(w / 2, h / 2, 0, 0)); transform(p, M.rotate(ang, 0, 0)); transform(p, M.move(cx, cy))
            p.shape = Shape("ellipse", ["cx": cx, "cy": cy, "w": w, "h": h, "ang": ang]); return p
        }
        static func polygon(_ cx: Double, _ cy: Double, _ n0: Int, _ r: Double, _ ang: Double = 0) -> VPath {
            let n = max(3, n0); let pts = (0..<n).map { i -> P in let a = Double.pi / 2 + 2 * .pi * Double(i) / Double(n); return P(cx + r * cos(a), cy + r * sin(a)) }
            let p = makePath(rotPts(pts, ang, cx, cy), true); p.shape = Shape("polygon", ["cx": cx, "cy": cy, "n": Double(n), "r": r, "ang": ang]); return p
        }
        static func star(_ cx: Double, _ cy: Double, _ n0: Int, _ r1: Double, _ r2: Double, _ ang: Double = 0) -> VPath {
            let n = max(3, n0); let pts = (0..<(2 * n)).map { i -> P in let a = Double.pi / 2 + .pi * Double(i) / Double(n); let r = i % 2 == 1 ? r2 : r1; return P(cx + r * cos(a), cy + r * sin(a)) }
            let p = makePath(rotPts(pts, ang, cx, cy), true); p.shape = Shape("star", ["cx": cx, "cy": cy, "n": Double(n), "r1": r1, "r2": r2, "ang": ang]); return p
        }
        /// начало, точка на дуге, конец
        static func arc3(_ x1: Double, _ y1: Double, _ xm: Double, _ ym: Double, _ x2: Double, _ y2: Double) -> VPath {
            guard let c = circ3(P(x1, y1), P(xm, ym), P(x2, y2)) else { return makePath([P(x1, y1), P(x2, y2)], false) }
            let ccw = ((xm - x1) * (y2 - y1) - (ym - y1) * (x2 - x1)) > 0
            return VPath(closed: false, x0: x1, y0: y1, segs: [ArcSeg(x2, y2, c.x, c.y, ccw)])
        }
        static func arcCSE(_ cx: Double, _ cy: Double, _ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double, _ ccw: Bool) -> VPath {
            let r = hypot(x1 - cx, y1 - cy); let a = atan2(y2 - cy, x2 - cx)
            return VPath(closed: false, x0: x1, y0: y1, segs: [ArcSeg(cx + r * cos(a), cy + r * sin(a), cx, cy, ccw)])
        }
    }
    static func circ3(_ a: P, _ b: P, _ c: P) -> P? {
        let d = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)); if abs(d) < 1e-12 { return nil }
        let A = a.x * a.x + a.y * a.y, B = b.x * b.x + b.y * b.y, C = c.x * c.x + c.y * c.y
        return P((A * (b.y - c.y) + B * (c.y - a.y) + C * (a.y - b.y)) / d, (A * (c.x - b.x) + B * (a.x - c.x) + C * (b.x - a.x)) / d)
    }

    // ---------- Clipper: смещение и булевы операции ----------
    static func toC(_ pts: [P]) -> CPath { pts.map { IntPoint(Int64(($0.x * SC).rounded()), Int64(($0.y * SC).rounded())) } }
    static func fromC(_ pl: CPath) -> [P] { pl.map { P(Double($0.X) / SC, Double($0.Y) / SC) } }
    static func toClip(_ paths: [VPath], _ tol: Double = 0.005) -> CPaths { paths.map { p in var f = flatten(p, tol); if p.closed && f.count > 1 { f.removeLast() }; return toC(f) } }
    static func fromClip(_ polys: CPaths, _ layer: Int) -> [VPath] { polys.filter { $0.count > 1 }.map { makePath(fromC($0), true, layer) } }

    /// dist > 0 — наружу. corners: round | chamfer | sharp
    static func offset(_ paths: [VPath], _ dist: Double, _ corners: String = "round", _ miterPct: Double = 100) -> [VPath] {
        let jt: JoinType = corners == "sharp" ? .miter : (corners == "chamfer" ? .square : .round)
        let miter = corners == "sharp" ? 1 + miterPct / 100 : 2.0
        let closed = paths.filter { $0.closed }, open = paths.filter { !$0.closed }
        var groups: [(CPaths, JoinType, EndType)] = []
        if !closed.isEmpty { groups.append((normalize(toClip(closed)), jt, .closedPolygon)) }
        if !open.isEmpty { groups.append((toClip(open), jt, corners == "round" ? .openRound : .openButt)) }
        let sol = Clip.offset(groups, dist * SC, miter: miter, arcTol: 0.005 * SC)
        return fromClip(sol, paths.first?.layer ?? 0)
    }
    /// объединение по чётности — вложенные контуры становятся отверстиями
    static func normalize(_ cp: CPaths) -> CPaths { Clip.boolean(.union, cp, [], .evenOdd, .evenOdd) }
    /// op: union | intersect | subtract | xor
    static func boolean(_ op: String, _ subj: [VPath], _ clip: [VPath]) -> [VPath] {
        let t: ClipType = op == "union" ? .union : op == "intersect" ? .intersection : op == "subtract" ? .difference : .xor
        let s = Clip.boolean(t, toClip(subj), clip.isEmpty ? [] : toClip(clip), .nonZero, .nonZero)
        return fromClip(s, subj.first?.layer ?? 0)
    }

    static func distToPath(_ p: VPath, _ x: Double, _ y: Double, _ tol: Double = 0.05) -> Double { let f = flatten(p, tol); var d = Double.infinity; if f.count > 1 { for i in 1..<f.count { d = min(d, distSeg(x, y, f[i - 1], f[i])) } }; return d }
    static func distSeg(_ x: Double, _ y: Double, _ a: P, _ b: P) -> Double { let dx = b.x - a.x, dy = b.y - a.y; let L = dx * dx + dy * dy; var t = L > 0 ? ((x - a.x) * dx + (y - a.y) * dy) / L : 0; t = clamp(t, 0, 1); return hypot(x - a.x - t * dx, y - a.y - t * dy) }
    static func pointInPoly(_ x: Double, _ y: Double, _ f: [P]) -> Bool {
        var inside = false; var j = f.count - 1
        for i in 0..<f.count { let xi = f[i].x, yi = f[i].y, xj = f[j].x, yj = f[j].y; if (yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi { inside = !inside }; j = i }
        return inside
    }

    /// Соединение отрезков в цепочки (импорт DXF)
    static func joinChains(_ paths: [VPath], _ tol: Double = 0.001) -> [VPath] {
        var open = paths.filter { !$0.closed }; let done = paths.filter { $0.closed }
        func near(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double) -> Bool { abs(ax - bx) <= tol && abs(ay - by) <= tol }
        var changed = true
        while changed {
            changed = false
            outer: for i in open.indices { for j in open.indices {
                if i == j || open[i].layer != open[j].layer { continue }
                let a = open[i], b = open[j]
                if near(a.endX, a.endY, b.x0, b.y0) { a.segs.append(contentsOf: b.segs) }
                else if near(a.endX, a.endY, b.endX, b.endY) { reverse(b); a.segs.append(contentsOf: b.segs) }
                else { continue }
                open.remove(at: j); changed = true; break outer
            } }
        }
        for p in open where p.segs.count > 1 && near(p.endX, p.endY, p.x0, p.y0) { let l = p.segs.last!; l.x = p.x0; l.y = p.y0; p.closed = true }
        return done + open
    }

    static func polyLen(_ f: [P]) -> Double { var L = 0.0; if f.count > 1 { for i in 1..<f.count { L += hypot(f[i].x - f[i - 1].x, f[i].y - f[i - 1].y) } }; return L }
    /// точка на длине s: x, y, угол касательной
    static func pointAt(_ f: [P], _ s: Double) -> [Double] {
        var acc = 0.0
        if f.count > 1 { for i in 1..<f.count {
            let d = hypot(f[i].x - f[i - 1].x, f[i].y - f[i - 1].y)
            if acc + d >= s || i == f.count - 1 { let t = d > 0 ? clamp((s - acc) / d, 0, 1) : 0; return [f[i - 1].x + (f[i].x - f[i - 1].x) * t, f[i - 1].y + (f[i].y - f[i - 1].y) * t, atan2(f[i].y - f[i - 1].y, f[i].x - f[i - 1].x)] }
            acc += d
        } }
        return [f[0].x, f[0].y, 0]
    }
    /// пересечение отрезков ab и cd
    static func segX(_ a: P, _ b: P, _ c: P, _ d: P) -> SegHit? {
        let rx = b.x - a.x, ry = b.y - a.y, qx = d.x - c.x, qy = d.y - c.y; let den = rx * qy - ry * qx
        if abs(den) < 1e-12 { return nil }
        let t = ((c.x - a.x) * qy - (c.y - a.y) * qx) / den; let u = ((c.x - a.x) * ry - (c.y - a.y) * rx) / den
        if t < -1e-9 || t > 1 + 1e-9 || u < -1e-9 || u > 1 + 1e-9 { return nil }
        return SegHit(t: t, u: u, x: a.x + rx * t, y: a.y + ry * t)
    }
    static func bezPt(_ a: P, _ s: BezSeg, _ t: Double) -> P { let m = 1 - t; return P(m * m * m * a.x + 3 * m * m * t * s.x1 + 3 * m * t * t * s.x2 + t * t * t * s.x, m * m * m * a.y + 3 * m * m * t * s.y1 + 3 * m * t * t * s.y2 + t * t * t * s.y) }
}

/// Параметры векторного текста (хранятся в каждом контуре текста для повторного редактирования)
final class TextParams {
    var text = "Текст", font = "sans", bold = false, italic = false
    var size = 50.0, align = "left", charSp = 0.0, lineSp = 0.0, kern = true
    var sx = 100.0, sy = 100.0, slant = 0.0, rot = 0.0, x = 0.0, y = 0.0
    var curveId: String? = nil, cPos = "center", cOff = 0.0, cStart = 0.0, cFlip = false
    init() {}
    func copy() -> TextParams {
        let t = TextParams(); t.text = text; t.font = font; t.bold = bold; t.italic = italic; t.size = size; t.align = align; t.charSp = charSp; t.lineSp = lineSp; t.kern = kern
        t.sx = sx; t.sy = sy; t.slant = slant; t.rot = rot; t.x = x; t.y = y; t.curveId = curveId; t.cPos = cPos; t.cOff = cOff; t.cStart = cStart; t.cFlip = cFlip; return t
    }
}
