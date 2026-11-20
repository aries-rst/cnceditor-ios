/* Экран редактора: меню, кнопки вида, панель (Проект / Помощник / Траектории), страницы инструментов. Порт Panels.kt */
import SwiftUI

let BLUE = Color(argb: 0xFF2A62B8), PANEL = Color(argb: 0xFFECEFF3), HEAD = Color(argb: 0xFFD5DBE3), PINK = Color(argb: 0xFFE0006A)

/// подписи иконок
let TITLES: [String: String] = ["new": "Новая модель", "open": "Открыть (DXF, SVG, проект)", "save": "Сохранить (DXF)", "importv": "Импорт векторов в модель (DXF, SVG)", "image": "Импорт картинки / фото с камеры", "undo": "Отменить", "redo": "Повторить", "cut": "Вырезать", "copy": "Копировать", "paste": "Вставить", "modelSize": "Размер модели", "modelPos": "Положение нуля модели", "select": "Выбор векторов", "node": "Редактирование узлов", "transform": "Трансформирование", "polyline": "Полилиния", "rect": "Прямоугольник", "circle": "Окружность", "ellipse": "Эллипс", "polygon": "Многоугольник", "star": "Звезда", "arc": "Дуга", "text": "Векторный текст", "textCurve": "Текст по кривой", "multiplate": "Multi-Plate — таблички на листе", "envelope": "Огибающая (искажение)", "pasteCurve": "Вставить вдоль кривой", "fitArcs": "Дуги вместо кривых Безье", "clip": "Обрезка по контуру (Clipping)", "slice": "Рассечь векторы", "measure": "Измерение", "offset": "Смещение векторов (offset)", "mirror": "Зеркальное отражение", "blockcopy": "Копирование блоком / по кругу", "fillet": "Скругление углов / продление до пересечения", "trim": "Обрезка по пересечениям (ножницы)", "doctor": "Доктор векторов", "nest": "Раскрой (Nesting)", "trace": "Векторизация картинки", "alignL": "Выровнять по левому краю", "alignR": "Выровнять по правому краю", "alignT": "Выровнять по верху", "alignB": "Выровнять по низу", "centerV": "Центрировать по вертикальной оси", "centerH": "Центрировать по горизонтальной оси", "centerC": "Центрировать по центру", "centerPage": "По центру листа", "group": "Группировать", "ungroup": "Разгруппировать", "weld": "Объединить (Weld)", "intersect": "Пересечение", "subtract": "Вычесть (последний выбранный)", "xor": "Исключить общую часть", "closeLine": "Замкнуть линией", "closeCurve": "Замкнуть кривой", "closeMove": "Замкнуть сдвигом конца", "joinLine": "Соединить линией", "joinCurve": "Соединить кривой", "joinMove": "Соединить сдвигом концов", "joinCoinc": "Соединить совпадающие точки", "reverse": "Обратить направление", "del": "Удалить",
    "material": "Настройка материала", "tooldb": "База инструментов", "savetp": "Сохранить траектории (УП)", "profile": "Обработка по профилю", "machine": "Обработка вдоль векторов", "area": "Выборка области", "vbit": "V-гравировка", "drill": "Сверление", "sim": "Имитация обработки", "zoomFit": "Показать всю модель", "grid": "Сетка", "multi": "Добавлять к выбору", "layers": "Слои", "zoomIn": "Приблизить", "zoomOut": "Отдалить"]
private let ICON_OF = ["importv": "open"]
func iconOf(_ k: String) -> String { ICON_OF[k] ?? k }

let SECTIONS: [(String, String, [[String]])] = [
    ("info", "Информация о модели", []),
    ("file", "Файл", [["new"], ["open"], ["save"], ["importv"], ["image"], ["undo"], ["redo"], ["cut"], ["copy"], ["paste"]]),
    ("model", "Модель", [["modelSize", "modelPos"]]),
    ("vec", "Векторные инструменты", [["select"], ["node"], ["transform"], ["rect", "polyline", "circle", "ellipse", "polygon", "star", "arc"], ["text", "textCurve"], ["trace"], ["measure"], ["doctor"], ["multiplate"], ["envelope"], ["blockcopy"], ["pasteCurve"], ["fitArcs"], ["fillet"], ["trim"], ["offset"], ["mirror"]]),
    ("pos", "Позиция, объединение, обрезка", [["alignL", "alignR", "alignT", "alignB", "centerV", "centerH", "centerC", "centerPage"], ["nest"], ["group", "ungroup"], ["weld", "subtract", "intersect", "xor"], ["closeLine", "closeCurve", "closeMove", "joinLine", "joinCurve", "joinMove", "joinCoinc"], ["clip"], ["slice"], ["reverse"], ["del"]]),
]

