/* Премиум — разовая покупка навсегда (StoreKit 2): без рекламы и без дневного лимита на программы для станка. Порт Premium.kt */
import Foundation
import StoreKit

enum Premium {
    static let PRODUCT_ID = "com.ariesrst.cnceditor.app.premium"
    static let FREE_PER_DAY = 1
    private static var product: Product? = nil
    static var price: String? = nil
    static func on() -> Bool { Prefs.bool("premium") }
    private static func set(_ v: Bool) { Prefs.setBool("premium", v); DispatchQueue.main.async { AppState.shared.bump() } }

    static func initApp() {
        Task { @MainActor in
            await query(); await refresh()
            for await r in Transaction.updates { if case .verified(let t) = r, t.productID == PRODUCT_ID { set(t.revocationDate == nil); await t.finish() } }
        }
    }
    @MainActor private static func query() async {
        if let p = try? await Product.products(for: [PRODUCT_ID]).first { product = p; price = p.displayPrice; AppState.shared.bump() }
    }
    /// проверить прошлые покупки (новый телефон, переустановка)
    @MainActor @discardableResult private static func refresh() async -> Bool {
        var own = false
        for await r in Transaction.currentEntitlements { if case .verified(let t) = r, t.productID == PRODUCT_ID, t.revocationDate == nil { own = true } }
        if own { set(true) } else if on() { set(false) }
        return own
    }
    static func restore(_ done: @escaping (Bool) -> Void) { Task { @MainActor in try? await AppStore.sync(); let own = await refresh(); done(own) } }
    /// done(false) — магазин недоступен
    static func buy(_ done: @escaping (Bool) -> Void) {
        Task { @MainActor in
            if product == nil { await query() }
            guard let p = product else { done(false); return }
            if let r = try? await p.purchase(), case .success(let v) = r, case .verified(let t) = v { set(true); await t.finish() }
            done(true)
        }
    }

    // ---- дневной лимит на программы для станка ----
    private static func today() -> String { let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }
    static func usedToday() -> Int { Prefs.str("ncDay") == today() ? Prefs.int("ncCount", 0) : 0 }
    static func canSaveNc() -> Bool { on() || usedToday() < FREE_PER_DAY }
    static func countNc() { if !on() { let n = usedToday() + 1; Prefs.set("ncDay", today()); Prefs.setInt("ncCount", n) } }
}
