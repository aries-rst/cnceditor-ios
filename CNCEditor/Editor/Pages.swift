/* ЧПУ Редактор 2D — страницы инструментов (по образцу страниц ArtCAM). Порт Pages.kt */
import Foundation

func pn(_ k: String, _ l: String, _ d: Double, _ u: String = "мм", _ int: Bool = false) -> F { .num(key: k, label: l, def: d, unit: u, int: int) }
func pg(_ t: String, _ f: F...) -> F { .group(t, f) }
func pbtns(_ b: Btn...) -> F { .buttons(b) }
func pb(_ l: String, _ pri: Bool = false, _ a: @escaping (PageCtx) -> Void) -> Btn { Btn(l, primary: pri, a) }
func pnote(_ t: @escaping (PageCtx) -> String) -> F { .note(t) }
func pchk(_ k: String, _ l: String, _ d: Bool = false) -> F { .chk(key: k, label: l, def: d) }
func pradio(_ k: String, _ o: [(String, String)], _ d: String) -> F { .radio(key: k, options: o, def: d) }
func psel(_ k: String, _ l: String, _ o: [(String, String)], _ d: String) -> F { .select(key: k, label: l, options: o, def: d) }
func pif(_ c: @escaping (PageCtx) -> Bool, _ f: F...) -> F { .iff(c, f) }
func ptxt(_ k: String, _ l: String, _ d: String = "", _ ml: Bool = false) -> F { .txt(key: k, label: l, def: d, multiline: ml) }
private let f2 = PageCtx.f2

/// Инструмент на листе из замыканий (как object : CanvasTool в Kotlin)
final class FnTool: CanvasTool {
    var onDown: (Double, Double, Double) -> Bool
    var onMove: (Double, Double) -> Bool = { _, _ in false }
    var onUp: () -> Void = {}
    var onOverlay: () -> [Ov] = { [] }
    var hintFn: () -> String = { "" }
    init(_ d: @escaping (Double, Double, Double) -> Bool) { onDown = d }
    func down(_ x: Double, _ y: Double, _ tol: Double) -> Bool { onDown(x, y, tol) }
    func move(_ x: Double, _ y: Double) -> Bool { onMove(x, y) }
    func up() { onUp() }
    func overlay() -> [Ov] { onOverlay() }
    var hint: String { hintFn() }
}

/// изменяемый список, хранимый в state страницы
final class PtList { var pts: [P] = [] }
final class StrList { var items: [String] = []; init(_ i: [String]) { items = i } }

enum Pages {
    static var all: [String: PageSpec] = [:]
    static var order: [String] = []
    private static func reg(_ p: PageSpec) { if all[p.id] == nil { order.append(p.id) }; all[p.id] = p }
    private static var inited = false