// ---------------- меню ----------------
func mainMenu(_ s: AppState, _ onHome: @escaping () -> Void) -> [(String, [MI])] {
    let d = s.doc
    func I(_ l: String, _ a: @escaping () -> Void) -> MI { .item(l, a) }
    func C(_ l: String, _ k: String) -> MI { .item(l) { s.cmd(k) } }
    var help: [MI] = [I("Инструкция") { s.dialog("help", nil) }, I("Премиум") { s.dialog("premium", nil) }, I("Язык") { s.dialog("lang", nil) }, I("О программе") { s.dialog("about", nil) }]
    if AdManager.privacyRequired() { help.append(I("Настройки конфиденциальности") { AdManager.showPrivacy() }) }
    return [
        ("Файл", [I("Новая модель…") { s.cmd("new") }, I("Открыть… (DXF, SVG, G-код, проект)") { s.openFile() }, I("Закрыть модель") { onHome() }, .sep,
            I("Сохранить (DXF)") { s.saveDxf(false) }, I("Поделиться (DXF)…") { s.shareDxf() }, .sub("Сохранить как", [I("DXF (R12)…") { s.saveDxf(true) }, I("SVG (для Inkscape)…") { s.exportSvg() }, I("Проект (.cnc2d)…") { s.saveText(d.baseName() + ".cnc2d", d.projectJSON()) }]),
            .sub("Экспорт", [I("PDF 1:1…") { s.exportPdf() }, I("PNG…") { s.dialog("raster", "png") }, I("JPG…") { s.dialog("raster", "jpg") }]), .sep,
            I("Импорт картинки / фото…") { s.cmd("image") }]),
        ("Правка", [C("Отменить", "undo"), C("Повторить", "redo"), .sep, C("Вырезать", "cut"), C("Копировать", "copy"), C("Вставить", "paste"), C("Удалить", "del"), .sep,
            I("Выбрать всё") { d.selectAll() }, I("Снять выбор") { d.clearSel(); s.select.stickyMulti = false }, I("Список выбранных") { s.dialog("selList", nil) }, .sep, I("Редактировать фигуру / текст") { s.editSelected() }, C("Слои…", "layers")]),
        ("Модель", [I("Размер модели…") { s.openPage("modelSize", nil) }, I("Положение нуля…") { s.openPage("modelPos", nil) }, I("Подложка (картинка)…") { s.openPage("image", nil) }]),
        ("Векторы", [I("Импорт векторов… (DXF, SVG, G-код)") { s.importVectors() }, I("Экспорт выбранных в DXF…") { s.exportSelDxf() }, .sep,
            .sub("Замкнуть вектор", [C("Линией", "closeLine"), C("Кривой", "closeCurve"), C("Сдвигом конца", "closeMove")]),
            .sub("Соединить векторы", [C("Линией", "joinLine"), C("Кривой", "joinCurve"), C("Сдвигом концов", "joinMove"), C("Совпадающие точки…", "joinCoinc")]),
            .sub("Выровнять векторы", [C("По левому краю", "alignL"), C("По правому краю", "alignR"), C("По верху", "alignT"), C("По низу", "alignB"), .sep, C("Центр по вертикали", "centerV"), C("Центр по горизонтали", "centerH"), C("По центру", "centerC"), C("По центру листа", "centerPage")]),
            .sub("Объединить векторы", [C("Weld — объединить", "weld"), C("Пересечение", "intersect"), C("Вычесть", "subtract"), C("Исключить общую часть", "xor")]),
            C("Группировать", "group"), C("Разгруппировать", "ungroup"), .sep,
            C("Трансформировать…", "transform"), C("Отразить…", "mirror"), C("Смещение…", "offset"), C("Копировать блоком…", "blockcopy"), C("Раскрой (Nesting)…", "nest"), C("Multi-Plate…", "multiplate"),
            C("Текст…", "text"), C("Текст по кривой…", "textCurve"), C("Огибающая…", "envelope"), .sep, C("Доктор векторов…", "doctor"), C("Дуги вместо Безье…", "fitArcs"), C("Обрезка (Clipping)…", "clip"), C("Рассечь…", "slice"), C("Скругление…", "fillet"), C("Ножницы…", "trim"), C("Рамка вокруг…", "border"), C("Преобразовать…", "convert"),
            C("Обратить направление", "reverse"), I("Заблокировать") { d.push(); d.selected().forEach { $0.locked = true }; d.changed() }, I("Разблокировать") { d.push(); d.paths.forEach { $0.locked = false }; d.changed() }, I("Свойства…") { s.dialog("props", nil) }]),
        ("Траектории", [I("Сохранить траектории как…") { s.dialog("saveTp", nil) }, .sep, I("Настройка материала…") { s.dialog("material", nil) }, I("База инструментов…") { s.dialog("toolDb", nil) }, .sep,
            C("Профиль…", "profile"), C("Вдоль векторов…", "machine"), C("Выборка области…", "area"), C("V-гравировка…", "vbit"), C("Сверление…", "drill"), C("Имитация…", "sim")]),
        ("Справка", help),
    ]
}

/// меню SwiftUI из списка MI (подменю — вложенные Menu)
struct MIList: View {
    let items: [MI]
    var body: some View {
        ForEach(Array(items.enumerated()), id: \.offset) { _, it in
            switch it {
            case .sep: Divider()
            case let .item(l, a): Button(tr(l), action: a)
            case let .sub(l, sub): Menu(tr(l)) { MIList(items: sub) }
            }
        }
    }
}

