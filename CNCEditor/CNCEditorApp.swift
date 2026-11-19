/* ЧПУ Редактор 2D — iOS (порт MainActivity.kt): заставка, выбор языка, стартовый экран, редактор. */
import SwiftUI

@main
struct CNCEditorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {
        if let l = Prefs.str("lang") { L10n.lang = l }; L10n.load()
        Pages.initAll(); ToolStore.load(AppState.shared); Premium.initApp()
        applyOrientation(Prefs.str("orient") ?? "auto")
        DispatchQueue.global(qos: .userInitiated).async { loadFonts() }
    }
    var body: some Scene { WindowGroup { Root(s: AppState.shared).onAppear { AdManager.initialize() }.onOpenURL { u in AppState.shared.openURL(u) } } }
}

func loadFonts() {
    func a(_ n: String, _ e: String) -> Data? { Bundle.main.url(forResource: n, withExtension: e).flatMap { try? Data(contentsOf: $0) } }
    do {
        if let r = a("LiberationSans-Regular", "ttf") { try TextEngine.registerTtf("sans", "Arial-подобный (Liberation Sans)", r, a("LiberationSans-Bold", "ttf")) }
        if let r = a("LiberationSerif-Regular", "ttf") { try TextEngine.registerTtf("serif", "Times-подобный (Liberation Serif)", r, a("LiberationSerif-Bold", "ttf")) }
        if let r = a("LiberationMono-Regular", "ttf") { try TextEngine.registerTtf("mono", "Courier-подобный (Liberation Mono)", r) }
        if let r = a("DejaVuSans", "ttf") { try TextEngine.registerTtf("dvsans", "DejaVu Sans", r, a("DejaVuSans-Bold", "ttf")) }
        if let r = a("DejaVuSerif", "ttf") { try TextEngine.registerTtf("dvserif", "DejaVu Serif", r) }
        if let h = a("hershey", "txt") { TextEngine.registerHershey(String(decoding: h, as: UTF8.self)) }
    } catch { DispatchQueue.main.async { AppState.shared.toast("Шрифты: \(error.localizedDescription)") } }
}

extension AppState {
    /// файл, открытый из «Файлов» / «Поделиться» → в приложение
    func openURL(_ u: URL) {
        let ok = u.startAccessingSecurityScopedResource(); defer { if ok { u.stopAccessingSecurityScopedResource() } }
        guard let d = try? Data(contentsOf: u) else { return }
        openData(u, d)
    }
}

struct Root: View {
    @ObservedObject var s: AppState
    @State private var splash = true
    @State private var askLang = Prefs.str("lang") == nil
    var body: some View {
        let _ = s.tick
        ZStack(alignment: .bottom) {
            Group {
                if splash { Splash() }
                else if askLang { LangFirst { k in L10n.lang = k; Prefs.set("lang", k); askLang = false; s.bump() } }
                else if s.screen == "editor" { EditorScreen(s: s) { if s.doc.dirty { s.dialog("home", nil) } else { s.closePage(); s.screen = "start"; s.bump() } } }
                else { StartScreen(s: s) }
            }
            if !splash && !askLang { DialogsHost(s: s) { s.closePage(); s.screen = "start"; s.bump() } }
            if let t = s.toastText { Text(t).font(.system(size: 14)).foregroundColor(.white).multilineTextAlignment(.center).padding(.horizontal, 14).padding(.vertical, 9).background(Color.black.opacity(0.8)).cornerRadius(18).padding(.bottom, 70).padding(.horizontal, 20).allowsHitTesting(false) }
        }
        .environment(\.layoutDirection, L10n.rtl ? .rightToLeft : .leftToRight)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { splash = false } }
    }
}

struct Logo: View {
    let size: CGFloat
    var body: some View { (Text(tr("ЧПУ Редактор") + " ").foregroundColor(BLUE) + Text("2D").foregroundColor(Color(argb: 0xFFC8382A))).font(.system(size: size, weight: .bold)) }
}
struct Splash: View {
    var body: some View {
        VStack { ToolIcon("rect", 96); Spacer().frame(height: 12); Logo(size: 30); Text("ARESTI Labs").foregroundColor(.gray).font(.system(size: 14)).padding(.top, 8) }
            .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.white)
    }
}
struct LangFirst: View {
    let onPick: (String) -> Void
    var body: some View {
        let sys = L10n.fromSystem()
        VStack {
            Text("Язык · Language · Til · 语言").font(.system(size: 22, weight: .bold)).padding(16)
            ScrollView { VStack { ForEach(L10n.LANGS, id: \.0) { (k, n) in
                Button { onPick(k) } label: { Text(n).font(.system(size: 17)).frame(width: 260).padding(10).foregroundColor(k == sys ? .white : BLUE).background(k == sys ? BLUE : Color.white).cornerRadius(22).overlay(RoundedRectangle(cornerRadius: 22).stroke(BLUE)) }.padding(4)
            } } }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.white)
    }
}

struct StartScreen: View {
    @ObservedObject var s: AppState
    var body: some View {
        let _ = s.tick
        ScrollView {
            VStack {
                Spacer().frame(height: 16); Logo(size: 32)
                Menu { ForEach(L10n.LANGS, id: \.0) { (k, n) in Button((k == L10n.lang ? "✓ " : "    ") + n) { L10n.lang = k; Prefs.set("lang", k); s.bump() } } } label: {
                    Text("🌐  " + L10n.langName() + "  ▾").font(.system(size: 15)).padding(.horizontal, 14).padding(.vertical, 8).overlay(RoundedRectangle(cornerRadius: 18).stroke(BLUE)) }.padding(.vertical, 10)
                item("new", "Создать новую модель") { s.dialog("newModel", nil) }
                item("open", "Открыть модель", "DXF, SVG, G-код .tap / .nc или проект .cnc2d") { s.openFile() }
                item("image", "Модель из картинки / фото", "подложка для обводки и векторизация") { s.dialog("imgSrc", nil) }
                if s.doc.hasModel { item("select", "Вернуться к модели", s.doc.fileName ?? "") { s.screen = "editor"; s.bump() } }
                item("measure", "Инструкция") { s.dialog("help", nil) }
                item("savetp", Premium.on() ? "Премиум активен" : "Премиум", Premium.on() ? "" : "без рекламы и без лимита программ") { s.dialog("premium", nil) }
                if AdManager.privacyRequired() { item("layers", "Настройки конфиденциальности") { AdManager.showPrivacy() } }
                let rec = Recent.list()
                if !rec.isEmpty { Text(tr("Последние файлы") + ":").foregroundColor(.gray).padding(.top, 10); ForEach(rec, id: \.self) { Text("📄 " + $0).font(.system(size: 13)).foregroundColor(.secondary) } }
                CrossPromoRow()
            }.padding(16)
        }.background(PANEL)
    }
    private func item(_ icon: String, _ title: String, _ sub: String = "", _ act: @escaping () -> Void) -> some View {
        HStack {
            ToolIcon(icon, 36)
            VStack(alignment: .leading) { Text(tr(title)).font(.system(size: 17, weight: .bold)).foregroundColor(.primary); if !sub.isEmpty { Text(tr(sub)).font(.system(size: 13)).foregroundColor(.gray) } }.padding(.leading, 14)
            Spacer()
        }.padding(14).frame(maxWidth: 480).background(Color.white).cornerRadius(8).padding(5).contentShape(Rectangle()).onTapGesture(perform: act)
    }
}
