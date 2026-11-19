/* Иконка инструмента из IconData (24×24, собственный рисунок). Порт Icons.kt — контуры SVG разбираются тем же Io.pathD. */
import SwiftUI

enum IconCache {
    static var paths: [String: [(Path, IconPart)]] = [:]
    static func get(_ name: String) -> [(Path, IconPart)] {
        if let c = paths[name] { return c }
        let parts = IconData.all[name] ?? IconData.all["new"]!
        let r = parts.map { part -> (Path, IconPart) in
            var pa = Path()
            for c in Io.pathD(part.d) {
                pa.move(to: CGPoint(x: c.x0, y: c.y0))
                for s in c.segs { if let b = s as? BezSeg { pa.addCurve(to: CGPoint(x: b.x, y: b.y), control1: CGPoint(x: b.x1, y: b.y1), control2: CGPoint(x: b.x2, y: b.y2)) } else { pa.addLine(to: CGPoint(x: s.x, y: s.y)) } }
                if c.closed { pa.closeSubpath() }
            }
            return (pa, part)
        }
        paths[name] = r; return r
    }
}

struct ToolIcon: View {
    let name: String; var size: CGFloat = 26; var disabled = false
    init(_ name: String, _ size: CGFloat = 26, _ disabled: Bool = false) { self.name = name; self.size = size; self.disabled = disabled }
    var body: some View {
        Canvas { ctx, sz in
            let k = sz.width / 24; ctx.scaleBy(x: k, y: k)
            let a = disabled ? 0.35 : 1.0
            for (path, p) in IconCache.get(name) {
                if let f = p.fill { ctx.fill(path, with: .color(Color(argb: f).opacity(a))) }
                let st: UInt32? = p.stroke ?? (p.fill == nil ? 0xFF333333 : nil)
                if let st = st { ctx.stroke(path, with: .color(Color(argb: st).opacity(a)), style: StrokeStyle(lineWidth: p.sw, lineCap: .round, lineJoin: .round)) }
            }
        }.frame(width: size, height: size)
    }
}
