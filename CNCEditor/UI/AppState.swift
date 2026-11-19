/* Всё состояние редактора + связь страниц с экраном (порт AppState.kt). Файлы — через «Файлы» iOS, камера и галерея — UIKit. */
import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

let GCODE_EXT: Set<String> = ["tap", "nc", "ngc", "gcode", "gc", "cnc", "iso", "nc1", "eia", "mpf"]
struct GcodeArg { let name: String; let text: String; let asNew: Bool }

/// настройки (как SharedPreferences "cnc")
enum Prefs {
    private static let ud = UserDefaults.standard
    static func str(_ k: String) -> String? { ud.string(forKey: "cnc_" + k) }
    static func set(_ k: String, _ v: String?) { if let v = v { ud.set(v, forKey: "cnc_" + k) } else { ud.removeObject(forKey: "cnc_" + k) } }
    static func int(_ k: String, _ d: Int = 0) -> Int { ud.object(forKey: "cnc_" + k) == nil ? d : ud.integer(forKey: "cnc_" + k) }
    static func setInt(_ k: String, _ v: Int) { ud.set(v, forKey: "cnc_" + k) }
    static func bool(_ k: String) -> Bool { ud.bool(forKey: "cnc_" + k) }
    static func setBool(_ k: String, _ v: Bool) { ud.set(v, forKey: "cnc_" + k) }
}

/// поворот экрана: авто / альбомная / книжная
final class AppDelegate: NSObject, UIApplicationDelegate {
    static var mask: UIInterfaceOrientationMask = .allButUpsideDown
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask { AppDelegate.mask }
}
func applyOrientation(_ o: String) {
    AppDelegate.mask = o == "land" ? .landscape : (o == "port" ? .portrait : .allButUpsideDown)
    guard let sc = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
    sc.requestGeometryUpdate(.iOS(interfaceOrientations: AppDelegate.mask)) { _ in }
    sc.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
}
func topVC() -> UIViewController? {
    guard var vc = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows.first?.rootViewController else { return nil }
    while let p = vc.presentedViewController { vc = p }; return vc
}

/// пункт меню
indirect enum MI { case item(String, () -> Void); case sub(String, [MI]); case sep }

final class AppState: NSObject, ObservableObject, UiBridge {
    static let shared = AppState()
    let doc = Doc(); lazy var ops = Ops(doc)
    @Published var tick = 0
    weak var canvas: UIView?
    func bump() { tick &+= 1; canvas?.setNeedsDisplay() }

    // ---- экран ----
    var screen = "start" // start | editor
    var tab = "assist"   // project | assist | tp
    var panelOpen = true
    var showGrid = true
    var showTp = true
    var multi = false
    var mode = "select" // select | node
    var dialog: (String, Any?)? = nil
    var pick: (String, (P) -> Void)? = nil
    var selTp: ToolpathRec? = nil
    var lastUri: URL? = nil
    var longMenu: (CGPoint, String)? = nil
    var toastText: String? = nil; private var toastSeq = 0

