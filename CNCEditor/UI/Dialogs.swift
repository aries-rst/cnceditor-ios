/* Диалоги (порт Dialogs.kt): новая модель, материал, база фрез, сохранение УП, экспорт PNG/JPG, слои, выбор, свойства, язык, инструкция, премиум, импорт G-кода. */
import SwiftUI

private func f2(_ v: Double) -> String { PageCtx.f2(v) }
private func num(_ s: String) -> Double? { s.replacingOccurrences(of: ",", with: ".").trimmed.toDoubleOrNull() }

struct DialogsHost: View {
    @ObservedObject var s: AppState
    let onHome: () -> Void
    var body: some View {
        let _ = s.tick
        if let dl = s.dialog {
            let close = { s.dialog = nil; s.bump() }
            ZStack {
                Color.black.opacity(0.35).ignoresSafeArea().onTapGesture { hideKeyboard() }
                switch dl.0 {
                case "newModel": NewModelDlg(s: s, close: close)
                case "material": MaterialDlg(s: s, close: close)
                case "toolDb", "toolSelect": ToolDbDlg(s: s, pc: dl.1 as? PageCtx, close: close)
                case "toolEdit": if let t = dl.1 as? ToolDef { ToolEditDlg(s: s, t: t, close: close) }
                case "saveTp": SaveTpDlg(s: s, close: close)
                case "raster": RasterDlg(s: s, type: dl.1 as? String ?? "png", close: close)
                case "layers": LayersDlg(s: s, close: close)
                case "selList": SelListDlg(s: s, close: close)
                case "props": PropsDlg(s: s, close: close)
                case "help": HelpDlg(s: s, close: close)
                case "lang": LangDlg(s: s, close: close)
                case "premium": PremiumDlg(s: s, limit: (dl.1 as? String) == "limit", close: close)
                case "gcode": if let a = dl.1 as? GcodeArg { GcodeDlg(s: s, a: a, close: close) }
                case "nodeXY": NodeXYDlg(s: s, close: close)
                case "about": Dlg(title: "ЧПУ Редактор 2D", close: close) {
                    Text(tr("2D-редактор для фрезерных станков с ЧПУ: черчение, DXF/SVG/PDF, векторизация картинок, траектории и управляющие программы для Weihong (.tap) и Superstar (.nc).") + "\n\nARESTI Labs · v" + appVersion() + "\n" + tr("Шрифты: Liberation (SIL OFL 1.1), DejaVu, Hershey.")).font(.system(size: 14))
                }
                case "home": Dlg(title: "Закрыть модель", close: close, buttons: { Button(tr("Да")) { close(); s.doc.dirty = false; onHome() } }) { Text(tr("Модель не сохранена. Продолжить?")) }
                case "imgSrc": Dlg(title: "Модель из картинки / фото", close: close, buttons: {
                    Button(tr("Из галереи")) { close(); s.pickImage { d in s.doc.hasModel = false; s.loadUnderlay(d) } }
                    Button(tr("Камера")) { close(); s.takePhoto { d in s.doc.hasModel = false; s.loadUnderlay(d) } }
                }) { Text(tr("Картинка ляжет подложкой на новую модель. Её можно обвести инструментами или векторизовать автоматически.")) }
                default: Color.clear.onAppear { close() }
                }
            }
        }
    }
}
func appVersion() -> String { (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0" }

/// окно диалога
struct Dlg<Body: View, Buttons: View>: View {
    let title: String; let close: () -> Void; var wide = false
    let buttons: () -> Buttons; let content: () -> Body
    @State private var contentH: CGFloat = 60
    init(title: String, close: @escaping () -> Void, wide: Bool = false, @ViewBuilder buttons: @escaping () -> Buttons, @ViewBuilder content: @escaping () -> Body) { self.title = title; self.close = close; self.wide = wide; self.buttons = buttons; self.content = content }
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                Text(tr(title)).font(.system(size: 17, weight: .bold)).padding(.bottom, 8)
                ScrollView { VStack(alignment: .leading, spacing: 4) { content() }.frame(maxWidth: .infinity, alignment: .leading)
                    .background(GeometryReader { g in Color.clear.preference(key: DlgHKey.self, value: g.size.height) }) }
                    .frame(height: wide ? max(100, geo.size.height * 0.92 - 110) : min(contentH, max(80, geo.size.height * 0.85 - 110)))
                    .onPreferenceChange(DlgHKey.self) { contentH = $0 }
                Flow(spacing: 6) { buttons(); Button(tr("Закрыть")) { hideKeyboard(); close() }.padding(.horizontal, 6).padding(.vertical, 8) }.padding(.top, 8).frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(14).background(Color.white).cornerRadius(12).shadow(radius: 8)
            .frame(width: wide ? geo.size.width * 0.95 : min(geo.size.width * 0.92, 460))
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}
struct DlgHKey: PreferenceKey { static var defaultValue: CGFloat = 60; static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) } }
extension Dlg where Buttons == EmptyView {
    init(title: String, close: @escaping () -> Void, wide: Bool = false, @ViewBuilder content: @escaping () -> Body) { self.init(title: title, close: close, wide: wide, buttons: { EmptyView() }, content: content) }
}
/// числовое поле диалога
struct NumRow: View {
    let label: String; @Binding var v: String; var unit = "мм"
    var body: some View {
        HStack {
            Text(tr(label)).font(.system(size: 14)).frame(maxWidth: .infinity, alignment: .leading)
            TextField("", text: $v).keyboardType(.numbersAndPunctuation).multilineTextAlignment(.trailing).font(.system(size: 14)).padding(6).frame(width: 96).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5)))
            Text(tr(unit)).font(.system(size: 11)).frame(width: 44, alignment: .leading)
        }
    }
}
struct Check: View {
    let label: String; @Binding var on: Bool
    var body: some View { HStack { Image(systemName: on ? "checkmark.square.fill" : "square").foregroundColor(on ? BLUE : .gray); Text(tr(label)).font(.system(size: 14)) }.contentShape(Rectangle()).onTapGesture { on.toggle() } }
}
struct RadioRow: View {
    let label: String; let on: Bool; let act: () -> Void
    var body: some View { HStack { Image(systemName: on ? "largecircle.fill.circle" : "circle").foregroundColor(on ? BLUE : .gray); Text(label).font(.system(size: 14)) }.padding(.vertical, 3).contentShape(Rectangle()).onTapGesture(perform: act) }
}
struct PrimaryBtn: View {
    let label: String; var enabled = true; let act: () -> Void
    init(_ label: String, enabled: Bool = true, _ act: @escaping () -> Void) { self.label = label; self.enabled = enabled; self.act = act }
    var body: some View { Button { hideKeyboard(); act() } label: { Text(label).font(.system(size: 14, weight: .semibold)).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8).background(enabled ? BLUE : Color.gray).cornerRadius(18) }.disabled(!enabled) }
}

