/* ЧПУ Редактор 2D — постпроцессоры (порт Post.kt).
 * Понимает текстовый формат конфигурации, совместимый с ArtCAM (*.con), и содержит две собственные
 * встроенные схемы: Weihong (.tap) и Superstar 4-шпиндельный (.nc).
 */
import Foundation

struct Fmt { let mode: String; let prefix: String; let dec: Int; var plus = false; var mult = 1.0
    init(_ mode: String, _ prefix: String, _ dec: Int, _ plus: Bool = false, _ mult: Double = 1.0) { self.mode = mode; self.prefix = prefix; self.dec = dec; self.plus = plus; self.mult = mult } }

final class PostDef {
    var desc = "", ext = "nc", units = "MM", eol = "\r\n"
    var fmt: [String: Fmt] = [:]; var start: [String] = []; var end: [String] = []
    var toolchange: [String] = []; var tpl: [String: String] = [:]
    var lineStart = 0.0, lineInc = 10.0, lineMax = 999999.0
    init() {}
    init(_ desc: String, _ ext: String, _ units: String, _ eol: String, _ fmt: [String: Fmt], _ start: [String], _ end: [String], _ toolchange: [String], _ tpl: [String: String]) {
        self.desc = desc; self.ext = ext; self.units = units; self.eol = eol; self.fmt = fmt; self.start = start; self.end = end; self.toolchange = toolchange; self.tpl = tpl
    }
}

/// Ход: r=true — холостой G0, иначе рабочий с подачей f (мм/мин)
struct Move: Equatable { let r: Bool; let x: Double; let y: Double; let z: Double; var f: Double = 0
    init(_ r: Bool, _ x: Double, _ y: Double, _ z: Double, _ f: Double = 0) { self.r = r; self.x = x; self.y = y; self.z = z; self.f = f } }
struct PostTool { let num: Int; var name = ""; var spindle = 0; var dia: Double? = nil }
struct PostPath { let tool: PostTool; let moves: [Move] }
struct Home { var x = 0.0, y = 0.0, z = 20.0 }

enum Post {
    static func parseCon(_ text: String) -> PostDef {
        let pp = PostDef()
        for raw in Rx.c("\\r?\\n").split(text) {
            let line = String(raw.drop(while: { $0 == " " || $0 == "\t" }))
            if line.isEmpty || line.first == ";" { continue }
            guard let m = Rx.c("^([A-Za-z_]+)\\s*=\\s*(.*)$").first(line) else { continue }
            let key = m.gv(1).uppercased(); let v = m.gv(2).trimmed
            func str() -> String { if let q = Rx.c("^\"(.*)\"\\s*(;.*)?$").first(v) { return q.gv(1) }; return Rx.c(";.*$").replace(v, "").trimmed }
            switch key {
            case "DESCRIPTION": pp.desc = str()
            case "FILE_EXTENSION": pp.ext = str()
            case "UNITS": pp.units = str().uppercased()
            case "END_OF_LINE": pp.eol = Rx.c("\\[(\\d+)\\]").replace(str()) { String(UnicodeScalar(UInt8(Int($0.gv(1)) ?? 0))) }
            case "LINE_NUM_START": pp.lineStart = str().toDoubleOrNull() ?? 0
            case "LINE_NUM_INCREMENT": pp.lineInc = str().toDoubleOrNull() ?? 10
            case "LINE_NUM_MAXIMUM": pp.lineMax = str().toDoubleOrNull() ?? 999999
            case "FORMAT":
                guard let f = Rx.c("\\[([^\\]]*)\\]").first(v) else { continue }
                let parts = f.gv(1).components(separatedBy: "|")
                let wd = (parts.getOrNull(3) ?? "1.3").replacingOccurrences(of: "+", with: "").components(separatedBy: ".")
                let mode = parts.getOrNull(1).map { $0.isEmpty ? "#" : $0 } ?? "#"
                pp.fmt[parts[0].uppercased()] = Fmt(mode, parts.getOrNull(2) ?? "", wd.getOrNull(1)?.toIntOrNull() ?? 0, (parts.getOrNull(3) ?? "").contains("+"), parts.getOrNull(4)?.toDoubleOrNull() ?? 1)
            case "START": pp.start.append(str())
            case "END": pp.end.append(str())
            case "TOOLCHANGE": pp.toolchange.append(str())
            default: pp.tpl[key] = str()
            }
        }
        return pp
    }

