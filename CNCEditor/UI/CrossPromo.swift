/* Другие приложения ARESTI Labs + сайт (порт CrossPromo.kt). На iOS, пока приложения не вышли в App Store, ссылки ведут на сайт ARESTI Labs. */
import SwiftUI

enum CrossPromo {
    static let SITE = "https://aresti-labs.web.app"
    struct App { let key: String; let icon: String; let ru: String; let en: String; var appStore: String? = nil }
    static let APPS: [App] = [
        App(key: "nardy", icon: "🎲", ru: "Нарды: Шёлковый путь", en: "Silk Road Backgammon"),
        App(key: "chess", icon: "♞", ru: "Шахматная задача дня", en: "Chess Puzzle of the Day"),
        App(key: "checkers", icon: "⛀", ru: "Шашки", en: "Checkers"),
        App(key: "durak", icon: "🃏", ru: "Дурак", en: "Durak"),
        App(key: "domino", icon: "🁢", ru: "Домино", en: "Dominoes"),
        App(key: "builder", icon: "🏠", ru: "Строитель", en: "Home Builder"),
        App(key: "comics", icon: "💬", ru: "Комиксы", en: "Comics Maker"),
        App(key: "tree", icon: "🌳", ru: "Моё древо", en: "My Family Tree"),
        App(key: "office", icon: "🏢", ru: "Мой офис", en: "MyOffice"),
    ]
    static func open(_ a: App) { open(a.appStore ?? SITE) }
    static func open(_ url: String) { if let u = URL(string: url) { UIApplication.shared.open(u) } }
}

struct CrossPromoRow: View {
    var body: some View {
        VStack {
            Text(tr("Больше приложений от ARESTI Labs")).font(.system(size: 14, weight: .bold)).foregroundColor(Color(argb: 0xFF445566))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack { ForEach(CrossPromo.APPS, id: \.key) { a in
                    VStack { Text(a.icon).font(.system(size: 26)); Text(L10n.lang == "ru" || L10n.lang == "kk" ? a.ru : a.en).font(.system(size: 11)).multilineTextAlignment(.center).lineLimit(3) }
                        .frame(width: 108).padding(8).background(Color.white).cornerRadius(10).onTapGesture { CrossPromo.open(a) }
                } }.padding(.vertical, 8)
            }
            Text("🌐 " + tr("Сайт ARESTI Labs") + " — aresti-labs.web.app").font(.system(size: 13)).foregroundColor(BLUE).padding(6).onTapGesture { CrossPromo.open(CrossPromo.SITE) }
        }.padding(.top, 18)
    }
}