    // ---- вид: экран = (x * k + offX, offY - y * k), в точках ----
    var k: Double = 1, offX: Double = 0, offY: Double = 0
    var cw: Double = 1, ch: Double = 1
    func resized(_ w: Double, _ h: Double) { let first = cw <= 1; let changed = (w > h) != (cw > ch); cw = w; ch = h; if first || changed { fit() } }
    func toScr(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * k + offX, y: offY - y * k) }
    func toMm(_ o: CGPoint) -> P { P((o.x - offX) / k, (offY - o.y) / k) }
    func tolMm() -> Double { 12.0 / k }
    func fit() {
        let m = doc.model; var x1 = m.x0, y1 = m.y0, x2 = m.x0 + m.w, y2 = m.y0 + m.h
        if !doc.paths.isEmpty { let b = Geom.bbox(doc.paths); x1 = min(x1, b.x1); y1 = min(y1, b.y1); x2 = max(x2, b.x2); y2 = max(y2, b.y2) }
        let w = max(1, x2 - x1), h = max(1, y2 - y1)
        k = max(0.0005, min(cw / w, ch / h) * 0.9)
        offX = cw / 2 - (x1 + w / 2) * k; offY = ch / 2 + (y1 + h / 2) * k; bump()
    }
    func zoomAt(_ f: Double, _ c: CGPoint) { let nk = clamp(k * f, 0.001, 1000); let r = nk / k; offX = c.x - (c.x - offX) * r; offY = c.y - (c.y - offY) * r; k = nk }
    func pan(_ dx: Double, _ dy: Double) { offX += dx; offY += dy }

    /// ориентация: авто → альбомная → книжная → авто (запоминается)
    func toggleOrientation() {
        let cur = Prefs.str("orient") ?? "auto"; let next = cur == "auto" ? "land" : (cur == "land" ? "port" : "auto")
        Prefs.set("orient", next); applyOrientation(next)
        toast(next == "land" ? "Экран: альбомный" : (next == "port" ? "Экран: книжный" : "Экран: автоповорот"))
    }
    // ---- инструменты листа ----
    lazy var select = SelectTool(doc) { [unowned self] in self.multi }
    lazy var node = NodeTool(doc)
    var pageTool: CanvasTool? = nil
    func activeTool() -> CanvasTool { pageTool ?? (mode == "node" ? node : select) }

    // ---- страница помощника ----
    var page: PageSpec? = nil
    var pctx: PageCtx? = nil
    func openPage(_ id: String, _ arg: Any?) {
        closePage(); guard let sp = Pages.all[id] else { return }
        let c = PageCtx(doc, ops, self, arg); page = sp; pctx = c; tab = "assist"; panelOpen = true; mode = "select"
        sp.onOpen(c); defaults(c, sp.fields(c)); bump()
    }
    func closePage() { let c = pctx, sp = page; page = nil; pctx = nil; pageTool = nil; pick = nil; if let c = c, let sp = sp { sp.onClose(c) }; bump() }

    override init() { super.init(); doc.onChange = { [weak self] in self?.bump() } }

    // ---- UiBridge ----
    func toast(_ msg: String) {
        toastText = tr(msg); toastSeq += 1; let seq = toastSeq; bump()
        DispatchQueue.main.asyncAfter(deadline: .now() + (msg.count > 60 ? 4 : 2.3)) { [weak self] in guard let s = self, s.toastSeq == seq else { return }; s.toastText = nil; s.bump() }
    }
    func pickPoint(_ hint: String, _ cb: @escaping (P) -> Void) { pick = (hint, cb); toast(hint) }
    func setTool(_ t: CanvasTool?) { pageTool = t; bump() }
    func refresh() { bump() }
    func pickFile(_ mime: String, _ cb: @escaping (String, Data) -> Void) { openDoc { url, data in cb(url.lastPathComponent, data) } }
    func dialog(_ id: String, _ arg: Any?) {
        switch id {
        case "imageGallery": pickImage { [weak self] d in self?.loadUnderlay(d) }
        case "imageCamera": takePhoto { [weak self] d in self?.loadUnderlay(d) }
        default: dialog = (id, arg); bump()
        }
    }
    func underlayGray(_ maxSide: Int) -> (Int, Int, [Int])? {
        guard let (w, h, px) = argb(maxSide) else { return nil }
        return (w, h, px.map { c in let a = Double((c >> 24) & 255), r = Double((c >> 16) & 255), g = Double((c >> 8) & 255), b = Double(c & 255)
            let gr = 0.299 * r + 0.587 * g + 0.114 * b; return kround(gr * a / 255 + 255 * (1 - a / 255)) })
    }
    func underlayArgb() -> (Int, Int, [UInt32])? { argb(4000) }
    func setUnderlayArgb(_ w: Int, _ h: Int, _ px: [UInt32], _ x: Double, _ y: Double, _ wMm: Double, _ hMm: Double) {
        guard let img = ImageUtil.cgImage(argb: px, w, h), let png = UIImage(cgImage: img).pngData() else { return }
        let old = doc.image; doc.image = Underlay(png, x, y, wMm, hMm, old?.opacity ?? 0.5, true, false); underlayCache = nil; doc.changed()
    }
    private func argb(_ maxSide: Int) -> (Int, Int, [UInt32])? {
        guard let im = doc.image, let ui = UIImage(data: im.data), let cg = ImageUtil.normalized(ui, maxSide) else { return nil }
        return ImageUtil.pixels(cg)
    }
    private var underlayCache: (Data, UIImage)? = nil
    func underlayImage() -> UIImage? {
        guard let im = doc.image else { return nil }
        if let c = underlayCache, c.0 == im.data { return c.1 }
        guard let ui = UIImage(data: im.data), let cg = ImageUtil.normalized(ui, 3000) else { return nil }
        let r = UIImage(cgImage: cg); underlayCache = (im.data, r); return r
    }

    /// картинка/фото → подложка (поворот по EXIF, размер — по модели)
    func loadUnderlay(_ bytes: Data) {
        guard let ui = UIImage(data: bytes), let cg = ImageUtil.normalized(ui, 4000), let jpg = UIImage(cgImage: cg).jpegData(compressionQuality: 0.92) else { toast("Не удалось открыть картинку"); return }
        let bw = Double(cg.width), bh = Double(cg.height)
        if !doc.hasModel { doc.newModel(1000, 1000 * bh / bw, "bl") }
        let mdl = doc.model; let ar = bh / bw; var w = mdl.w * 0.95, h = w * ar; if h > mdl.h * 0.95 { h = mdl.h * 0.95; w = h / ar }
        doc.push(); doc.image = Underlay(jpg, mdl.x0 + (mdl.w - w) / 2, mdl.y0 + (mdl.h - h) / 2, w, h, 0.5, true, false); underlayCache = nil
        screen = "editor"; doc.changed(); fit()
        if page?.id != "image" { openPage("image", nil) } else if let c = pctx { c.set("iw", w); c.set("ih", h); c.bump() }
    }

    // ---- файлы ----
    private var pickerDelegate: NSObject? = nil
    /// открыть файл (с доступом на запись — для «Сохранить» поверх)
    func openDoc(_ cb: @escaping (URL, Data) -> Void) {
        let p = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: false)
        let d = DocPickerDelegate { [weak self] urls in
            guard let u = urls.first else { return }
            _ = u.startAccessingSecurityScopedResource() // доступ остаётся — для «Сохранить» поверх этого файла
            do { let data = try Data(contentsOf: u); cb(u, data) } catch { self?.toast(tr("Ошибка чтения: ") + error.localizedDescription) }
        }
        pickerDelegate = d; p.delegate = d; topVC()?.present(p, animated: true)
    }
    /// сохранить: выбор места в «Файлах» (имя файла — name)
    func createDoc(_ name: String, _ data: Data, _ cb: @escaping (URL) -> Void) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("export", isDirectory: true)
        try? FileManager.default.removeItem(at: dir); try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let f = dir.appendingPathComponent(safeName(name))
        do { try data.write(to: f) } catch { toast(tr("Ошибка записи: ") + error.localizedDescription); return }
        let p = UIDocumentPickerViewController(forExporting: [f], asCopy: true)
        let d = DocPickerDelegate { urls in if let u = urls.first { cb(u) } }
        pickerDelegate = d; p.delegate = d; topVC()?.present(p, animated: true)
    }
    private func safeName(_ n: String) -> String { Rx.c("[\\\\/:*?\"<>|]").replace(n, "_") }
    func write(_ u: URL, _ b: Data) -> Bool {
        let ok = u.startAccessingSecurityScopedResource(); defer { if ok { u.stopAccessingSecurityScopedResource() } }
        do { try b.write(to: u, options: .atomic); return true } catch { return false }
    }
    func takePhoto(_ cb: @escaping (Data) -> Void) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { toast("Камера недоступна"); return }
        let p = UIImagePickerController(); p.sourceType = .camera
        let d = CameraDelegate { img in if let j = img.jpegData(compressionQuality: 0.92) { cb(j) } }
        pickerDelegate = d; p.delegate = d; topVC()?.present(p, animated: true)
    }
    func pickImage(_ cb: @escaping (Data) -> Void) {
        var cfg = PHPickerConfiguration(); cfg.filter = .images; cfg.selectionLimit = 1
        let p = PHPickerViewController(configuration: cfg)
        let d = PhotoDelegate(cb); pickerDelegate = d; p.delegate = d; topVC()?.present(p, animated: true)
    }

    func openFile() { openDoc { [weak self] u, b in self?.openData(u, b) } }
    func openData(_ u: URL, _ b: Data) {
        let n = u.lastPathComponent; let ext = u.pathExtension.lowercased()
        do {
            switch ext {
            case "jpg", "jpeg", "png", "webp", "bmp", "heic": loadUnderlay(b); return
            case "cnc2d", "json": try doc.loadProject(String(decoding: b, as: UTF8.self)); doc.fileName = n
            default:
                if GCODE_EXT.contains(ext) { dialog = ("gcode", GcodeArg(name: n, text: Io.decodeText(b), asNew: true)); bump(); return }
                let t = Io.decodeText(b)
                if ext != "dxf" && ext != "svg" && Gcode.looksLikeGcode(t) { dialog = ("gcode", GcodeArg(name: n, text: t, asNew: true)); bump(); return }
                let wasModel = doc.hasModel; try doc.openText(n, t, true); if !wasModel || ext == "dxf" { lastUri = ext == "dxf" ? u : nil }
            }
            closePage(); screen = "editor"; Recent.add(n); doc.changed(); fit()
        } catch { toast(tr("Не удалось открыть: ") + error.localizedDescription) }
    }
    func importVectors() { openDoc { [weak self] u, b in guard let s = self else { return }; let n = u.lastPathComponent; let t = Io.decodeText(b)
        do { let ext = u.pathExtension.lowercased()
            if GCODE_EXT.contains(ext) || (ext != "dxf" && ext != "svg" && Gcode.looksLikeGcode(t)) { s.dialog = ("gcode", GcodeArg(name: n, text: t, asNew: false)); s.bump() }
            else { try s.doc.openText(n, t, false); s.fit() } } catch { s.toast(tr("Ошибка: ") + error.localizedDescription) } } }
    func gInfo(_ r: Gcode.Result) -> String { tr("Ходов") + ": \(r.moves), " + tr("векторов") + ": \(r.imp.paths.count), " + tr("инструментов") + ": \(r.tools.count)" +
        (r.minZ < 0 ? ", " + tr("глубина до") + " " + String(format: "%.2f", -r.minZ) + " " + tr("мм") : "") }
    /// импорт управляющей программы → векторы
    func importGcode(_ a: GcodeArg, _ o: Gcode.Opt) {
        let r = Gcode.parse(a.text, o)
        do { let base = a.name.contains(".") ? String(a.name[..<a.name.lastIndex(of: ".")!]) : a.name
            try doc.openImported(base + ".dxf", r.imp, a.asNew)
            if a.asNew { lastUri = nil; doc.dirty = true; if r.minZ < 0 { doc.material.thickness = max(doc.material.thickness, -r.minZ) } }
            closePage(); screen = "editor"; Recent.add(a.name); doc.changed(); fit(); toast(gInfo(r)) }
        catch { toast(tr("Не удалось прочитать программу: ") + error.localizedDescription) }
    }
    func saveDxf(_ asNew: Bool) {
        let data = Data(doc.saveDXF().utf8)
        if !asNew, let u = lastUri, write(u, data) { doc.dirty = false; toast("Сохранено: \(doc.fileName ?? u.lastPathComponent)"); bump(); return }
        createDoc(doc.baseName() + ".dxf", data) { [weak self] nu in guard let s = self else { return }; s.lastUri = nu; s.doc.fileName = nu.lastPathComponent; s.doc.dirty = false; Recent.add(nu.lastPathComponent); s.toast("Сохранено: \(nu.lastPathComponent)"); s.bump() }
    }
    func saveText(_ name: String, _ text: String, _ onOk: @escaping () -> Void = {}) { saveBytes(name, Data(text.utf8), onOk) }
    func saveBytes(_ name: String, _ b: Data, _ onOk: @escaping () -> Void = {}) { createDoc(name, b) { [weak self] u in self?.toast("Сохранено: \(u.lastPathComponent)"); onOk() } }
    /// отправить готовый файл через «Поделиться» (Telegram, почта, AirDrop…)
    @discardableResult func shareBytes(_ name: String, _ b: Data) -> Bool {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("share", isDirectory: true)
        try? FileManager.default.removeItem(at: dir); try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let f = dir.appendingPathComponent(safeName(name))
        do { try b.write(to: f) } catch { toast(tr("Не удалось отправить файл: ") + error.localizedDescription); return false }
        let av = UIActivityViewController(activityItems: [f], applicationActivities: nil)
        if let vc = topVC() { av.popoverPresentationController?.sourceView = vc.view; av.popoverPresentationController?.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 1, height: 1); vc.present(av, animated: true) }
        return true
    }
    func shareText(_ name: String, _ text: String) -> Bool { shareBytes(name, Data(text.utf8)) }
    func shareDxf() { shareBytes(doc.baseName() + ".dxf", Data(doc.saveDXF().utf8)) }
    func exportSvg() { saveText(doc.baseName() + ".svg", Io.exportSVG(doc.paths.filter { doc.visible($0) }, doc.layers.map { $0.name }, doc.model.w, doc.model.h)) }
    func exportPdf() { saveBytes(doc.baseName() + ".pdf", Io.exportPDF(doc.paths.filter { doc.visible($0) }, doc.model.w, doc.model.h)) }
    func exportSelDxf() { let s = doc.selected(); if s.isEmpty { toast("Сначала выберите векторы"); return }; saveText(doc.baseName() + "_vybor.dxf", Io.exportDXF(s, doc.layers.map { $0.name })) }

    // ---- команды (иконки и меню) ----
    func cmd(_ k: String) {
        let noSel = doc.selected().isEmpty
        switch k {
        case "new": dialog = ("newModel", nil)
        case "open": openFile()
        case "save": saveDxf(false)
        case "importv": importVectors()
        case "image": openPage("image", nil)
        case "trace": openPage("trace", nil)
        case "undo": doc.undo()
        case "redo": doc.redo()
        case "cut": doc.cut()
        case "copy": doc.copy(); toast("Скопировано: \(doc.clip.count)")
        case "paste": doc.paste()
        case "del": doc.del()
        case "select": closePage(); mode = "select"
        case "node": closePage(); mode = "node"; if noSel { toast("Выберите вектор для редактирования узлов") }
        case "textCurve": openPage("text", "curve")
        case "alignL", "alignR", "alignT", "alignB", "centerH", "centerV", "centerC", "centerPage": res(ops.align(k))
        case "group": res(ops.group())
        case "ungroup": res(ops.ungroup())
        case "weld", "subtract", "intersect", "xor": res(ops.bool(k))
        case "closeLine", "closeCurve", "closeMove": res(ops.close(k))
        case "joinLine", "joinCurve", "joinMove": res(ops.join(k))
        case "reverse": res(ops.reverse())
        case "zoomFit": fit()
        case "grid": showGrid.toggle()
        case "multi": multi.toggle(); if !multi { select.stickyMulti = false }; toast(multi ? "Касание добавляет или убирает вектор" : "Обычный выбор")
        case "material": dialog = ("material", nil)
        case "tooldb": dialog = ("toolDb", nil)
        case "savetp": dialog = ("saveTp", nil)
        case "profile", "machine", "area", "vbit", "drill":
            if noSel { toast("Сначала выберите векторы") } else { openPage(["profile": "tp_profile", "machine": "tp_machine", "area": "tp_area", "vbit": "tp_vcarve"][k] ?? "tp_drill", nil) }
        case "sim": openPage("sim", nil)
        case "layers": dialog = ("layers", nil)
        case "rotatecopy": openPage("blockcopy", "rotate")
        default: if Pages.all[k] != nil { openPage(k, nil) } else { toast("Нет команды: \(k)") }
        }
        bump()
    }
    private func res(_ e: String?) { if let e = e { toast(e) } }
    /// правка выбранной фигуры (прямоугольник, круг, текст…)
    func editSelected() {
        let s = doc.selected(); guard let p = s.first else { return }
        if p.text != nil { openPage("text", doc.groupMembers(p)) }
        else if s.count == 1, let sh = p.shape, Pages.all[sh.type] != nil { openPage(sh.type, p) }
        else { openPage("transform", nil) }
    }
}

