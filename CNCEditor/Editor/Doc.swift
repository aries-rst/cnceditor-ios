/* ЧПУ Редактор 2D — документ: модель, слои, векторы, выбор, отмена/повтор, траектории, база фрез, формат проекта. Порт Doc.kt
 * Формат проекта совместим с HTML- и Android-версией (JSON «CNC Editor 2D», в т. ч. внутри DXF). */
import Foundation

final class Layer { var name: String; var color: UInt32; var visible: Bool; var locked: Bool
    init(_ name: String, _ color: UInt32 = 0xFF000000, _ visible: Bool = true, _ locked: Bool = false) { self.name = name; self.color = color; self.visible = visible; self.locked = locked } }
final class ModelBox { var w: Double, h: Double, x0: Double, y0: Double
    init(_ w: Double = 1000, _ h: Double = 1000, _ x0: Double = 0, _ y0: Double = 0) { self.w = w; self.h = h; self.x0 = x0; self.y0 = y0 } }
final class Material { var thickness: Double, safeZ: Double, homeX: Double, homeY: Double, homeZ: Double
    init(_ thickness: Double = 16, _ safeZ: Double = 15, _ homeX: Double = 0, _ homeY: Double = 0, _ homeZ: Double = 20) { self.thickness = thickness; self.safeZ = safeZ; self.homeX = homeX; self.homeY = homeY; self.homeZ = homeZ } }
/// подложка-картинка: data — исходные байты (JPEG/PNG), позиция в мм
final class Underlay { var data: Data; var x: Double, y: Double, w: Double, h: Double; var opacity: Double; var visible: Bool; var locked: Bool
    init(_ data: Data, _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ opacity: Double = 0.5, _ visible: Bool = true, _ locked: Bool = false) { self.data = data; self.x = x; self.y = y; self.w = w; self.h = h; self.opacity = opacity; self.visible = visible; self.locked = locked } }

final class ToolDef {
    var id: String, name: String, type: String; var num: Int; var dia: Double, angle: Double
    var stepdown: Double, stepover: Double; var spindle: Int; var feed: Double, plunge: Double
    var units: String, notes: String, group: String
    init(_ id: String = "t" + Geom.uid(), _ name: String = "Фреза", _ type: String = "slot", _ num: Int = 1, _ dia: Double = 6, _ angle: Double = 90,
         _ stepdown: Double = 6, _ stepover: Double = 2.4, _ spindle: Int = 15000, _ feed: Double = 76, _ plunge: Double = 50,
         _ units: String = "mm/s", _ notes: String = "", _ group: String = "") {
        self.id = id; self.name = name; self.type = type; self.num = num; self.dia = dia; self.angle = angle; self.stepdown = stepdown; self.stepover = stepover
        self.spindle = spindle; self.feed = feed; self.plunge = plunge; self.units = units; self.notes = notes; self.group = group
    }
    func copy() -> ToolDef { ToolDef(id, name, type, num, dia, angle, stepdown, stepover, spindle, feed, plunge, units, notes, group) }
    private func perMin(_ v: Double) -> Double { units == "mm/min" ? v : v * 60 }
    func cut() -> CutTool { CutTool(num, name, dia, stepdown, stepover, spindle, perMin(feed), perMin(plunge), angle) }
    func toMap() -> JMap { JMap([("id", id), ("name", name), ("type", type), ("num", num), ("dia", dia), ("angle", angle), ("stepdown", stepdown), ("stepover", stepover),
        ("spindle", spindle), ("feed", feed), ("plunge", plunge), ("units", units), ("notes", notes), ("group", group)]) }
    static func from(_ m: JMap) -> ToolDef { ToolDef(m.s("id", "t" + Geom.uid()), m.s("name", "Фреза"), m.s("type", "slot"), m.i("num", 1), m.d("dia", 6), m.d("angle", 90),
        m.d("stepdown", 6), m.d("stepover", 2.4), m.i("spindle", 15000), m.d("feed", 76), m.d("plunge", 50), m.s("units", "mm/s"), m.s("notes"), m.s("group")) }
    static let TYPES: [(String, String)] = [("slot", "Концевая (пазовая)"), ("end", "Концевая"), ("ball", "Сферическая"), ("vbit", "V-резец (гравёр)"), ("drill", "Сверло")]
    static func defaults() -> [ToolDef] { [
        ToolDef("t1", "Abd-Uzish 16", "slot", 1, 6, 90, 6, 6, 15000, 76, 50, "mm/s", "Концевая фреза: черновая, выборка, вырезание, профиль", "Дерево и пластик / Черновая и 2D-чистовая"),
        ToolDef("t2", "Концевая 3 мм", "end", 1, 3, 90, 3, 1.2, 18000, 40, 20, "mm/s", "", "Дерево и пластик / Черновая и 2D-чистовая"),
        ToolDef("t3", "Концевая 8 мм", "end", 1, 8, 90, 8, 3.2, 16000, 70, 40, "mm/s", "", "Дерево и пластик / Черновая и 2D-чистовая"),
        ToolDef("t4", "V-резец 90°", "vbit", 1, 12, 90, 2, 0.5, 18000, 40, 20, "mm/s", "Для гравировки и V-резьбы", "Дерево и пластик / V-резцы"),
        ToolDef("t5", "Сверло 5 мм", "drill", 1, 5, 118, 5, 0, 12000, 20, 10, "mm/s", "", "Сверление")] }
}

