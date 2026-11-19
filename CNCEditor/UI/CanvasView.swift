/* Лист: рисование модели и обработка касаний (порт CanvasView.kt). UIKit — чтобы касание, тяга, долгое нажатие и два пальца работали как на Android. */
import SwiftUI
import UIKit

private let SEL: UInt32 = 0xFFE0006A

struct CanvasHost: UIViewRepresentable {
    @ObservedObject var s: AppState
    func makeUIView(context: Context) -> CanvasUIView { let v = CanvasUIView(); v.s = s; s.canvas = v; return v }
    func updateUIView(_ v: CanvasUIView, context: Context) { v.s = s; s.canvas = v; v.setNeedsDisplay(); v.syncSim() }
}

final class CanvasUIView: UIView {
    weak var s: AppState?
    private var cache: [String: [P]] = [:]; private var cacheKey = ""
    // касания
    private var touchesOn: [UITouch] = []
    private var downPt = CGPoint.zero, lastPt = CGPoint.zero, p0 = P(0, 0), tol = 1.0
    private var tool: CanvasTool? = nil
    private var multiTouch = false, moved = false, longDone = false, hadPick = false
    private var longTimer: Timer? = nil
    private var pinchD: CGFloat = 0, pinchC = CGPoint.zero
    private var link: CADisplayLink? = nil

    override init(frame: CGRect) { super.init(frame: frame); isMultipleTouchEnabled = true; backgroundColor = UIColor(argb: 0xFF9AA3AD); contentMode = .redraw }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() { super.layoutSubviews(); if bounds.width > 0 && bounds.height > 0 { s?.resized(bounds.width, bounds.height) } }

