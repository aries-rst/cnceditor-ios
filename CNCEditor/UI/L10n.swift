/* Перевод интерфейса (порт L10n.kt): исходные строки — русские; для других языков — словарь i18n.tsv, иначе английский, иначе русский. */
import Foundation

enum L10n {
    static var lang = "ru"
    /// 17 языков приложения: код → самоназвание
    static let LANGS: [(String, String)] = [("ru", "Русский"), ("en", "English"), ("uz", "O‘zbekcha"), ("kk", "Қазақша"), ("tr", "Türkçe"), ("de", "Deutsch"), ("es", "Español"),
        ("fr", "Français"), ("pt", "Português"), ("id", "Bahasa Indonesia"), ("hi", "हिन्दी"), ("ar", "العربية"), ("fa", "فارسی"), ("ja", "日本語"), ("ko", "한국어"), ("zh-CN", "简体中文"), ("zh-TW", "繁體中文")]
    static func langName(_ k: String? = nil) -> String { let k = k ?? lang; return LANGS.first { $0.0 == k }?.1 ?? k }
    /// язык телефона → наш код (для первого запуска)
    static func fromSystem() -> String {
        let pref = Locale.preferredLanguages.first ?? "en"; let c = String(pref.split(separator: "-").first ?? "en")
        if c == "zh" { return (pref.contains("Hant") || pref.contains("TW") || pref.contains("HK") || pref.contains("MO")) ? "zh-TW" : "zh-CN" }
        if c == "in" { return "id" }
        return LANGS.contains { $0.0 == c } ? c : "en"
    }
    private static var dict: [String: [String: String]] = [:]
    private static func d(_ ru: String, _ e: String, _ u: String) { dict["en", default: [:]][ru] = e; dict["uz", default: [:]][ru] = u }
    private static var loaded = false
    /// словарь из i18n.tsv: первая строка — коды языков; \n — перенос строки
    static func load() {
        if loaded { return }; loaded = true; builtin()
        guard let url = Bundle.main.url(forResource: "i18n", withExtension: "tsv"), let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        var hdr: [String]? = nil
        for l in text.components(separatedBy: "\n") {
            let line = l.hasSuffix("\r") ? String(l.dropLast()) : l
            let p = line.components(separatedBy: "\t")
            guard let h = hdr else { hdr = p; continue }
            if p.isEmpty || p[0].isEmpty { continue }
            let key = u(p[0])
            for i in 1..<min(p.count, h.count) where !p[i].isEmpty { if dict[h[i], default: [:]][key] == nil { dict[h[i], default: [:]][key] = u(p[i]) } }
        }
    }
    private static func u(_ x: String) -> String { x.replacingOccurrences(of: "\\n", with: "\n") }
    /// перевод: выбранный язык → английский → русский оригинал
    static func tr(_ s: String) -> String { let l = lang; if l == "ru" || s.isEmpty { return s }; return look(l, s) ?? dyn(l, s) }
    private static func look(_ l: String, _ s: String) -> String? { dict[l]?[s] ?? dict["en"]?[s] }
    private static let cyr = Rx("[А-Яа-яЁё]")
    private static let seg = Rx("[^\\d,:;()\\n·×=+]+")
    private static var cache: [String: String] = [:]
    /// строки с числами: переводим по строкам, частям «a / b» и кусочкам между числами
    private static func dyn(_ l: String, _ s: String) -> String {
        if !cyr.test(s) { return s }
        let ck = l + "|" + s; if let c = cache[ck] { return c }
        let r = s.components(separatedBy: "\n").map { line -> String in
            let lt = line.trimmed
            if let t = look(l, lt) { return line.replacingOccurrences(of: lt, with: t) }
            return line.components(separatedBy: " / ").map { part -> String in
                let pt = part.trimmed
                if let t = look(l, pt) { return part.replacingOccurrences(of: pt, with: t) }
                return seg.replace(part) { m in
                    let t = m.value.trimmed; if t.isEmpty || !cyr.test(t) { return m.value }
                    let tr2 = look(l, t) ?? look(l, String(t.reversed().drop(while: { ":.… ".contains($0) }).reversed())) ?? t
                    return m.value.replacingOccurrences(of: t, with: tr2)
                }
            }.joined(separator: " / ")
        }.joined(separator: "\n")
        if cache.count > 2000 { cache.removeAll() }; cache[ck] = r; return r
    }
    static var rtl: Bool { lang == "ar" || lang == "fa" }

