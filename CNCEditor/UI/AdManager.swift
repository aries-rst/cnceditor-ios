/* Реклама AdMob (порт Ads.kt). Включается для релиза: ADS_ENABLED = true (как на Android — пока выключена). */
import SwiftUI
import UIKit
import AppTrackingTransparency
import GoogleMobileAds
import UserMessagingPlatform

enum AdManager {
    static let ADS_ENABLED = false
    static let BANNER_ID = "ca-app-pub-9638598348702189/3684386601"
    static let INTERSTITIAL_ID = "ca-app-pub-9638598348702189/3324247775"
    private static var started = false
    private static var inter: InterstitialAd? = nil
    private static var lastShow = Date.distantPast
    private static let delegate = FSDelegate()

    static func active() -> Bool { ADS_ENABLED && started && !Premium.on() }
    /// запуск: согласие (UMP) → ATT → SDK
    static func initialize() {
        if !ADS_ENABLED { return }
        Task { @MainActor in
            do { try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
                 if let vc = topVC() { try await ConsentForm.loadAndPresentIfRequired(from: vc) } } catch {}
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined { _ = await ATTrackingManager.requestTrackingAuthorization() }
            if ConsentInformation.shared.canRequestAds { start() }
        }
    }
    private static func start() { if started { return }; started = true; MobileAds.shared.start(completionHandler: nil); loadInter(); AppState.shared.bump() }
    private static func loadInter() { if Premium.on() { return }; InterstitialAd.load(with: INTERSTITIAL_ID, request: Request()) { ad, _ in inter = ad } }
    /// не чаще раза в 3 минуты, после сохранения УП
    static func maybeInterstitial() {
        if !active() { return }
        guard let ad = inter, let vc = topVC() else { loadInter(); return }
        if Date().timeIntervalSince(lastShow) < 180 { return }
        lastShow = Date(); inter = nil; delegate.onDismiss = { loadInter() }; ad.fullScreenContentDelegate = delegate; ad.present(from: vc)
    }
    /// кнопка «Настройки конфиденциальности» (UMP) — видна, только если нужна
    static func privacyRequired() -> Bool { ADS_ENABLED && ConsentInformation.shared.privacyOptionsRequirementStatus == .required }
    static func showPrivacy() { guard let vc = topVC() else { return }; Task { @MainActor in try? await ConsentForm.presentPrivacyOptionsForm(from: vc) } }
}
final class FSDelegate: NSObject, FullScreenContentDelegate {
    var onDismiss: () -> Void = {}
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { onDismiss() }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { onDismiss() }
}
struct AdBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let v = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width))
        v.adUnitID = AdManager.BANNER_ID; v.rootViewController = topVC(); v.load(Request()); return v
    }
    func updateUIView(_ v: BannerView, context: Context) {}
}
struct AdBanner: View {
    var body: some View { if AdManager.active() { AdBannerView().frame(height: 60) } }
}