/// всплывающее меню у точки касания (долгое нажатие)
struct PopupMenu: View {
    @ObservedObject var s: AppState
    let at: CGPoint; let items: [MI]
    @State private var stack: [[MI]] = []
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.001).onTapGesture { s.longMenu = nil; s.bump() }
                let cur = stack.last ?? items
                VStack(alignment: .leading, spacing: 0) {
                    if stack.count > 0 { Button("← " + tr("Назад")) { stack.removeLast() }.foregroundColor(BLUE).padding(.horizontal, 14).padding(.vertical, 9) }
                    ForEach(Array(cur.enumerated()), id: \.offset) { _, it in
                        switch it {
                        case .sep: Divider()
                        case let .item(l, a): Button { s.longMenu = nil; a(); s.bump() } label: { Text(tr(l)).foregroundColor(.primary).frame(maxWidth: .infinity, alignment: .leading) }.padding(.horizontal, 14).padding(.vertical, 9)
                        case let .sub(l, sub): Button { stack.append(sub) } label: { Text(tr(l) + "  ▸").foregroundColor(.primary).frame(maxWidth: .infinity, alignment: .leading) }.padding(.horizontal, 14).padding(.vertical, 9)
                        }
                    }
                }
                .frame(width: 260).background(Color.white).cornerRadius(8).shadow(radius: 6)
                .offset(x: min(max(4, at.x), max(4, geo.size.width - 264)), y: min(max(4, at.y), max(4, geo.size.height - CGFloat((stack.last ?? items).count) * 38 - 20)))
            }
        }
    }
}

/// простой перенос элементов по строкам (FlowRow)
struct Flow: Layout {
    var spacing: CGFloat = 2
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity; var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, w: CGFloat = 0
        for v in subviews { let sz = v.sizeThatFits(.unspecified); if x > 0 && x + sz.width > maxW { y += rowH + spacing; x = 0; rowH = 0 }; x += sz.width + spacing; rowH = max(rowH, sz.height); w = max(w, x) }
        return CGSize(width: proposal.width ?? w, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rows: [[(Int, CGSize)]] = [[]]; var x: CGFloat = 0
        for (i, v) in subviews.enumerated() { let sz = v.sizeThatFits(.unspecified)
            if x > 0 && bounds.minX + x + sz.width > bounds.maxX { rows.append([]); x = 0 }
            rows[rows.count - 1].append((i, sz)); x += sz.width + spacing }
        var y = bounds.minY
        for r in rows { let rowH = r.map { $0.1.height }.max() ?? 0; var xx = bounds.minX
            for (i, sz) in r { subviews[i].place(at: CGPoint(x: xx, y: y + (rowH - sz.height) / 2), proposal: ProposedViewSize(sz)); xx += sz.width + spacing }
            y += rowH + spacing }
    }
}

// ---------------- экран редактора ----------------
struct EditorScreen: View {
    @ObservedObject var s: AppState
    let onHome: () -> Void
    var body: some View {
        let _ = s.tick
        GeometryReader { geo in
            let wide = geo.size.width >= 600 || geo.size.width > geo.size.height
            VStack(spacing: 0) {
                TopBars(s: s, onHome: onHome, land: geo.size.width > geo.size.height)
                if wide {
                    HStack(spacing: 0) {
                        if s.panelOpen { SidePanel(s: s).frame(width: 320) }
                        canvasBox
                    }
                } else {
                    VStack(spacing: 0) {
                        canvasBox
                        if s.panelOpen { SidePanel(s: s).frame(height: geo.size.height * 0.46) }
                    }
                }
                AdBanner()
            }.background(PANEL)
        }
    }
    private var canvasBox: some View {
        ZStack(alignment: .bottomLeading) {
            CanvasHost(s: s)
            HintBar(s: s)
            if let lm = s.longMenu { PopupMenu(s: s, at: lm.0, items: lm.1 == "node" ? nodeMenu(s) : vecMenu(s)) }
        }.clipped()
    }
}

