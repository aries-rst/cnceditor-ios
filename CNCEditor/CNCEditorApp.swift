import SwiftUI

@main
struct CNCEditorApp: App {
    var body: some Scene { WindowGroup { SmokeView() } }
}

/// Временный экран проверки сборки (будет заменён редактором).
struct SmokeView: View {
    var body: some View {
        let r = Geom.Shapes.rect(0, 0, 100, 50)
        let o = Geom.offset([r], 5)
        return Text("CNC Editor 2D — build check\noffset paths: \(o.count), num: \(fmtNum(2.0005, 3))").padding()
    }
}