    private static func stdFmt() -> [String: Fmt] {
        ["N": Fmt("@", "N", 0), "S": Fmt("@", "S", 0), "F": Fmt("#", "F", 1),
         "X": Fmt("#", "X", 3), "Y": Fmt("#", "Y", 3), "Z": Fmt("#", "Z", 3),
         "XH": Fmt("@", "X", 3), "YH": Fmt("@", "Y", 3), "ZH": Fmt("@", "Z", 3)]
    }
    private static func stdTpl() -> [String: String] { ["RAPID_RATE_MOVE": "G0[X][Y][Z]", "FIRST_FEED_RATE_MOVE": "G1[X][Y][Z][F]", "FEED_RATE_MOVE": "[X][Y][Z]"] }

    /// Собственные встроенные схемы (описания форматов, не файлы Delcam)
    static var weihong: PostDef { PostDef("G-Code (mm) (*.tap) — Weihong / NcStudio", "tap", "MM", "\r\n", stdFmt(),
        ["T1M6", "G0[ZH]", "G0[XH][YH][S]M3"], ["G0[ZH]", "G0X0Y0", "M30"], [], stdTpl()) }
    static var superstar: PostDef { PostDef("Superstarcnc-LNC (*.nc) — 4 шпинделя", "nc", "MM", "\r\n", stdFmt(),
        ["G90 G0 G54", "M6 T[T]", "M03 [S]", "G4 P3000", "G43 H[T]"], ["M05", "M30", "%"],
        ["M5", "M6 T[T]", "M3 [S]", "G4 P3000", "G43 H[T]"], stdTpl()) }

    /// число как toFixed в JS: точное значение double, округление половины вверх
    static func fmtNum(_ v: Double, _ f: Fmt) -> String {
        var s = CNCEditor.fmtNum(v * f.mult, f.dec, strip: false)
        if Rx.c("^-0\\.?0*$").test(s) { s = String(s.dropFirst()) }
        if f.plus && !s.hasPrefix("-") { s = "+" + s }
        return s
    }

