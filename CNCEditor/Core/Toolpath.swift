/* ЧПУ Редактор 2D — расчёт 2D-траекторий: профиль, вдоль векторов, выборка, V-резьба, сверление.
 * Подачи инструмента — мм/мин. Порт Toolpath.kt */
import Foundation

/// Фреза для расчёта (подачи в мм/мин)
struct CutTool { let num: Int; let name: String; let dia: Double; let stepdown: Double; let stepover: Double; let spindle: Int; let feed: Double; let plunge: Double; var angle = 90.0
    init(_ num: Int, _ name: String, _ dia: Double, _ stepdown: Double, _ stepover: Double, _ spindle: Int, _ feed: Double, _ plunge: Double, _ angle: Double = 90) {
        self.num = num; self.name = name; self.dia = dia; self.stepdown = stepdown; self.stepover = stepover; self.spindle = spindle; self.feed = feed; self.plunge = plunge; self.angle = angle }
    func copy() -> CutTool { self }
}

final class Tabs {
    var on = false, mode = "count", n = 4, dist = 300.0, len = 10.0, h = 3.0, points: [P] = []
    init(_ on: Bool = false, _ mode: String = "count", _ n: Int = 4, _ dist: Double = 300, _ len: Double = 10, _ h: Double = 3, _ points: [P] = []) { self.on = on; self.mode = mode; self.n = n; self.dist = dist; self.len = len; self.h = h; self.points = points }
    func copy() -> Tabs { Tabs(on, mode, n, dist, len, h, points) }
}
final class Ramp { var on = false, len = 30.0; init(_ on: Bool = false, _ len: Double = 30) { self.on = on; self.len = len }; func copy() -> Ramp { Ramp(on, len) } }

final class TpParams {
    var start = 0.0, finish = 3.0, tol = 0.01, safeZ = 15.0
    var sequencing = "optimise", side = "outside", allowance = 0.0, climb = true
    var tabs = Tabs(), ramp = Ramp()
    var strategy = "offset", rasterAngle = 0, lastProfile = true, stepover = 0.0
    var peck = 0.0, retract = 2.0, vangle = 90.0, name = ""
    init() {}
    init(_ start: Double, _ finish: Double, _ tol: Double, _ safeZ: Double, _ sequencing: String, _ side: String, _ allowance: Double, _ climb: Bool,
         _ tabs: Tabs, _ ramp: Ramp, _ strategy: String, _ rasterAngle: Int, _ lastProfile: Bool, _ stepover: Double, _ peck: Double, _ retract: Double, _ vangle: Double, _ name: String) {
        self.start = start; self.finish = finish; self.tol = tol; self.safeZ = safeZ; self.sequencing = sequencing; self.side = side; self.allowance = allowance; self.climb = climb
        self.tabs = tabs; self.ramp = ramp; self.strategy = strategy; self.rasterAngle = rasterAngle; self.lastProfile = lastProfile; self.stepover = stepover
        self.peck = peck; self.retract = retract; self.vangle = vangle; self.name = name
    }
    /// глубокая копия (мостики и рампа тоже)
    func copy() -> TpParams { TpParams(start, finish, tol, safeZ, sequencing, side, allowance, climb, tabs.copy(), ramp.copy(), strategy, rasterAngle, lastProfile, stepover, peck, retract, vangle, name) }
}

final class Chain { let pts: [P]; let closed: Bool; let drill: Bool; let z: Double
    init(_ pts: [P], _ closed: Bool, _ drill: Bool = false, z: Double = 0) { self.pts = pts; self.closed = closed; self.drill = drill; self.z = z } }
final class TpResult { let type: String; let name: String; let moves: [Move]; let chains: [Chain]; let tabMarks: [P]
    init(_ type: String, _ name: String, _ moves: [Move], _ chains: [Chain], _ tabMarks: [P] = []) { self.type = type; self.name = name; self.moves = moves; self.chains = chains; self.tabMarks = tabMarks } }
struct Summary { let cut: Double; let rapid: Double; let plunges: Int; let minutes: Double }

