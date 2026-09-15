import SwiftData
import SwiftUI

/// アプリのルート。3 タブのシェルとプリセット投入のトリガーを担う。
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection: AppTab = .buyList
    @State private var didSeed = false

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selection {
                case .buyList:
                    BuyListView(selection: $selection)
                case .stocks:
                    StocksView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            LOTabBar(selection: $selection)
        }
        // ヘッダーの padding 64 は画面上端からの距離なので、上の safe area は無視する。
        .ignoresSafeArea(.container, edges: .top)
        .background(LOColor.background.ignoresSafeArea())
        .onAppear(perform: seedIfNeeded)
    }

    private func seedIfNeeded() {
        guard !didSeed else { return }
        didSeed = true
        CategorySeeder.seedIfNeeded(in: modelContext)
    }
}