func vecMenu(_ s: AppState) -> [MI] {
    let d = s.doc; let sel = d.selected(); let one = sel.count == 1 ? sel[0] : nil
    var l: [MI] = []
    if !sel.isEmpty && (sel[0].text != nil || one?.shape != nil) { l.append(.item("Редактировать фигуру / текст…") { s.editSelected() }) }
    l += [.item("Трансформировать…") { s.openPage("transform", nil) }, .item("Редактировать узлы") { s.mode = "node"; s.bump() }, .sep,
          .item("Копировать") { d.copy() }, .item("Вырезать") { d.cut() }, .item("Удалить") { d.del() }, .sep,
          .item("Группировать") { s.cmd("group") }, .item("Разгруппировать") { s.cmd("ungroup") }, .sub("На слой", d.layers.enumerated().map { (i, ly) in MI.item(ly.name) { d.moveToLayer(i) } }), .sep,
          .item(one != nil && one!.closed ? (Geom.isClockwise(one!) ? "Сделать против часовой" : "Сделать по часовой") : "Обратить направление") { s.cmd("reverse") },
          .item(sel.contains { $0.locked } ? "Разблокировать" : "Заблокировать") { let v = !sel.contains { $0.locked }; d.push(); sel.forEach { $0.locked = v }; d.changed() },
          .item("Список выбранных") { s.dialog("selList", nil) }, .item("Свойства…") { s.dialog("props", nil) }]
    return l
}
func nodeMenu(_ s: AppState) -> [MI] {
    let n = s.node
    func A(_ l: String, _ a: String) -> MI { .item(l) { if let e = n.action(a) { s.toast(e) }; s.bump() } }
    if n.selNode != nil { return [A("Удалить точку", "delpt"), A("Сгладить точку", "smooth"), A("Сделать начальной", "start"), .item("Координаты точки…") { s.dialog("nodeXY", nil) }] }
    if n.selSeg != nil { return [A("Участок → в линию", "line"), A("Участок → в дугу", "arc"), A("Участок → в кривую Безье", "bez"), A("Вставить точку", "insert"), A("Вставить начальную точку", "insertStart"), A("Удалить участок (разрезать)", "remove")] }
    return [.item("Коснитесь точки или участка") {}]
}

/// меню + кнопки вида; в книжной — две полосы
struct TopBars: View {
    @ObservedObject var s: AppState
    let onHome: () -> Void; let land: Bool
    var body: some View {
        let _ = s.tick
        if land {
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 0) { menus; VSep(); ViewButtons(s: s) } }.background(Color.white)
        } else {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 0) { menus } }.background(Color.white)
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 0) { ViewButtons(s: s) }.padding(.horizontal, 2) }.background(Color(argb: 0xFFF7F8FA))
            }
        }
    }
    private var menus: some View {
        HStack(spacing: 0) {
            Button(action: onHome) { Image(systemName: "house").foregroundColor(BLUE).frame(width: 40, height: 40) }
            ForEach(Array(mainMenu(s, onHome).enumerated()), id: \.offset) { _, m in
                Menu { MIList(items: m.1) } label: { Text(tr(m.0)).font(.system(size: 14)).foregroundColor(Color(argb: 0xFF222222)).lineLimit(1).padding(.horizontal, 7).frame(height: 40) }
            }
        }
    }
}

struct ViewButtons: View {
    @ObservedObject var s: AppState
    var body: some View {
        HStack(spacing: 0) {
            Button { s.panelOpen.toggle(); s.bump() } label: { Image(systemName: "sidebar.left").foregroundColor(s.panelOpen ? BLUE : .gray).frame(width: 40, height: 40) }
            VBtn(s: s, k: "zoomFit") { s.fit() }
            VBtn(s: s, k: "zoomIn") { s.zoomAt(1.4, CGPoint(x: s.cw / 2, y: s.ch / 2)); s.bump() }
            VBtn(s: s, k: "zoomOut") { s.zoomAt(1 / 1.4, CGPoint(x: s.cw / 2, y: s.ch / 2)); s.bump() }
            VBtn(s: s, k: "grid", on: s.showGrid) { s.showGrid.toggle(); s.bump() }
            VBtn(s: s, k: "undo", dis: !s.doc.canUndo) { s.doc.undo() }
            VBtn(s: s, k: "redo", dis: !s.doc.canRedo) { s.doc.redo() }
            VBtn(s: s, k: "select", on: s.mode == "select" && s.pageTool == nil) { s.cmd("select") }
            VBtn(s: s, k: "node", on: s.mode == "node") { s.cmd("node") }
            VBtn(s: s, k: "multi", on: s.multi || s.select.stickyMulti) { if s.select.stickyMulti { s.select.stickyMulti = false; s.multi = false; s.bump() } else { s.cmd("multi") } }
            Button { s.toggleOrientation() } label: { Image(systemName: "rotate.right").foregroundColor(Color(argb: 0xFF555555)).frame(width: 40, height: 40) }
            Menu { MIList(items: selectMenu()) } label: { HStack(spacing: 2) { Text(tr("Выбрать")).font(.system(size: 13)).lineLimit(1); Image(systemName: "chevron.down").font(.system(size: 10)) }.padding(.horizontal, 6).frame(height: 40) }
            Menu { MIList(items: vecMenu(s)) } label: { Image(systemName: "ellipsis.circle").frame(width: 40, height: 40) }.disabled(s.doc.sel.isEmpty)
            if !s.doc.sel.isEmpty {
                Text(tr("Выбрано") + ": \(s.doc.sel.count)").font(.system(size: 13, weight: .bold)).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 4).background(PINK).cornerRadius(12).padding(.horizontal, 4)
                    .onTapGesture { s.dialog("selList", nil) }
            }
        }
    }
    private func selectMenu() -> [MI] {
        let d = s.doc
        return [.item("Выбрать всё") { d.selectAll() }, .item("Все на текущем слое") { d.selectWhere { $0.layer == d.active } }, .item("Замкнутые") { d.selectWhere { $0.closed } }, .item("Открытые") { d.selectWhere { !$0.closed } },
                .item("Похожие по размеру") { guard let p = d.selected().first else { s.toast("Сначала выберите образец"); return }; let b = Geom.bbox(p); let tol = max(0.5, max(b.w, b.h) * 0.02)
                    d.selectWhere { q in let c = Geom.bbox(q); return q.closed == p.closed && abs(c.w - b.w) <= tol && abs(c.h - b.h) <= tol }; s.toast("Выбрано похожих: \(d.sel.count)") },
                .item("Обратить выбор") { let old = Set(d.sel); d.selectWhere { !old.contains($0.id) } }, .item("Снять выбор") { d.clearSel(); s.select.stickyMulti = false }, .item("Список выбранных") { s.dialog("selList", nil) }]
    }
}
struct VBtn: View {
    @ObservedObject var s: AppState
    let k: String; var on = false; var dis = false; let act: () -> Void
    init(s: AppState, k: String, on: Bool = false, dis: Bool = false, _ act: @escaping () -> Void) { self.s = s; self.k = k; self.on = on; self.dis = dis; self.act = act }
    var body: some View {
        ToolIcon(iconOf(k), 26, dis).frame(width: 38, height: 38).background(on ? Color(argb: 0xFFCFE0F7) : Color.clear).cornerRadius(6).padding(1)
            .contentShape(Rectangle())
            .onTapGesture { if !dis { act(); s.bump() } }
            .onLongPressGesture { s.toast(TITLES[k] ?? k) }
    }
}
struct VSep: View { var body: some View { Rectangle().fill(Color(argb: 0xFFCCCCCC)).frame(width: 1, height: 28).padding(.horizontal, 3) } }