enum Toolpath {
    static func depthPasses(_ start: Double, _ finish: Double, _ step: Double) -> [Double] {
        let total = finish - start; if total <= 1e-9 { return [finish] }
        let n = max(1, Int(ceil(total / step - 1e-9)))
        return (1...n).map { start + total * Double($0) / Double(n) }
    }
    /// порядок: ближайший сосед от текущей точки
    static func order(_ chains: [Chain], _ mode: String, _ fx: Double = 0, _ fy: Double = 0) -> [Chain] {
        if mode != "optimise" { return chains }
        var left = chains; var res: [Chain] = []; var cx = fx, cy = fy
        while !left.isEmpty {
            var bi = 0, bd = Double.infinity
            for (i, c) in left.enumerated() { let d = hypot(c.pts[0].x - cx, c.pts[0].y - cy); if d < bd { bd = d; bi = i } }
            let c = left.remove(at: bi); res.append(c); let e = c.pts.last!; cx = e.x; cy = e.y
        }
        return res
    }

    fileprivate static func cumOf(_ p: [P]) -> [Double] { var cum = [Double](repeating: 0, count: p.count); if p.count > 1 { for i in 1..<p.count { cum[i] = cum[i - 1] + hypot(p[i].x - p[i - 1].x, p[i].y - p[i - 1].y) } }; return cum }
    fileprivate static func atS(_ p: [P], _ cum: [Double], _ s: Double) -> P {
        var lo = 1, hi = cum.count - 1
        while lo < hi { let m = (lo + hi) >> 1; if cum[m] < s { lo = m + 1 } else { hi = m } }
        let i = max(1, lo); let d = cum[i] - cum[i - 1]; let f = (s - cum[i - 1]) / (d == 0 ? 1 : d)
        return P(p[i - 1].x + (p[i].x - p[i - 1].x) * f, p[i - 1].y + (p[i].y - p[i - 1].y) * f)
    }
    private static func nearestS(_ p: [P], _ cum: [Double], _ q: P) -> (Double, Double) {
        var bs = 0.0, bd = Double.infinity
        for i in 1..<p.count {
            let a = p[i - 1], b = p[i]; let dx = b.x - a.x, dy = b.y - a.y; var l2 = dx * dx + dy * dy; if l2 == 0 { l2 = 1e-12 }
            let t = clamp(((q.x - a.x) * dx + (q.y - a.y) * dy) / l2, 0, 1)
            let d = hypot(a.x + dx * t - q.x, a.y + dy * t - q.y); if d < bd { bd = d; bs = cum[i - 1] + t * sqrt(l2) }
        }
        return (bs, bd)
    }
    struct TabZones { let zones: [[Double]]; let centers: [P]; let cum: [Double]; let L: Double }
    /// мостики на замкнутой цепочке (авто — количество/расстояние; вручную — точки на траектории)
    static func tabZones(_ p: [P], _ T: Tabs, _ tool: CutTool) -> TabZones {
        let cum = cumOf(p); let L = cum.last!; let half = T.len / 2 + tool.dia / 2; var centers: [Double] = []
        if T.mode == "manual" { for q in T.points { let (s, d) = nearestS(p, cum, q); if d <= tool.dia / 2 + 3 { centers.append(s) } }; centers.sort() }
        else {
            var n = T.mode == "dist" ? max(1, kround(L / max(1, T.dist))) : max(1, T.n)
            if L < Double(n) * half * 2 * 1.5 { n = max(0, Int(floor(L / (half * 2 * 1.5)))) }
            for i in 0..<n { centers.append(L * (Double(i) + 0.5) / Double(n)) }
        }
        return TabZones(zones: centers.map { [max(0.001, $0 - half), min(L - 0.001, $0 + half)] }, centers: centers.map { atS(p, cum, $0) }, cum: cum, L: L)
    }
    /// проход по цепочке от s0 до s1 с высотой zf(s); разрывы (мостики) — вертикальным ходом
    fileprivate static func walk(_ p: [P], _ cum: [Double], _ s0: Double, _ s1: Double, _ zf: (Double) -> Double, _ brk: [Double], _ mv: inout [Move], _ tool: CutTool) {
        let S = (cum.filter { $0 > s0 + 1e-9 && $0 < s1 - 1e-9 } + brk.filter { $0 > s0 + 1e-9 && $0 < s1 - 1e-9 } + [s1]).sorted()
        var prev = s0
        for s in S {
            if s - prev < 1e-9 { continue }
            let za = zf(prev + 1e-7), zb = zf(s - 1e-7); let last = mv.last!
            if abs(last.z - za) > 1e-9 { mv.append(Move(false, last.x, last.y, za, tool.plunge)) }
            let q = atS(p, cum, s); mv.append(Move(false, q.x, q.y, zb, tool.feed)); prev = s
        }
    }
    static func movesFor(_ chains: [Chain], _ prm: TpParams, _ tool: CutTool) -> [Move] {
        let passes = depthPasses(prm.start, prm.finish, tool.stepdown > 0 ? tool.stepdown : prm.finish)
        let safe = prm.safeZ; var mv: [Move] = []; let R: Ramp? = prm.ramp.on ? prm.ramp : nil
        for c in chains {
            let p = c.pts; if p.count < 2 { continue }
            mv.append(Move(true, p[0].x, p[0].y, safe))
            let tabs: TabZones? = c.closed && prm.tabs.on ? tabZones(p, prm.tabs, tool) : nil
            let tabTop = -(prm.finish - prm.tabs.h)
            if c.closed && (tabs != nil || R != nil) {
                let cum = tabs?.cum ?? cumOf(p); let L = cum.last!; let Lr = R != nil ? min(max(1, R!.len), L * 0.9) : 0
                let tz = { (s: Double) -> Double in if let t = tabs, t.zones.contains(where: { s > $0[0] && s < $0[1] }) { return tabTop }; return -Double.infinity }
                let brk = tabs?.zones.flatMap { [$0[0], $0[1]] } ?? []
                var zPrev = -prm.start; mv.append(Move(false, p[0].x, p[0].y, max(zPrev, tz(1e-6)), tool.plunge))
                for d in passes {
                    let z0 = zPrev
                    let base = { (s: Double) -> Double in Lr > 0 && s < Lr ? z0 + (-d - z0) * s / Lr : -d }
                    walk(p, cum, 0, L, { s in max(base(s), tz(s)) }, Lr > 0 ? brk + [Lr] : brk, &mv, tool); zPrev = -d
                }
                if Lr > 0 { let zf = zPrev; walk(p, cum, 0, Lr, { s in max(zf, tz(s)) }, brk, &mv, tool) } // дочистка рампы
                let e = mv.last!; mv.append(Move(true, e.x, e.y, safe)); continue
            }
            for (k, d) in passes.enumerated() {
                if k > 0 && !c.closed { mv.append(Move(true, p.last!.x, p.last!.y, safe)); mv.append(Move(true, p[0].x, p[0].y, safe)) }
                mv.append(Move(false, p[0].x, p[0].y, -d, tool.plunge))
                for i in 1..<p.count { mv.append(Move(false, p[i].x, p[i].y, -d, tool.feed)) }
            }
            let e = p.last!; mv.append(Move(true, e.x, e.y, safe))
        }
        return mv
    }