// ---------- новая модель ----------
struct NewModelDlg: View {
    @ObservedObject var s: AppState; let close: () -> Void
    @State private var w = "", h = "", t = ""; @State private var org = "bl"; @State private var inch = false; @State private var inited = false
    private let pts: [(String, CGPoint)] = [("tl", CGPoint(x: 0, y: 0)), ("tr", CGPoint(x: 1, y: 0)), ("c", CGPoint(x: 0.5, y: 0.5)), ("bl", CGPoint(x: 0, y: 1)), ("br", CGPoint(x: 1, y: 1))]
    var body: some View {
        Dlg(title: "Размер новой модели", close: close, buttons: { PrimaryBtn("OK") {
            let k = inch ? 25.4 : 1.0
            guard let W = num(w), let H = num(h), W > 0, H > 0 else { s.toast("Введите размеры"); return }
            let d = s.doc; d.newModel(W * k, H * k, org); d.material.thickness = (num(t) ?? 16) * k
            s.closePage(); s.lastUri = nil; s.screen = "editor"; close(); s.fit()
        } }) {
            NumRow(label: "Ширина (X)", v: $w, unit: inch ? "″" : "мм"); NumRow(label: "Высота (Y)", v: $h, unit: inch ? "″" : "мм")
            Text(tr("Ноль модели") + ":").font(.system(size: 14)).padding(.top, 6)
            ZStack {
                Rectangle().fill(Color(argb: 0xFFF7F7F7)).overlay(Rectangle().stroke(Color.black, lineWidth: 2))
                GeometryReader { g in
                    ForEach(pts, id: \.0) { (key, p) in
                        Circle().fill(key == org ? Color(argb: 0xFFC8382A) : Color(argb: 0xFFDDDDDD)).overlay(Circle().stroke(Color.black, lineWidth: 1.5)).frame(width: 22, height: 22)
                            .position(x: p.x * g.size.width, y: p.y * g.size.height).onTapGesture { org = key }
                    }
                }
            }.frame(width: 180, height: 100).padding(12)
            Text(tr(["tl": "левый верхний угол", "tr": "правый верхний угол", "c": "центр", "bl": "левый нижний угол", "br": "правый нижний угол"][org]!)).font(.system(size: 13)).foregroundColor(Color(argb: 0xFFC8382A))
            HStack { Text(tr("Единицы") + ": "); RadioRow(label: tr("мм"), on: !inch) { inch = false }; RadioRow(label: tr("дюймы"), on: inch) { inch = true } }
            NumRow(label: "Толщина материала", v: $t, unit: inch ? "″" : "мм")
            Text(tr("Листы") + ":").font(.system(size: 13))
            Flow { ForEach(["1830x2750", "2070x2800", "1220x2440", "2050x3050"], id: \.self) { sz in Button(sz.replacingOccurrences(of: "x", with: "×")) { let p = sz.components(separatedBy: "x"); w = p[0]; h = p[1]; inch = false }.font(.system(size: 13)).padding(4) } }
        }.onAppear { if !inited { inited = true; w = f2(s.doc.model.w); h = f2(s.doc.model.h); t = f2(s.doc.material.thickness) } }
    }
}

