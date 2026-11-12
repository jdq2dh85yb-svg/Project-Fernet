import SwiftUI

@main
struct ProjectFernetApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var backend  = BackendManager()
    @StateObject private var downloadVM = FernetDownloadViewModel()
    @StateObject private var shopVM     = FernetShopViewModel()
    @StateObject private var leaderboardVM = FernetLeaderboardViewModel()

    var body: some Scene {
        WindowGroup {
            FernetRootView()
                .environmentObject(settings)
                .environmentObject(backend)
                .environmentObject(downloadVM)
                .environmentObject(shopVM)
                .environmentObject(leaderboardVM)
                .preferredColorScheme(.dark)
        }
    }
}
