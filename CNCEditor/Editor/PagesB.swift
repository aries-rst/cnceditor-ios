/* ЧПУ Редактор 2D — страницы: текст, огибающая, картинка и векторизация, траектории, имитация. Порт PagesB.kt */
import Foundation

private let f2 = PageCtx.f2

enum PagesB {
    static func register(_ reg: (PageSpec) -> Void) {
        // ================= текст =================
        reg(PageSpec("text", "Векторный текст", "text", help: "Коснитесь листа, где будет начало текста (или задайте X, Y), и введите текст.", fields: { c in
            let curve = (c.arg as? String) == "curve" || ((c.arg as? [VPath])?.first?.text?.curveId != nil)
            return [
                psel("txF", "Шрифт", TextEngine.list().map { ($0.0, $0.1) }, "sans"), pchk("txB", "Жирный"), pchk("txI", "Курсив"),
                pradio("txA", [("left", "Влево"), ("center", "По центру"), ("right", "Вправо")], "left"), pn("txS", "Высота букв (заглавных)", 50),
                ptxt("txT", "Текст", "Текст", true),
                pif({ _ in !curve }, pg("Положение (начало первой строки)", pn("txX", "X", c.doc.model.x0 + c.doc.model.w * 0.1), pn("txY", "Y", c.doc.model.y0 + c.doc.model.h / 2))),
                pg("Трансформация", pn("txSX", "Ширина букв", 100, "%"), pn("txSY", "Высота букв", 100, "%"), pn("txSl", "Наклон", 0, "°"), pif({ _ in !curve }, pn("txR", "Поворот", 0, "°"))),
                pg("Интервалы", pn("txCS", "Между символами", 0, "% пробела"), pif({ _ in !curve }, pn("txLS", "Между строками (0 — авто)", 0)), pchk("txK", "Кернинг", true)),
                pif({ _ in curve }, pg("По кривой", pbtns(pb("Кривая = выбранная") { ctx in let s = ctx.doc.selectedOrdered().filter { $0.text == nil }; if s.isEmpty { ctx.ui.toast("Выберите кривую"); return }; ctx.state["curve"] = s.last!.id; ctx.bump() }),
                    pnote { ctx in (ctx.state["curve"] as? String).flatMap { ctx.doc.byId($0) }.map { "Кривая выбрана, длина \(f2(Geom.length($0))) мм" } ?? "Кривая не выбрана" },
                    pradio("txCP", [("start", "От начала"), ("center", "По центру"), ("end", "К концу")], "center"), pn("txCO", "Отступ от кривой", 0), pn("txCSt", "Сдвиг вдоль кривой", 0), pchk("txCF", "Перевернуть (с другой стороны)"))),
                pnote { $0.info["tx"] ?? "" },
                pbtns(pb(c.arg is [VPath] ? "Применить" : "Создать", true) { textCommit($0) })]
        }, onOpen: { c in
            let edit = c.arg as? [VPath]
            let t = edit?.first?.text ?? (c.doc.lastText ?? TextParams())
            c.values["txF"] = t.font; c.set("txB", t.bold); c.set("txI", t.italic); c.values["txA"] = t.align; c.set("txS", t.size); c.values["txT"] = t.text
            if edit != nil { c.set("txX", t.x); c.set("txY", t.y) }
            c.set("txSX", t.sx); c.set("txSY", t.sy); c.set("txSl", t.slant); c.set("txR", t.rot); c.set("txCS", t.charSp); c.set("txLS", t.lineSp); c.set("txK", t.kern)
            c.values["txCP"] = t.cPos; c.set("txCO", t.cOff); c.set("txCSt", t.cStart); c.set("txCF", t.cFlip)
            if let cid = t.curveId { c.state["curve"] = cid } else if (c.arg as? String) == "curve", let l = c.doc.selectedOrdered().last(where: { $0.text == nil }) { c.state["curve"] = l.id }
            let isCurve = (c.arg as? String) == "curve"
            if !isCurve && edit == nil {
                let tl = FnTool { x, y, _ in c.set("txX", x); c.set("txY", y); c.bump(); return true }
                tl.onOverlay = { textPreview(c).map { [Ov.paths(paths: $0, color: 0xFF2A62B8)] } ?? [] }
                tl.hintFn = { "Коснитесь листа — начало текста" }
                c.ui.setTool(tl)
            } else {
                let tl = FnTool { _, _, _ in false }; tl.onOverlay = { textPreview(c).map { [Ov.paths(paths: $0, color: 0xFF2A62B8)] } ?? [] }; c.ui.setTool(tl)
            }
        }))

        // ================= огибающая =================
        reg(PageSpec("envelope", "Огибающая", "envelope", help: "Тяните узлы и рычаги рамки — объект искажается. Или впишите объект вдоль кривой.", fields: { _ in [
            pradio("emode", [("nodes", "Редактировать узлы огибающей"), ("move", "Перемещать огибающую")], "nodes"),
            pg("По готовым кривым", pchk("euse", "Использовать кривые"), pradio("ecm", [("one", "Вдоль одной кривой"), ("two", "Между двумя кривыми")], "one"),
                psel("eside", "Сторона", [("center", "По центру"), ("left", "Слева"), ("right", "Справа")], "center"), pchk("ewon", "Задать ширину огибающей"), pn("ew", "Ширина", 50),
                pbtns(pb("Выбрать кривую…") { $0.state["pick"] = "one"; $0.values["ecm"] = "one"; $0.ui.toast("Коснитесь кривой, вдоль которой разместить рисунок") }),
                pbtns(pb("Верхняя кривая…") { $0.state["pick"] = "top"; $0.values["ecm"] = "two"; $0.ui.toast("Коснитесь верхней кривой") }, pb("Нижняя кривая…") { $0.state["pick"] = "bot"; $0.values["ecm"] = "two"; $0.ui.toast("Коснитесь нижней кривой") }),
                pnote { ctx in let cv = (ctx.state["env"] as? EnvelopeTool)?.curves ?? [:]; return "Кривая: \(cv["one"] != nil ? "выбрана" : "—"); верхняя: \(cv["top"] != nil ? "да" : "—"); нижняя: \(cv["bot"] != nil ? "да" : "—")" },
                pg("Количество копий", pradio("ecopy", [("one", "Одна — растянуть по длине"), ("best", "Много — по пропорциям"), ("n", "Много — задать число")], "one"), pn("en", "Копий", 3, "", true)),
                pbtns(pb("Применить") { ctx in (ctx.state["env"] as? EnvelopeTool)?.apply(); ctx.bump() })),
            pbtns(pb("Отмена") { $0.ui.setTool(nil); $0.ui.closePage() }, pb("Готово", true) { ctx in (ctx.state["env"] as? EnvelopeTool)?.finish(); ctx.ui.setTool(nil); ctx.ui.closePage() })]
        }, onOpen: { c in let src = c.doc.selected(); if src.isEmpty { c.ui.toast("Сначала выберите векторы, затем откройте инструмент"); return }
            let t = EnvelopeTool(c, src); c.state["env"] = t; c.ui.setTool(t) }))

        // ================= картинка и векторизация =================
        reg(PageSpec("image", "Картинка / фото", "image", help: "Картинка ложится подложкой под чертёж: по ней можно обводить вручную или векторизовать автоматически.", fields: { _ in [
            pbtns(pb("Из галереи…") { $0.ui.dialog("imageGallery") }, pb("Камера…") { $0.ui.dialog("imageCamera") }),
            pif({ $0.doc.image != nil },
                pg("Подложка", pn("iop", "Прозрачность", 50, "%"), pchk("ivis", "Показывать", true), pchk("ilock", "Закрепить"),
                    pbtns(pb("Применить") { ctx in if let im = ctx.doc.image { im.opacity = ctx.num("iop") / 100; im.visible = ctx.chk("ivis"); im.locked = ctx.chk("ilock"); ctx.doc.changed() } }, pb("Убрать") { ctx in ctx.doc.image = nil; ctx.doc.changed(); ctx.bump() })),
                pg("Размер подложки", pn("iw", "Ширина", 0), pn("ih", "Высота", 0), pchk("ilink", "Связать пропорции", true),
                    pbtns(pb("Задать размер") { ctx in if let im = ctx.doc.image { let k = ctx.chk("ilink") ? ctx.num("iw") / im.w : 0; let nh = ctx.chk("ilink") ? im.h * k : ctx.num("ih"); im.w = ctx.num("iw"); im.h = nh; ctx.set("ih", nh); ctx.doc.changed(); ctx.bump() } })),
                pg("Масштаб по двум точкам", pnote { _ in "Укажите две точки на фото и введите реальное расстояние между ними." }, pn("icd", "Расстояние", 100),
                    pbtns(pb("Указать 2 точки") { ctx in ctx.ui.pickPoint("Первая точка") { a in ctx.ui.pickPoint("Вторая точка") { bb in let d0 = hypot(bb.x - a.x, bb.y - a.y); guard let im = ctx.doc.image, d0 >= 1e-6 else { return }
                        let k = ctx.num("icd") / d0; im.x = a.x + (im.x - a.x) * k; im.y = a.y + (im.y - a.y) * k; im.w *= k; im.h *= k; ctx.doc.changed(); ctx.ui.fit() } } })),
                pg("Исправить перспективу (фото под углом)", pnote { _ in "Отметьте 4 угла прямоугольника на фото: левый верхний, правый верхний, правый нижний, левый нижний." },
                    pn("pw", "Ширина прямоугольника", 600), pn("ph", "Высота прямоугольника", 400), pbtns(pb("Отметить 4 угла") { $0.ui.setTool(PerspTool($0)) })),
                pbtns(pb("Векторизовать…", true) { $0.ui.openPage("trace") }))]
        }, onOpen: { c in if let im = c.doc.image { c.set("iop", im.opacity * 100); c.set("ivis", im.visible); c.set("ilock", im.locked); c.set("iw", im.w); c.set("ih", im.h) } }))
        reg(PageSpec("trace", "Векторизация", "trace", help: "Контуры строятся по тёмным областям подложки (или по светлым — «Инвертировать»).", fields: { _ in [
            pg("Чёрно-белое", pchk("tauto", "Порог автоматически", true), pn("tth", "Порог", 128, "0…255", true), pchk("tinv", "Инвертировать"), pn("tblur", "Размытие", 1, "пикс", true)),
            pg("Контуры", pn("tmin", "Убрать мусор меньше", 30, "пикс²"), pn("ttol", "Точность", 1, "пикс"), pchk("tsm", "Плавные кривые", true), pn("tcor", "Острые углы до", 60, "°")),
            pg("Трафарет", pchk("tbr", "Мостики для островков (середины «О», «А», «Р» не выпадут)"), pn("tbw", "Ширина мостика", 3), psel("tbd", "Направление", [("v", "Вертикально"), ("h", "Горизонтально"), ("x", "Крестом")], "v")),
            pn("tmax", "Разрешение обработки (макс. сторона)", 1200, "пикс", true),
            pnote { $0.info["tr"] ?? "" }, pbtns(pb("Просмотр") { traceRun($0, false) }, pb("Создать векторы", true) { traceRun($0, true) })]
        }, onOpen: { c in if c.doc.image == nil { c.info["tr"] = "Сначала загрузите картинку или фото" } }))

        // ================= траектории =================
        for (type, title, help) in [
            ("profile", "Обработка по профилю", "Фреза идёт по замкнутым векторам со смещением на радиус: снаружи (вырезать деталь) или внутри (отверстие). Отверстия внутри детали — автоматически с нужной стороны."),
            ("machine", "Обработка вдоль векторов", "Центр фрезы идёт точно по линии вектора (Machine Vectors). Подходит и для гравировки однолинейным шрифтом."),
            ("area", "Выборка (Area Clearance)", "Материал внутри замкнутых векторов выбирается на глубину. Вложенные контуры — островки, они остаются."),
            ("vcarve", "V-резьба (гравировка V-резцом)", "V-резец идёт внутри контуров, глубина растёт к середине линий. При ограничении глубины дно плоское."),
            ("drill", "Сверление", "Отверстия сверлятся в центрах выбранных векторов (окружностей и т. п.).")] {
            reg(PageSpec("tp_\(type)", title, type == "vcarve" ? "vbit" : type, help: help, fields: { tpFields(type, $0) }, onOpen: { tpOpen(type, $0) }, onClose: { $0.ui.setTool(nil) }))
        }

        reg(PageSpec("sim", "Имитация обработки", "sim", help: "Вид сверху: светлое — поверхность, темнее — глубже, чёрное — насквозь.", fields: { _ in [
            pn("simSpd", "Скорость", 30, "ходов/кадр", true), pnote { ctx in guard let s = ctx.state["sim"] as? SimTool else { return "" }; return "Ход \(s.k) из \(s.segs.count)" + ((s.k >= 1 && s.k <= s.segs.count) ? ", глубина \(f2(s.segs[s.k - 1].d)) мм" : "") },
            pbtns(pb("▶ Пуск / ⏸ Пауза", true) { ctx in if let s = ctx.state["sim"] as? SimTool { s.play.toggle(); if s.play && s.k >= s.segs.count { s.k = 0 } }; ctx.bump() },
                pb("⏭ Результат") { ctx in if let s = ctx.state["sim"] as? SimTool { s.play = false; s.k = s.segs.count }; ctx.bump() }, pb("⏮ Сначала") { ctx in if let s = ctx.state["sim"] as? SimTool { s.play = false; s.k = 0 }; ctx.bump() })]
        }, onOpen: { c in let t = SimTool(c); c.state["sim"] = t; c.ui.setTool(t) }, onClose: { $0.ui.setTool(nil) }))
    }