    // ================= фигуры =================
    static func buildShape(_ type: String, _ c: PageCtx) -> VPath? {
        switch type {
        case "rect": let w = c.num("w"); let h = c.str("rsq") == "sq" ? w : c.num("h"); return (w <= 0 || h <= 0) ? nil : Geom.Shapes.rect(c.num("cx"), c.num("cy"), w, h, c.num("r"), c.num("ang"), c.chk("rinv"))
        case "circle": let r = c.str("ctype") == "d" ? c.num("cr") / 2 : c.num("cr"); if r <= 0 { return nil }; let p = Geom.Shapes.circle(c.num("cx"), c.num("cy"), r); if !c.chk("carc") { arcsToBez(p) }; return p
        case "ellipse": return (c.num("w") <= 0 || c.num("h") <= 0) ? nil : Geom.Shapes.ellipse(c.num("cx"), c.num("cy"), c.num("w"), c.num("h"), c.num("ang"))
        case "polygon": return c.num("r") <= 0 ? nil : Geom.Shapes.polygon(c.num("cx"), c.num("cy"), c.int("n"), c.num("r"), c.num("ang"))
        case "star": return c.num("r1") <= 0 ? nil : Geom.Shapes.star(c.num("cx"), c.num("cy"), c.int("n"), c.num("r1"), c.num("r2"), c.num("ang"))
        default: return nil
        }
    }
    private static func arcsToBez(_ p: VPath) { var a = P(p.x0, p.y0); var out: [Seg] = []; for s in p.segs { if let arc = s as? ArcSeg { out.append(contentsOf: Geom.arcToBeziers(a, arc) as [Seg]) } else { out.append(s) }; a = P(s.x, s.y) }; p.segs = out }
    private static func sgn(_ v: Double) -> Double { v > 0 ? 1 : (v < 0 ? -1 : 0) }
    /// заполнение полей по перетаскиванию пальцем от a до b
    static func dragToFields(_ type: String, _ a: P, _ b: P, _ c: PageCtx) {
        switch type {
        case "rect": var w = abs(b.x - a.x), h = abs(b.y - a.y); if c.str("rsq") == "sq" { let m = max(w, h); w = m; h = m }
            c.set("cx", a.x + sgn(b.x - a.x) * w / 2); c.set("cy", a.y + sgn(b.y - a.y) * h / 2); c.set("w", w); c.set("h", h)
        case "ellipse": c.set("cx", (a.x + b.x) / 2); c.set("cy", (a.y + b.y) / 2); c.set("w", abs(b.x - a.x)); c.set("h", abs(b.y - a.y))
        case "circle": c.set("cx", a.x); c.set("cy", a.y); let r = hypot(b.x - a.x, b.y - a.y); c.set("cr", c.str("ctype") == "d" ? 2 * r : r)
        case "polygon": c.set("cx", a.x); c.set("cy", a.y); c.set("r", hypot(b.x - a.x, b.y - a.y))
        case "star": c.set("cx", a.x); c.set("cy", a.y); let r = hypot(b.x - a.x, b.y - a.y); let k = c.num("r1") > 0 ? c.num("r2") / c.num("r1") : 0.4; c.set("r1", r); c.set("r2", r * k)
        default: break
        }
    }
    /// Создание фигуры перетаскиванием; после отпускания фигура остаётся «в работе» — поля меняют её
    final class ShapeTool: CanvasTool {
        let type: String; let c: PageCtx; var a: P? = nil; var preview: VPath? = nil
        init(_ type: String, _ c: PageCtx) { self.type = type; self.c = c }
        func down(_ x: Double, _ y: Double, _ tol: Double) -> Bool { a = P(x, y); return true }
        func move(_ x: Double, _ y: Double) -> Bool { guard let s = a else { return false }; dragToFields(type, s, P(x, y), c); preview = buildShape(type, c); c.bump(); return true }
        func up() { guard a != nil else { return }; a = nil; let p = preview; preview = nil; if let p = p { c.doc.addOnActive([p]); c.state["cur"] = p.id }; c.bump() }
        func overlay() -> [Ov] { preview.map { [Ov.paths(paths: [$0], color: 0xFF2A62B8)] } ?? [] }
        var hint: String { "Тяните по листу, чтобы нарисовать, или введите числа" }
    }
    /// изменение полей — меняется нарисованная фигура (пока не нажато «Готово»)
    static func liveUpdate(_ type: String, _ c: PageCtx) {
        guard let id = c.state["cur"] as? String, let p = c.doc.byId(id), let np = buildShape(type, c) else { return }
        p.x0 = np.x0; p.y0 = np.y0; p.segs = np.segs; p.shape = np.shape; c.doc.changed()
    }
    private static func shapePage(_ id: String, _ title: String, _ help: String, _ fs: @escaping (PageCtx) -> [F]) {
        reg(PageSpec(id, title, id, help: help, fields: { c in
            let edit = c.arg as? VPath
            let tail: F = edit != nil
                ? pbtns(pb("Применить", true) { ctx in guard let np = buildShape(id, ctx), let e = edit else { return }; ctx.doc.push(); e.x0 = np.x0; e.y0 = np.y0; e.segs = np.segs; e.shape = np.shape; ctx.doc.changed() })
                : pbtns(pb("Создать / Готово", true) { ctx in if ctx.doc.byId(ctx.state["cur"] as? String ?? "") != nil { ctx.state["cur"] = nil; ctx.doc.clearSel() } else if let p = buildShape(id, ctx) { ctx.doc.addOnActive([p]) }; ctx.bump() },
                        pb("Центр мышью") { ctx in ctx.ui.pickPoint("Укажите центр") { q in ctx.set("cx", q.x); ctx.set("cy", q.y); ctx.bump() } })
            return fs(c) + [pnote { $0.doc.byId($0.state["cur"] as? String ?? "") != nil ? "Нарисованная фигура выбрана — изменение полей меняет её. «Готово» — закрепить." : "" }, tail]
        }, onOpen: { c in
            let e = c.arg as? VPath
            if let sh = e?.shape { for (k, v) in sh.v { let key = (id == "circle" && k == "r") ? "cr" : (k == "inv" ? "rinv" : k); if k == "inv" { c.set(key, v != 0) } else { c.set(key, v) } } }
            if e == nil { c.ui.setTool(ShapeTool(id, c)) }
        }))
    }