final class ToolpathRec { let id: String; var name: String; let type: String; var tool: ToolDef; var params: TpParams; var srcIds: [String]; var result: TpResult; var show = true; var color: UInt32 = 0xFFE0302A
    init(_ id: String, _ name: String, _ type: String, _ tool: ToolDef, _ params: TpParams, _ srcIds: [String], _ result: TpResult, color: UInt32 = 0xFFE0302A) {
        self.id = id; self.name = name; self.type = type; self.tool = tool; self.params = params; self.srcIds = srcIds; self.result = result; self.color = color } }

extension TextParams {
    convenience init(_ text: String, _ font: String, _ bold: Bool, _ italic: Bool, _ size: Double, _ align: String, _ charSp: Double, _ lineSp: Double, _ kern: Bool,
                     _ sx: Double, _ sy: Double, _ slant: Double, _ rot: Double, _ x: Double, _ y: Double, _ curveId: String?, _ cPos: String, _ cOff: Double, _ cStart: Double, _ cFlip: Bool) {
        self.init(); self.text = text; self.font = font; self.bold = bold; self.italic = italic; self.size = size; self.align = align; self.charSp = charSp; self.lineSp = lineSp; self.kern = kern
        self.sx = sx; self.sy = sy; self.slant = slant; self.rot = rot; self.x = x; self.y = y; self.curveId = curveId; self.cPos = cPos; self.cOff = cOff; self.cStart = cStart; self.cFlip = cFlip
    }
}

final class Doc {
    var model = ModelBox(); var hasModel = false
    var layers: [Layer] = [Layer("Слой 1")]
    var active = 0
    var paths: [VPath] = []
    /// выбор (порядок добавления сохраняется)
    var sel: [String] = []; private var selSet = Set<String>()
    var toolpaths: [ToolpathRec] = []
    var material = Material()
    var image: Underlay? = nil
    var fileName: String? = nil; var dirty = false
    var clip: [VPath] = []
    var tools: [ToolDef] = ToolDef.defaults()
    var lastText: TextParams? = nil; var lastTool: ToolDef? = nil
    private var undoSt: [String] = [], redoSt: [String] = []
    /// счётчик изменений — экран перерисовывается при его изменении
    private(set) var version = 0
    var onChange: (() -> Void)? = nil

