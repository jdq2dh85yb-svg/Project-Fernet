import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        TabView(selection: $settings.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            SeasonLibraryView()
                .tabItem {
                    Label("Seasons", systemImage: "square.grid.2x2.fill")
                }
                .tag(2)

            BackendDashboardView()
                .tabItem {
                    Label("Backend", systemImage: "server.rack")
                }
                .tag(1)

            NavigationStack {
                LockerView()
            }
            .tabItem {
                Label("Locker", systemImage: "tshirt.fill")
            }
            .tag(4)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(Color(red: 0.25, green: 0.72, blue: 1))
        .toolbarBackground(
            Color(red: 0.03, green: 0.045, blue: 0.08).opacity(0.94),
            for: .tabBar
        )
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .preferredColorScheme(.dark)
    }
}