struct HintBar: View {
    @ObservedObject var s: AppState
    var body: some View {
        let pick = s.pick
        let hint = pick?.0 ?? (s.pageTool?.hint ?? (s.mode == "node" ? s.node.hint : ""))
        if !hint.isEmpty {
            HStack {
                Text(tr(hint)).font(.system(size: 12)).frame(maxWidth: .infinity, alignment: .leading)
                if pick != nil { Button(tr("Отмена")) { s.pick = nil; s.bump() } }
            }.padding(.horizontal, 8).padding(.vertical, 4).background(Color(argb: 0xDDFFFFF0))
        }
    }
}

// ---------------- панель ----------------
struct SidePanel: View {
    @ObservedObject var s: AppState
    var body: some View {
        let _ = s.tick
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach([("project", "Проект"), ("assist", "Помощник"), ("tp", "Траектории")], id: \.0) { (id, nm) in
                    VStack(spacing: 0) {
                        Text(tr(nm)).font(.system(size: 13, weight: s.tab == id ? .bold : .regular)).foregroundColor(s.tab == id ? BLUE : Color(argb: 0xFF444444)).lineLimit(1).minimumScaleFactor(0.7).padding(.vertical, 11)
                        Rectangle().fill(s.tab == id ? BLUE : Color.clear).frame(height: 3)
                    }.frame(maxWidth: .infinity).contentShape(Rectangle()).onTapGesture { s.tab = id; s.bump() }
                }
            }.background(HEAD)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch s.tab {
                    case "project": ProjectTab(s: s)
                    case "tp": if s.page?.id.hasPrefix("tp_") == true || s.page?.id == "sim" { PageView(s: s) } else { ToolpathsTab(s: s) }
                    default: if s.page != nil { PageView(s: s) } else { AssistTab(s: s) }
                    }
                }
            }
        }.background(PANEL).border(Color(argb: 0xFFBBC3CC), width: 1)
    }
}
enum SectionState { static var closed = Set<String>() }
struct SectionBox<Content: View>: View {
    @ObservedObject var s: AppState
    let title: String; @ViewBuilder let content: () -> Content
    var body: some View {
        let open = !SectionState.closed.contains(title)
        VStack(alignment: .leading, spacing: 0) {
            Text((open ? "▾ " : "▸ ") + tr(title)).font(.system(size: 14, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading).padding(8).background(HEAD).cornerRadius(4)
                .contentShape(Rectangle()).onTapGesture { if open { SectionState.closed.insert(title) } else { SectionState.closed.remove(title) }; s.bump() }
            if open { VStack(alignment: .leading, spacing: 2) { content() }.padding(6) }
        }.background(Color.white).cornerRadius(4).padding(4)
    }
}

struct AssistTab: View {
    @ObservedObject var s: AppState
    var body: some View {
        ForEach(SECTIONS, id: \.0) { (id, title, groups) in
            SectionBox(s: s, title: title) {
                if id == "info" { InfoBox(s: s) }
                else { Flow { ForEach(Array(groups.enumerated()), id: \.offset) { _, g in groupBtn(g) } } }
            }
        }
    }
    @ViewBuilder private func groupBtn(_ g: [String]) -> some View {
        let shown = g.count > 1 ? (Prefs.str("fly_" + g[0]) ?? g[0]) : g[0]
        if g.count > 1 {
            Menu {
                ForEach(g, id: \.self) { k in Button { Prefs.set("fly_" + g[0], k); s.cmd(k) } label: { Label { Text(tr(TITLES[k] ?? k)) } icon: { Image(uiImage: iconImage(iconOf(k))) } } }
            } label: { iconTile(shown, true) }
        } else {
            iconTile(shown, false).onTapGesture { s.cmd(shown) }.onLongPressGesture { s.toast(TITLES[shown] ?? shown) }
        }
    }
}
func iconTile(_ k: String, _ fly: Bool) -> some View {
    ZStack(alignment: .bottomTrailing) {
        ToolIcon(iconOf(k), 30).frame(width: 46, height: 46)
        if fly { Text("◢").font(.system(size: 8)).foregroundColor(.gray).padding(1) }
    }.frame(width: 46, height: 46).background(Color(argb: 0xFFF4F6F9)).cornerRadius(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(argb: 0xFFD0D6DE), lineWidth: 1)).padding(3).contentShape(Rectangle())
}
/// иконка для системного меню (растр)
func iconImage(_ name: String) -> UIImage {
    let r = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24))
    return r.image { c in
        let g = c.cgContext
        for (path, p) in IconCache.get(name) {
            let cg = path.cgPath
            if let f = p.fill { g.addPath(cg); g.setFillColor(UIColor(argb: f).cgColor); g.fillPath() }
            let st: UInt32? = p.stroke ?? (p.fill == nil ? 0xFF333333 : nil)
            if let st = st { g.addPath(cg); g.setStrokeColor(UIColor(argb: st).cgColor); g.setLineWidth(p.sw); g.setLineCap(.round); g.setLineJoin(.round); g.strokePath() }
        }
    }.withRenderingMode(.alwaysOriginal)
}