    // выбор: помощники над упорядоченным множеством
    func isSel(_ id: String) -> Bool { selSet.contains(id) }
    func selAdd(_ id: String) { if selSet.insert(id).inserted { sel.append(id) } }
    func selRemove(_ id: String) { if selSet.remove(id) != nil { sel.removeAll { $0 == id } } }
    func selClear() { sel.removeAll(); selSet.removeAll() }
    private func selRetain(_ ids: Set<String>) { sel = sel.filter { ids.contains($0) }; selSet = Set(sel) }

    /// в выборе не остаётся векторов, которых уже нет на листе
    func changed() { version += 1; if !sel.isEmpty { selRetain(Set(paths.map { $0.id })) }; onChange?() }

    // ---------- отмена / повтор ----------
    private func snapshot() -> String { Json.stringify(JMap([("paths", paths.map { Doc.pathToMap($0) as Any }), ("layers", layers.map { layerMap($0) as Any }), ("model", modelMap())])) }
    private func restore(_ s: String) {
        guard let o = (try? Json.parse(s)) as? JMap else { return }
        paths = o.l("paths").compactMap { ($0 as? JMap).map { Doc.pathFrom($0) } }
        layers = o.l("layers").compactMap { ($0 as? JMap).map { layerFrom($0) } }
        if let m = o.m("model") { modelFrom(m) }
        selRetain(Set(paths.map { $0.id }))
    }
    func push() { undoSt.append(snapshot()); if undoSt.count > 80 { undoSt.removeFirst() }; redoSt.removeAll(); dirty = true }
    func undo() { guard let s = undoSt.popLast() else { return }; redoSt.append(snapshot()); restore(s); changed() }
    func redo() { guard let s = redoSt.popLast() else { return }; undoSt.append(snapshot()); restore(s); changed() }
    var canUndo: Bool { !undoSt.isEmpty }; var canRedo: Bool { !redoSt.isEmpty }

    // ---------- выбор ----------
    func editable(_ p: VPath) -> Bool { !p.locked && (layers.getOrNull(p.layer).map { $0.visible && !$0.locked } ?? true) }
    func visible(_ p: VPath) -> Bool { layers.getOrNull(p.layer)?.visible ?? true }
    func byId(_ id: String) -> VPath? { paths.first { $0.id == id } }
    func selected() -> [VPath] { paths.filter { selSet.contains($0.id) } }
    func selectedOrdered() -> [VPath] { sel.compactMap { byId($0) } }
    func groupMembers(_ p: VPath) -> [VPath] { p.group != nil ? paths.filter { $0.group == p.group } : [p] }
    /// units — группы выбора по порядку (каждая группа — одна единица)
    func selectedUnits() -> [[VPath]] { var seen = Set<String>(); var out: [[VPath]] = []; for p in selectedOrdered() { let k = p.group ?? p.id; if seen.insert(k).inserted { out.append(groupMembers(p)) } }; return out }
    func selectPath(_ p: VPath, _ add: Bool) {
        let mem = groupMembers(p); if !add { selClear() }
        if add && mem.allSatisfy({ isSel($0.id) }) { mem.forEach { selRemove($0.id) } } else { mem.forEach { selAdd($0.id) } }
        changed()
    }
    func selectAll() { selClear(); paths.filter { editable($0) }.forEach { selAdd($0.id) }; changed() }
    func selectWhere(_ f: (VPath) -> Bool) { selClear(); paths.filter { editable($0) && f($0) }.forEach { selAdd($0.id) }; changed() }
    func clearSel() { if !sel.isEmpty { selClear(); changed() } }