// ---------- материал ----------
struct MaterialDlg: View {
    @ObservedObject var s: AppState; let close: () -> Void
    @State private var t = "", z = "", hx = "", hy = "", hz = ""
    var body: some View {
        let m = s.doc.material
        Dlg(title: "Настройка материала", close: close, buttons: { PrimaryBtn("OK") { m.thickness = num(t) ?? m.thickness; m.safeZ = num(z) ?? m.safeZ; m.homeX = num(hx) ?? 0; m.homeY = num(hy) ?? 0; m.homeZ = num(hz) ?? m.homeZ; s.doc.dirty = true; s.doc.changed(); close() } }) {
            NumRow(label: "Толщина материала", v: $t); NumRow(label: "Безопасная Z", v: $z)
            Text(tr("Точка «дом» (куда станок уходит в конце)")).font(.system(size: 13)).padding(.top, 6); NumRow(label: "X", v: $hx); NumRow(label: "Y", v: $hy); NumRow(label: "Z", v: $hz)
            Text(tr("Ноль по Z — верх материала. Глубины в траекториях считаются от верха.")).font(.system(size: 12)).foregroundColor(.gray)
        }.onAppear { t = f2(m.thickness); z = f2(m.safeZ); hx = f2(m.homeX); hy = f2(m.homeY); hz = f2(m.homeZ) }
    }
}