    static func initAll() {
        if inited { return }; inited = true
        func cx(_ c: PageCtx) -> Double { c.doc.model.x0 + c.doc.model.w / 2 }
        func cy(_ c: PageCtx) -> Double { c.doc.model.y0 + c.doc.model.h / 2 }
        shapePage("rect", "Прямоугольник", "Тяните по листу или введите размеры.") { c in [
            pradio("rsq", [("rect", "Прямоугольник"), ("sq", "Квадрат")], "rect"),
            pn("w", "Ширина", 200), pif({ $0.str("rsq") != "sq" }, pn("h", "Высота", 100)),
            pn("r", "Радиус углов", 0), pchk("rinv", "Обратные углы"),
            pg("Центр", pn("cx", "X", cx(c)), pn("cy", "Y", cy(c))), pn("ang", "Угол", 0, "°")] }
        shapePage("circle", "Окружность", "Тяните от центра или введите размер.") { c in [
            pg("Центр", pn("cx", "X", cx(c)), pn("cy", "Y", cy(c))),
            pradio("ctype", [("r", "Радиус"), ("d", "Диаметр")], "d"), pn("cr", "Размер", 100), pchk("carc", "Создать дугами", true)] }
        shapePage("ellipse", "Эллипс", "Тяните рамку или введите размеры.") { c in [
            pg("Центр", pn("cx", "X", cx(c)), pn("cy", "Y", cy(c))), pn("h", "Высота эллипса", 100), pn("w", "Ширина эллипса", 200), pn("ang", "Угол", 0, "°")] }
        shapePage("polygon", "Многоугольник", "Тяните от центра.") { c in [
            pn("n", "Число сторон", 6, "", true), pn("ang", "Угол", 0, "°"), pg("Центр", pn("cx", "X", cx(c)), pn("cy", "Y", cy(c))), pn("r", "Радиус", 50)] }
        shapePage("star", "Звезда", "Тяните от центра.") { c in [
            pn("n", "Число лучей", 5, "", true), pn("ang", "Угол", 0, "°"), pg("Центр", pn("cx", "X", cx(c)), pn("cy", "Y", cy(c))),
            pn("r1", "Радиус вершин", 50), pn("r2", "Радиус впадин", 20)] }

        // ---------- полилиния ----------
        reg(PageSpec("polyline", "Полилиния", "polyline", help: "Касайтесь листа — точки полилинии. Или вводите следующую точку числами.", fields: { c in [
            pg("Следующая точка", pn("px", "X", 0), pn("py", "Y", 0), pbtns(pb("Добавить XY") { polyAdd($0, P($0.num("px"), $0.num("py"))) }),
                pn("pa", "Угол", 0, "°"), pn("pl", "Длина", 100), pbtns(pb("Добавить угол+длина") { let l = polyPts($0).pts.last ?? P(0, 0); let a = $0.num("pa") * .pi / 180; polyAdd($0, P(l.x + $0.num("pl") * cos(a), l.y + $0.num("pl") * sin(a))) }),
                pn("pdx", "dX", 50), pn("pdy", "dY", 0), pbtns(pb("Добавить dX, dY") { let l = polyPts($0).pts.last ?? P(0, 0); polyAdd($0, P(l.x + $0.num("pdx"), l.y + $0.num("pdy"))) })),
            pnote { let p = polyPts($0).pts; return p.isEmpty ? "Точек нет" : "Точек: \(p.count); последняя X \(f2(p.last!.x)) Y \(f2(p.last!.y))" },
            pchk("psm", "Плавная полилиния"),
            pbtns(pb("Закончить", true) { finishPoly($0, false) }, pb("Замкнуть") { finishPoly($0, true) }, pb("Отменить точку") { _ = polyPts($0).pts.popLast(); $0.bump() })]
        }, onOpen: { c in
            c.state["poly"] = PtList()
            var cur: P? = nil
            let t = FnTool { x, y, tol in let pl = polyPts(c); if pl.pts.count > 2 && hypot(x - pl.pts[0].x, y - pl.pts[0].y) < tol { finishPoly(c, true); return true }; pl.pts.append(P(x, y)); c.bump(); return true }
            t.onMove = { x, y in cur = P(x, y); return false }
            t.onOverlay = { let pts = polyPts(c).pts; if pts.isEmpty { return [] }; return [Ov.poly(pts: pts + (cur.map { [$0] } ?? []), color: 0xFF2A62B8, width: 1.5, dash: true)] + pts.map { Ov.mark(p: $0, kind: "dot", color: 0xFF2A62B8) } }
            t.hintFn = { "Касайтесь листа — точки. Касание первой точки замыкает." }
            c.ui.setTool(t)
        }))

        // ---------- дуга ----------
        reg(PageSpec("arc", "Дуга", "arc", help: "Касайтесь точек на листе по выбранному типу или вводите числа.", fields: { _ in [
            pradio("atype", [("cse", "Центр — начало — конец"), ("sep", "Начало — конец — точка на дуге"), ("ser", "Начало — конец — радиус")], "sep"),
            pif({ $0.str("atype") != "sep" }, pchk("acw", "По часовой стрелке")), pif({ $0.str("atype") == "ser" }, pn("arad", "Радиус", 50)),
            pg("Точки", pn("a1x", "Начало X", 0), pn("a1y", "Начало Y", 0), pn("a3x", "Конец X", 100), pn("a3y", "Конец Y", 0),
                pif({ $0.str("atype") == "sep" }, pn("a2x", "Точка на дуге X", 50), pn("a2y", "Точка на дуге Y", 30)),
                pif({ $0.str("atype") == "cse" }, pn("acx", "Центр X", 50), pn("acy", "Центр Y", 0))),
            pnote { $0.info["arc"] ?? "" }, pbtns(pb("Создать", true) { ctx in if let p = arcFromFields(ctx) { ctx.doc.addOnActive([p]); arcInfo(ctx, p) } })]
        }, onOpen: { c in
            let pl = PtList(); c.state["apts"] = pl; var cur: P? = nil
            func need() -> Int { c.str("atype") == "ser" ? 2 : 3 }
            let t = FnTool { x, y, _ in
                pl.pts.append(P(x, y)); let ty = c.str("atype")
                let ord = ty == "cse" ? [("acx", "acy"), ("a1x", "a1y"), ("a3x", "a3y")] : [("a1x", "a1y"), ("a3x", "a3y"), ("a2x", "a2y")]
                let o = ord[min(pl.pts.count - 1, 2)]; c.set(o.0, x); c.set(o.1, y)
                if pl.pts.count >= need() { if let p = arcBuild(c, pl.pts) { c.doc.addOnActive([p]); arcInfo(c, p) }; pl.pts.removeAll() }
                c.bump(); return true }
            t.onMove = { x, y in cur = P(x, y); return !pl.pts.isEmpty }
            t.onOverlay = { guard let q = cur, !pl.pts.isEmpty else { return [] }; let P2 = pl.pts + [q]
                if P2.count == need() { return arcBuild(c, P2).map { [Ov.paths(paths: [$0], color: 0xFF2A62B8)] } ?? [] }; return [Ov.poly(pts: P2, color: 0xFF888888, width: 1, dash: true)] }
            t.hintFn = { "Укажите точки дуги" }
            c.ui.setTool(t)
        }))

        // ---------- измерение ----------
        reg(PageSpec("measure", "Измерение", "measure", help: "Коснитесь начала и конца отрезка.", fields: { _ in [
            pg("Якорь", pnote { $0.info["m1"] ?? "—" }), pg("Расстояние", pnote { $0.info["md"] ?? "—" }), pg("Угол", pnote { $0.info["ma"] ?? "—" }), pg("По X и Y", pnote { $0.info["mxy"] ?? "—" })]
        }, onOpen: { c in
            var a: P? = nil, bP: P? = nil
            let t = FnTool { x, y, _ in a = P(x, y); bP = nil; c.info["m1"] = "X \(f2(x))  Y \(f2(y))"; c.bump(); return true }
            t.onMove = { x, y in guard let s = a else { return false }; bP = P(x, y); c.info["md"] = "\(f2(hypot(x - s.x, y - s.y))) мм"; c.info["ma"] = "\(f2(atan2(y - s.y, x - s.x) * 180 / .pi))°"; c.info["mxy"] = "dX \(f2(x - s.x))  dY \(f2(y - s.y))"; c.bump(); return true }
            t.onOverlay = { if let s = a, let e = bP { return [Ov.poly(pts: [s, e], color: 0xFFE00000, width: 1.5)] }; return [] }
            t.hintFn = { "Тяните от точки к точке" }
            c.ui.setTool(t)
        }))

        // ---------- трансформирование ----------
        reg(PageSpec("transform", "Трансформирование", "transform", help: "Положение, размер, поворот и наклон выбранных векторов.", fields: { _ in [
            psel("torg", "Точка привязки", [("c", "Центр"), ("bl", "Левый нижний"), ("tl", "Левый верхний"), ("tr", "Правый верхний"), ("br", "Правый нижний")], "c"),
            pg("Положение", pn("tx", "X", 0), pn("ty", "Y", 0), pbtns(pb("Переместить в X, Y", true) { ctx in if ctx.doc.selected().isEmpty { ctx.ui.toast("Выберите векторы"); return }; let o = anchor(ctx); ctx.res(ctx.ops.transformSel(Geom.M.move(ctx.num("tx") - o.x, ctx.num("ty") - o.y), ctx.chk("tcopy"))) })),
            pg("Размер", pn("tw", "Ширина", 0), pn("th", "Высота", 0), pchk("tlink", "Связать пропорции", true), pn("tsc", "Масштаб", 100, "%"),
                pbtns(pb("Задать размер") { ctx in let s = ctx.doc.selected(); if s.isEmpty { ctx.ui.toast("Выберите векторы"); return }; let bb = Geom.bbox(s); let o = anchor(ctx)
                    var kx = bb.w > 0 ? ctx.num("tw") / bb.w : 1, ky = bb.h > 0 ? ctx.num("th") / bb.h : 1; if ctx.chk("tlink") { if ctx.num("tw") > 0 && bb.w > 0 { ky = kx } else { kx = ky } }
                    ctx.res(ctx.ops.transformSel(Geom.M.scale(kx, ky, o.x, o.y), ctx.chk("tcopy"))) },
                    pb("Масштаб %") { ctx in let k = ctx.num("tsc") / 100; let o = anchor(ctx); ctx.res(ctx.ops.transformSel(Geom.M.scale(k, k, o.x, o.y), ctx.chk("tcopy"))) })),
            pg("Поворот", pn("trot", "Угол (+ по часовой)", 90, "°"), pbtns(pb("Повернуть") { ctx in let o = anchor(ctx); ctx.res(ctx.ops.transformSel(Geom.M.rotate(ctx.num("trot"), o.x, o.y), ctx.chk("tcopy"))) })),
            pg("Сдвиг на", pn("tmx", "dX", 0), pn("tmy", "dY", 0), pbtns(pb("Сдвинуть") { ctx in ctx.res(ctx.ops.transformSel(Geom.M.move(ctx.num("tmx"), ctx.num("tmy")), ctx.chk("tcopy"))) })),
            pg("Наклон", pn("tsx", "По X", 0, "°"), pn("tsy", "По Y", 0, "°"), pbtns(pb("Наклонить") { ctx in let o = anchor(ctx); ctx.res(ctx.ops.transformSel(Geom.M.shear(ctx.num("tsx"), ctx.num("tsy"), o.x, o.y), ctx.chk("tcopy"))) })),
            pchk("tcopy", "Применить к копии"), pnote { let s = $0.doc.selected(); if s.isEmpty { return "Ничего не выбрано" }; let bb = Geom.bbox(s); return "Выбрано: \(f2(bb.w)) × \(f2(bb.h)) мм, центр \(f2(bb.cx)); \(f2(bb.cy))" }]
        }, onOpen: { c in let s = c.doc.selected(); if !s.isEmpty { let bb = Geom.bbox(s); c.set("tw", bb.w); c.set("th", bb.h); c.set("tx", bb.cx); c.set("ty", bb.cy) } }))

        // ---------- смещение / отражение / копирование ----------
        reg(PageSpec("offset", "Смещение векторов", "offset", help: "Выберите векторы и задайте расстояние.", fields: { _ in [
            pn("od", "Смещение", 5), pradio("odir", [("out", "Наружу / вправо"), ("in", "Внутрь / влево"), ("both", "Обе стороны")], "out"),
            pradio("ocor", [("round", "Скруглённые углы"), ("chamfer", "Срезанные углы"), ("sharp", "Острые углы")], "round"),
            pif({ $0.str("ocor") == "sharp" }, pn("osh", "Предел остроты", 100, "%")), pchk("odel", "Удалить исходные векторы"),
            pbtns(pb("Сместить", true) { $0.res($0.ops.offset($0.num("od"), $0.str("odir"), $0.str("ocor"), $0.num("osh"), $0.chk("odel"))) })] }))
        reg(PageSpec("mirror", "Зеркальное отражение", "mirror", help: "Относительно краёв выделения или линии (выберите линию последней).", fields: { _ in [
            pchk("mcopy", "Сохранить оригинал (копия)"),
            pg("По горизонтали", pbtns(pb("Левый край") { $0.res($0.ops.mirror("L", $0.chk("mcopy"))) }, pb("Центр") { $0.res($0.ops.mirror("CH", $0.chk("mcopy"))) }, pb("Правый край") { $0.res($0.ops.mirror("R", $0.chk("mcopy"))) })),
            pg("По вертикали", pbtns(pb("Верх") { $0.res($0.ops.mirror("T", $0.chk("mcopy"))) }, pb("Центр") { $0.res($0.ops.mirror("CV", $0.chk("mcopy"))) }, pb("Низ") { $0.res($0.ops.mirror("B", $0.chk("mcopy"))) })),
            pg("Относительно линии", pbtns(pb("Последний выбранный — ось") { $0.res($0.ops.mirror("line", $0.chk("mcopy"))) }))] }))
        reg(PageSpec("blockcopy", "Копирование блоком / по кругу", "blockcopy", fields: { c in [
            pradio("bmode", [("block", "Блоком (сетка)"), ("rot", "По кругу")], "block"),
            pif({ $0.str("bmode") == "block" }, pradio("bdist", [("off", "Смещения (знак = направление)"), ("gap", "Зазоры")], "off"),
                pn("bx", "Смещение X", 1.5), pn("by", "Смещение Y", 1.5), pn("bcols", "Столбцов", 3, "", true), pn("brows", "Строк", 2, "", true),
                pif({ $0.str("bdist") == "gap" }, pchk("bright", "Вправо (иначе влево)", true), pchk("bup", "Вверх (иначе вниз)", true))),
            pif({ $0.str("bmode") == "rot" }, pn("rcx", "Центр X", cx(c)), pn("rcy", "Центр Y", cy(c)),
                pbtns(pb("Центр на листе") { ctx in ctx.ui.pickPoint("Укажите центр поворота") { q in ctx.set("rcx", q.x); ctx.set("rcy", q.y); ctx.bump() } }),
                pradio("rang", [("inc", "Угол шага"), ("tot", "Общий угол")], "tot"), pn("ra", "Угол", 360, "°"), pn("rn", "Количество", 6, "", true)),
            pbtns(pb("Применить", true) { ctx in ctx.res(ctx.str("bmode") == "block" ? ctx.ops.blockCopy(ctx.str("bdist") == "gap", ctx.num("bx"), ctx.num("by"), ctx.int("bcols"), ctx.int("brows"), ctx.chk("bright"), ctx.chk("bup"))
                : ctx.ops.rotateCopy(ctx.num("rcx"), ctx.num("rcy"), ctx.str("rang") == "tot", ctx.num("ra"), ctx.int("rn"))) })] }))
        reg(PageSpec("joinCoinc", "Соединить совпадающие точки", "joinCoinc", help: "Открытые векторы с совпадающими концами соединяются в один.", fields: { _ in [
            pn("jt", "Допуск", 0.01), pnote { $0.info["j"] ?? "" },
            pbtns(pb("Подсчитать") { ctx in let r = ctx.ops.joinCoincident(ctx.num("jt"), false); ctx.info["j"] = r.map { "Было \($0.0), станет \($0.1)" } ?? "Выберите открытые векторы"; ctx.bump() },
                pb("Соединить", true) { ctx in let r = ctx.ops.joinCoincident(ctx.num("jt"), true); ctx.info["j"] = r.map { "Было \($0.0), стало \($0.1)" } ?? "Выберите открытые векторы"; ctx.bump() })] }))
        reg(PageSpec("border", "Рамка вокруг векторов", "border", fields: { _ in [pn("bgx", "Зазор по X", 10), pn("bgy", "Зазор по Y", 10), pbtns(pb("Создать рамку", true) { $0.res($0.ops.border($0.num("bgx"), $0.num("bgy"))) })] }))
        reg(PageSpec("convert", "Преобразовать в фигуры", "convert", help: "Каждый вектор (или группа) заменяется окружностью или прямоугольником.", fields: { _ in [
            pg("В окружности", pradio("ccm", [("orig", "По размеру оригинала"), ("spec", "Задать")], "orig"), pn("ccd", "Диаметр", 10), pbtns(pb("В окружности") { $0.res($0.ops.convert(true, $0.str("ccm") == "spec", $0.num("ccd"), 0, 0)) })),
            pg("В прямоугольники", pradio("crm", [("orig", "По размеру оригинала"), ("spec", "Задать")], "orig"), pn("crh", "Высота", 10), pn("crw", "Ширина", 20), pbtns(pb("В прямоугольники") { $0.res($0.ops.convert(false, $0.str("crm") == "spec", 0, $0.num("crw"), $0.num("crh"))) }))] }))

        // ---------- доктор, дуги, вдоль кривой ----------
        reg(PageSpec("doctor", "Доктор векторов", "doctor", help: "Находит и исправляет типичные проблемы векторов перед обработкой.", fields: { _ in [
            pg("Найти проблемы", pchk("dcp", "Совпадающие точки", true), pn("dctol", "Допуск", 0.01), pchk("dxi", "Самопересечения и пересечения", true),
                pbtns(pb("Найти") { ctx in if ctx.doc.selected().isEmpty { ctx.ui.toast("Выберите векторы"); return }; let mk = ctx.ops.doctorFind(ctx.chk("dcp"), ctx.num("dctol"), ctx.chk("dxi")); ctx.state["marks"] = mk; ctx.info["d"] = "Найдено отметок: \(mk.count)"; ctx.ui.setTool(marksTool(mk)); ctx.bump() },
                    pb("Убрать метки") { $0.state["marks"] = nil; $0.ui.setTool(nil); $0.bump() })),
            pg("Исправить", pchk("dloop", "Удалить петли", true), pn("dpct", "% площади, чтобы оставить петлю", 0.2, "%"), ptxt("dlay", "Слой для результата"), pchk("dkeep", "Сохранить оригиналы", true),
                pbtns(pb("Исправить", true) { $0.res($0.ops.doctorFix($0.chk("dloop"), $0.num("dpct"), $0.str("dlay"), $0.chk("dkeep"))) })),
            pnote { $0.info["d"] ?? "" }] }))
        reg(PageSpec("fitArcs", "Дуги вместо кривых", "fitArcs", help: "Заменяет кривые Безье дугами с заданной точностью (удобнее для станка).", fields: { _ in [
            pn("fat", "Точность", 0.05), pnote { let c = $0.ops.segCounts($0.doc.selected()); return "Линий: \(c[0])\nБезье: \(c[1])\nДуг: \(c[2])\nТочек: \(c[3])" },
            pbtns(pb("Подобрать дуги", true) { $0.res($0.ops.fitArcs($0.num("fat"))); $0.bump() })] }))
        reg(PageSpec("pasteCurve", "Вставить вдоль кривой", "pasteCurve", help: "Выберите объект(ы), затем (в режиме «добавлять») — кривую последней.", fields: { _ in [
            pradio("pcm", [("num", "Задать количество"), ("dist", "Задать расстояние")], "dist"), pn("pcn", "Количество копий", 5, "", true), pn("pcd", "Расстояние между копиями", 50),
            pchk("pcev", "Сделать шаг равномерным"), pchk("pcrot", "Поворачивать по кривой"),
            pbtns(pb("Вставить", true) { $0.res($0.ops.pasteAlongCurve($0.str("pcm") == "num", $0.int("pcn"), $0.num("pcd"), $0.chk("pcev"), $0.chk("pcrot"))) })] }))

        // ---------- скругление и обрезка (работа щелчками) ----------
        reg(PageSpec("fillet", "Скругление", "fillet", help: "Коснитесь угла вектора. Для «Продлить» — коснитесь двух концов открытых векторов.", fields: { _ in [
            pradio("fmode", [("ins", "Вставить скругление"), ("ext", "Продлить / обрезать линии до пересечения")], "ins"), pn("frad", "Радиус скругления", 5), pnote { $0.info["f"] ?? "" }]
        }, onOpen: { c in c.ui.setTool(FilletTool(c)) }))
        reg(PageSpec("trim", "Обрезка", "trim", help: "Разбейте векторы в точках пересечения, затем касайтесь лишних кусков — они удаляются. В конце — соединить.", fields: { _ in [
            pchk("tkeep", "Сохранить оригинал (копию)"),
            pg("Разбить по пересечениям", pbtns(pb("Разбить все") { $0.res($0.ops.explode(true, $0.chk("tkeep"))) }, pb("Разбить выбранные") { $0.res($0.ops.explode(false, $0.chk("tkeep"))) })),
            pg("Соединить", pbtns(pb("Соединить все") { $0.res($0.ops.joinOpen(true)) }, pb("Соединить выбранные") { $0.res($0.ops.joinOpen(false)) }))]
        }, onOpen: { c in
            let t = FnTool { x, y, tol in let p = c.doc.paths.filter { c.doc.visible($0) }.min { Geom.distToPath($0, x, y) < Geom.distToPath($1, x, y) }; if let p = p, Geom.distToPath(p, x, y) <= tol { c.ops.scissors(p) }; return true }
            t.hintFn = { "Ножницы: касание куска удаляет его" }
            c.ui.setTool(t)
        }))

        // ---------- обрезка по контуру и рассечение ----------
        reg(PageSpec("clip", "Обрезка по контуру", "clip", help: "Сначала выберите контур-границу, затем (добавляя) — векторы, которые нужно обрезать.", fields: { _ in [
            pg("Что оставить", pradio("cdir", [("in", "Внутри"), ("out", "Снаружи")], "in")), pg("Векторы на границе", pradio("cov", [("trim", "Обрезать"), ("del", "Удалить"), ("keep", "Оставить")], "trim")),
            pbtns(pb("Обрезать векторы", true) { $0.res($0.ops.clip($0.str("cdir") == "in", $0.str("cov"))) })] }))
        reg(PageSpec("slice", "Рассечь векторы", "slice", fields: { _ in [
            pg("Результат", pradio("scl", [("close", "Замкнуть части"), ("open", "Оставить открытыми")], "close")),
            pg("Чем рассечь", pradio("sm", [("last", "Последним выбранным вектором"), ("v", "Вертикальной линией (X =)"), ("h", "Горизонтальной линией (Y =)")], "last"), pn("sc", "Координата линии", 0)),
            pbtns(pb("Рассечь", true) { $0.res($0.ops.slice($0.str("sm"), $0.num("sc"), $0.str("scl") == "close")) })] }))

        // ---------- модель ----------
        reg(PageSpec("modelSize", "Размер модели", "modelSize", fields: { c in [pn("mw", "Ширина (X)", c.doc.model.w), pn("mh", "Высота (Y)", c.doc.model.h),
            psel("manc", "Привязка", [("bl", "Левый нижний угол"), ("c", "Центр"), ("tl", "Левый верхний")], "bl"), pn("mt", "Толщина материала", c.doc.material.thickness),
            pbtns(pb("Применить", true) { $0.ops.setModelSize($0.num("mw"), $0.num("mh"), $0.str("manc"), $0.num("mt")); $0.ui.fit() })] }))
        reg(PageSpec("modelPos", "Положение нуля", "modelPos", help: "Где на заготовке находится ноль X0 Y0 (от него считаются координаты в УП).", fields: { c in [
            pradio("mpos", [("bl", "Левый нижний угол"), ("tl", "Левый верхний угол"), ("c", "Центр"), ("tr", "Правый верхний угол"), ("br", "Правый нижний угол"), ("custom", "Задать: левый нижний угол модели в точке")], "bl"),
            pif({ $0.str("mpos") == "custom" }, pn("mpx", "X", c.doc.model.x0), pn("mpy", "Y", c.doc.model.y0)),
            pbtns(pb("Применить", true) { $0.ops.setModelPos($0.str("mpos"), $0.num("mpx"), $0.num("mpy")); $0.ui.fit() })] }))

        // ---------- раскрой, multi-plate ----------
        reg(PageSpec("nest", "Раскрой (Nesting)", "nest", help: "Детали раскладываются по габаритам (подходит для мебельных деталей). Выберите детали.", fields: { _ in [
            pg("Зазоры", pn("nD", "Диаметр фрезы (D)", 6), pn("nC", "Зазор траектории (C)", 2), pn("nE", "Отступ от края листа", 10)),
            pg("Детали", pchk("nRot", "Разрешить поворот на 90°", true), psel("nFrom", "Начинать от", [("bl", "Левый низ"), ("br", "Правый низ"), ("tl", "Левый верх"), ("tr", "Правый верх")], "bl"),
                psel("nDir", "Направление", [("x", "X"), ("y", "Y")], "x"), pchk("nGrp", "Группировать отверстия с деталями", true),
                pbtns(pb("Сгруппировать сейчас") { ctx in if ctx.doc.selected().isEmpty { ctx.ui.toast("Выберите векторы"); return }; ctx.doc.push(); ctx.ops.autoGroupHoles(ctx.doc.selected()); ctx.doc.changed() })),
            pg("Лист", pchk("nSheet", "Лист = модель", true), pnote { _ in "Иначе лист — первый выбранный замкнутый вектор (по габариту)." }, pchk("nGN", "Группировать детали каждого листа", true),
                pn("nCopies", "Копий каждой детали", 1, "", true), pn("nMax", "Макс. листов", 999, "", true)),
            pbtns(pb("Раскроить", true) { ctx in ctx.info["n"] = ctx.ops.nest(Ops.NestOpt(toolD: ctx.num("nD"), clear: ctx.num("nC"), edge: ctx.num("nE"), rotate: ctx.chk("nRot"), from: ctx.str("nFrom"), dirX: ctx.str("nDir") == "x", groupHoles: ctx.chk("nGrp"), sheetIsModel: ctx.chk("nSheet"), groupSheets: ctx.chk("nGN"), copies: ctx.int("nCopies"), maxSheets: ctx.int("nMax"))); ctx.ui.fit(); ctx.bump() }),
            pnote { $0.info["n"] ?? "" }] }))
        reg(PageSpec("multiplate", "Multi-Plate", "multiplate", help: "Раскладка одинаковых табличек (шаблон = выбранные векторы) по листам.", fields: { c in [
            pg("Шаблон", pbtns(pb("Задать шаблон") { ctx in let s = ctx.doc.selected(); if s.isEmpty { ctx.ui.toast("Выберите векторы"); return }; ctx.state["tpl"] = Ops.Plate(paths: s.map { $0.copy(newId: false) }, ids: s.map { $0.id }, bb: Geom.bbox(s)); ctx.bump() }),
                pnote { ($0.state["tpl"] as? Ops.Plate).map { t in "Шаблон: \(f2(t.bb.w)) × \(f2(t.bb.h)) мм (\(t.paths.count) вект.)" } ?? "Шаблон не задан" }),
            pg("Данные из текстового файла", pbtns(pb("Загрузить данные…") { ctx in ctx.ui.pickFile("text/*") { _, bytes in let lines = Rx.c("\\r?\\n").split(String(decoding: bytes, as: UTF8.self)).map { $0.trimmed }.filter { !$0.isEmpty }; ctx.state["lines"] = StrList(lines); ctx.set("mpN", Double(lines.count)); ctx.bump() } }),
                pnote { let l = ($0.state["lines"] as? StrList)?.items.count ?? 0; return l > 0 ? "Загружено строк: \(l) — табличек будет столько же." : "Каждая строка файла — текст одной таблички (заменяет текст шаблона). Символ | — перенос строки." }),
            pg("Лист", pn("mpW", "Ширина листа", c.doc.model.w), pn("mpH", "Высота листа", c.doc.model.h), pn("mpN", "Количество табличек", 1, "", true),
                pnote { ctx in guard let t = ctx.state["tpl"] as? Ops.Plate else { return "" }; let (co, ro) = ctx.ops.plateLayout(t, ctx.num("mpW"), ctx.num("mpH"), ctx.num("mpGX"), ctx.num("mpGY"), ctx.num("mpBX"), ctx.num("mpBY")); let per = co * ro
                    return per > 0 ? "На листе: \(co) × \(ro) = \(per); листов: \(Int(ceil(Double(max(1, ctx.int("mpN"))) / Double(per))))" : "Табличка не помещается на лист" }),
            pg("Раскладка", psel("mpF", "Первая табличка", [("1", "1 — левый нижний"), ("2", "2 — правый нижний"), ("3", "3 — левый верхний"), ("4", "4 — правый верхний")], "1"),
                pn("mpGX", "Зазор по X", 0), pn("mpGY", "Зазор по Y", 0), pn("mpBX", "Поле листа X", 0), pn("mpBY", "Поле листа Y", 0), pchk("mpDel", "Удалить исходный шаблон", true)),
            pbtns(pb("Разложить", true) { ctx in guard let t = ctx.state["tpl"] as? Ops.Plate else { ctx.ui.toast("Сначала задайте шаблон"); return }
                let lines = (ctx.state["lines"] as? StrList)?.items ?? []
                ctx.res(ctx.ops.multiPlate(t, ctx.int("mpN"), lines, Int(ctx.str("mpF")) ?? 1, ctx.num("mpW"), ctx.num("mpGX"), ctx.num("mpGY"), ctx.num("mpBX"), ctx.num("mpBY"), ctx.num("mpH"), ctx.chk("mpDel")) { TextEngine.build($0) }); ctx.ui.fit() })] }))
        PagesB.register(reg)
    }