    // ---------- текст ----------
    private static func textParams(_ c: PageCtx) -> TextParams {
        TextParams(c.str("txT"), c.str("txF"), c.chk("txB"), c.chk("txI"), max(0.1, c.num("txS")), c.str("txA"), c.num("txCS"), c.num("txLS"), c.chk("txK"),
                   c.num("txSX") == 0 ? 100 : c.num("txSX"), c.num("txSY") == 0 ? 100 : c.num("txSY"), c.num("txSl"), c.num("txR"), c.num("txX"), c.num("txY"),
                   c.state["curve"] as? String, c.str("txCP"), c.num("txCO"), c.num("txCSt"), c.chk("txCF"))
    }
    private static func curveMode(_ c: PageCtx) -> Bool { (c.arg as? String) == "curve" || c.state["curve"] != nil }
    static func textPreview(_ c: PageCtx) -> [VPath]? {
        let t = textParams(c)
        var curve: VPath? = nil
        if curveMode(c) { guard let id = t.curveId, let cv = c.doc.byId(id) else { return nil }; curve = cv }
        let r = TextEngine.build(t, curve.map { Geom.flatten($0, 0.05) })
        if r.isEmpty { c.info["tx"] = "Нет контуров (пустой текст?)" } else { let bb = Geom.bbox(r); c.info["tx"] = "Контуров: \(r.count), размер \(f2(bb.w)) × \(f2(bb.h)) мм" }
        return r
    }
    private static func textCommit(_ c: PageCtx) {
        if curveMode(c) && c.state["curve"] == nil { c.ui.toast("Выберите кривую"); return }
        guard let ps = textPreview(c), !ps.isEmpty else { c.ui.toast("Нечего создавать"); return }
        let t = textParams(c); if !curveMode(c) { t.curveId = nil }; c.doc.lastText = t.copy()
        let gid = "g" + Geom.uid(); ps.forEach { $0.group = gid; $0.text = t.copy(); $0.layer = c.doc.active }
        if let edit = c.arg as? [VPath], !edit.isEmpty { ps.forEach { $0.layer = edit[0].layer }; c.doc.replace(edit, ps); c.ui.openPage("text", ps) } else { c.doc.add(ps) }
    }