    // ---------- области (Clipper) ----------
    private static func region(_ paths: [VPath], _ tol: Double) -> CPaths {
        let polys = paths.filter { $0.closed }.map { v -> CPath in var f = Geom.flatten(v, tol > 0 ? tol : 0.02); f.removeLast(); return Geom.toC(f) }
        return Clip.simplifyPolygons(polys, .evenOdd)
    }
    private static func offsetC(_ polys: CPaths, _ d: Double) -> CPaths { Clip.offset([(polys, .round, .closedPolygon)], d * Geom.SC, miter: 2, arcTol: 0.005 * Geom.SC) }
    fileprivate struct Ring { let pts: [P]; var closed = true }
    private static func close(_ p: [P]) -> [P] { p.isEmpty ? p : p + [p[0]] }
    private static func rotStart(_ p: [P], _ from: P) -> [P] { var bi = 0, bd = Double.infinity; for (i, q) in p.enumerated() { let d = hypot(q.x - from.x, q.y - from.y); if d < bd { bd = d; bi = i } }; return Array(p[bi...] + p[..<bi]) }
    private static func inRegion(_ polys: [[P]], _ a: P, _ b: P) -> Bool {
        for pl in polys { for i in pl.indices { if let x = Geom.segX(a, b, pl[i], pl[(i + 1) % pl.count]), x.t > 1e-6 && x.t < 1 - 1e-6 { return false } } }
        let mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2; var c = 0; for pl in polys { if Geom.pointInPoly(mx, my, close(pl)) { c += 1 } }
        return c % 2 == 1
    }
    fileprivate struct Level { let z: Double; let zTop: Double?; let rings: [Ring]; let region: [[P]] }
    private static func ringMoves(_ levels: [Level], _ prm: TpParams, _ tool: CutTool, _ link: Double) -> [Move] {
        var mv: [Move] = []; let safe = prm.safeZ; var cur: P? = nil; var up = true
        for L in levels {
            var left = L.rings.filter { $0.pts.count > 1 }
            while !left.isEmpty {
                let from = cur ?? P(0, 0); var bi = 0, bd = Double.infinity
                for (i, r) in left.enumerated() { for q in r.pts { let d = hypot(q.x - from.x, q.y - from.y); if d < bd { bd = d; bi = i } } }
                let rr = left.remove(at: bi); let ring = rr.closed ? close(rotStart(rr.pts, from)) : rr.pts; let st = ring[0]
                if let c = cur, !up, bd <= link, inRegion(L.region, c, st) { mv.append(Move(false, st.x, st.y, L.z, tool.feed)) }
                else {
                    if !up, let c = cur { mv.append(Move(true, c.x, c.y, safe)) }; mv.append(Move(true, st.x, st.y, safe))
                    let R: Ramp? = prm.ramp.on && rr.closed ? prm.ramp : nil
                    let cum: [Double]? = R != nil ? cumOf(ring) : nil; let Lr = R != nil ? min(R!.len, cum!.last! * 0.9) : 0
                    if Lr > 0.5 {
                        let z0 = min(0, L.zTop ?? 0); mv.append(Move(false, st.x, st.y, z0, tool.plunge)); let Le = cum!.last!
                        walk(ring, cum!, 0, Lr, { s in z0 + (L.z - z0) * s / Lr }, [], &mv, tool)
                        walk(ring, cum!, Lr, Le, { _ in L.z }, [], &mv, tool); walk(ring, cum!, 0, Lr, { _ in L.z }, [], &mv, tool)
                        let e = mv.last!; cur = P(e.x, e.y); up = false; continue
                    } else { mv.append(Move(false, st.x, st.y, L.z, tool.plunge)) }
                }
                for i in 1..<ring.count { mv.append(Move(false, ring[i].x, ring[i].y, L.z, tool.feed)) }
                cur = ring.last!; up = false
            }
        }
        if let c = cur { mv.append(Move(true, c.x, c.y, safe)) }
        return mv
    }
    private static func chainsOf(_ levels: [Level]) -> [Chain] { levels.flatMap { L in L.rings.map { Chain($0.closed ? close($0.pts) : $0.pts, $0.closed, z: L.z) } } }