/// последние файлы
enum Recent {
    static func list() -> [String] { (Prefs.str("recent") ?? "").components(separatedBy: "\n").filter { !$0.trimmed.isEmpty } }
    static func add(_ n: String) { let l = Array(([n] + list().filter { $0 != n }).prefix(8)); Prefs.set("recent", l.joined(separator: "\n")) }
}

// ---------- делегаты UIKit ----------
final class DocPickerDelegate: NSObject, UIDocumentPickerDelegate {
    let cb: ([URL]) -> Void
    init(_ cb: @escaping ([URL]) -> Void) { self.cb = cb }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { cb(urls) }
}
final class CameraDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let cb: (UIImage) -> Void
    init(_ cb: @escaping (UIImage) -> Void) { self.cb = cb }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true); if let img = info[.originalImage] as? UIImage { cb(img) }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
}
final class PhotoDelegate: NSObject, PHPickerViewControllerDelegate {
    let cb: (Data) -> Void
    init(_ cb: @escaping (Data) -> Void) { self.cb = cb }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let pr = results.first?.itemProvider, pr.canLoadObject(ofClass: UIImage.self) else { return }
        pr.loadObject(ofClass: UIImage.self) { obj, _ in
            guard let img = obj as? UIImage, let d = img.jpegData(compressionQuality: 0.92) else { return }
            DispatchQueue.main.async { self.cb(d) }
        }
    }
}