    // ---------- векторизация ----------
    private static func traceRun(_ c: PageCtx, _ make: Bool) {
        guard let im = c.doc.image else { c.ui.toast("Сначала загрузите картинку"); return }
        guard let (w, h, gray) = c.ui.underlayGray(clampI(c.int("tmax"), 100, 4000)) else { c.ui.toast("Не удалось прочитать картинку"); return }
        let r = Trace.trace(gray, w, h, TraceOpt(c.chk("tauto") ? -1 : c.int("tth"), c.chk("tinv"), c.int("tblur"), c.num("tmin"), max(0.1, c.num("ttol")), c.chk("tsm"), c.num("tcor")))
        c.set("tth", Double(r.threshold))
        let sx = im.w / Double(w), sy = im.h / Double(h); let m = [sx, 0, 0, -sy, im.x, im.y + im.h]
        var paths = r.contours.map { cn -> VPath in
            let p = cn.segs != nil ? VPath(layer: c.doc.active, closed: true, x0: cn.pts[0].x, y0: cn.pts[0].y, segs: cn.segs!.map { $0.copy() }) : Geom.makePath(cn.pts, true, c.doc.active)
            return Geom.transform(p, m) }
        if c.chk("tbr") { paths = Trace.stencilBridges(paths, max(0.2, c.num("tbw")), c.str("tbd"), c.doc.active) }
        c.info["tr"] = "Порог \(r.threshold); контуров: \(paths.count)"
        if make { if !paths.isEmpty { let gid = "g" + Geom.uid(); paths.forEach { $0.group = gid }; c.doc.add(paths) }; c.ui.setTool(nil) }
        else { let t = FnTool { _, _, _ in false }; let pv = paths; t.onOverlay = { [Ov.paths(paths: pv, color: 0xFFD81F2A, dash: false)] }; c.ui.setTool(t) }
        c.bump()
    }
    /// 4 угла для выпрямления перспективы
    final class PerspTool: CanvasTool {
        let c: PageCtx; var pts: [P] = []
        init(_ c: PageCtx) { self.c = c }
        func down(_ x: Double, _ y: Double, _ tol: Double) -> Bool {
            pts.append(P(x, y))
            if pts.count == 4 { c.ui.setTool(nil); straighten() } else { c.ui.toast(["", "Угол 2 из 4: правый верхний", "Угол 3 из 4: правый нижний", "Угол 4 из 4: левый нижний"][pts.count]) }
            c.bump(); return true
        }
        private func straighten() {
            guard let im = c.doc.image, let (w, h, px) = c.ui.underlayArgb() else { return }
            let quad = pts.map { P(($0.x - im.x) / im.w * Double(w), (im.y + im.h - $0.y) / im.h * Double(h)) }
            let W = c.num("pw"), H = c.num("ph"); let k = min(4.0, 2400 / max(W, H)); let ow = max(2, kround(W * k)), oh = max(2, kround(H * k))
            let out = Trace.warpArgb(px, w, h, quad, ow, oh)
            c.doc.push(); c.ui.setUnderlayArgb(ow, oh, out, c.doc.model.x0, c.doc.model.y0, W, H); c.ui.toast("Фото выпрямлено: \(f2(W)) × \(f2(H)) мм"); c.ui.fit()
        }
        func overlay() -> [Ov] { pts.isEmpty ? [] : [Ov.poly(pts: pts, color: 0xFFFF8800, width: 2, dash: false, closed: pts.count == 4)] + pts.map { Ov.mark(p: $0, kind: "box", color: 0xFFFF8800) } }
        var hint: String { "Угол \(pts.count + 1) из 4" + ([": левый верхний", ": правый верхний", ": правый нижний", ": левый нижний"].getOrNull(pts.count) ?? "") }
    }