struct InfoBox: View {
    @ObservedObject var s: AppState
    var body: some View {
        let d = s.doc, m = d.model; let f = PageCtx.f2
        Text("\(tr("Модель")): X \(f(m.w)) × Y \(f(m.h)) \(tr("мм")), \(tr("материал")) \(f(d.material.thickness)) \(tr("мм"))\n\(tr("векторов")): \(d.paths.count), \(tr("траекторий")): \(d.toolpaths.count)").font(.system(size: 13))
        let sel = d.selected()
        if !sel.isEmpty {
            let b = Geom.bbox(sel); let kind = sel.allSatisfy { $0.closed } ? tr("замкнутые") : (sel.contains { $0.closed } ? tr("смешанные") : tr("открытые"))
            Text("\(tr("Выбрано")): \(sel.count) — \(f(b.w)) × \(f(b.h)) \(tr("мм")); \(kind)").font(.system(size: 13)).foregroundColor(PINK)
        }
    }
}

struct ProjectTab: View {
    @ObservedObject var s: AppState
    var body: some View {
        let d = s.doc
        SectionBox(s: s, title: "Информация о модели") { InfoBox(s: s) }
        SectionBox(s: s, title: "Слои") {
            ForEach(Array(d.layers.enumerated()), id: \.offset) { i, l in
                HStack {
                    Rectangle().fill(Color(argb: l.color)).frame(width: 14, height: 14)
                    Text(tr(l.name)).font(.system(size: 14)).frame(maxWidth: .infinity, alignment: .leading)
                    Button(l.visible ? "👁" : "—") { l.visible.toggle(); d.changed() }
                    Button(l.locked ? "🔒" : "🔓") { l.locked.toggle(); d.changed() }
                }.padding(4).background(i == d.active ? Color(argb: 0xFFDDE8F7) : Color.clear).contentShape(Rectangle()).onTapGesture { d.active = i; d.changed() }
            }
            HStack { Button("+ " + tr("Слой")) { d.addLayer(tr("Слой") + " \(d.layers.count + 1)") }; Button(tr("Слои…")) { s.dialog("layers", nil) } }
        }
        SectionBox(s: s, title: "Выбор") {
            Text(tr("Касание — выбрать вектор. Долгое нажатие на векторе — выбор нескольких (номера показывают порядок). Рамка: слева→направо — только целиком внутри, справа→налево — все касающиеся. Двумя пальцами — сдвиг и масштаб.")).font(.system(size: 12)).foregroundColor(.secondary)
            HStack { Button(tr("Добавлять к выбору") + (s.multi ? " ✓" : "")) { s.cmd("multi") }; Button(tr("Список выбранных")) { s.dialog("selList", nil) } }
        }
        if let im = d.image {
            SectionBox(s: s, title: "Подложка") {
                HStack { Toggle(tr("Показывать"), isOn: Binding(get: { im.visible }, set: { im.visible = $0; d.changed() })); Button(tr("Настроить…")) { s.openPage("image", nil) } }
            }
        }
    }
}