// ---------- база инструментов ----------
enum ToolStore {
    static func load(_ s: AppState) { guard let j = Prefs.str("tools"), let l = (try? Json.parse(j)) as? [Any] else { return }
        let tools = l.compactMap { ($0 as? JMap).map { ToolDef.from($0) } }; if !tools.isEmpty { s.doc.tools = tools } }
    static func save(_ s: AppState) { Prefs.set("tools", Json.stringify(s.doc.tools.map { $0.toMap() as Any })) }
}
struct ToolDbDlg: View {
    @ObservedObject var s: AppState; let pc: PageCtx?; let close: () -> Void
    @State private var selId: String? = nil
    var body: some View {
        let d = s.doc
        let sel = d.tools.first { $0.id == selId } ?? d.tools.first
        Dlg(title: pc != nil ? "Выбор инструмента" : "База инструментов", close: close, buttons: {
            if let pc = pc { PrimaryBtn(tr("Выбрать"), enabled: sel != nil) { if let t = sel { pc.state["tool"] = t.copy(); d.lastTool = t; pc.version += 1; s.bump() }; close() } }
        }) {
            let groups = Dictionary(grouping: d.tools) { t in t.group.isEmpty ? (ToolDef.TYPES.first { $0.0 == t.type }?.1 ?? t.type) : t.group }
            let order = d.tools.map { t in t.group.isEmpty ? (ToolDef.TYPES.first { $0.0 == t.type }?.1 ?? t.type) : t.group }.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
            ForEach(order, id: \.self) { g in
                Text(tr(g)).font(.system(size: 13, weight: .bold)).foregroundColor(BLUE).padding(.top, 6)
                ForEach(groups[g] ?? [], id: \.id) { t in
                    VStack(alignment: .leading) { Text(tr(t.name)).font(.system(size: 14))
                        Text("№\(t.num) · D \(f2(t.dia)) \(tr("мм"))\(t.type == "vbit" ? " · \(f2(t.angle))°" : "") · \(tr("подача")) \(f2(t.feed)) \(t.units == "mm/min" ? tr("мм/мин") : tr("мм/с"))").font(.system(size: 11)).foregroundColor(.gray) }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(6).background(t === sel ? Color(argb: 0xFFDDE8F7) : Color.clear).contentShape(Rectangle()).onTapGesture { selId = t.id }
                }
            }
            Flow {
                Button("+ " + tr("Добавить")) { let t = ToolDef(); d.tools.append(t); ToolStore.save(s); s.dialog = ("toolEdit", t); s.bump() }.padding(6)
                Button(tr("Изменить")) { if let t = sel { s.dialog = ("toolEdit", t); s.bump() } }.padding(6).disabled(sel == nil)
                Button(tr("Копия")) { if let t = sel { let c = t.copy(); c.id = "t" + Geom.uid(); c.name = t.name + " (копия)"; d.tools.append(c); selId = c.id; ToolStore.save(s); s.bump() } }.padding(6).disabled(sel == nil)
                Button(tr("Удалить")) { if let t = sel { d.tools.removeAll { $0 === t }; selId = d.tools.first?.id; ToolStore.save(s); s.bump() } }.padding(6).disabled(sel == nil || d.tools.count <= 1)
            }.padding(.top, 8)
        }.onAppear { selId = ((pc?.state["tool"] as? ToolDef).flatMap { t in d.tools.first { $0.id == t.id } } ?? d.tools.first)?.id }
    }
}
struct ToolEditDlg: View {
    @ObservedObject var s: AppState; let t: ToolDef; let close: () -> Void
    @State private var name = "", type = "slot", units = "mm/s", group = ""
    @State private var num0 = "", dia = "", ang = "", sd = "", so = "", sp = "", fd = "", pl = ""
    var body: some View {
        Dlg(title: "Инструмент", close: close, buttons: { PrimaryBtn(tr("Сохранить")) {
            t.name = name; t.type = type; t.units = units; t.group = group; t.num = num(num0).map { Int($0) } ?? t.num; t.dia = num(dia) ?? t.dia; t.angle = num(ang) ?? t.angle
            t.stepdown = num(sd) ?? t.stepdown; t.stepover = num(so) ?? t.stepover; t.spindle = num(sp).map { Int($0) } ?? t.spindle; t.feed = num(fd) ?? t.feed; t.plunge = num(pl) ?? t.plunge
            ToolStore.save(s); s.bump(); close() } }) {
            Text(tr("Название")).font(.system(size: 12)).foregroundColor(.secondary); TextField("", text: $name).padding(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5)))
            Text(tr("Группа (необязательно)")).font(.system(size: 12)).foregroundColor(.secondary); TextField("", text: $group).padding(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5)))
            HStack { Text(tr("Тип")).frame(maxWidth: .infinity, alignment: .leading)
                Menu { ForEach(ToolDef.TYPES, id: \.0) { (k, l) in Button(tr(l)) { type = k } } } label: { Text(tr(ToolDef.TYPES.first { $0.0 == type }?.1 ?? type)).padding(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5))) } }
            NumRow(label: "Номер инструмента / шпинделя", v: $num0, unit: ""); NumRow(label: "Диаметр", v: $dia); if type == "vbit" { NumRow(label: "Угол", v: $ang, unit: "°") }
            NumRow(label: "Шаг вниз", v: $sd); NumRow(label: "Шаг в сторону", v: $so); NumRow(label: "Обороты шпинделя", v: $sp, unit: "об/мин")
            HStack { Text(tr("Единицы подачи")).frame(maxWidth: .infinity, alignment: .leading); RadioRow(label: "мм/с", on: units == "mm/s") { units = "mm/s" }; RadioRow(label: "мм/мин", on: units == "mm/min") { units = "mm/min" } }
            NumRow(label: "Подача", v: $fd, unit: units == "mm/s" ? "мм/с" : "мм/мин"); NumRow(label: "Скорость врезания", v: $pl, unit: units == "mm/s" ? "мм/с" : "мм/мин")
            Text(tr("Для Superstar (4 шпинделя) номер инструмента = номер шпинделя (1–4).")).font(.system(size: 12)).foregroundColor(.gray)
        }.onAppear { name = t.name; type = t.type; units = t.units; group = t.group; num0 = String(t.num); dia = f2(t.dia); ang = f2(t.angle); sd = f2(t.stepdown); so = f2(t.stepover); sp = String(t.spindle); fd = f2(t.feed); pl = f2(t.plunge) }
    }
}

