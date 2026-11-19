import Foundation

/// Небольшие помощники, чтобы порт с Kotlin оставался близким к оригиналу.
final class Rx {
    let re: NSRegularExpression
    init(_ p: String, _ opts: NSRegularExpression.Options = []) { re = try! NSRegularExpression(pattern: p, options: opts) }
    private static var cache: [String: Rx] = [:]
    static func c(_ p: String) -> Rx { if let r = cache[p] { return r }; let r = Rx(p); cache[p] = r; return r }

    struct Match {
        let s: String; let m: NSTextCheckingResult
        var value: String { g(0) ?? "" }
        /// группа или nil, если не участвовала
        func g(_ i: Int) -> String? { guard i < m.numberOfRanges, let r = Range(m.range(at: i), in: s) else { return nil }; return String(s[r]) }
        /// как groupValues в Kotlin: пустая строка вместо nil
        func gv(_ i: Int) -> String { g(i) ?? "" }
        var range: Range<String.Index> { Range(m.range, in: s)! }
    }
    func all(_ s: String) -> [Match] { re.matches(in: s, range: NSRange(s.startIndex..., in: s)).map { Match(s: s, m: $0) } }
    func first(_ s: String) -> Match? { re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)).map { Match(s: s, m: $0) } }
    func test(_ s: String) -> Bool { first(s) != nil }
    func replace(_ s: String, _ with: String) -> String { re.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: NSRegularExpression.escapedTemplate(for: with)) }
    func replace(_ s: String, _ f: (Match) -> String) -> String {
        var out = ""; var last = s.startIndex
        for m in all(s) { let r = m.range; out += s[last..<r.lowerBound]; out += f(m); last = r.upperBound }
        out += s[last...]; return out
    }
    func split(_ s: String) -> [String] {
        var out: [String] = []; var last = s.startIndex
        for m in all(s) { let r = m.range; if r.isEmpty { continue }; out.append(String(s[last..<r.lowerBound])); last = r.upperBound }
        out.append(String(s[last...])); return out
    }
}

extension String {
    func toDoubleOrNull() -> Double? { let t = self; if t.isEmpty || t.hasPrefix(" ") || t.hasSuffix(" ") { return nil }; if let d = Double(t) { return d }; if t.hasSuffix("."), let d = Double(t + "0") { return d }; return nil }
    func toIntOrNull() -> Int? { Int(self) }
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    /// подстрока по индексам символов (как Kotlin substring)
    func sub(_ a: Int, _ b: Int? = nil) -> String {
        let n = count; let a = max(0, min(a, n)); let b = max(a, min(b ?? n, n))
        let s = index(startIndex, offsetBy: a), e = index(startIndex, offsetBy: b); return String(self[s..<e])
    }
    func ch(_ i: Int) -> Character { self[index(startIndex, offsetBy: i)] }
    func padStart(_ n: Int, _ c: Character = " ") -> String { count >= n ? self : String(repeating: String(c), count: n - count) + self }
    func padEnd(_ n: Int, _ c: Character = " ") -> String { count >= n ? self : self + String(repeating: String(c), count: n - count) }
    func removePrefix(_ p: String) -> String { hasPrefix(p) ? String(dropFirst(p.count)) : self }
    func removeSuffix(_ p: String) -> String { hasSuffix(p) ? String(dropLast(p.count)) : self }
}

extension Array {
    func getOrNull(_ i: Int) -> Element? { i >= 0 && i < count ? self[i] : nil }
}

/// Округление «половина вверх» по точному двоичному значению (как BigDecimal.setScale(HALF_UP).stripTrailingZeros().toPlainString())
func fmtNum(_ v: Double, _ dec: Int, strip: Bool = true) -> String {
    if !v.isFinite { return "0" }
    let s = String(format: "%.40f", abs(v))
    let parts = s.split(separator: ".", omittingEmptySubsequences: false)
    let ip = Array(parts[0]); let fp = parts.count > 1 ? Array(parts[1]) : []
    var digits: [Int] = ip.map { Int($0.asciiValue! - 48) } + (0..<dec).map { $0 < fp.count ? Int(fp[$0].asciiValue! - 48) : 0 }
    let next = dec < fp.count ? Int(fp[dec].asciiValue! - 48) : 0
    if next >= 5 {
        var k = digits.count - 1; var carry = true
        while carry && k >= 0 { digits[k] += 1; if digits[k] == 10 { digits[k] = 0; k -= 1 } else { carry = false } }
        if carry { digits.insert(1, at: 0) }
    }
    let nInt = digits.count - dec
    var intS = digits[0..<nInt].map { String($0) }.joined(); var fracS = digits[nInt...].map { String($0) }.joined()
    if strip { while fracS.hasSuffix("0") { fracS.removeLast() } }
    while intS.count > 1 && intS.hasPrefix("0") { intS.removeFirst() }
    if intS.isEmpty { intS = "0" }
    var r = fracS.isEmpty ? intS : intS + "." + fracS
    if v < 0 && (r != "0" || !strip) { r = "-" + r }
    return r
}

/// Kotlin roundToInt / Math.round: половина вверх (к +∞)
@inline(__always) func kround(_ x: Double) -> Int { Int((x + 0.5).rounded(.down)) }
@inline(__always) func kroundL(_ x: Double) -> Int64 { Int64((x + 0.5).rounded(.down)) }