struct ToolpathsTab: View {
    @ObservedObject var s: AppState
    var body: some View {
        let d = s.doc
        SectionBox(s: s, title: "Траектории") {
            if d.toolpaths.isEmpty { Text(tr("Нет траекторий. Выберите векторы и нажмите «Профиль» или «Вдоль векторов».")).font(.system(size: 12)).foregroundColor(.secondary) }
            ForEach(Array(d.toolpaths.enumerated()), id: \.offset) { _, tp in
                HStack {
                    Rectangle().fill(Color(argb: tp.color)).frame(width: 12, height: 12)
                    VStack(alignment: .leading) { Text(tp.name).font(.system(size: 14)); Text("T\(tp.tool.num) \(tp.tool.name), \(PageCtx.f2(tp.params.finish)) мм").font(.system(size: 11)).foregroundColor(.gray) }.frame(maxWidth: .infinity, alignment: .leading)
                    Toggle("", isOn: Binding(get: { tp.show }, set: { tp.show = $0; s.bump() })).labelsHidden()
                }.padding(2).background(tp === s.selTp ? Color(argb: 0xFFDDE8F7) : Color.clear).contentShape(Rectangle())
                .onTapGesture { s.selTp = tp; d.selClear(); tp.srcIds.filter { d.byId($0) != nil }.forEach { d.selAdd($0) }; d.changed() }
            }
            Toggle(tr("Показывать траектории"), isOn: Binding(get: { s.showTp }, set: { s.showTp = $0; s.bump() })).font(.system(size: 13))
            if let tp = s.selTp {
                Flow {
                    OBtn(tr("Изменить…")) { s.openPage("tp_" + tp.type, tp); s.tab = "tp"; s.bump() }
                    OBtn(tr("Пересчитать")) { let ids = Set(tp.srcIds); let src = d.paths.filter { ids.contains($0.id) }; if src.isEmpty { s.toast("Исходные векторы удалены") } else { d.computeToolpath(tp.type, src, tp.params, tp.tool, tp.name, tp.id); s.toast("Пересчитано") } }
                    OBtn(tr("Удалить")) { d.toolpaths.removeAll { $0 === tp }; s.selTp = nil; d.changed() }
                }
            }
        }
        IconSection(s: s, title: "Операции с траекториями", keys: ["material", "tooldb", "savetp"])
        IconSection(s: s, title: "2D траектории", keys: ["profile", "machine", "area", "vbit", "drill"])
        IconSection(s: s, title: "Имитация обработки", keys: ["sim"])
    }
}
struct IconSection: View {
    @ObservedObject var s: AppState
    let title: String; let keys: [String]
    var body: some View {
        SectionBox(s: s, title: title) { Flow { ForEach(keys, id: \.self) { k in iconTile(k, false).onTapGesture { s.cmd(k) }.onLongPressGesture { s.toast(TITLES[k] ?? k) } } } }
    }
}
/// кнопка с рамкой / основная
struct OBtn: View {
    let label: String; var primary = false; let act: () -> Void
    init(_ label: String, primary: Bool = false, _ act: @escaping () -> Void) { self.label = label; self.primary = primary; self.act = act }
    var body: some View {
        Button(action: act) { Text(label).font(.system(size: 13)).padding(.horizontal, primary ? 12 : 10).padding(.vertical, 6).foregroundColor(primary ? .white : BLUE)
            .background(primary ? BLUE : Color.white).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(BLUE, lineWidth: primary ? 0 : 1)) }
        .buttonStyle(.plain).padding(2)
    }
}

// ---------------- страница инструмента ----------------
private let LIVE: Set<String> = ["rect", "circle", "ellipse", "polygon", "star"]