// ---------- сохранение УП ----------
enum PostStore {
    static func list() -> [PostDef] { var l = [Post.weihong, Post.superstar]
        for txt in (Prefs.str("cons") ?? "").components(separatedBy: "\u{1}") where !txt.trimmed.isEmpty { l.append(Post.parseCon(txt)) }; return l }
    static func add(_ text: String) { Prefs.set("cons", (Prefs.str("cons") ?? "") + "\u{1}" + text) }
}
struct SaveTpDlg: View {
    @ObservedObject var s: AppState; let close: () -> Void
    @State private var off: Set<String> = []; @State private var posts: [PostDef] = PostStore.list(); @State private var pi = Prefs.int("post", 0)
    @State private var preview = ""; @State private var fname = ""
    var body: some View {
        let d = s.doc; let post = posts.getOrNull(pi) ?? posts[0]
        func gen() -> String? { let recs = d.toolpaths.filter { !off.contains($0.id) }; if recs.isEmpty { s.toast("Отметьте траектории"); return nil }; return d.gcode(recs, post) }
        return Dlg(title: "Сохранить траектории", close: close, wide: true, buttons: {
            Button(tr("Просмотр")) { if let g = gen() { preview = g.components(separatedBy: post.eol).prefix(60).joined(separator: "\n") } }.padding(6)
            PrimaryBtn(tr("Сохранить")) { if !Premium.canSaveNc() { s.dialog = ("premium", "limit"); s.bump() } else if let g = gen() { Prefs.setInt("post", pi); s.saveText(fname + "." + post.ext, g) { Premium.countNc(); AdManager.maybeInterstitial(); s.bump() } } }
        }) {
            if !Premium.on() { Text(tr("Бесплатно: 1 программа для станка в день. Сегодня осталось:") + " \(max(0, Premium.FREE_PER_DAY - Premium.usedToday()))").font(.system(size: 12)).foregroundColor(Color(argb: 0xFFB8862A)) }
            if d.toolpaths.isEmpty { Text(tr("Нет траекторий. Выберите векторы и нажмите «Профиль» или «Вдоль векторов».")) }
            ForEach(Array(d.toolpaths.enumerated()), id: \.offset) { _, tp in
                HStack { Image(systemName: off.contains(tp.id) ? "square" : "checkmark.square.fill").foregroundColor(BLUE); Rectangle().fill(Color(argb: tp.color)).frame(width: 10, height: 10); Text("\(tr(tp.name)) — T\(tp.tool.num) \(tr(tp.tool.name))").font(.system(size: 14)) }
                    .contentShape(Rectangle()).onTapGesture { if off.contains(tp.id) { off.remove(tp.id) } else { off.insert(tp.id) } }
            }
            Text(tr("Формат файла (постпроцессор)") + ":").font(.system(size: 14, weight: .bold)).padding(.top, 8)
            ForEach(Array(posts.enumerated()), id: \.offset) { i, p in RadioRow(label: tr(p.desc) + "  (." + p.ext + ")", on: pi == i) { pi = i } }
            Button("+ " + tr("Загрузить свой .con…")) { s.pickFile("*/*") { _, b in let txt = Io.decodeText(b); _ = Post.parseCon(txt); PostStore.add(txt); posts = PostStore.list(); pi = posts.count - 1 } }.font(.system(size: 13)).padding(.vertical, 4)
            Text(tr("Имя файла")).font(.system(size: 12)).foregroundColor(.secondary)
            HStack { TextField("", text: $fname).padding(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5))); Text("." + post.ext) }
            Button { if !Premium.canSaveNc() { s.dialog = ("premium", "limit"); s.bump() } else if let g = gen() { Prefs.setInt("post", pi); if s.shareText(fname + "." + post.ext, g) { Premium.countNc() } } } label: {
                Text("📤  " + tr("Поделиться") + " (Telegram, " + tr("почта") + "…)").frame(maxWidth: .infinity).padding(8).overlay(RoundedRectangle(cornerRadius: 18).stroke(BLUE)) }.padding(.top, 6)
            Text(tr("Точка «дом»") + ": X\(f2(d.material.homeX)) Y\(f2(d.material.homeY)) Z\(f2(d.material.homeZ))").font(.system(size: 12)).foregroundColor(.gray)
            if !preview.isEmpty { Text(preview).font(.system(size: 11, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading).padding(6).background(Color(argb: 0xFFF4F4F4)) }
        }.onAppear { if fname.isEmpty { fname = d.baseName() } }
    }
}