/// работа с пикселями
enum ImageUtil {
    /// изображение с учётом ориентации (EXIF) и уменьшением до maxSide
    static func normalized(_ ui: UIImage, _ maxSide: Int) -> CGImage? {
        let sz = ui.size; if sz.width < 1 || sz.height < 1 { return nil }
        let s = min(1, Double(maxSide) / max(sz.width, sz.height))
        let w = max(1, Int(sz.width * s)), h = max(1, Int(sz.height * s))
        let f = UIGraphicsImageRendererFormat(); f.scale = 1; f.opaque = false
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: f).image { _ in ui.draw(in: CGRect(x: 0, y: 0, width: w, height: h)) }
        return img.cgImage
    }
    /// пиксели ARGB (как Android getPixels)
    static func pixels(_ cg: CGImage) -> (Int, Int, [UInt32])? {
        let w = cg.width, h = cg.height
        var buf = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &buf, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var px = [UInt32](repeating: 0, count: w * h)
        for i in 0..<(w * h) { let a = UInt32(buf[i * 4 + 3]); var r = UInt32(buf[i * 4]), g = UInt32(buf[i * 4 + 1]), b = UInt32(buf[i * 4 + 2])
            if a > 0 && a < 255 { r = min(255, r * 255 / a); g = min(255, g * 255 / a); b = min(255, b * 255 / a) }
            px[i] = (a << 24) | (r << 16) | (g << 8) | b }
        return (w, h, px)
    }
    static func cgImage(argb px: [UInt32], _ w: Int, _ h: Int) -> CGImage? {
        var buf = [UInt8](repeating: 0, count: w * h * 4)
        for i in 0..<min(px.count, w * h) { let c = px[i]; buf[i * 4] = UInt8((c >> 16) & 255); buf[i * 4 + 1] = UInt8((c >> 8) & 255); buf[i * 4 + 2] = UInt8(c & 255); buf[i * 4 + 3] = 255 }
        guard let prov = CGDataProvider(data: Data(buf) as CFData) else { return nil }
        return CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue), provider: prov, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}

extension UIColor { convenience init(argb c: UInt32) { self.init(red: CGFloat((c >> 16) & 255) / 255, green: CGFloat((c >> 8) & 255) / 255, blue: CGFloat(c & 255) / 255, alpha: CGFloat((c >> 24) & 255) / 255) } }
extension Color { init(argb c: UInt32) { self.init(UIColor(argb: c)) } }