    // ---------- вспомогательное ----------
    static func polyPts(_ c: PageCtx) -> PtList { if let l = c.state["poly"] as? PtList { return l }; let l = PtList(); c.state["poly"] = l; return l }
    private static func polyAdd(_ c: PageCtx, _ q: P) { polyPts(c).pts.append(q); c.bump() }
    private static func finishPoly(_ c: PageCtx, _ close: Bool) {
        let pl = polyPts(c); let pts = pl.pts; if pts.count < 2 { c.ui.toast("Нужно хотя бы две точки"); return }
        var p = Geom.makePath(pts, close)
        if c.chk("psm") && pts.count > 2 { p = smoothPoly(pts, close) }
        c.doc.addOnActive([p]); pl.pts.removeAll(); c.bump()
    }
    private static func smoothPoly(_ pts: [P], _ closed: Bool) -> VPath {
        let n = pts.count; let p = VPath(closed: closed, x0: pts[0].x, y0: pts[0].y)
        let cnt = closed ? n : n - 1
        for i in 0..<cnt { let p0 = pts[closed ? (i - 1 + n) % n : max(0, i - 1)], p1 = pts[i], p2 = pts[(i + 1) % n], p3 = pts[closed ? (i + 2) % n : min(n - 1, i + 2)]
            p.segs.append(BezSeg(p1.x + (p2.x - p0.x) / 6, p1.y + (p2.y - p0.y) / 6, p2.x - (p3.x - p1.x) / 6, p2.y - (p3.y - p1.y) / 6, p2.x, p2.y)) }
        return p
    }
    private static func arcBuild(_ c: PageCtx, _ P2: [P]) -> VPath? {
        let t = c.str("atype"); let cw = c.chk("acw")
        switch t {
        case "sep": guard P2.count >= 3 else { return nil }; let a = P2[0], bb = P2[1], m = P2[2]; return Geom.Shapes.arc3(a.x, a.y, m.x, m.y, bb.x, bb.y)
        case "cse": guard P2.count >= 3 else { return nil }; let cc = P2[0], a = P2[1], bb = P2[2]; let r = hypot(a.x - cc.x, a.y - cc.y); let an = atan2(bb.y - cc.y, bb.x - cc.x); return Geom.Shapes.arcCSE(cc.x, cc.y, a.x, a.y, cc.x + r * cos(an), cc.y + r * sin(an), !cw)
        default:
            guard P2.count >= 2 else { return nil }
            let a = P2[0], bb = P2[1]; let dx = bb.x - a.x, dy = bb.y - a.y; let L = hypot(dx, dy); if L < 1e-9 { return nil }
            let half = L / 2; let R = max(c.num("arad"), half); let h = sqrt(R * R - half * half); let s: Double = cw ? -1 : 1
            return Geom.Shapes.arcCSE((a.x + bb.x) / 2 - dy / L * h * s, (a.y + bb.y) / 2 + dx / L * h * s, a.x, a.y, bb.x, bb.y, !cw)
        }
    }
    private static func arcFromFields(_ c: PageCtx) -> VPath? { let a = P(c.num("a1x"), c.num("a1y")), bb = P(c.num("a3x"), c.num("a3y"))
        switch c.str("atype") { case "sep": return arcBuild(c, [a, bb, P(c.num("a2x"), c.num("a2y"))]); case "cse": return arcBuild(c, [P(c.num("acx"), c.num("acy")), a, bb]); default: return arcBuild(c, [a, bb]) } }
    private static func arcInfo(_ c: PageCtx, _ p: VPath) { guard let s = p.segs.first as? ArcSeg else { return }
        c.info["arc"] = "Начало X \(f2(p.x0)) Y \(f2(p.y0))\nКонец X \(f2(s.x)) Y \(f2(s.y))\nЦентр X \(f2(s.cx)) Y \(f2(s.cy))\nРадиус \(f2(hypot(s.cx - s.x, s.cy - s.y))) мм" }
    private static func anchor(_ c: PageCtx) -> P { let s = c.doc.selected(); if s.isEmpty { return P(0, 0) }; let bb = Geom.bbox(s)
        switch c.str("torg") { case "bl": return P(bb.x1, bb.y1); case "tl": return P(bb.x1, bb.y2); case "tr": return P(bb.x2, bb.y2); case "br": return P(bb.x2, bb.y1); default: return P(bb.cx, bb.cy) } }
    static func marksTool(_ mk: [P]) -> CanvasTool { let t = FnTool { _, _, _ in false }; t.onOverlay = { mk.map { Ov.mark(p: $0, kind: "x") } }; return t }