// ---------- экспорт PNG/JPG ----------
struct RasterDlg: View {
    @ObservedObject var s: AppState; let type: String; let close: () -> Void
    @State private var dpi = 150; @State private var transp = false
    var body: some View {
        let m = s.doc.model; let k = Double(dpi) / 25.4
        Dlg(title: "Экспорт " + type.uppercased(), close: close, buttons: { PrimaryBtn(tr("Сохранить")) { close(); s.saveBytes(s.doc.baseName() + "." + type, rasterize(s.doc, dpi, type, transp)) } }) {
            Text(tr("Разрешение (точек на дюйм)"))
            HStack { ForEach([96, 150, 300, 600], id: \.self) { v in RadioRow(label: "\(v)", on: dpi == v) { dpi = v } } }
            if type == "png" { Check(label: "Прозрачный фон", on: $transp) }
            Text("\(Int(m.w * k)) × \(Int(m.h * k)) px").font(.system(size: 12)).foregroundColor(.gray)
        }
    }
}
func rasterize(_ d: Doc, _ dpi: Int, _ type: String, _ transp: Bool) -> Data {
    let m = d.model; var k = Double(dpi) / 25.4; k = min(k, 12000 / max(m.w, m.h))
    let W = max(1, Int(m.w * k)), H = max(1, Int(m.h * k))
    let f = UIGraphicsImageRendererFormat(); f.scale = 1; f.opaque = !(transp && type == "png")
    let img = UIGraphicsImageRenderer(size: CGSize(width: W, height: H), format: f).image { c in
        let g = c.cgContext
        if !(transp && type == "png") { g.setFillColor(UIColor.white.cgColor); g.fill(CGRect(x: 0, y: 0, width: W, height: H)) }
        g.setLineWidth(max(1, 0.3 * k)); g.setLineJoin(.round)
        for p in d.paths where d.visible(p) { let fl = Geom.flatten(p, 0.5 / k); if fl.count < 2 { continue }; let pa = CGMutablePath()
            for (i, q) in fl.enumerated() { let pt = CGPoint(x: (q.x - m.x0) * k, y: Double(H) - (q.y - m.y0) * k); if i == 0 { pa.move(to: pt) } else { pa.addLine(to: pt) } }; if p.closed { pa.closeSubpath() }
            g.addPath(pa); g.setStrokeColor(UIColor(argb: d.layers.getOrNull(p.layer)?.color ?? 0xFF000000).cgColor); g.strokePath() }
    }
    return (type == "png" ? img.pngData() : img.jpegData(compressionQuality: 0.92)) ?? Data()
}

// ---------- слои ----------
private let COLORS: [UInt32] = [0xFF000000, 0xFFC8382A, 0xFF2A62B8, 0xFF1F9A3A, 0xFFB8862A, 0xFF8A2AB8, 0xFF2AA6B8, 0xFF7A7A7A]
struct LayersDlg: View {
    @ObservedObject var s: AppState; let close: () -> Void
    @State private var ren: Int? = nil; @State private var nm = ""
    var body: some View {
        let d = s.doc
        Dlg(title: "Слои", close: close, buttons: { Button("+ " + tr("Слой")) { d.addLayer(tr("Слой") + " \(d.layers.count + 1)") }.padding(6) }) {
            ForEach(Array(d.layers.enumerated()), id: \.offset) { i, l in
                VStack(alignment: .leading) {
                    HStack {
                        Text(l.name + "  (\(d.paths.filter { $0.layer == i }.count))").fontWeight(i == d.active ? .bold : .regular).frame(maxWidth: .infinity, alignment: .leading)
                        Button(l.visible ? "👁" : "—") { l.visible.toggle(); d.changed() }
                        Button(l.locked ? "🔒" : "🔓") { l.locked.toggle(); d.changed() }
                        Button("✎") { ren = i; nm = l.name }
                        Button("✕") { d.deleteLayer(i) }.disabled(d.layers.count <= 1)
                    }
                    HStack { ForEach(COLORS, id: \.self) { c in Rectangle().fill(Color(argb: c)).frame(width: l.color == c ? 24 : 18, height: l.color == c ? 24 : 18).onTapGesture { l.color = c; d.dirty = true; d.changed() } } }
                    if ren == i { HStack { TextField("", text: $nm).padding(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5))); Button("OK") { l.name = nm; ren = nil; d.dirty = true; d.changed() } } }
                }.padding(4).background(i == d.active ? Color(argb: 0xFFDDE8F7) : Color.clear).contentShape(Rectangle()).onTapGesture { d.active = i; d.changed() }
            }
            Text(tr("Выбранные векторы → на активный слой:")).font(.system(size: 12)); Button(tr("Перенести")) { d.moveToLayer(d.active) }
        }
    }
}

// ---------- список выбранных ----------
struct SelListDlg: View {
    @ObservedObject var s: AppState; let close: () -> Void
    var body: some View {
        let d = s.doc; let units = d.selectedUnits()
        Dlg(title: "Выбранные векторы (по порядку)", close: close, buttons: { Button(tr("Снять выбор")) { d.clearSel(); s.select.stickyMulti = false }.padding(6) }) {
            if units.isEmpty { Text(tr("Ничего не выбрано")) }
            ForEach(Array(units.enumerated()), id: \.offset) { i, u in
                let b = Geom.bbox(u); let p = u[0]
                let nm: String = u.count > 1 ? (p.text.map { "Текст «" + String($0.text.prefix(20)) + "»" } ?? "Группа (\(u.count))")
                    : (p.shape.flatMap { ["rect": "Прямоугольник", "circle": "Окружность", "ellipse": "Эллипс", "polygon": "Многоугольник", "star": "Звезда"][$0.type] } ?? (p.closed ? "Замкнутый вектор" : "Открытый вектор"))
                HStack {
                    Text("\(i + 1)").foregroundColor(PINK).fontWeight(.bold).frame(width: 28)
                    VStack(alignment: .leading) { Text(tr(nm)).font(.system(size: 14)); Text("\(f2(b.w)) × \(f2(b.h)) мм").font(.system(size: 11)).foregroundColor(.gray) }.frame(maxWidth: .infinity, alignment: .leading)
                    Button("✕") { u.forEach { d.selRemove($0.id) }; d.changed() }
                }.padding(2)
            }
        }
    }
}