    // ---------- правка ----------
    func add(_ ps: [VPath], _ select: Bool = true) { if ps.isEmpty { return }; push(); for p in ps { if p.layer < 0 || p.layer >= layers.count { p.layer = active }; paths.append(p) }; if select { selClear(); ps.forEach { selAdd($0.id) } }; changed() }
    func addOnActive(_ ps: [VPath]) { ps.forEach { $0.layer = active }; add(ps) }
    func replace(_ old: [VPath], _ new: [VPath]) {
        push(); let ids = Set(old.map { $0.id }); let lay = old.first?.layer ?? active
        paths.removeAll { ids.contains($0.id) }; for p in new { if !layers.indices.contains(p.layer) { p.layer = lay }; paths.append(p) }
        selClear(); new.forEach { selAdd($0.id) }; changed()
    }
    func del() { let s = selected().filter { editable($0) }; if s.isEmpty { return }; push(); let ids = Set(s.map { $0.id }); paths.removeAll { ids.contains($0.id) }; selClear(); toolpaths.removeAll { tp in tp.srcIds.allSatisfy { ids.contains($0) } }; changed() }
    func copy() { clip = selected().map { $0.copy() } }
    func cut() { copy(); del() }
    func paste(_ dx: Double = 10, _ dy: Double = -10) {
        if clip.isEmpty { return }
        var gm: [String: String] = [:]
        let ps = clip.map { c -> VPath in
            let p = c.copy(); Geom.transform(p, Geom.M.move(dx, dy))
            p.shape = c.shape.map { s in var v = s.v; if let x = v["cx"] { v["cx"] = x + dx }; if let y = v["cy"] { v["cy"] = y + dy }; return Shape(s.type, v) }
            p.group = c.group.map { g in if let n = gm[g] { return n }; let n = "g" + Geom.uid(); gm[g] = n; return n }
            return p
        }
        clip = ps.map { $0.copy() }; add(ps)
    }
    func applyMatrix(_ m: [Double], _ copy: Bool = false) {
        let s = selected().filter { editable($0) }; if s.isEmpty { return }
        push()
        if copy { var gm: [String: String] = [:]; let ns = s.map { o -> VPath in let c = o.copy(); c.group = o.group.map { g in if let n = gm[g] { return n }; let n = "g" + Geom.uid(); gm[g] = n; return n }; Geom.transform(c, m); return c }; paths.append(contentsOf: ns); selClear(); ns.forEach { selAdd($0.id) } }
        else { s.forEach { Geom.transform($0, m) } }
        changed()
    }
    func newModel(_ w: Double, _ h: Double, _ org: String) {
        let x0: Double = (org == "tr" || org == "br") ? -w : (org == "c" ? -w / 2 : 0)
        let y0: Double = (org == "tl" || org == "tr") ? -h : (org == "c" ? -h / 2 : 0)
        model = ModelBox(w, h, x0, y0)
        hasModel = true; paths.removeAll(); selClear(); toolpaths.removeAll(); layers = [Layer("Слой 1")]; active = 0; image = nil
        undoSt.removeAll(); redoSt.removeAll(); fileName = nil; dirty = false; changed()
    }
    func addLayer(_ name: String) { layers.append(Layer(name)); active = layers.count - 1; changed() }
    func deleteLayer(_ i: Int) { if layers.count <= 1 { return }; push(); paths.removeAll { $0.layer == i }; for p in paths where p.layer > i { p.layer -= 1 }; layers.remove(at: i); active = clampI(active, 0, layers.count - 1); changed() }
    func moveToLayer(_ i: Int) { let s = selected(); if s.isEmpty { return }; push(); s.forEach { $0.layer = i }; changed() }

    // ---------- траектории ----------
    func tool(_ id: String) -> ToolDef? { tools.first { $0.id == id } }
    @discardableResult func computeToolpath(_ type: String, _ src: [VPath], _ prm: TpParams, _ tool: ToolDef, _ name: String, _ replaceId: String? = nil) -> ToolpathRec? {
        prm.safeZ = material.safeZ; prm.name = name
        let res = Toolpath.compute(type, src, prm, tool.cut())
        if res.chains.isEmpty { return nil }
        let colors: [UInt32] = [0xFFE0302A, 0xFF2A62B8, 0xFF1F9A3A, 0xFFB8862A, 0xFF8A2AB8, 0xFF2AA6B8]
        let old = toolpaths.firstIndex { $0.id == replaceId }
        let rec = ToolpathRec(replaceId ?? ("tp" + Geom.uid()), name, type, tool.copy(), prm.copy(), src.map { $0.id }, res,
                              color: old != nil ? toolpaths[old!].color : colors[toolpaths.count % colors.count])
        if let o = old { toolpaths[o] = rec } else { toolpaths.append(rec) }
        dirty = true; changed(); return rec
    }
    func gcode(_ recs: [ToolpathRec], _ post: PostDef) -> String {
        Post.generate(post, recs.map { PostPath(tool: PostTool(num: $0.tool.num, name: $0.tool.name, spindle: $0.tool.spindle, dia: $0.tool.dia), moves: Post.simplify($0.result.moves, $0.params.tol)) },
                      Home(x: material.homeX, y: material.homeY, z: material.homeZ), fileName ?? "")
    }

