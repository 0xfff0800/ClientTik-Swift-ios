import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var store = SavedStore()
    @StateObject private var model = FetchModel()

    var body: some View {
        TabView {
            FetchScreen()
                .tabItem { Label("جلب", systemImage: "arrow.down.circle.fill") }
            SavedScreen()
                .tabItem { Label("المحفوظات", systemImage: "bookmark.fill") }
        }
        .accentColor(Theme.accent)
        .environmentObject(store)
        .environmentObject(model)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