    // ---------- траектории ----------
    private static func tpFields(_ type: String, _ c: PageCtx) -> [F] {
        let th = c.doc.material.thickness
        var extra: [F] = []
        let ramp = pg("Врезание", pchk("rpOn", "Наклонное врезание (рампа) вдоль контура"), pn("rpL", "Длина рампы", 30), pnote { _ in "Фреза опускается постепенно, двигаясь по контуру — меньше нагрузка и нагрев." })
        switch type {
        case "profile":
            extra.append(pg("Сторона", pradio("side", [("outside", "Снаружи"), ("inside", "Внутри"), ("on", "По линии")], "outside"), pn("allow", "Припуск", 0), pchk("climb", "Попутное фрезерование", true)))
            extra.append(pg("Мостики (перемычки)", pchk("tbOn", "Добавить мостики — деталь не сдвинется и не вылетит"), pradio("tbMode", [("count", "Количество на контур"), ("dist", "Через расстояние"), ("manual", "Вручную")], "count"),
                pn("tbN", "Количество", 4, "шт", true), pn("tbD", "Расстояние", 300), pn("tbL", "Длина мостика", 10), pn("tbH", "Толщина (высота)", 3),
                pbtns(pb("Ставить / убирать касанием") { manualTabs($0) }), pnote { _ in "Оранжевые метки — мостики. «Вручную»: рассчитайте траекторию и касайтесь её линии." }))
            extra.append(ramp)
        case "area":
            extra.append(ramp); extra.append(pg("Стратегия", pradio("strat", [("offset", "Смещением (по контуру)"), ("raster", "Растром (строками)")], "offset"),
                psel("rang", "Угол растра", [("0", "0° (вдоль X)"), ("90", "90° (вдоль Y)")], "0"), pchk("lastP", "Чистовой проход по контуру после растра", true),
                pn("aso", "Перекрытие (0 — из фрезы)", 0), pn("allow", "Припуск", 0)))
        case "vcarve": extra.append(pg("V-резец", pn("vang", "Угол резца", 90, "°"), pn("vso", "Шаг колец", 0.2)))
        case "drill": extra.append(pg("Сверление", pn("peck", "Шаг подъёма (0 — сразу на всю глубину)", 0), pn("retr", "Высота отвода", 2)))
        default: break
        }
        let defName = ["profile": "Профиль", "machine": "Machine Vectors", "area": "Выборка", "vcarve": "V-резьба", "drill": "Сверление"][type] ?? type
        return [pnote { "Выбрано векторов: \($0.doc.selected().count)" }] + extra + [
            pg("Глубина", pn("pStart", "Начальная глубина", 0), pn("pFin", type == "vcarve" ? "Предельная глубина" : "Конечная глубина", (type == "profile" || type == "drill") ? th : (type == "vcarve" ? 5 : 3)), pn("pTol", "Точность", 0.01)),
            pg("Станок", pnote { "Безопасная Z: \(f2($0.doc.material.safeZ)) мм\nТочка «дом»: X\(f2($0.doc.material.homeX)) Y\(f2($0.doc.material.homeY)) Z\(f2($0.doc.material.homeZ))" }, pbtns(pb("Материал…") { $0.ui.dialog("material") })),
            pg("Инструмент", pnote { ctx in (ctx.state["tool"] as? ToolDef).map { t in "\(t.name)\n№\(t.num), D \(f2(t.dia)) мм\(t.type == "vbit" ? ", \(f2(t.angle))°" : ""), шаг \(f2(t.stepdown)) мм, \(t.spindle) об/мин, подача \(f2(t.feed)) \(t.units == "mm/min" ? "мм/мин" : "мм/с")" } ?? "не выбран" },
                pbtns(pb("Выбрать…") { $0.ui.dialog("toolSelect", $0) }, pb("Изменить…") { ctx in if let t = ctx.state["tool"] as? ToolDef { ctx.ui.dialog("toolEdit", t) } })),
            pg("Порядок обработки", pradio("seq", [("optimise", "Авто (оптимально)"), ("order", "Как выбраны / нарисованы")], "optimise")),
            ptxt("pName", "Имя траектории", defName),
            pbtns(pb(c.state["rec"] != nil ? "Пересчитать" : "Рассчитать", true) { tpCalc(type, $0) }), pnote { $0.info["tp"] ?? "" }]
    }
    private static func tpOpen(_ type: String, _ c: PageCtx) {
        let rec = c.arg as? ToolpathRec
        if let rec = rec { c.state["rec"] = rec; c.state["tool"] = rec.tool; c.doc.selClear(); rec.srcIds.forEach { id in if c.doc.byId(id) != nil { c.doc.selAdd(id) } }; let p = rec.params
            c.set("pStart", p.start); c.set("pFin", p.finish); c.set("pTol", p.tol); c.values["seq"] = p.sequencing; c.values["side"] = p.side; c.set("allow", p.allowance); c.set("climb", p.climb)
            c.set("tbOn", p.tabs.on); c.values["tbMode"] = p.tabs.mode; c.set("tbN", Double(p.tabs.n)); c.set("tbD", p.tabs.dist); c.set("tbL", p.tabs.len); c.set("tbH", p.tabs.h)
            c.set("rpOn", p.ramp.on); c.set("rpL", p.ramp.len); c.values["strat"] = p.strategy; c.values["rang"] = String(p.rasterAngle); c.set("lastP", p.lastProfile); c.set("aso", p.stepover); c.set("vso", p.stepover > 0 ? p.stepover : 0.2)
            c.set("vang", p.vangle); c.set("peck", p.peck); c.set("retr", p.retract); c.values["pName"] = rec.name }
        else {
            let pref: ToolDef? = type == "vcarve" ? c.doc.tools.first { $0.type == "vbit" } : (type == "drill" ? c.doc.tools.first { $0.type == "drill" } : nil)
            c.state["tool"] = pref ?? c.doc.lastTool ?? c.doc.tools.first
        }
        if let t = c.state["tool"] as? ToolDef, type == "vcarve" && rec == nil { c.set("vang", t.angle) }
    }
    private static func tpParams(_ type: String, _ c: PageCtx) -> TpParams {
        let r = c.state["rec"] as? ToolpathRec
        let pts: [P] = r.map { $0.params.tabs.mode == "manual" ? $0.params.tabs.points : $0.result.tabMarks } ?? []
        let seq = c.str("seq").isEmpty ? "optimise" : c.str("seq"), side = c.str("side").isEmpty ? "outside" : c.str("side")
        return TpParams(c.num("pStart"), c.num("pFin"), max(0.001, c.num("pTol")), c.doc.material.safeZ, seq, side, c.num("allow"), c.values["climb"] != "0",
            Tabs(c.chk("tbOn"), c.str("tbMode").isEmpty ? "count" : c.str("tbMode"), c.int("tbN"), c.num("tbD"), c.num("tbL"), min(c.num("tbH"), c.num("pFin") - c.num("pStart")), pts),
            Ramp(c.chk("rpOn"), max(1, c.num("rpL"))), c.str("strat").isEmpty ? "offset" : c.str("strat"), Int(c.str("rang")) ?? 0, c.values["lastP"] != "0",
            type == "vcarve" ? max(0.02, c.num("vso")) : c.num("aso"), c.num("peck"), c.num("retr"), c.num("vang") <= 0 ? 90 : c.num("vang"), "")
    }
    private static func tpCalc(_ type: String, _ c: PageCtx) {
        let src = c.doc.selected(); if src.isEmpty { c.ui.toast("Выберите векторы на чертеже"); return }
        guard let tool = c.state["tool"] as? ToolDef else { c.ui.toast("Выберите инструмент"); return }
        if c.num("pFin") <= c.num("pStart") { c.ui.toast("Конечная глубина должна быть больше начальной"); return }
        guard let rec = c.doc.computeToolpath(type, src, tpParams(type, c), tool, c.str("pName").isEmpty ? type : c.str("pName"), (c.state["rec"] as? ToolpathRec)?.id) else {
            c.info["tp"] = "Траектория пустая — проверьте векторы и диаметр фрезы."; c.bump(); return }
        c.state["rec"] = rec; c.doc.lastTool = tool; let s = Toolpath.summary(rec.result.moves)
        c.info["tp"] = "✓ Рассчитано: \(type == "drill" ? "отверстий" : "контуров") \(rec.result.chains.count)\nДлина реза \(f2(s.cut / 1000)) м, врезок \(s.plunges), время ≈ \(Int(ceil(s.minutes))) мин"; c.bump()
    }
    private static func manualTabs(_ c: PageCtx) {
        guard let rec = c.state["rec"] as? ToolpathRec else { c.ui.toast("Сначала рассчитайте траекторию"); return }
        c.set("tbOn", true); c.values["tbMode"] = "manual"
        if rec.params.tabs.mode != "manual" { rec.params.tabs.on = true; rec.params.tabs.mode = "manual"; rec.params.tabs.points = rec.result.tabMarks }
        c.ui.toast("Касайтесь линии траектории: добавить мостик; рядом с меткой — убрать")
        let t = FnTool { x, y, tol in
            guard let r = c.state["rec"] as? ToolpathRec else { return true }
            if let i = r.params.tabs.points.firstIndex(where: { hypot($0.x - x, $0.y - y) < max(tol, r.tool.dia) }) { r.params.tabs.points.remove(at: i) }
            else { var best = Double.greatestFiniteMagnitude; for ch in r.result.chains { for k in 1..<max(1, ch.pts.count) { best = min(best, Geom.distSeg(x, y, ch.pts[k - 1], ch.pts[k])) } }; if best > max(tol, r.tool.dia / 2 + 3) { return true }; r.params.tabs.points.append(P(x, y)) }
            let ids = Set(r.srcIds); let src = c.doc.paths.filter { ids.contains($0.id) }
            if let n = c.doc.computeToolpath(r.type, src, r.params, r.tool, r.name, r.id) { c.state["rec"] = n }; c.bump(); return true
        }
        t.hintFn = { "Касание линии — мостик; касание метки — убрать" }
        c.ui.setTool(t)
    }

