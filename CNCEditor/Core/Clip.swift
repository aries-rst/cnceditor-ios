import Foundation

/// Обёртка над C++ Clipper 6.4.2 (тот же алгоритм, что в Android-порте Clipper.kt).
struct IntPoint: Equatable { var X: Int64; var Y: Int64; init(_ x: Int64, _ y: Int64) { X = x; Y = y } }
typealias CPath = [IntPoint]
typealias CPaths = [CPath]

enum ClipType: Int32 { case intersection = 0, union, difference, xor }
enum PolyFillType: Int32 { case evenOdd = 0, nonZero, positive, negative }
enum JoinType: Int64 { case square = 0, round, miter }
enum EndType: Int64 { case closedPolygon = 0, closedLine, openButt, openSquare, openRound }

enum Clip {
    static func enc(_ ps: CPaths, into a: inout [Int64]) {
        a.append(Int64(ps.count))
        for p in ps { a.append(Int64(p.count)); for q in p { a.append(q.X); a.append(q.Y) } }
    }
    private static func dec(_ r: UnsafeMutablePointer<Int64>?, _ len: Int64) -> CPaths {
        guard let r = r, len > 0 else { return [] }
        defer { cb_free(r) }
        var i = 0; let n = Int(r[i]); i += 1; var out: CPaths = []; out.reserveCapacity(n)
        for _ in 0..<n {
            let m = Int(r[i]); i += 1; var p: CPath = []; p.reserveCapacity(m)
            for _ in 0..<m { p.append(IntPoint(r[i], r[i + 1])); i += 2 }
            out.append(p)
        }
        return out
    }
    static func boolean(_ ct: ClipType, _ subj: CPaths, _ clip: CPaths, _ sf: PolyFillType, _ cf: PolyFillType, strict: Bool = false) -> CPaths {
        var s: [Int64] = []; enc(subj, into: &s); var c: [Int64] = []; enc(clip, into: &c)
        var len: Int64 = 0
        let r = s.withUnsafeBufferPointer { sp in c.withUnsafeBufferPointer { cp in cb_boolean(ct.rawValue, sf.rawValue, cf.rawValue, strict ? 1 : 0, sp.baseAddress, cp.baseAddress, &len) } }
        return dec(r, len)
    }
    static func offset(_ groups: [(CPaths, JoinType, EndType)], _ delta: Double, miter: Double = 2.0, arcTol: Double = 0.25) -> CPaths {
        var g: [Int64] = [Int64(groups.count)]
        for (ps, jt, et) in groups { g.append(jt.rawValue); g.append(et.rawValue); enc(ps, into: &g) }
        var len: Int64 = 0
        let r = g.withUnsafeBufferPointer { cb_offset(miter, arcTol, $0.baseAddress, delta, &len) }
        return dec(r, len)
    }
    static func simplifyPolygons(_ polys: CPaths, _ fill: PolyFillType = .evenOdd) -> CPaths { boolean(.union, polys, [], fill, fill, strict: true) }
    static func simplifyPolygon(_ poly: CPath, _ fill: PolyFillType = .evenOdd) -> CPaths { simplifyPolygons([poly], fill) }
    static func area(_ poly: CPath) -> Double {
        let cnt = poly.count; if cnt < 3 { return 0 }
        var a = 0.0; var j = cnt - 1
        for i in 0..<cnt { a += Double(poly[j].X + poly[i].X) * Double(poly[j].Y - poly[i].Y); j = i }
        return -a * 0.5
    }
}
