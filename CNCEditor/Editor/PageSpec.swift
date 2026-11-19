/* Описание страниц инструментов (как панель «Помощник» в ArtCAM): поля, кнопки, работа с листом. Порт PageSpec.kt
 * Экран только рисует эти описания. */
import Foundation

indirect enum F {
    case num(key: String, label: String, def: Double, unit: String = "", int: Bool = false)
    case chk(key: String, label: String, def: Bool = false)
    case radio(key: String, options: [(String, String)], def: String)
    case select(key: String, label: String, options: [(String, String)], def: String)
    case txt(key: String, label: String, def: String = "", multiline: Bool = false)
    /// динамический текст (информация)
    case note((PageCtx) -> String)
    case group(String, [F])
    case btn(Btn)
    case buttons([Btn])
    /// поле видно только при условии
    case iff((PageCtx) -> Bool, [F])
}
struct Btn { let label: String; var primary = false; let action: (PageCtx) -> Void
    init(_ label: String, primary: Bool = false, _ action: @escaping (PageCtx) -> Void) { self.label = label; self.primary = primary; self.action = action } }

/// Рисование поверх листа (подсказки инструментов)
enum Ov {
    case poly(pts: [P], color: UInt32, width: Double = 1.5, dash: Bool = false, closed: Bool = false)
    case paths(paths: [VPath], color: UInt32, dash: Bool = true)
    case mark(p: P, kind: String = "x", color: UInt32 = 0xFFE00000) // x | box | dot | handle
    /// толстый след фрезы (ширина в мм) — для имитации
    case thick(a: P, b: P, color: UInt32, wMm: Double)
    case fill(x1: Double, y1: Double, x2: Double, y2: Double, color: UInt32)
}

/// Инструмент, работающий щелчками на листе. Координаты — мм; tol — допуск попадания в мм
protocol CanvasTool: AnyObject {
    func down(_ x: Double, _ y: Double, _ tol: Double) -> Bool
    func move(_ x: Double, _ y: Double) -> Bool
    func up()
    func overlay() -> [Ov]
    var hint: String { get }
}
extension CanvasTool {
    func move(_ x: Double, _ y: Double) -> Bool { false }
    func up() {}
    func overlay() -> [Ov] { [] }
    var hint: String { "" }
}

/// Связь страницы с экраном
protocol UiBridge: AnyObject {
    func toast(_ msg: String)
    func pickPoint(_ hint: String, _ cb: @escaping (P) -> Void)
    func setTool(_ t: CanvasTool?)
    func openPage(_ id: String, _ arg: Any?)
    func closePage()
    func refresh()
    func pickFile(_ mime: String, _ cb: @escaping (String, Data) -> Void)
    func fit()
    /// серое изображение подложки (w, h, пиксели 0..255) с учётом макс. стороны
    func underlayGray(_ maxSide: Int) -> (Int, Int, [Int])?
    func dialog(_ id: String, _ arg: Any?)
    /// пиксели подложки ARGB (w, h, массив) и замена подложки новыми пикселями с размером в мм
    func underlayArgb() -> (Int, Int, [UInt32])?
    func setUnderlayArgb(_ w: Int, _ h: Int, _ px: [UInt32], _ x: Double, _ y: Double, _ wMm: Double, _ hMm: Double)
}
extension UiBridge { func openPage(_ id: String) { openPage(id, nil) }; func dialog(_ id: String) { dialog(id, nil) } }

final class PageCtx {
    let doc: Doc; let ops: Ops; unowned let ui: UiBridge; let arg: Any?
    var values: [String: String] = [:]
    var info: [String: String] = [:]
    /// хранилище для состояния страницы между нажатиями
    var state: [String: Any] = [:]
    init(_ doc: Doc, _ ops: Ops, _ ui: UiBridge, _ arg: Any?) { self.doc = doc; self.ops = ops; self.ui = ui; self.arg = arg }
    func num(_ k: String) -> Double { values[k]?.replacingOccurrences(of: ",", with: ".").trimmed.toDoubleOrNull() ?? 0 }
    func int(_ k: String) -> Int { let v = num(k); return v.isFinite ? Int(v) : 0 }
    func chk(_ k: String) -> Bool { values[k] == "1" }
    func str(_ k: String) -> String { values[k] ?? "" }
    func set(_ k: String, _ v: Any) { switch v { case let b as Bool: values[k] = b ? "1" : "0"; case let d as Double: values[k] = PageCtx.f2(d); default: values[k] = "\(v)" } }
    /// сообщение об ошибке или успехе (nil — ничего)
    func res(_ err: String?) { if let e = err { ui.toast(e) } }
    var version = 0; func bump() { version += 1; ui.refresh() }
    static func f2(_ v: Double) -> String { let r = Double(kroundL(v * 1000)) / 1000; return r == r.rounded() ? String(Int64(r)) : "\(r)" }
}

final class PageSpec {
    let id: String; let title: String; let icon: String; let help: String
    let fields: (PageCtx) -> [F]; let onOpen: (PageCtx) -> Void; let onClose: (PageCtx) -> Void
    init(_ id: String, _ title: String, _ icon: String, help: String = "", fields: @escaping (PageCtx) -> [F], onOpen: @escaping (PageCtx) -> Void = { _ in }, onClose: @escaping (PageCtx) -> Void = { _ in }) {
        self.id = id; self.title = title; self.icon = icon; self.help = help; self.fields = fields; self.onOpen = onOpen; self.onClose = onClose
    }
}

func defaults(_ ctx: PageCtx, _ fs: [F]) {
    for f in fs {
        switch f {
        case let .num(key, _, def, _, _): if ctx.values[key] == nil { ctx.set(key, def) }
        case let .chk(key, _, def): if ctx.values[key] == nil { ctx.set(key, def) }
        case let .radio(key, _, def): if ctx.values[key] == nil { ctx.values[key] = def }
        case let .select(key, _, _, def): if ctx.values[key] == nil { ctx.values[key] = def }
        case let .txt(key, _, def, _): if ctx.values[key] == nil { ctx.values[key] = def }
        case let .group(_, fs2): defaults(ctx, fs2)
        case let .iff(_, fs2): defaults(ctx, fs2)
        default: break
        }
    }
}