    /// Скругление: касание угла; «продлить» — касание двух концов
    final class FilletTool: CanvasTool {
        let c: PageCtx
        private var first: (VPath, Bool, P)? = nil
        init(_ c: PageCtx) { self.c = c }
        private func nodeAt(_ x: Double, _ y: Double, _ tol: Double, _ endsOnly: Bool) -> (VPath, Int)? {
            for p in c.doc.selected() + c.doc.paths.filter({ c.doc.editable($0) }) {
                let pts = [P(p.x0, p.y0)] + p.segs.map { P($0.x, $0.y) }
                for i in pts.indices { if endsOnly && (p.closed || (i > 0 && i < pts.count - 1)) { continue }; if hypot(pts[i].x - x, pts[i].y - y) <= tol { return (p, i) } }
            }
            return nil
        }
        func down(_ x: Double, _ y: Double, _ tol: Double) -> Bool {
            if c.str("fmode") == "ins" { guard let n = nodeAt(x, y, tol, false) else { return true }; c.info["f"] = c.ops.fillet(n.0, n.1, c.num("frad")) ?? "Скругление R\(f2(c.num("frad"))) вставлено"; c.bump(); return true }
            guard let n = nodeAt(x, y, tol, true) else { return true }
            let atStart = n.1 == 0; let pt = atStart ? P(n.0.x0, n.0.y0) : P(n.0.endX, n.0.endY)
            guard let f = first else { first = (n.0, atStart, pt); c.info["f"] = "Теперь второй конец"; c.bump(); return true }
            first = nil; c.info["f"] = c.ops.extendToIntersection(f.0, f.1, n.0, atStart) ?? "Готово"; c.bump(); return true
        }
        func overlay() -> [Ov] { first.map { [Ov.mark(p: $0.2, kind: "box", color: 0xFF19B23B)] } ?? [] }
        var hint: String { c.str("fmode") == "ins" ? "Коснитесь угла (узла) вектора" : "Коснитесь двух концов" }
    }
}