    /// убрать лишние точки на рабочих ходах (одна глубина): отклонение от исходной линии не больше tol.
    static func simplify(_ moves: [Move], _ tol: Double) -> [Move] {
        let t = max(0.001, tol); var out: [Move] = []; out.reserveCapacity(moves.count); var i = 0
        while i < moves.count {
            let m = moves[i]
            if m.r || out.isEmpty { out.append(m); i += 1; continue }
            let prev = out.last!; var j = i
            while j + 1 < moves.count && !moves[j + 1].r && moves[j + 1].z == prev.z && m.z == prev.z && moves[j + 1].f == m.f { j += 1 }
            if j == i || m.z != prev.z { out.append(m); i += 1; continue }
            var run: [Move] = [prev]; for k in i...j { run.append(moves[k]) }
            var keep = [Bool](repeating: false, count: run.count); keep[0] = true; keep[run.count - 1] = true
            var st: [(Int, Int)] = [(0, run.count - 1)]
            while let (a, b) = st.popLast() {
                if b - a < 2 { continue }
                let ax = run[a].x, ay = run[a].y, dx = run[b].x - ax, dy = run[b].y - ay; let L = hypot(dx, dy)
                var md = -1.0, mi = -1
                for k in (a + 1)..<b { let d = L < 1e-9 ? hypot(run[k].x - ax, run[k].y - ay) : abs((run[k].x - ax) * dy - (run[k].y - ay) * dx) / L; if d > md { md = d; mi = k } }
                if md > t { keep[mi] = true; st.append((a, mi)); st.append((mi, b)) }
            }
            for k in 1..<run.count where keep[k] { out.append(run[k]) }
            i = j + 1
        }
        return out
    }
    static func generate(_ pp: PostDef, _ paths0: [PostPath], _ home: Home = Home(), _ name: String = "") -> String {
        var out: [String] = []
        var lineNo = pp.lineStart
        var last: [String: String] = [:]
        var ctx: [String: Any] = [:]
        func varVal(_ nm: String) -> String {
            let f = pp.fmt[nm]; guard let v = ctx[nm] else { return "" }
            if let s = v as? String { return s }
            let d = v as! Double
            guard let ff = f else { let r = (d * 1000 + 0.5).rounded(.down) / 1000; return r == r.rounded(.down) ? String(Int64(r)) : "\(r)" }
            let s = fmtNum(d, ff)
            if ff.mode == "#" && nm != "N" { if last[nm] == s { return "" }; last[nm] = s }
            return ff.prefix + s
        }
        func emit(_ tpl: String, _ isMove: Bool) {
            var any = false
            let line = Rx.c("\\[([A-Za-z_0-9]+)\\]").replace(tpl) { mr -> String in
                let n = mr.gv(1).uppercased()
                if n.allSatisfy({ $0.isASCII && $0.isNumber }) { return String(UnicodeScalar(UInt8(Int(n) ?? 0))) }
                if n == "N" { let f = pp.fmt["N"]; let s = f != nil ? f!.prefix + fmtNum(lineNo, f!) : "N" + String(Int64(lineNo)); lineNo += pp.lineInc; if lineNo > pp.lineMax { lineNo = pp.lineStart }; return s }
                let s = varVal(n)
                if !s.isEmpty && ["X", "Y", "Z"].contains(n) { any = true }
                return s
            }
            if isMove && !any { return }
            out.append(line)
        }
        func setTool(_ t: PostTool) { ctx["T"] = String(t.num); ctx["S"] = Double(t.spindle); ctx["TOOLNAME"] = t.name; ctx["TOOLDIA"] = t.dia.map { "\($0)" } ?? "" }
        ctx["XH"] = home.x; ctx["YH"] = home.y; ctx["ZH"] = home.z; ctx["PATHNAME"] = name
        let paths = paths0.filter { !$0.moves.isEmpty }
        if paths.isEmpty { return "" }
        setTool(paths[0].tool)
        for l in pp.start { emit(l, false) }
        for l in pp.start { for (h, a) in [("XH", "X"), ("YH", "Y"), ("ZH", "Z")] where l.uppercased().contains("[\(h)]") && pp.fmt[a] != nil { last[a] = fmtNum(ctx[h] as! Double, pp.fmt[a]!) } }
        var prevRapid = true; var curTool = paths[0].tool.num
        let rapidT = pp.tpl["RAPID_RATE_MOVE"] ?? "G0[X][Y][Z]", firstT = pp.tpl["FIRST_FEED_RATE_MOVE"] ?? "G1[X][Y][Z][F]", feedT = pp.tpl["FEED_RATE_MOVE"] ?? "[X][Y][Z]"
        for (i, tp) in paths.enumerated() {
            if i > 0 && tp.tool.num != curTool {
                setTool(tp.tool)
                for l in pp.toolchange { emit(l, false) }
                if !pp.toolchange.isEmpty { last["X"] = nil; last["Y"] = nil; last["Z"] = nil; last["F"] = nil }
                curTool = tp.tool.num
            }
            for m in tp.moves {
                ctx["X"] = m.x; ctx["Y"] = m.y; ctx["Z"] = m.z
                if m.r { emit(rapidT, true); prevRapid = true }
                else {
                    ctx["F"] = m.f
                    let fs = pp.fmt["F"].map { fmtNum(m.f, $0) } ?? "\(m.f)"
                    let first = prevRapid || last["F"] != fs
                    emit(first ? firstT : feedT, true)
                    prevRapid = false
                }
            }
        }
        ctx["X"] = home.x; ctx["Y"] = home.y; ctx["Z"] = home.z; emit(rapidT, true)
        for l in pp.end { emit(l, false) }
        return out.joined(separator: pp.eol) + pp.eol
    }
}