    private static func builtin() {
        d("ЧПУ Редактор 2D", "CNC Editor 2D", "ChPU Muharrir 2D")
        d("Создать новую модель", "Create new model", "Yangi model yaratish")
        d("Открыть модель", "Open model", "Modelni ochish")
        d("Модель из картинки / фото", "Model from picture / photo", "Rasm / fotodan model")
        d("Инструкция", "User guide", "Qo‘llanma")
        d("Язык", "Language", "Til")
        d("Выход", "Exit", "Chiqish")
        d("Файл", "File", "Fayl")
        d("Правка", "Edit", "Tahrir")
        d("Модель", "Model", "Model")
        d("Векторы", "Vectors", "Vektorlar")
        d("Траектории", "Toolpaths", "Traektoriyalar")
        d("Справка", "Help", "Yordam")
        d("Проект", "Project", "Loyiha")
        d("Помощник", "Assistant", "Yordamchi")
        d("Новая модель…", "New model…", "Yangi model…")
        d("Открыть… (DXF, SVG, проект)", "Open… (DXF, SVG, project)", "Ochish… (DXF, SVG, loyiha)")
        d("Закрыть модель", "Close model", "Modelni yopish")
        d("Сохранить (DXF)", "Save (DXF)", "Saqlash (DXF)")
        d("Сохранить как", "Save as", "Boshqacha saqlash")
        d("Экспорт", "Export", "Eksport")
        d("Отменить", "Undo", "Bekor qilish")
        d("Повторить", "Redo", "Qaytarish")
        d("Вырезать", "Cut", "Kesib olish")
        d("Копировать", "Copy", "Nusxalash")
        d("Вставить", "Paste", "Qo‘yish")
        d("Удалить", "Delete", "O‘chirish")
        d("Выбрать всё", "Select all", "Hammasini tanlash")
        d("Снять выбор", "Deselect", "Tanlovni bekor qilish")
        d("Размер модели…", "Model size…", "Model o‘lchami…")
        d("Положение нуля…", "Zero position…", "Nol holati…")
        d("Информация о модели", "Model information", "Model ma’lumoti")
        d("Векторные инструменты", "Vector tools", "Vektor asboblari")
        d("Позиция, объединение, обрезка", "Position, combine, trim", "Joylash, birlashtirish, kesish")
        d("Операции с траекториями", "Toolpath operations", "Traektoriya amallari")
        d("2D траектории", "2D toolpaths", "2D traektoriyalar")
        d("Имитация обработки", "Simulation", "Ishlov imitatsiyasi")
        d("Слои", "Layers", "Qatlamlar")
        d("Выбрано", "Selected", "Tanlangan")
        d("Закрыть", "Close", "Yopish")
        d("Отмена", "Cancel", "Bekor")
        d("Сохранить", "Save", "Saqlash")
        d("Да", "Yes", "Ha")
        d("Нет", "No", "Yo‘q")
        d("Размер новой модели", "Size for new model", "Yangi model o‘lchami")
        d("Ширина (X)", "Width (X)", "Kenglik (X)")
        d("Высота (Y)", "Height (Y)", "Balandlik (Y)")
        d("Толщина материала", "Material thickness", "Material qalinligi")
        d("Ноль модели", "Model origin", "Model noli")
        d("Единицы", "Units", "Birliklar")
        d("Настройка материала", "Material setup", "Material sozlamasi")
        d("База инструментов", "Tool database", "Asboblar bazasi")
        d("Сохранить траектории", "Save toolpaths", "Traektoriyalarni saqlash")
        d("Постпроцессор", "Post processor", "Postprotsessor")
        d("Имя файла", "File name", "Fayl nomi")
        d("Добавлять к выбору", "Add to selection", "Tanlovga qo‘shish")
        d("Модель не сохранена. Продолжить?", "Model not saved. Continue?", "Model saqlanmagan. Davom etilsinmi?")
        d("Выйти из программы?", "Exit the app?", "Dasturdan chiqilsinmi?")
        d("Свойства…", "Properties…", "Xususiyatlar…")
        d("Готово", "Done", "Tayyor")
        d("Создать", "Create", "Yaratish")
        d("Применить", "Apply", "Qo‘llash")
        d("Рассчитать", "Calculate", "Hisoblash")
        d("Выбор", "Select", "Tanlash")
        d("Узлы", "Nodes", "Tugunlar")
        d("Сетка", "Grid", "To‘r")
        d("Показать всю модель", "Zoom to model", "Butun model")
        d("Выбрать", "Select", "Tanlash")
        d("Все на текущем слое", "All on current layer", "Joriy qatlamdagi barchasi")
        d("Замкнутые", "Closed", "Yopiq")
        d("Открытые", "Open", "Ochiq")
        d("Похожие по размеру", "Similar size", "O‘lchami o‘xshash")
        d("Обратить выбор", "Invert selection", "Tanlovni teskari qilish")
        d("Список выбранных", "Selected list", "Tanlanganlar ro‘yxati")
        d("Действия", "Actions", "Amallar")
        d("Нет траекторий. Выберите векторы и нажмите «Профиль» или «Вдоль векторов».", "No toolpaths. Select vectors and press Profile or Machine Vectors.", "Traektoriya yo‘q. Vektorlarni tanlang va «Profil» yoki «Vektor bo‘ylab» ni bosing.")
        d("Сначала выберите векторы", "Select vectors first", "Avval vektorlarni tanlang")    }
}
func tr(_ s: String) -> String { L10n.tr(s) }