    // ---------- имитация ----------
    struct SimSeg { let a: P; let b: P; let d: Double; let w: Double }
    final class SimTool: CanvasTool {
        let c: PageCtx; var segs: [SimSeg] = []; var k = 0; var play = false
        private var sorted: [SimSeg] = []; private var sortedK = -1
        init(_ c: PageCtx) {
            self.c = c
            for tp in c.doc.toolpaths where tp.show { let v = tp.type == "vcarve" || tp.tool.type == "vbit"; let ang = (tp.type == "vcarve" ? tp.params.vangle : tp.tool.angle) * .pi / 360; var prev: Move? = nil
                for m in tp.result.moves { if let p0 = prev, !m.r && (m.z < 0 || p0.z < 0) { let d = -min(m.z, p0.z); segs.append(SimSeg(a: P(p0.x, p0.y), b: P(m.x, m.y), d: d, w: v ? max(0.15, 2 * d * tan(ang)) : tp.tool.dia)) }; prev = m } }
        }
        /// вызывается экраном каждый кадр; true — нужно перерисовать
        func tick() -> Bool { if !play { return false }; k = min(segs.count, k + max(1, c.int("simSpd"))); if k >= segs.count { play = false }; return true }
        func down(_ x: Double, _ y: Double, _ tol: Double) -> Bool { false }
        func overlay() -> [Ov] {
            let th = c.doc.material.thickness; let m = c.doc.model; var out: [Ov] = [.fill(x1: m.x0, y1: m.y0, x2: m.x0 + m.w, y2: m.y0 + m.h, color: 0xFFECCF9F)]
            func col(_ d: Double) -> UInt32 { if d >= th - 0.01 { return 0xFF2B2B2B }; let t = min(1, d / th); let r = UInt32(226 - 140 * t), g = UInt32(190 - 125 * t), b = UInt32(140 - 100 * t); return 0xFF000000 | (r << 16) | (g << 8) | b }
            if sortedK != k { sorted = Array(segs[0..<k]).enumerated().sorted { $0.element.d != $1.element.d ? $0.element.d < $1.element.d : $0.offset < $1.offset }.map { $0.element }; sortedK = k }
            for s in sorted { out.append(.thick(a: s.a, b: s.b, color: col(s.d), wMm: s.w)) }
            if k >= 1 && k <= segs.count { out.append(.mark(p: segs[k - 1].b, kind: "dot", color: 0xFFDD0000)) }
            return out
        }
    }
}