struct PropsDlg: View {
    @ObservedObject var s: AppState; let close: () -> Void
    var body: some View { Dlg(title: "Свойства векторов", close: close) { Text(PropsDlg.info(s.doc.selected())).font(.system(size: 14)) } }
    static func info(_ sel: [VPath]) -> String {
        if sel.isEmpty { return tr("Ничего не выбрано") }
        var area = 0.0, per = 0.0; var pts = 0, lines = 0, arcs = 0, bez = 0
        for p in sel { per += Geom.length(p); pts += p.segs.count + 1; if p.closed { area += abs(Geom.signedArea(Geom.flatten(p, 0.05))) }
            for sg in p.segs { if sg is ArcSeg { arcs += 1 } else if sg is BezSeg { bez += 1 } else { lines += 1 } } }
        let bb = Geom.bbox(sel)
        return "\(tr("Векторов")): \(sel.count) (\(tr("групп")): \(Set(sel.compactMap { $0.group }).count))\n\(tr("Замкнутых")): \(sel.filter { $0.closed }.count), \(tr("открытых")): \(sel.filter { !$0.closed }.count)\n" +
            "\(tr("Размер")): \(f2(bb.w)) × \(f2(bb.h)) мм\n\(tr("Позиция")): X \(f2(bb.x1))…\(f2(bb.x2)), Y \(f2(bb.y1))…\(f2(bb.y2))\n\(tr("Длина")): \(f2(per)) мм\n\(tr("Площадь (замкнутые)")): \(f2(area)) мм² (\(f2(area / 1e6)) м²)\n" +
            "\(tr("Точек")): \(pts) — \(tr("линий")) \(lines), \(tr("дуг")) \(arcs), \(tr("кривых")) \(bez)"
    }
}

struct NodeXYDlg: View {
    @ObservedObject var s: AppState; let close: () -> Void
    @State private var x = "", y = ""
    var body: some View {
        Dlg(title: "Координаты точки", close: close, buttons: { PrimaryBtn("OK") { if let a = num(x), let b = num(y) { s.node.setPoint(a, b) }; close() } }) { NumRow(label: "X", v: $x); NumRow(label: "Y", v: $y) }
            .onAppear { guard let n = s.node.selNode else { close(); return }; let p0 = n.i < 0 ? P(n.p.x0, n.p.y0) : P(n.p.segs[n.i].x, n.p.segs[n.i].y); x = f2(p0.x); y = f2(p0.y) }
    }
}

struct LangDlg: View {
    @ObservedObject var s: AppState; let close: () -> Void
    var body: some View {
        Dlg(title: "Язык", close: close) {
            ForEach(L10n.LANGS, id: \.0) { (k, nm) in RadioRow(label: nm, on: L10n.lang == k) { L10n.lang = k; Prefs.set("lang", k); s.bump(); close() }.padding(.vertical, 4) }
        }
    }
}

// ---------- инструкция ----------
struct HelpDlg: View {
    @ObservedObject var s: AppState; let close: () -> Void
    var body: some View {
        let text = ["help_\(L10n.lang)", "help_en", "help_ru"].lazy.compactMap { n -> String? in Bundle.main.url(forResource: n, withExtension: "md").flatMap { try? String(contentsOf: $0, encoding: .utf8) } }.first ?? ""
        Dlg(title: "Инструкция", close: close, wide: true) { MarkdownText(md: text) }
    }
}
struct MarkdownText: View {
    let md: String
    var body: some View {
        ForEach(Array(md.components(separatedBy: "\n").enumerated()), id: \.offset) { _, raw in
            let l = raw.trimmingCharacters(in: .whitespaces)
            if l.hasPrefix("# ") { Text(String(l.dropFirst(2))).font(.system(size: 20, weight: .bold)).foregroundColor(BLUE).padding(.top, 10).padding(.bottom, 4) }
            else if l.hasPrefix("## ") { Text(String(l.dropFirst(3))).font(.system(size: 17, weight: .bold)).foregroundColor(BLUE).padding(.top, 10).padding(.bottom, 2) }
            else if l.hasPrefix("### ") { Text(String(l.dropFirst(4))).font(.system(size: 15, weight: .bold)).padding(.top, 6) }
            else if l.hasPrefix("- ") || l.hasPrefix("* ") { Text("•  " + String(l.dropFirst(2)).replacingOccurrences(of: "**", with: "")).font(.system(size: 14)).padding(.leading, 8) }
            else if l.isEmpty { Spacer().frame(height: 4) }
            else { Text(l.replacingOccurrences(of: "**", with: "")).font(.system(size: 14)) }
        }
    }
}

