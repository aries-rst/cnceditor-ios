/* ЧПУ Редактор 2D — векторизация растра (собственная реализация) и выпрямление перспективы. Порт Trace.kt
 * trace(gray w*h 0..255) -> контуры в пикселях (y вниз) */
import Foundation

struct TraceOpt { var threshold = -1, invert = false, blur = 1; var minArea = 20.0, tolerance = 1.0; var smooth = true; var cornerDeg = 50.0
    init(_ threshold: Int = -1, _ invert: Bool = false, _ blur: Int = 1, _ minArea: Double = 20, _ tolerance: Double = 1, _ smooth: Bool = true, _ cornerDeg: Double = 50) {
        self.threshold = threshold; self.invert = invert; self.blur = blur; self.minArea = minArea; self.tolerance = tolerance; self.smooth = smooth; self.cornerDeg = cornerDeg } }
struct TraceContour { let pts: [P]; let segs: [Seg]? }
struct TraceResult { let contours: [TraceContour]; let threshold: Int }

enum Trace {
    static func boxBlur(_ src: [Int], _ w: Int, _ h: Int, _ r: Int) -> [Int] {
        if r < 1 { return src }
        var tmp = [Float](repeating: 0, count: w * h); var out = [Int](repeating: 0, count: w * h)
        for y in 0..<h { var acc = 0.0; var n = 0; let row = y * w
            for x in -r..<w { if x + r < w { acc += Double(src[row + x + r]); n += 1 }; if x - r - 1 >= 0 { acc -= Double(src[row + x - r - 1]); n -= 1 }; if x >= 0 { tmp[row + x] = Float(acc / Double(n)) } } }
        for x in 0..<w { var acc = 0.0; var n = 0
            for y in -r..<h { if y + r < h { acc += Double(tmp[(y + r) * w + x]); n += 1 }; if y - r - 1 >= 0 { acc -= Double(tmp[(y - r - 1) * w + x]); n -= 1 }; if y >= 0 { out[y * w + x] = Int(acc / Double(n)) } } }
        return out
    }
    /// Порог Оцу — автоматический подбор
    static func otsu(_ gray: [Int]) -> Int {
        var hist = [Int](repeating: 0, count: 256); for v in gray { hist[v] += 1 }
        let total = Double(gray.count); var sum = 0.0; for i in 0..<256 { sum += Double(i) * Double(hist[i]) }
        var sumB = 0.0, wB = 0.0, best = 0.0; var th = 128
        for t in 0..<256 { wB += Double(hist[t]); if wB == 0 { continue }; let wF = total - wB; if wF == 0 { break }; sumB += Double(t) * Double(hist[t])
            let mB = sumB / wB, mF = (sum - sumB) / wF; let v = wB * wF * (mB - mF) * (mB - mF); if v > best { best = v; th = t } }
        return th
    }
    private static func contours(_ mask: [Bool], _ w: Int, _ h: Int) -> [[P]] {
        let W = w + 1; var out: [Int: [Int]] = [:]; var keys: [Int] = []
        func inside(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < w && y < h && mask[y * w + x] }
        func add(_ a: Int, _ b: Int) { if out[a] == nil { out[a] = []; keys.append(a) }; out[a]!.append(b) }
        for y in 0..<h { for x in 0..<w {
            if !mask[y * w + x] { continue }
            if !inside(x, y - 1) { add(y * W + x, y * W + x + 1) }
            if !inside(x + 1, y) { add(y * W + x + 1, (y + 1) * W + x + 1) }
            if !inside(x, y + 1) { add((y + 1) * W + x + 1, (y + 1) * W + x) }
            if !inside(x - 1, y) { add((y + 1) * W + x, y * W + x) }
        } }
        var loops: [[P]] = []
        for start in keys {
            while let l = out[start], !l.isEmpty {
                var loop: [Int] = [start]; var prev = start; var cur = out[start]!.removeFirst(); var guardN = 0
                while cur != start && guardN < 4_000_000 {
                    guardN += 1
                    loop.append(cur); guard let nx = out[cur], !nx.isEmpty else { break }
                    var pick = 0
                    if nx.count > 1 { // седло: поворачиваем направо
                        let px = prev % W, py = prev / W, cx = cur % W, cy = cur / W; let dx = cx - px, dy = cy - py
                        pick = nx.firstIndex { let ex = $0 % W - cx, ey = $0 / W - cy; return ex == -dy && ey == dx } ?? 0
                    }
                    prev = cur; cur = out[cur]!.remove(at: pick)
                }
                if loop.count > 2 { loops.append(loop.map { P(Double($0 % W), Double($0 / W)) }) }
            }
        }
        return loops
    }
    private static func area(_ p: [P]) -> Double { var a = 0.0; for i in p.indices { let q1 = p[i], q2 = p[(i + 1) % p.count]; a += q1.x * q2.y - q2.x * q1.y }; return a / 2 }
    private static func dp(_ pts: [P], _ tol: Double) -> [P] {
        if pts.count < 3 { return pts }
        var keep = [Bool](repeating: false, count: pts.count); keep[0] = true; keep[pts.count - 1] = true
        var st: [(Int, Int)] = [(0, pts.count - 1)]
        while let (a, b) = st.popLast() {
            var md = 0.0, mi = -1
            let ax = pts[a].x, ay = pts[a].y, dx = pts[b].x - ax, dy = pts[b].y - ay; var L = hypot(dx, dy); if L == 0 { L = 1e-9 }
            if a + 1 < b { for i in (a + 1)..<b { let d = abs((pts[i].x - ax) * dy - (pts[i].y - ay) * dx) / L; if d > md { md = d; mi = i } } }
            if md > tol && mi > 0 { keep[mi] = true; st.append((a, mi)); st.append((mi, b)) }
        }
        return pts.enumerated().filter { keep[$0.offset] }.map { $0.element }
    }
    private static func simplifyClosed(_ p: [P], _ tol: Double) -> [P] {
        var far = 0, fd = 0.0
        for i in 1..<p.count { let d = pow(p[i].x - p[0].x, 2) + pow(p[i].y - p[0].y, 2); if d > fd { fd = d; far = i } }
        let a = dp(Array(p[0...far]), tol); let b = dp(Array(p[far...]) + [p[0]], tol)
        return Array(a.dropLast()) + Array(b.dropLast())
    }
    /// Сглаживание: Catmull-Rom → Безье, острые углы сохраняются
    private static func smoothSegs(_ p: [P], _ cornerDeg: Double) -> [Seg] {
        let n = p.count; var segs: [Seg] = []; let cosLim = cos((180 - cornerDeg) * .pi / 180)
        let isC: [Bool] = (0..<n).map { i in let a = p[(i - 1 + n) % n], b = p[i], c = p[(i + 1) % n]
            let ux = a.x - b.x, uy = a.y - b.y, vx = c.x - b.x, vy = c.y - b.y
            let den = hypot(ux, uy) * hypot(vx, vy); return (ux * vx + uy * vy) / (den == 0 ? 1 : den) > cosLim }
        for i in 0..<n {
            let p0 = p[(i - 1 + n) % n], p1 = p[i], p2 = p[(i + 1) % n], p3 = p[(i + 2) % n]
            if isC[i] && isC[(i + 1) % n] { segs.append(LineSeg(p2.x, p2.y)); continue }
            let t1x = isC[i] ? 0 : (p2.x - p0.x) / 6, t1y = isC[i] ? 0 : (p2.y - p0.y) / 6
            let t2x = isC[(i + 1) % n] ? 0 : (p3.x - p1.x) / 6, t2y = isC[(i + 1) % n] ? 0 : (p3.y - p1.y) / 6
            segs.append(BezSeg(p1.x + t1x, p1.y + t1y, p2.x - t2x, p2.y - t2y, p2.x, p2.y))
        }
        return segs
    }
    static func trace(_ gray: [Int], _ w: Int, _ h: Int, _ opt: TraceOpt = TraceOpt()) -> TraceResult {
        let g = boxBlur(gray, w, h, opt.blur)
        let th = opt.threshold < 0 ? otsu(g) : opt.threshold
        let mask = (0..<(w * h)).map { (g[$0] < th) != opt.invert }
        var res: [TraceContour] = []
        for loop in contours(mask, w, h) {
            if abs(area(loop)) < opt.minArea { continue }
            let s = simplifyClosed(loop, opt.tolerance); if s.count < 3 { continue }
            res.append(TraceContour(pts: s, segs: opt.smooth ? smoothSegs(s, opt.cornerDeg) : nil))
        }
        return TraceResult(contours: res, threshold: th)
    }
    /// Гомография по 4 парам точек
    static func homography(_ src: [P], _ dst: [P]) -> [Double] {
        var A = [[Double]](repeating: [Double](repeating: 0, count: 8), count: 8); var b = [Double](repeating: 0, count: 8)
        for i in 0..<4 { let x = src[i].x, y = src[i].y, u = dst[i].x, v = dst[i].y
            A[2 * i] = [x, y, 1, 0, 0, 0, -u * x, -u * y]; b[2 * i] = u
            A[2 * i + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y]; b[2 * i + 1] = v }
        for c in 0..<8 {
            var m = c; for r in (c + 1)..<8 where abs(A[r][c]) > abs(A[m][c]) { m = r }
            A.swapAt(c, m); b.swapAt(c, m)
            for r in 0..<8 where r != c { let f = A[r][c] / A[c][c]; for k in c..<8 { A[r][k] -= f * A[c][k] }; b[r] -= f * b[c] }
        }
        return (0..<9).map { $0 < 8 ? b[$0] / A[$0][$0] : 1 }
    }
    /// выпрямление: quad — 4 угла на исходном изображении (ЛВ, ПВ, ПН, ЛН) → прямоугольник outW×outH; argb — пиксели
    static func warpArgb(_ src: [UInt32], _ w: Int, _ h: Int, _ quad: [P], _ outW: Int, _ outH: Int) -> [UInt32] {
        let H = homography([P(0, 0), P(Double(outW), 0), P(Double(outW), Double(outH)), P(0, Double(outH))], quad)
        var out = [UInt32](repeating: 0, count: outW * outH)
        for y in 0..<outH { for x in 0..<outW {
            let fx = Double(x), fy = Double(y)
            let d = H[6] * fx + H[7] * fy + H[8]; let sx = (H[0] * fx + H[1] * fy + H[2]) / d, sy = (H[3] * fx + H[4] * fy + H[5]) / d
            out[y * outW + x] = src[clampI(kround(sy), 0, h - 1) * w + clampI(kround(sx), 0, w - 1)]
        } }
        return out
    }
    /// мостики трафарета: островки соединяются полосками (W мм, dir v/h/x)
    static func stencilBridges(_ paths: [VPath], _ W: Double, _ dir: String, _ layer: Int) -> [VPath] {
        let F = paths.map { Geom.flatten($0, 0.05) }
        let depth = F.enumerated().map { (i, f) in F.indices.filter { j in j != i && Geom.pointInPoly(f[0].x, f[0].y, F[j]) }.count }
        let islands = F.indices.filter { depth[$0] % 2 == 1 }; if islands.isEmpty { return paths }
        var bars: [[P]] = []
        for i in islands {
            let f = F[i]; let par = F.indices.first { j in j != i && depth[j] == depth[i] - 1 && Geom.pointInPoly(f[0].x, f[0].y, F[j]) }.map { F[$0] }
            let pb = Geom.bbox(Geom.makePath(par ?? f, true)), b = Geom.bbox(Geom.makePath(f, true))
            if dir != "h" { bars.append([P(b.cx - W / 2, pb.y1 - 1), P(b.cx + W / 2, pb.y1 - 1), P(b.cx + W / 2, pb.y2 + 1), P(b.cx - W / 2, pb.y2 + 1)]) }
            if dir != "v" { bars.append([P(pb.x1 - 1, b.cy - W / 2), P(pb.x2 + 1, b.cy - W / 2), P(pb.x2 + 1, b.cy + W / 2), P(pb.x1 - 1, b.cy + W / 2)]) }
        }
        let sol = Clip.boolean(.difference, F.map { Geom.toC(Array($0.dropLast())) }, bars.map { Geom.toC($0) }, .evenOdd, .nonZero)
        return Geom.fromClip(sol, layer)
    }
}