    static func chainsFromPaths(_ paths: [VPath], _ tol: Double) -> [Chain] {
        paths.map { v in
            let pts = Geom.flatten(v, tol > 0 ? tol : 0.01); var out: [P] = [pts[0]]
            for i in 1..<pts.count { let a = out.last!; if abs(pts[i].x - a.x) > 1e-9 || abs(pts[i].y - a.y) > 1e-9 { out.append(pts[i]) } }
            return Chain(out, v.closed)
        }
    }

    /// Machine Vectors — по векторам
    static func machineVectors(_ paths: [VPath], _ prm: TpParams, _ tool: CutTool) -> TpResult {
        let ch = order(chainsFromPaths(paths, prm.tol), prm.sequencing)
        return TpResult("machine", prm.name.isEmpty ? "Machine Vectors" : prm.name, movesFor(ch, prm, tool), ch)
    }
    /// Профиль — снаружи/внутри со смещением на радиус; отверстия — с противоположной стороны
    static func profile(_ paths: [VPath], _ prm: TpParams, _ tool: CutTool) -> TpResult {
        let r = tool.dia / 2 + prm.allowance
        let closed = paths.filter { $0.closed }
        let res: [VPath]
        if prm.side == "on" { res = closed.map { $0.copy() } }
        else {
            let F = closed.map { Geom.flatten($0, 0.05) }; var outer: [VPath] = [], holes: [VPath] = []
            for (i, p) in closed.enumerated() { let q = F[i][0]; var depth = 0; for (j, f) in F.enumerated() where j != i && Geom.pointInPoly(q.x, q.y, f) { depth += 1 }; if depth % 2 == 1 { holes.append(p) } else { outer.append(p) } }
            let sgn = prm.side == "inside" ? -1.0 : 1.0
            res = (outer.isEmpty ? [] : Geom.offset(outer, sgn * r, "round")) + (holes.isEmpty ? [] : Geom.offset(holes, -sgn * r, "round"))
        }
        let tri = res.map { p -> (VPath, Double, Bool) in let f = Geom.flatten(p, 0.05); let a = Geom.signedArea(f); return (p, abs(a), a < 0) }
        let ordered = tri.enumerated().sorted { $0.element.1 != $1.element.1 ? $0.element.1 < $1.element.1 : $0.offset < $1.offset }.map { e -> VPath in let (p, _, cw) = e.element; if prm.climb != cw { Geom.reverse(p) }; return p }
        var ch = chainsFromPaths(ordered, prm.tol).map { startNear($0, paths) }
        if prm.sequencing == "optimise" { ch = order(ch, "optimise") }
        let marks = prm.tabs.on ? ch.filter { $0.closed }.flatMap { tabZones($0.pts, prm.tabs, tool).centers } : []
        return TpResult("profile", prm.name.isEmpty ? "Profile" : prm.name, movesFor(ch, prm, tool), ch, marks)
    }
    private static func startNear(_ c: Chain, _ srcs: [VPath]) -> Chain {
        if !c.closed { return c }
        var best = 0, bd = Double.infinity
        for s in srcs { for (i, q) in c.pts.enumerated() { let d = hypot(q.x - s.x0, q.y - s.y0); if d < bd { bd = d; best = i } } }
        let p = Array(c.pts[0..<(c.pts.count - 1)]); let rot = Array(p[best...] + p[..<best])
        return Chain(rot + [rot[0]], true)
    }
    /// Выборка (Area Clearance) смещением или растром
    static func area(_ paths: [VPath], _ prm: TpParams, _ tool: CutTool) -> TpResult {
        let r = tool.dia / 2 + prm.allowance
        let so = max(0.01, prm.stepover > 0 ? prm.stepover : (tool.stepover > 0 ? tool.stepover : tool.dia * 0.4))
        let reg = region(paths, prm.tol); let base = offsetC(reg, -r)
        let nm = prm.name.isEmpty ? "Выборка" : prm.name
        if base.isEmpty { return TpResult("area", nm, [], []) }
        let baseP = base.map { Geom.fromC($0) }
        var rings: [Ring] = []
        if prm.strategy == "raster" {
            let sw = prm.rasterAngle == 90
            let B = baseP.map { pl in sw ? pl.map { P($0.y, $0.x) } : pl }
            var y1 = Double.infinity, y2 = -Double.infinity; for pl in B { for q in pl { y1 = min(y1, q.y); y2 = max(y2, q.y) } }
            var k = 0; var y = y1 + so / 2
            while y < y2 {
                var xs: [Double] = []
                for pl in B { for i in pl.indices { let a = pl[i], b = pl[(i + 1) % pl.count]; if (a.y <= y) != (b.y <= y) { xs.append(a.x + (y - a.y) / (b.y - a.y) * (b.x - a.x)) } } }
                xs.sort()
                var segs: [[P]] = []
                var i = 0; while i + 1 < xs.count { segs.append(k % 2 == 1 ? [P(xs[i + 1], y), P(xs[i], y)] : [P(xs[i], y), P(xs[i + 1], y)]); i += 2 }
                if k % 2 == 1 { segs.reverse() }
                for s in segs { rings.append(Ring(pts: sw ? s.map { P($0.y, $0.x) } : s, closed: false)) }
                y += so; k += 1
            }
            if prm.lastProfile { for b in baseP { rings.append(Ring(pts: b)) } }
        } else {
            var lv: [[[P]]] = []; var d = r
            for i in 0..<10000 { let o = i > 0 ? offsetC(reg, -d) : base; if o.isEmpty { break }; lv.append(o.map { Geom.fromC($0) }); d += so }
            for i in lv.indices.reversed() { for q in lv[i] { rings.append(Ring(pts: q)) } } // от центра к краю
        }
        let passes = depthPasses(prm.start, prm.finish, tool.stepdown > 0 ? tool.stepdown : prm.finish)
        let levels = passes.enumerated().map { (k, dd) in Level(z: -dd, zTop: k > 0 ? -passes[k - 1] : -prm.start, rings: rings, region: baseP) }
        return TpResult("area", nm, ringMoves(levels, prm, tool, so * 1.6), chainsOf([Level(z: -prm.finish, zTop: nil, rings: rings, region: baseP)]))
    }
    /// V-резьба: кольца смещения внутрь, глубина = смещение / tg(угол/2), предел глубины — плоское дно
    static func vcarve(_ paths: [VPath], _ prm: TpParams, _ tool: CutTool) -> TpResult {
        let reg = region(paths, prm.tol); let regP = reg.map { Geom.fromC($0) }
        let A = (prm.vangle > 0 ? prm.vangle : tool.angle) * .pi / 360; let so = max(0.02, prm.stepover > 0 ? prm.stepover : 0.2); let maxD = prm.finish
        var levels: [Level] = []; var o = so
        for _ in 0..<20000 {
            let dpt = min(maxD, o / tan(A)); let rings = offsetC(reg, -o); if rings.isEmpty { break }
            levels.append(Level(z: -dpt, zTop: nil, rings: rings.map { Ring(pts: Geom.fromC($0)) }, region: regP))
            o += dpt >= maxD - 1e-9 ? max(so, 2 * maxD * tan(A) * 0.7) : so
        }
        levels.reverse()
        let show = levels.isEmpty ? [] : [levels.last!, levels.first!]
        return TpResult("vcarve", prm.name.isEmpty ? "V-резьба" : prm.name, ringMoves(levels, prm, tool, so * 2.5), chainsOf(show))
    }
    /// Сверление в центрах векторов, с подъёмами
    static func drill(_ paths: [VPath], _ prm: TpParams, _ tool: CutTool) -> TpResult {
        let pts = paths.map { p -> P in let b = Geom.bbox(p); return P(b.cx, b.cy) }; let safe = prm.safeZ, rz = prm.retract
        let peck = prm.peck > 0 ? prm.peck : prm.finish; var mv: [Move] = []
        let ord = order(pts.map { Chain([$0], false) }, prm.sequencing).map { $0.pts[0] }
        for q in ord {
            mv.append(Move(true, q.x, q.y, safe)); mv.append(Move(true, q.x, q.y, rz)); var d = 0.0
            while d < prm.finish - 1e-9 { d = min(prm.finish, d + peck); mv.append(Move(false, q.x, q.y, -d, tool.plunge)); mv.append(Move(true, q.x, q.y, rz)) }
            mv.append(Move(true, q.x, q.y, safe))
        }
        return TpResult("drill", prm.name.isEmpty ? "Сверление" : prm.name, mv, ord.map { Chain([$0], false, true) })
    }
    static func compute(_ type: String, _ paths: [VPath], _ prm: TpParams, _ tool: CutTool) -> TpResult {
        switch type {
        case "profile": return profile(paths, prm, tool)
        case "area": return area(paths, prm, tool)
        case "vcarve": return vcarve(paths, prm, tool)
        case "drill": return drill(paths, prm, tool)
        default: return machineVectors(paths, prm, tool)
        }
    }
    static func summary(_ moves: [Move]) -> Summary {
        var cut = 0.0, rapid = 0.0, time = 0.0; var plunges = 0; var prev: Move? = nil
        for m in moves {
            if let pv = prev {
                let d = sqrt(pow(m.x - pv.x, 2) + pow(m.y - pv.y, 2) + pow(m.z - pv.z, 2))
                if m.r { rapid += d; time += d / 6000 } else { cut += d; time += d / (m.f > 0 ? m.f : 1); if m.z < pv.z - 1e-6 && hypot(m.x - pv.x, m.y - pv.y) < 1e-6 { plunges += 1 } }
            }
            prev = m
        }
        return Summary(cut: cut, rapid: rapid, plunges: plunges, minutes: time)
    }
}
