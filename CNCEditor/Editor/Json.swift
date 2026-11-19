/* Простой JSON (порт Json.kt): разбор в [String: Any] / [Any] / Double / String / Bool / NSNull и запись обратно.
 * Порядок ключей объектов сохраняется (JMap). */
import Foundation

/// Упорядоченный словарь (как LinkedHashMap в Kotlin)
final class JMap: Sequence {
    private(set) var keys: [String] = []; private var dict: [String: Any] = [:]
    init() {}
    init(_ pairs: [(String, Any?)]) { for (k, v) in pairs { self[k] = v } }
    subscript(k: String) -> Any? {
        get { dict[k] }
        set { if let v = newValue, !(v is NSNull) { if dict[k] == nil { keys.append(k) }; dict[k] = v } else if dict[k] != nil { dict[k] = nil; keys.removeAll { $0 == k } } }
    }
    var count: Int { keys.count }
    var isEmpty: Bool { keys.isEmpty }
    func contains(_ k: String) -> Bool { dict[k] != nil }
    func makeIterator() -> AnyIterator<(String, Any)> { var i = 0; let ks = keys; let d = dict; return AnyIterator { while i < ks.count { let k = ks[i]; i += 1; if let v = d[k] { return (k, v) } }; return nil } }
}

func jnum(_ v: Any?) -> Double? {
    switch v { case let d as Double: return d; case let i as Int: return Double(i); case let f as Float: return Double(f); case let l as Int64: return Double(l); case let n as NSNumber: return n.doubleValue; default: return nil }
}

enum Json {
    static func parse(_ s: String) throws -> Any? { let p = Parser(s); p.ws(); return try p.value() }
    private final class Parser {
        let s: [Character]; var i = 0
        init(_ s: String) { self.s = Array(s) }
        func ws() { while i < s.count && s[i].isWhitespace { i += 1 } }
        func value() throws -> Any? {
            ws()
            if i >= s.count { throw IoError(msg: "JSON: неожиданный конец") }
            let c = s[i]
            switch c {
            case "{": return try obj()
            case "[": return try arr()
            case "\"": return try str()
            case "t": i += 4; return true
            case "f": i += 5; return false
            case "n": i += 4; return nil
            default: if c == "-" || c.isASCII && c.isNumber { return try num() }; throw IoError(msg: "JSON: символ '\(c)' в позиции \(i)")
            }
        }
        func obj() throws -> JMap {
            let m = JMap(); i += 1; ws()
            if s[i] == "}" { i += 1; return m }
            while true { ws(); let k = try str(); ws(); i += 1; m[k] = try value(); ws(); if s[i] == "," { i += 1; continue }; i += 1; return m }
        }
        func arr() throws -> [Any] {
            var a: [Any] = []; i += 1; ws()
            if s[i] == "]" { i += 1; return a }
            while true { a.append(try value() ?? NSNull()); ws(); if s[i] == "," { i += 1; continue }; i += 1; return a }
        }
        func str() throws -> String {
            var sb = ""; i += 1
            while true {
                if i >= s.count { throw IoError(msg: "JSON: строка не закрыта") }
                let c = s[i]; i += 1
                if c == "\"" { return sb }
                if c == "\\" {
                    let e = s[i]; i += 1
                    switch e {
                    case "n": sb.append("\n"); case "t": sb.append("\t"); case "r": sb.append("\r"); case "b": sb.append("\u{8}"); case "f": sb.append("\u{c}")
                    case "u": let hex = String(s[i..<(i + 4)]); i += 4; if let v = UInt32(hex, radix: 16), let u = UnicodeScalar(v) { sb.unicodeScalars.append(u) }
                    default: sb.append(e)
                    }
                } else { sb.append(c) }
            }
        }
        func num() throws -> Double { let st = i; while i < s.count && (s[i].isASCII && s[i].isNumber || "+-.eE".contains(s[i])) { i += 1 }; guard let d = Double(String(s[st..<i])) else { throw IoError(msg: "JSON: число") }; return d }
    }
    static func stringify(_ v: Any?) -> String { var sb = ""; write(&sb, v); return sb }
    private static func write(_ sb: inout String, _ v: Any?) {
        guard let v = v, !(v is NSNull) else { sb += "null"; return }
        switch v {
        case let b as Bool: sb += b ? "true" : "false"
        case let i as Int: sb += String(i)
        case let d as Double: if !d.isFinite { sb += "0" } else if d == d.rounded() && abs(d) < 1e15 { sb += String(Int64(d)) } else { sb += "\(d)" }
        case let s as String:
            sb += "\""
            for c in s.unicodeScalars { switch c { case "\"": sb += "\\\""; case "\\": sb += "\\\\"; case "\n": sb += "\\n"; case "\r": sb += "\\r"; case "\t": sb += "\\t"; default: if c.value < 32 { sb += String(format: "\\u%04x", c.value) } else { sb.unicodeScalars.append(c) } } }
            sb += "\""
        case let m as JMap: sb += "{"; var f = true; for (k, x) in m { if !f { sb += "," }; f = false; write(&sb, k); sb += ":"; write(&sb, x) }; sb += "}"
        case let m as [String: Any]: sb += "{"; var f = true; for k in m.keys.sorted() { if !f { sb += "," }; f = false; write(&sb, k); sb += ":"; write(&sb, m[k]) }; sb += "}"
        case let a as [Any]: sb += "["; var f = true; for x in a { if !f { sb += "," }; f = false; write(&sb, x) }; sb += "]"
        case let a as [Double]: write(&sb, a.map { $0 as Any })
        default: if let d = jnum(v) { write(&sb, d) } else { write(&sb, "\(v)") }
        }
    }
}

/* удобные чтения из JMap */
extension JMap {
    func d(_ k: String, _ def: Double = 0) -> Double { jnum(self[k]) ?? (self[k] as? String)?.toDoubleOrNull() ?? def }
    func i(_ k: String, _ def: Int = 0) -> Int { jnum(self[k]).map { Int($0) } ?? def }
    func s(_ k: String, _ def: String = "") -> String { self[k] as? String ?? def }
    func b(_ k: String, _ def: Bool = false) -> Bool { self[k] as? Bool ?? def }
    func m(_ k: String) -> JMap? { self[k] as? JMap }
    func l(_ k: String) -> [Any] { self[k] as? [Any] ?? [] }
}
