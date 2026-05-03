import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("今日", systemImage: "face.smiling")
                }

            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "chart.bar")
                }
        }
    }
}