/// Огибающая: рамка из 4 кривых Безье (сетка Кунса) или вписывание вдоль кривых
final class EnvelopeTool: CanvasTool {
    let c: PageCtx; let src: [VPath]
    private let bb: BBox
    final class Env { var B: [P], T: [P], L: [P], R: [P]; init(_ B: [P], _ T: [P], _ L: [P], _ R: [P]) { self.B = B; self.T = T; self.L = L; self.R = R } }
    private var envs: [(Double, Double) -> P] = []
    private var bez: Env? = nil
    private var drag: (Character, Int)? = nil; private var moveFrom: P? = nil
    var curves: [String: String] = [:]
    init(_ c: PageCtx, _ src: [VPath]) { self.c = c; self.src = src; bb = Geom.bbox(src); bez = rectEnv(); rebuild() }
    private func th(_ a: P, _ b: P, _ k: Double) -> P { P(a.x + (b.x - a.x) * k, a.y + (b.y - a.y) * k) }
    private func rectEnv() -> Env { let BL = P(bb.x1, bb.y1), BR = P(bb.x2, bb.y1), TR = P(bb.x2, bb.y2), TL = P(bb.x1, bb.y2)
        return Env([BL, th(BL, BR, 1.0 / 3), th(BL, BR, 2.0 / 3), BR], [TL, th(TL, TR, 1.0 / 3), th(TL, TR, 2.0 / 3), TR], [BL, th(BL, TL, 1.0 / 3), th(BL, TL, 2.0 / 3), TL], [BR, th(BR, TR, 1.0 / 3), th(BR, TR, 2.0 / 3), TR]) }
    private func bezF(_ q: [P]) -> (Double) -> P { let s = BezSeg(q[1].x, q[1].y, q[2].x, q[2].y, q[3].x, q[3].y); let a = q[0]; return { u in Geom.bezPt(a, s, u) } }
    private func polyF(_ f: [P]) -> (Double) -> P { let L = Geom.polyLen(f); return { u in let p = Geom.pointAt(f, u * L); return P(p[0], p[1]) } }
    private func lineF(_ a: P, _ b: P) -> (Double) -> P { { u in P(a.x + (b.x - a.x) * u, a.y + (b.y - a.y) * u) } }
    private func coons(_ B: @escaping (Double) -> P, _ T: @escaping (Double) -> P, _ L: @escaping (Double) -> P, _ R: @escaping (Double) -> P) -> (Double, Double) -> P {
        let B0 = B(0), B1 = B(1), T0 = T(0), T1 = T(1)
        return { u, w in let b = B(u), t = T(u), l = L(w), r = R(w)
            return P((1 - w) * b.x + w * t.x + (1 - u) * l.x + u * r.x - ((1 - u) * (1 - w) * B0.x + u * (1 - w) * B1.x + (1 - u) * w * T0.x + u * w * T1.x),
                     (1 - w) * b.y + w * t.y + (1 - u) * l.y + u * r.y - ((1 - u) * (1 - w) * B0.y + u * (1 - w) * B1.y + (1 - u) * w * T0.y + u * w * T1.y)) }
    }
    private func rebuild() { if let e = bez { envs = [coons(bezF(e.B), bezF(e.T), bezF(e.L), bezF(e.R))] } }
    private func mapPaths(_ P2: (Double, Double) -> P) -> [VPath] { src.map { p in
        let f = Geom.flatten(p, 0.02); var dense: [P] = [f[0]]; let maxL = max(bb.w, bb.h) / 200
        for i in 1..<f.count { let d = hypot(f[i].x - f[i - 1].x, f[i].y - f[i - 1].y); let n = max(1, Int(ceil(d / maxL))); for k in 1...n { dense.append(th(f[i - 1], f[i], Double(k) / Double(n))) } }
        var pts = dense.map { P2(($0.x - bb.x1) / (bb.w == 0 ? 1 : bb.w), ($0.y - bb.y1) / (bb.h == 0 ? 1 : bb.h)) }; if p.closed { pts.removeLast() }
        let r = Geom.makePath(pts, p.closed, p.layer); r.group = p.group; return r
    } }
    func apply() {
        if !c.chk("euse") { bez = rectEnv(); rebuild(); return }
        func sub(_ f: [P], _ s0: Double, _ s1: Double) -> [P] { let n = max(8, Int(Double(f.count) * (s1 - s0) / Geom.polyLen(f)) + 8); return (0...n).map { let p = Geom.pointAt(f, s0 + (s1 - s0) * Double($0) / Double(n)); return P(p[0], p[1]) } }
        func offs(_ pts: [P], _ d: Double) -> [P] { pts.enumerated().map { (i, p) in let a = pts[max(0, i - 1)], b = pts[min(pts.count - 1, i + 1)]; let tx = b.x - a.x, ty = b.y - a.y; var l = hypot(tx, ty); if l == 0 { l = 1 }; return P(p.x - ty / l * d, p.y + tx / l * d) } }
        func mk(_ bot: [P], _ top: [P]) -> (Double, Double) -> P { coons(polyF(bot), polyF(top), lineF(bot.first!, top.first!), lineF(bot.last!, top.last!)) }
        let copies = c.str("ecopy")
        bez = nil
        if c.str("ecm") == "one" {
            guard let cv = curves["one"].flatMap({ c.doc.byId($0) }) else { c.ui.toast("Укажите кривую"); return }
            let f = Geom.flatten(cv); let L = Geom.polyLen(f); let w = c.chk("ewon") ? c.num("ew") : bb.h
            let n = copies == "one" ? 1 : (copies == "n" ? max(1, c.int("en")) : max(1, Int(floor(L / (bb.w * w / (bb.h == 0 ? 1 : bb.h))))))
            let side = c.str("eside")
            envs = (0..<n).map { k in let base = sub(f, L * Double(k) / Double(n), L * Double(k + 1) / Double(n))
                let bot = side == "left" ? base : (side == "right" ? offs(base, -w) : offs(base, -w / 2)); let top = side == "left" ? offs(base, w) : (side == "right" ? base : offs(base, w / 2)); return mk(bot, top) }
        } else {
            guard let tp = curves["top"].flatMap({ c.doc.byId($0) }), let bt = curves["bot"].flatMap({ c.doc.byId($0) }) else { c.ui.toast("Укажите верхнюю и нижнюю кривые"); return }
            let ft = Geom.flatten(tp), fb = Geom.flatten(bt); let Lt = Geom.polyLen(ft), Lb = Geom.polyLen(fb); var w = Geom.bbox(tp).cy - Geom.bbox(bt).cy; if w == 0 { w = bb.h }
            let n = copies == "one" ? 1 : (copies == "n" ? max(1, c.int("en")) : max(1, Int(floor(Lb / (bb.w * abs(w) / (bb.h == 0 ? 1 : bb.h))))))
            envs = (0..<n).map { k in mk(sub(fb, Lb * Double(k) / Double(n), Lb * Double(k + 1) / Double(n)), sub(ft, Lt * Double(k) / Double(n), Lt * Double(k + 1) / Double(n))) }
        }
    }
    func finish() {
        var out: [VPath] = []; for (k, e) in envs.enumerated() { for p in mapPaths(e) { if envs.count > 1, let g = p.group { p.group = g + "_" + String(k) }; out.append(p) } }
        c.doc.replace(src, out)
    }
    private func handles() -> [(Character, Int, P)] { guard let e = bez else { return [] }; var h: [(Character, Int, P)] = []; for (k, a) in [("B" as Character, e.B), ("T", e.T), ("L", e.L), ("R", e.R)] { for (i, q) in a.enumerated() { h.append((k, i, q)) } }; return h }
    private func getArr(_ k: Character) -> [P] { let e = bez!; switch k { case "B": return e.B; case "T": return e.T; case "L": return e.L; default: return e.R } }
    private func setArr(_ k: Character, _ v: [P]) { let e = bez!; switch k { case "B": e.B = v; case "T": e.T = v; case "L": e.L = v; default: e.R = v } }
    func down(_ x: Double, _ y: Double, _ tol: Double) -> Bool {
        if let pk = c.state["pick"] as? String {
            let p = c.doc.paths.filter { q in !src.contains { $0 === q } && c.doc.visible(q) }.min { Geom.distToPath($0, x, y) < Geom.distToPath($1, x, y) }
            if let p = p, Geom.distToPath(p, x, y) <= tol { curves[pk] = p.id; c.state["pick"] = nil; c.values["euse"] = "1"; c.bump() }; return true }
        if bez == nil { return true }
        if c.str("emode") == "move" { moveFrom = P(x, y); return true }
        for (k, i, q) in handles() where hypot(q.x - x, q.y - y) <= tol { drag = (k, i); return true }
        return true
    }
    func move(_ x: Double, _ y: Double) -> Bool {
        guard let e = bez else { return false }
        if let m = moveFrom { let dx = x - m.x, dy = y - m.y; for k: Character in ["B", "T", "L", "R"] { setArr(k, getArr(k).map { P($0.x + dx, $0.y + dy) }) }; _ = e; moveFrom = P(x, y); rebuild(); return true }
        guard let (k, i) = drag else { return false }
        var a = getArr(k); let old = a[i]; let dx = x - old.x, dy = y - old.y; a[i] = P(x, y)
        if i == 0 || i == 3 { // угол общий для двух рёбер
            setArr(k, a)
            for kk: Character in ["B", "T", "L", "R"] { var aa = getArr(kk); for j in [0, 3] where (kk != k || j != i) && abs(aa[j].x - old.x) < 1e-9 && abs(aa[j].y - old.y) < 1e-9 { aa[j] = P(x, y) }; setArr(kk, aa) }
            a = getArr(k); let ci = i == 0 ? 1 : 2; a[ci] = P(a[ci].x + dx, a[ci].y + dy)
        }
        setArr(k, a)
        rebuild(); return true
    }
    func up() { drag = nil; moveFrom = nil }
    func overlay() -> [Ov] {
        var out: [Ov] = []
        for P2 in envs { for k in 0...8 { out.append(.poly(pts: (0...30).map { P2(Double(k) / 8, Double($0) / 30) }, color: 0xFFB0B0B0, width: 1)); out.append(.poly(pts: (0...30).map { P2(Double($0) / 30, Double(k) / 8) }, color: 0xFFB0B0B0, width: 1)) }
            out.append(.paths(paths: mapPaths(P2), color: 0xFF2040D0)) }
        if let e = bez { for a in [e.B, e.T, e.L, e.R] { out.append(.poly(pts: [a[0], a[1]], color: 0xFF888888, width: 1)); out.append(.poly(pts: [a[3], a[2]], color: 0xFF888888, width: 1)) } }
        for (_, i, q) in handles() { out.append(.mark(p: q, kind: (i == 0 || i == 3) ? "box" : "dot", color: 0xFF2A62B8)) }
        for (k, id) in curves { if let p = c.doc.byId(id) { let f = Geom.flatten(p, 0.2); out.append(.poly(pts: f, color: k == "one" ? 0xFFE07000 : (k == "top" ? 0xFFC0007A : 0xFF0A8A8A), width: 2.5)); out.append(.mark(p: f[0], kind: "box", color: 0xFF19B23B)) } }
        return out
    }
    var hint: String { c.state["pick"] != nil ? "Коснитесь кривой" : "Тяните узлы огибающей" }
}