    // ---------- формат проекта (как в HTML-версии) ----------
    private func modelMap() -> JMap { JMap([("w", model.w), ("h", model.h), ("x0", model.x0), ("y0", model.y0)]) }
    private func modelFrom(_ m: JMap) { model = ModelBox(m.d("w", 1000), m.d("h", 1000), m.d("x0"), m.d("y0")) }
    private func layerMap(_ l: Layer) -> JMap { JMap([("name", l.name), ("color", String(format: "#%06X", l.color & 0xFFFFFF)), ("visible", l.visible), ("locked", l.locked)]) }
    private func layerFrom(_ m: JMap) -> Layer { Layer(m.s("name", "Слой"), (UInt32(m.s("color", "#000000").removePrefix("#"), radix: 16) ?? 0) | 0xFF000000, m.b("visible", true), m.b("locked")) }

    static func segMap(_ s: Seg) -> JMap {
        if let a = s as? ArcSeg { return JMap([("t", "A"), ("x", a.x), ("y", a.y), ("cx", a.cx), ("cy", a.cy), ("ccw", a.ccw)]) }
        if let b = s as? BezSeg { return JMap([("t", "B"), ("x1", b.x1), ("y1", b.y1), ("x2", b.x2), ("y2", b.y2), ("x", b.x), ("y", b.y)]) }
        return JMap([("t", "L"), ("x", s.x), ("y", s.y)])
    }
    static func segFrom(_ m: JMap) -> Seg {
        switch m.s("t") {
        case "A": return ArcSeg(m.d("x"), m.d("y"), m.d("cx"), m.d("cy"), m.b("ccw"))
        case "B": return BezSeg(m.d("x1"), m.d("y1"), m.d("x2"), m.d("y2"), m.d("x"), m.d("y"))
        default: return LineSeg(m.d("x"), m.d("y"))
        }
    }
    static func textMap(_ t: TextParams) -> JMap { JMap([("text", t.text), ("font", t.font), ("bold", t.bold), ("italic", t.italic), ("size", t.size), ("align", t.align), ("charSp", t.charSp), ("lineSp", t.lineSp),
        ("kern", t.kern), ("sx", t.sx), ("sy", t.sy), ("slant", t.slant), ("rot", t.rot), ("x", t.x), ("y", t.y), ("curveId", t.curveId), ("cPos", t.cPos), ("cOff", t.cOff), ("cStart", t.cStart), ("cFlip", t.cFlip)]) }
    static func textFrom(_ m: JMap) -> TextParams { TextParams(m.s("text"), m.s("font", "sans"), m.b("bold"), m.b("italic"), m.d("size", 50), m.s("align", "left"), m.d("charSp"), m.d("lineSp"), m.b("kern", true),
        m.d("sx", 100), m.d("sy", 100), m.d("slant"), m.d("rot"), m.d("x"), m.d("y"), m["curveId"] as? String, m.s("cPos", "center"), m.d("cOff"), m.d("cStart"), m.b("cFlip")) }
    static func pathToMap(_ p: VPath) -> JMap {
        let sh: JMap? = p.shape.map { s in let m = JMap(); m["type"] = s.type; for k in s.v.keys.sorted() { let v = s.v[k]!; m[k] = k == "inv" ? (v != 0) as Any : v as Any }; return m }
        return JMap([("id", p.id), ("layer", p.layer), ("closed", p.closed), ("x0", p.x0), ("y0", p.y0), ("segs", p.segs.map { segMap($0) as Any }),
                     ("group", p.group), ("shape", sh), ("locked", p.locked), ("text", p.text.map { textMap($0) })])
    }
    static func pathFrom(_ m: JMap) -> VPath {
        let shape: Shape? = m.m("shape").map { sh in var v: [String: Double] = [:]; for (k, x) in sh where k != "type" { if let b = x as? Bool { v[k] = b ? 1 : 0 } else { v[k] = jnum(x) ?? 0 } }; return Shape(sh.s("type"), v) }
        return VPath(id: m.s("id", Geom.uid()), layer: m.i("layer"), closed: m.b("closed"), x0: m.d("x0"), y0: m.d("y0"), segs: m.l("segs").compactMap { ($0 as? JMap).map { segFrom($0) } },
                     group: m["group"] as? String, shape: shape, locked: m.b("locked"), text: m.m("text").map { textFrom($0) })
    }
    static func paramsMap(_ p: TpParams) -> JMap { JMap([("start", p.start), ("finish", p.finish), ("tol", p.tol), ("sequencing", p.sequencing), ("side", p.side), ("allowance", p.allowance), ("climb", p.climb),
        ("tabs", JMap([("on", p.tabs.on), ("mode", p.tabs.mode), ("n", p.tabs.n), ("dist", p.tabs.dist), ("len", p.tabs.len), ("h", p.tabs.h), ("points", p.tabs.points.map { [$0.x, $0.y] as Any })])),
        ("ramp", JMap([("on", p.ramp.on), ("len", p.ramp.len)])), ("strategy", p.strategy), ("angle", p.rasterAngle), ("lastProfile", p.lastProfile), ("stepover", p.stepover),
        ("peck", p.peck), ("retract", p.retract), ("vangle", p.vangle)]) }
    static func paramsFrom(_ m: JMap, _ type: String) -> TpParams {
        let t = m.m("tabs") ?? JMap(), r = m.m("ramp") ?? JMap()
        let pts = t.l("points").compactMap { q -> P? in guard let a = q as? [Any], a.count >= 2, let x = jnum(a[0]), let y = jnum(a[1]) else { return nil }; return P(x, y) }
        return TpParams(m.d("start"), m.d("finish", 3), m.d("tol", 0.01), 15, m.s("sequencing", "optimise"), m.s("side", "outside"), m.d("allowance"), m.b("climb", true),
            Tabs(t.b("on"), t.s("mode", "count"), t.i("n", 4), t.d("dist", 300), t.d("len", 10), t.d("h", 3), pts),
            Ramp(r.b("on"), r.d("len", 30)), m.s("strategy", "offset"), type == "area" ? m.i("angle") : 0, m.b("lastProfile", true), m.d("stepover"), m.d("peck"), m.d("retract", 2),
            type == "vcarve" ? m.d("vangle", m.d("angle", 90)) : m.d("vangle", 90), "")
    }
    func projectJSON() -> String {
        let img: JMap? = image.map { JMap([("src", "data:image/jpeg;base64," + $0.data.base64EncodedString()), ("x", $0.x), ("y", $0.y), ("w", $0.w), ("h", $0.h), ("opacity", $0.opacity), ("visible", $0.visible), ("locked", $0.locked)]) }
        return Json.stringify(JMap([("app", "CNC Editor 2D"), ("ver", 1), ("model", modelMap()), ("layers", layers.map { layerMap($0) as Any }), ("paths", paths.map { Doc.pathToMap($0) as Any }),
            ("material", JMap([("thickness", material.thickness), ("safeZ", material.safeZ), ("home", JMap([("x", material.homeX), ("y", material.homeY), ("z", material.homeZ)]))])),
            ("image", img),
            ("toolpaths", toolpaths.map { JMap([("name", $0.name), ("type", $0.type), ("params", Doc.paramsMap($0.params)), ("tool", $0.tool.toMap()), ("srcIds", $0.srcIds.map { $0 as Any })]) as Any })]))
    }
    func loadProject(_ text: String) throws {
        guard let o = (try? Json.parse(text)) as? JMap else { throw IoError(msg: "Неверный файл проекта") }
        if o.s("app") != "CNC Editor 2D" { throw IoError(msg: "Это не проект ЧПУ Редактора 2D") }
        hasModel = true; if let m = o.m("model") { modelFrom(m) }
        layers = o.l("layers").compactMap { ($0 as? JMap).map { layerFrom($0) } }; if layers.isEmpty { layers = [Layer("Слой 1")] }; active = 0
        paths = o.l("paths").compactMap { ($0 as? JMap).map { Doc.pathFrom($0) } }
        if let m = o.m("material") { let h = m.m("home") ?? JMap(); material = Material(m.d("thickness", 16), m.d("safeZ", 15), h.d("x"), h.d("y"), h.d("z", 20)) }
        image = o.m("image").flatMap { im in
            let src = im.s("src"); guard let r = src.range(of: "base64,") else { return nil }; let b64 = String(src[r.upperBound...])
            guard !b64.isEmpty, let d = Data(base64Encoded: b64) else { return nil }
            return Underlay(d, im.d("x"), im.d("y"), im.d("w"), im.d("h"), im.d("opacity", 0.5), im.b("visible", true), im.b("locked"))
        }
        selClear(); undoSt.removeAll(); redoSt.removeAll(); toolpaths.removeAll()
        for t in o.l("toolpaths") { guard let tm = t as? JMap else { continue }; let type = tm.s("type"); let ids = Set(tm.l("srcIds").compactMap { $0 as? String }); let src = paths.filter { ids.contains($0.id) }
            if !src.isEmpty { computeToolpath(type, src, Doc.paramsFrom(tm.m("params") ?? JMap(), type), ToolDef.from(tm.m("tool") ?? JMap()), tm.s("name", type)) } }
        dirty = false; changed()
    }
    /// сохранение по умолчанию: DXF с данными проекта внутри
    func saveDXF() -> String { Io.embedProject(Io.exportDXF(paths, layers.map { $0.name }), projectJSON()) }
    /// открыть файл: DXF (с проектом или без), SVG, .cnc2d/.json
    func openText(_ name: String, _ text: String, _ asNew: Bool = true) throws {
        let ext = name.contains(".") ? String(name.split(separator: ".").last!).lowercased() : ""
        if ext == "dxf", let emb = Io.extractProject(text) { try loadProject(emb); fileName = name; return }
        if ext == "cnc2d" || ext == "json" { try loadProject(text); fileName = name; return }
        try openImported(name, ext == "svg" ? try Io.importSVG(text) : Io.importDXF(text), asNew)
    }
    /// открыть уже разобранные векторы (DXF, SVG, G-код) — новой моделью или добавить в текущую
    func openImported(_ name: String, _ imp: Imported, _ asNew: Bool) throws {
        if imp.paths.isEmpty { throw IoError(msg: "В файле нет векторов") }
        let bb = Geom.bbox(imp.paths)
        if asNew || !hasModel {
            model = ModelBox(max(10, ceil(bb.w + 20)), max(10, ceil(bb.h + 20)), floor(bb.x1 - 10), floor(bb.y1 - 10)); hasModel = true
            layers = imp.layers.map { Layer($0) }; paths = imp.paths; selClear(); toolpaths.removeAll(); undoSt.removeAll(); redoSt.removeAll(); fileName = name; dirty = false; changed()
        } else {
            let base = layers.count; imp.layers.forEach { layers.append(Layer($0)) }; imp.paths.forEach { $0.layer += base }; add(imp.paths)
        }
    }
    func baseName() -> String { let n = fileName ?? "chertezh"; if let i = n.lastIndex(of: ".") { return String(n[..<i]) }; return n }
}