struct PageView: View {
    @ObservedObject var s: AppState
    var body: some View {
        if let sp = s.page, let c = s.pctx {
            HStack {
                Button { s.closePage() } label: { Image(systemName: "chevron.backward").frame(width: 36, height: 36) }
                ToolIcon(sp.icon, 28)
                Text(tr(sp.title)).font(.system(size: 15, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
                Button { s.closePage() } label: { Image(systemName: "xmark").frame(width: 36, height: 36) }
            }.padding(4).background(HEAD)
            if !sp.help.isEmpty { Text(tr(sp.help)).font(.system(size: 12)).foregroundColor(.secondary).padding(8) }
            VStack(alignment: .leading, spacing: 2) { FieldsView(s: s, sp: sp, c: c, fs: sp.fields(c)) }.padding(.horizontal, 6)
            Button(tr("Закрыть")) { s.closePage() }.frame(maxWidth: .infinity).padding(10).overlay(RoundedRectangle(cornerRadius: 18).stroke(BLUE)).padding(8)
        }
    }
}

struct FieldsView: View {
    @ObservedObject var s: AppState
    let sp: PageSpec; let c: PageCtx; let fs: [F]
    private func changed() { if LIVE.contains(sp.id) { Pages.liveUpdate(sp.id, c) }; c.version += 1; s.bump() }
    var body: some View {
        ForEach(Array(fs.enumerated()), id: \.offset) { _, f in field(f) }
    }
    @ViewBuilder private func field(_ f: F) -> some View {
        switch f {
        case let .num(key, label, _, unit, _):
            NumField(value: c.values[key] ?? "", label: tr(label), unit: unit, fid: sp.id + "|" + key) { v in c.values[key] = v; if v.replacingOccurrences(of: ",", with: ".").toDoubleOrNull() != nil { changed() } }
        case let .chk(key, label, _):
            HStack { Image(systemName: c.chk(key) ? "checkmark.square.fill" : "square").foregroundColor(c.chk(key) ? BLUE : .gray); Text(tr(label)).font(.system(size: 14)).frame(maxWidth: .infinity, alignment: .leading) }
                .padding(.vertical, 5).contentShape(Rectangle()).onTapGesture { c.set(key, !c.chk(key)); changed() }
        case let .radio(key, options, _):
            VStack(alignment: .leading, spacing: 0) { ForEach(options, id: \.0) { (v, l) in
                HStack { Image(systemName: c.str(key) == v ? "largecircle.fill.circle" : "circle").foregroundColor(c.str(key) == v ? BLUE : .gray); Text(tr(l)).font(.system(size: 14)).frame(maxWidth: .infinity, alignment: .leading) }
                    .padding(.vertical, 5).contentShape(Rectangle()).onTapGesture { c.values[key] = v; changed() } } }
        case let .select(key, label, options, _):
            HStack {
                Text(tr(label)).font(.system(size: 14)).frame(maxWidth: .infinity, alignment: .leading)
                Menu { ForEach(options, id: \.0) { (v, l) in Button(tr(l)) { c.values[key] = v; changed() } } } label: {
                    HStack(spacing: 2) { Text(tr(options.first { $0.0 == c.str(key) }?.1 ?? c.str(key))).font(.system(size: 13)).lineLimit(1); Image(systemName: "chevron.down").font(.system(size: 10)) }
                        .padding(.horizontal, 10).padding(.vertical, 6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5))) }
            }.padding(.vertical, 2)
        case let .txt(key, label, _, multiline):
            TxtField(value: c.str(key), label: tr(label), multiline: multiline, fid: sp.id + "|" + key) { v in c.values[key] = v; changed() }
        case let .note(t):
            let txt = t(c)
            if !txt.isEmpty { Text(tr(txt)).font(.system(size: 12)).foregroundColor(Color(argb: 0xFF334455)).frame(maxWidth: .infinity, alignment: .leading).padding(6).background(Color(argb: 0xFFF2F6FB)) }
        case let .group(title, fields):
            SectionBox(s: s, title: title) { FieldsView(s: s, sp: sp, c: c, fs: fields) }
        case let .btn(b):
            PBtn(b: b, s: s, c: c)
        case let .buttons(list):
            Flow { ForEach(Array(list.enumerated()), id: \.offset) { _, b in PBtn(b: b, s: s, c: c) } }
        case let .iff(cond, fields):
            if cond(c) { let _ = defaults(c, fields); FieldsView(s: s, sp: sp, c: c, fs: fields) }
        }
    }
}
struct PBtn: View {
    let b: Btn; @ObservedObject var s: AppState; let c: PageCtx
    var body: some View { OBtn(tr(b.label), primary: b.primary) { hideKeyboard(); b.action(c); c.version += 1; s.bump() } }
}
func hideKeyboard() { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }

struct NumField: View {
    let value: String; let label: String; let unit: String; let fid: String; let onChange: (String) -> Void
    @State private var v: String = ""; @State private var inited = false
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).frame(maxWidth: .infinity, alignment: .leading)
            TextField("", text: Binding(get: { inited ? v : value }, set: { v = $0; inited = true; onChange($0) }))
                .keyboardType(.numbersAndPunctuation).font(.system(size: 14)).multilineTextAlignment(.trailing)
                .padding(.horizontal, 6).padding(.vertical, 6).frame(width: 96).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5)))
            Text(tr(unit)).font(.system(size: 11)).lineLimit(2).frame(width: 44, alignment: .leading)
        }.padding(.vertical, 2)
        .onChange(of: value) { nv in if nv.replacingOccurrences(of: ",", with: ".").toDoubleOrNull() != v.replacingOccurrences(of: ",", with: ".").toDoubleOrNull() { v = nv } }
        .id(fid)
    }
}
struct TxtField: View {
    let value: String; let label: String; let multiline: Bool; let fid: String; let onChange: (String) -> Void
    @State private var v: String = ""; @State private var inited = false
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 12)).foregroundColor(.secondary)
            let bind = Binding(get: { inited ? v : value }, set: { v = $0; inited = true; onChange($0) })
            if multiline { TextEditor(text: bind).font(.system(size: 14)).frame(minHeight: 70).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5))) }
            else { TextField("", text: bind).font(.system(size: 14)).padding(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5))) }
        }.padding(.vertical, 2)
        .onChange(of: value) { nv in if nv != v { v = nv } }
        .id(fid)
    }
}
