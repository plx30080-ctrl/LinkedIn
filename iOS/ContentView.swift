import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            CreateView()
                .tabItem {
                    Label("Create", systemImage: "pencil.and.outline")
                }
                .tag(0)

            QueueView()
                .tabItem {
                    Label("Queue", systemImage: "list.bullet.clipboard")
                }
                .badge(appState.queuedCount > 0 ? appState.queuedCount : 0)
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .badge(appState.apiKey.isEmpty ? "!" : nil)
                .tag(2)
        }
    }
}