// ---------- премиум ----------
struct PremiumDlg: View {
    @ObservedObject var s: AppState; let limit: Bool; let close: () -> Void
    var body: some View {
        Dlg(title: "Премиум", close: close, buttons: {
            if !Premium.on() {
                Button(tr("Восстановить")) { Premium.restore { ok in s.toast(ok ? "Покупка восстановлена" : "Покупок не найдено") } }.padding(6)
                PrimaryBtn(tr("Купить") + (Premium.price.map { " — " + $0 } ?? "")) { Premium.buy { ok in if !ok { s.toast("App Store недоступен, попробуйте позже") }; s.bump() } }
            }
        }) {
            if Premium.on() { Text("✓ " + tr("Премиум активен. Спасибо за поддержку!")).foregroundColor(Color(argb: 0xFF1F9A3A)).fontWeight(.bold) }
            else {
                if limit { Text(tr("Сегодняшняя бесплатная программа для станка уже сохранена. Следующая — завтра, или без ограничений в Премиуме.")).foregroundColor(Color(argb: 0xFFC8382A)).padding(.bottom, 8) }
                Text(tr("Разовая покупка навсегда:")).fontWeight(.bold)
                ForEach(["Без ограничений на сохранение программ для станка (.tap, .nc, свой .con)", "Без рекламы", "Все будущие функции"], id: \.self) { l in Text("•  " + tr(l)).font(.system(size: 14)).padding(.leading, 6) }
                Text(tr("Черчение, траектории, имитация, DXF/SVG/PDF и векторизация остаются бесплатными.")).font(.system(size: 12)).foregroundColor(.gray).padding(.top, 8)
            }
        }
    }
}

// ---------- импорт G-кода (.tap, .nc …) ----------
struct GcodeDlg: View {
    @ObservedObject var s: AppState; let a: GcodeArg; let close: () -> Void
    @State private var pre: Gcode.Result? = nil; @State private var dia = ""; @State private var comp = "none"; @State private var merge = true; @State private var perTool = true; @State private var inited = false
    var body: some View {
        Dlg(title: "Импорт программы станка", close: close, buttons: { PrimaryBtn(tr("Импорт")) { close(); let o = Gcode.Opt(); o.toolDia = num(dia) ?? 0; o.comp = comp; o.mergePasses = merge; o.layerPerTool = perTool; s.importGcode(a, o) } }) {
            Text(a.name).font(.system(size: 14, weight: .bold))
            Text(pre.map { r -> String in let g = s.gInfo(r); return tr("Найдено") + ": " + g.prefix(1).lowercased() + g.dropFirst() } ?? tr("Не удалось прочитать программу")).font(.system(size: 12)).foregroundColor(.gray).padding(.bottom, 6)
            Text(tr("В программе записан путь центра фрезы. Для гравировки и «вдоль векторов» это и есть рисунок; для профиля можно сдвинуть контуры на радиус фрезы.")).font(.system(size: 12)).foregroundColor(Color(argb: 0xFF334455))
            Text(tr("Компенсация фрезы") + ":").font(.system(size: 14)).padding(.top, 6)
            ForEach([("none", "Нет — центр фрезы"), ("auto", "Авто: детали внутрь, отверстия наружу"), ("in", "Все контуры внутрь"), ("out", "Все контуры наружу")], id: \.0) { (k, l) in RadioRow(label: tr(l), on: comp == k) { comp = k } }
            if comp != "none" { NumRow(label: "Диаметр фрезы", v: $dia) }
            Check(label: "Слить проходы по глубине в один контур", on: $merge)
            if (pre?.tools.count ?? 0) > 1 { Check(label: "Каждый инструмент — отдельный слой", on: $perTool) }
            Text(tr("После импорта сохраните чертёж: Файл → Сохранить (DXF).")).font(.system(size: 12)).foregroundColor(.gray).padding(.top, 6)
        }.onAppear { if !inited { inited = true; let r = Gcode.parse(a.text); pre = r; let ft = r.tools.first ?? 1; dia = f2(s.doc.tools.first { $0.num == ft }?.dia ?? 6) } }
    }
}
