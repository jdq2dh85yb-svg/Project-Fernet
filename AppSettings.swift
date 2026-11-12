import SwiftUI

final class AppSettings: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var backendURL: String {
        didSet { defaults.set(backendURL, forKey: "backendURL") }
    }

    @Published var startPath: String {
        didSet { defaults.set(startPath, forKey: "startPath") }
    }

    @Published var stopPath: String {
        didSet { defaults.set(stopPath, forKey: "stopPath") }
    }

    @Published var eventsPath: String {
        didSet { defaults.set(eventsPath, forKey: "eventsPath") }
    }

    @Published var apiToken: String {
        didSet { defaults.set(apiToken, forKey: "apiToken") }
    }

    @Published var gameserverHost: String {
        didSet { defaults.set(gameserverHost, forKey: "gameserverHost") }
    }

    @Published var gameserverPort: String {
        didSet { defaults.set(gameserverPort, forKey: "gameserverPort") }
    }

    @Published var selectedSeasonID: String {
        didSet { defaults.set(selectedSeasonID, forKey: "selectedSeasonID") }
    }

    @Published var selectedVersion: String {
        didSet { defaults.set(selectedVersion, forKey: "selectedVersion") }
    }

    @Published var playerName: String {
        didSet { defaults.set(playerName, forKey: "playerName") }
    }

    @Published var autoConnect: Bool {
        didSet { defaults.set(autoConnect, forKey: "autoConnect") }
    }

    @Published var showNotifications: Bool {
        didSet { defaults.set(showNotifications, forKey: "showNotifications") }
    }

    @Published var selectedTab: Int {
        didSet { defaults.set(selectedTab, forKey: "selectedTab") }
    }

    @Published var hasOnboarded: Bool {
        didSet { defaults.set(hasOnboarded, forKey: "hasOnboarded") }
    }

    init() {
        backendURL = defaults.string(forKey: "backendURL") ?? ""
        startPath = defaults.string(forKey: "startPath") ?? ""
        stopPath = defaults.string(forKey: "stopPath") ?? ""
        eventsPath = defaults.string(forKey: "eventsPath") ?? "/api/events"
        apiToken = defaults.string(forKey: "apiToken") ?? ""
        gameserverHost = defaults.string(forKey: "gameserverHost") ?? "127.0.0.1"
        gameserverPort = defaults.string(forKey: "gameserverPort") ?? "7777"
        selectedSeasonID = defaults.string(forKey: "selectedSeasonID") ?? "c1s5"
        selectedVersion = defaults.string(forKey: "selectedVersion") ?? "v5.4.1"
        playerName = defaults.string(forKey: "playerName") ?? "Player"
        autoConnect = defaults.object(forKey: "autoConnect") as? Bool ?? false
        showNotifications = defaults.object(forKey: "showNotifications") as? Bool ?? true
        selectedTab = defaults.object(forKey: "selectedTab") as? Int ?? 0
        hasOnboarded = defaults.object(forKey: "hasOnboarded") as? Bool ?? false
    }
}