    /// имитация: шаги анимации
    func syncSim() {
        let sim = s?.pageTool as? PagesB.SimTool
        if let sim = sim, sim.play { if link == nil { let l = CADisplayLink(target: self, selector: #selector(frameTick)); l.add(to: .main, forMode: .common); link = l } }
        else { link?.invalidate(); link = nil }
    }
    @objc private func frameTick() { guard let s = s, let sim = s.pageTool as? PagesB.SimTool else { link?.invalidate(); link = nil; return }; if sim.tick() { s.bump() }; if !sim.play { link?.invalidate(); link = nil; s.bump() } }

    // ---------- касания ----------
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let s = s else { return }
        for t in touches where !touchesOn.contains(t) { touchesOn.append(t) }
        if touchesOn.count == 1 {
            let pt = touchesOn[0].location(in: self); downPt = pt; lastPt = pt; p0 = s.toMm(pt); tol = s.tolMm()
            multiTouch = false; moved = false; longDone = false; hadPick = s.pick != nil; tool = nil; s.longMenu = nil
            if !hadPick { let at = s.activeTool(); if at.down(p0.x, p0.y, tol) { tool = at } else if s.pageTool != nil && s.select.down(p0.x, p0.y, tol) { tool = s.select }; s.bump() }
            longTimer?.invalidate(); longTimer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: false) { [weak self] _ in self?.longPress() }
        } else if touchesOn.count >= 2 {
            if !multiTouch { multiTouch = true; tool?.up(); tool = nil; longTimer?.invalidate() }
            let (c, d) = pinch(); pinchC = c; pinchD = d
        }
    }
    private func pinch() -> (CGPoint, CGFloat) {
        let a = touchesOn[0].location(in: self), b = touchesOn[1].location(in: self)
        return (CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2), hypot(a.x - b.x, a.y - b.y))
    }
    private func longPress() {
        guard let s = s, !moved, !multiTouch, touchesOn.count == 1 else { return }
        longDone = true
        if !hadPick {
            tool?.up(); tool = nil
            if s.mode == "node" && s.pageTool == nil { _ = s.node.down(p0.x, p0.y, tol); s.longMenu = (downPt, "node"); s.bump() }
            else if s.pageTool == nil && s.select.longPress(p0.x, p0.y, tol) { s.toast("Выбор нескольких: касайтесь векторов"); s.bump() }
            else if !s.doc.sel.isEmpty { s.longMenu = (downPt, "vec"); s.bump() }
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let s = s else { return }
        if multiTouch {
            if touchesOn.count >= 2 { let (c, d) = pinch(); if pinchD > 0 && d > 0 { s.zoomAt(d / pinchD, c) }; s.pan(c.x - pinchC.x, c.y - pinchC.y); pinchC = c; pinchD = d; s.bump() }
            return
        }
        guard let t = touchesOn.first else { return }
        let pt = t.location(in: self), prev = t.previousLocation(in: self); lastPt = pt
        if !moved && hypot(pt.x - downPt.x, pt.y - downPt.y) > 8 { moved = true; longTimer?.invalidate() }
        if moved && !longDone && !hadPick { let q = s.toMm(pt); if let tl = tool { if tl.move(q.x, q.y) { s.bump() } } else { s.pan(pt.x - prev.x, pt.y - prev.y); s.bump() } }
        else if moved && hadPick { s.pan(pt.x - prev.x, pt.y - prev.y); s.bump() }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { finish(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { finish(touches) }
    private func finish(_ touches: Set<UITouch>) {
        touchesOn.removeAll { touches.contains($0) }
        if multiTouch && touchesOn.count == 1 { pinchD = 0; return }
        guard touchesOn.isEmpty, let s = s else { return }
        longTimer?.invalidate()
        if !multiTouch && !longDone {
            if hadPick { if !moved, let pk = s.pick { s.pick = nil; pk.1(s.toMm(lastPt)); s.bump() } }
            else { tool?.up(); s.bump() }
        }
        tool = nil; multiTouch = false
    }

    // ---------- рисование ----------
    override func draw(_ rect: CGRect) {
        guard let s = s, let g = UIGraphicsGetCurrentContext() else { return }
        let d = s.doc; let k = s.k
        let key = "\(d.version)|\(Int(log10(k) * 4))"
        if key != cacheKey { cache.removeAll(); cacheKey = key }
        func pts(_ p: VPath) -> [P] { if let c = cache[p.id] { return c }; let f = Geom.flatten(p, max(0.01, 0.25 / k)); cache[p.id] = f; return f }
        func path(_ f: [P], _ closed: Bool) -> CGPath { let pa = CGMutablePath(); for (i, q) in f.enumerated() { let o = s.toScr(q.x, q.y); if i == 0 { pa.move(to: o) } else { pa.addLine(to: o) } }; if closed { pa.closeSubpath() }; return pa }
        func stroke(_ pa: CGPath, _ c: UInt32, _ w: CGFloat, dash: Bool = false, round: Bool = false) {
            g.saveGState(); g.addPath(pa); g.setStrokeColor(UIColor(argb: c).cgColor); g.setLineWidth(w); g.setLineCap(round ? .round : .butt); g.setLineJoin(.round)
            if dash { g.setLineDash(phase: 0, lengths: [5, 3]) }; g.strokePath(); g.restoreGState() }
        func fillPath(_ pa: CGPath, _ c: UInt32) { g.saveGState(); g.addPath(pa); g.setFillColor(UIColor(argb: c).cgColor); g.fillPath(); g.restoreGState() }
        func line(_ a: CGPoint, _ b: CGPoint, _ c: UInt32, _ w: CGFloat, round: Bool = false) { let pa = CGMutablePath(); pa.move(to: a); pa.addLine(to: b); stroke(pa, c, w, round: round) }
        func rectF(_ r: CGRect, _ c: UInt32) { g.setFillColor(UIColor(argb: c).cgColor); g.fill(r) }
        func rectS(_ r: CGRect, _ c: UInt32, _ w: CGFloat, dash: Bool = false) { stroke(CGPath(rect: r, transform: nil), c, w, dash: dash) }
        func circle(_ o: CGPoint, _ r: CGFloat, fill: UInt32?, stroke st: UInt32?, _ w: CGFloat = 1) { let e = CGPath(ellipseIn: CGRect(x: o.x - r, y: o.y - r, width: 2 * r, height: 2 * r), transform: nil); if let f = fill { fillPath(e, f) }; if let c = st { stroke(e, c, w) } }

        // лист модели
        let m = d.model; let a = s.toScr(m.x0, m.y0 + m.h), b = s.toScr(m.x0 + m.w, m.y0)
        let sheet = CGRect(x: a.x, y: a.y, width: b.x - a.x, height: b.y - a.y)
        if d.hasModel { rectF(sheet, 0xFFFFFFFF) }
        // подложка
        if let im = d.image, im.visible, let ui = s.underlayImage() { let ia = s.toScr(im.x, im.y + im.h), ib = s.toScr(im.x + im.w, im.y)
            ui.draw(in: CGRect(x: ia.x, y: ia.y, width: max(1, ib.x - ia.x), height: max(1, ib.y - ia.y)), blendMode: .normal, alpha: CGFloat(im.opacity)) }
        // сетка
        if s.showGrid && d.hasModel {
            var st = pow(10, floor(log10(16.0 / k))); if st * k < 5 { st *= 5 }
            let major = st * 10
            var x = floor(m.x0 / st) * st
            while x <= m.x0 + m.w + 1e-9 { if x >= m.x0 { let o = s.toScr(x, 0); let mj = abs(x / major - (x / major).rounded()) < 1e-6; line(CGPoint(x: o.x, y: a.y), CGPoint(x: o.x, y: b.y), mj ? 0xFFC8D0DA : 0xFFEDF0F4, 0.5) }; x += st }
            var y = floor(m.y0 / st) * st
            while y <= m.y0 + m.h + 1e-9 { if y >= m.y0 { let o = s.toScr(0, y); let mj = abs(y / major - (y / major).rounded()) < 1e-6; line(CGPoint(x: a.x, y: o.y), CGPoint(x: b.x, y: o.y), mj ? 0xFFC8D0DA : 0xFFEDF0F4, 0.5) }; y += st }
        }
        if d.hasModel {
            rectS(sheet, 0xFF555555, 0.5)
            let z = s.toScr(0, 0); line(z, CGPoint(x: z.x + 14, y: z.y), 0xFFE0302A, 1.2); line(z, CGPoint(x: z.x, y: z.y - 14), 0xFF1F9A3A, 1.2)
        }
        // траектории
        if s.showTp { for tp in d.toolpaths where tp.show {
            var prev: Move? = nil; let cut = CGMutablePath(), rap = CGMutablePath(); var cutOpen = false
            for mv in tp.result.moves { let o = s.toScr(mv.x, mv.y)
                if let pv = prev { let po = s.toScr(pv.x, pv.y); if mv.r { rap.move(to: po); rap.addLine(to: o) } else { if !cutOpen { cut.move(to: po); cutOpen = true }; cut.addLine(to: o) } }
                if mv.r { cutOpen = false }; prev = mv }
            stroke(rap, 0x66E0302A, 0.5, dash: true); stroke(cut, tp.color, tp === s.selTp ? 1.6 : 0.9)
            for q in tp.result.tabMarks { let o = s.toScr(q.x, q.y); rectF(CGRect(x: o.x - 2.5, y: o.y - 2.5, width: 5, height: 5), 0xFFFFB000) }
        } }
        // векторы
        for p in d.paths { if !d.visible(p) { continue }; let f = pts(p); if f.count < 2 { continue }; let pa = path(f, p.closed)
            if d.isSel(p.id) { if p.closed { fillPath(pa, 0x22E0006A) }; stroke(pa, 0x55E0006A, 5, round: true); stroke(pa, SEL, 1.4) }
            else { stroke(pa, p.locked ? 0xFF9A9A9A : (d.layers.getOrNull(p.layer)?.color ?? 0xFF000000), 0.8) } }
        // выбор: рамка, ручки, номера
        let sl = d.selected()
        if !sl.isEmpty && s.pageTool == nil {
            let bb = Geom.bbox(sl); let ba = s.toScr(bb.x1, bb.y2), bz = s.toScr(bb.x2, bb.y1)
            rectS(CGRect(x: ba.x, y: ba.y, width: bz.x - ba.x, height: bz.y - ba.y), 0x88E0006A, 0.6, dash: true)
            if s.mode == "select" && !s.multi && !s.select.stickyMulti { for (i, h) in s.select.handles(s.tolMm()).enumerated() { let o = s.toScr(h.x, h.y)
                if i == 4 { line(CGPoint(x: o.x, y: ba.y), o, 0xFFE0006A, 0.6); circle(o, 6, fill: 0xFFFFFFFF, stroke: 0xFFE0006A, 1.2) }
                else { let r = CGRect(x: o.x - 5.5, y: o.y - 5.5, width: 11, height: 11); rectF(r, 0xFFFFFFFF); rectS(r, 0xFFE0006A, 1.2) } } }
            let units = d.selectedUnits()
            if units.count > 1 { for (i, u) in units.enumerated() { let ub = Geom.bbox(u); let o = s.toScr(ub.x1, ub.y2); let c = CGPoint(x: o.x - 3, y: o.y - 3)
                circle(c, 9, fill: 0xFFE0006A, stroke: nil)
                let str = NSAttributedString(string: "\(i + 1)", attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.white]); let sz = str.size()
                str.draw(at: CGPoint(x: c.x - sz.width / 2, y: c.y - sz.height / 2)) } }
        }
        // подсказки инструмента
        for o in (s.pageTool ?? (s.mode == "node" ? s.node : s.select)).overlay() { drawOv(o, s, g) }
    }

    private func drawOv(_ o: Ov, _ s: AppState, _ g: CGContext) {
        func stroke(_ pa: CGPath, _ c: UInt32, _ w: CGFloat, dash: Bool = false, round: Bool = false) {
            g.saveGState(); g.addPath(pa); g.setStrokeColor(UIColor(argb: c).cgColor); g.setLineWidth(w); g.setLineCap(round ? .round : .butt); g.setLineJoin(.round)
            if dash { g.setLineDash(phase: 0, lengths: [5, 3]) }; g.strokePath(); g.restoreGState() }
        switch o {
        case let .poly(pts, color, width, dash, closed):
            if pts.count < 2 { return }; let pa = CGMutablePath(); for (i, q) in pts.enumerated() { let p = s.toScr(q.x, q.y); if i == 0 { pa.move(to: p) } else { pa.addLine(to: p) } }; if closed { pa.closeSubpath() }
            stroke(pa, color, CGFloat(width) * 0.6, dash: dash)
        case let .paths(paths, color, dash):
            for p in paths { let f = Geom.flatten(p, max(0.01, 0.25 / s.k)); if f.count < 2 { continue }; let pa = CGMutablePath(); for (i, q) in f.enumerated() { let pp = s.toScr(q.x, q.y); if i == 0 { pa.move(to: pp) } else { pa.addLine(to: pp) } }; if p.closed { pa.closeSubpath() }
                stroke(pa, color, 0.9, dash: dash) }
        case let .mark(p, kind, color):
            let c = s.toScr(p.x, p.y)
            switch kind {
            case "box": let r = CGRect(x: c.x - 4.5, y: c.y - 4.5, width: 9, height: 9); g.setFillColor(UIColor.white.cgColor); g.fill(r); stroke(CGPath(rect: r, transform: nil), color, 1.2)
            case "dot": g.setFillColor(UIColor(argb: color).cgColor); g.fillEllipse(in: CGRect(x: c.x - 4, y: c.y - 4, width: 8, height: 8))
            case "handle": let r = CGRect(x: c.x - 6, y: c.y - 6, width: 12, height: 12); g.setFillColor(UIColor.white.cgColor); g.fillEllipse(in: r); stroke(CGPath(ellipseIn: r, transform: nil), color, 1.5)
            default: let pa = CGMutablePath(); pa.move(to: CGPoint(x: c.x - 5.5, y: c.y - 5.5)); pa.addLine(to: CGPoint(x: c.x + 5.5, y: c.y + 5.5)); pa.move(to: CGPoint(x: c.x - 5.5, y: c.y + 5.5)); pa.addLine(to: CGPoint(x: c.x + 5.5, y: c.y - 5.5)); stroke(pa, color, 1.2)
            }
        case let .thick(a, b, color, wMm):
            let pa = CGMutablePath(); pa.move(to: s.toScr(a.x, a.y)); pa.addLine(to: s.toScr(b.x, b.y)); stroke(pa, color, max(0.5, CGFloat(wMm * s.k)), round: true)
        case let .fill(x1, y1, x2, y2, color):
            let a = s.toScr(x1, y2), b = s.toScr(x2, y1); g.setFillColor(UIColor(argb: color).cgColor); g.fill(CGRect(x: a.x, y: a.y, width: b.x - a.x, height: b.y - a.y))
        }
    }
}
