import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
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

            BannerAdView(adUnitID: "ca-app-pub-9404799280370656/6375047719")
                .frame(height: 50)
        }
    }
}
