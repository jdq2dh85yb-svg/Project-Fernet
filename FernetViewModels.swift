import SwiftUI
import Combine

// MARK: - Download ViewModel

final class FernetDownloadViewModel: ObservableObject {
    enum DownloadState {
        case idle, downloading, paused, complete
    }

    @Published var state: DownloadState = .idle
    @Published var progress: Double = 0
    @Published var speedText: String = "0 MB/s"
    @Published var etaText: String = "--:--"
    @Published var downloadedGB: Double = 0

    let totalGB: Double = 26.4
    private var timer: AnyCancellable?

    func start() {
        guard state != .downloading else { return }
        state = .downloading
        scheduleTimer()
    }

    func pause() {
        state = .paused
        timer?.cancel()
    }

    func resume() {
        guard state == .paused else { return }
        state = .downloading
        scheduleTimer()
    }

    func reset() {
        timer?.cancel()
        state = .idle
        progress = 0
        downloadedGB = 0
        speedText = "0 MB/s"
        etaText = "--:--"
    }

    private func scheduleTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 0.3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.state == .downloading else { return }
                let speed = Double.random(in: 8...25)
                let increment = (speed / 1024) * 0.3
                self.progress = min(self.progress + increment / self.totalGB, 1.0)
                self.downloadedGB = self.progress * self.totalGB
                self.speedText = String(format: "%.1f MB/s", speed)
                let remaining = (self.totalGB - self.downloadedGB) / (speed / 1024)
                let mins = Int(remaining / 60)
                let secs = Int(remaining) % 60
                self.etaText = String(format: "%d:%02d", mins, secs)
                if self.progress >= 1.0 {
                    self.state = .complete
                    self.timer?.cancel()
                }
            }
    }
}

// MARK: - Item Shop ViewModel

struct ShopItem: Identifiable {
    let id = UUID()
    let name: String
    let rarity: Rarity
    let type: ItemType
    let price: Int
    let description: String
    var isOwned: Bool = false

    enum Rarity: String {
        case legendary, epic, rare, uncommon
        var color: Color {
            switch self {
            case .legendary: return .fernetGold
            case .epic:      return .fernetViolet
            case .rare:      return .fernetCyan
            case .uncommon:  return Color(red: 0.3, green: 0.8, blue: 0.3)
            }
        }
        var gradient: LinearGradient {
            switch self {
            case .legendary:
                return LinearGradient(colors: [Color(red:1,green:0.7,blue:0.1), Color(red:0.8,green:0.4,blue:0)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .epic:
                return LinearGradient(colors: [.fernetViolet, Color(red:0.25,green:0.1,blue:0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .rare:
                return LinearGradient(colors: [.fernetCyan, .fernetCyanDim], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .uncommon:
                return LinearGradient(colors: [Color(red:0.3,green:0.75,blue:0.3), Color(red:0.1,green:0.5,blue:0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
    enum ItemType: String { case outfit, glider, pickaxe, emote, wrap }
}

final class FernetShopViewModel: ObservableObject {
    @Published var featuredItems: [ShopItem] = []
    @Published var dailyItems: [ShopItem] = []
    @Published var purchasedItemID: UUID? = nil
    @Published var showPurchaseAnim = false

    init() { load() }

    private func load() {
        featuredItems = [
            ShopItem(name: "Aqua Commander", rarity: .legendary, type: .outfit,  price: 2000, description: "Master of the flooded seas. Full battle-ready aquatic suit."),
            ShopItem(name: "Tidecaller",      rarity: .epic,     type: .outfit,  price: 1500, description: "She rises with the flood waters. Iconic Chapter 2 silhouette."),
            ShopItem(name: "Shark Rider",     rarity: .epic,     type: .glider,  price: 1200, description: "Ride a great white through the skies."),
            ShopItem(name: "Coral Crusher",   rarity: .legendary, type: .pickaxe, price: 1800, description: "Harvested from deep sea ruins."),
        ]
        dailyItems = [
            ShopItem(name: "Wave Breaker",    rarity: .rare,     type: .outfit,  price: 1200, description: "Casual coastal warrior aesthetic."),
            ShopItem(name: "Current",         rarity: .uncommon, type: .emote,   price: 500,  description: "Flow like water, strike like lightning."),
            ShopItem(name: "Oceanside",       rarity: .rare,     type: .wrap,    price: 700,  description: "Saltwater texture for all your gear."),
            ShopItem(name: "Bubble Pop",      rarity: .uncommon, type: .emote,   price: 300,  description: "Blow 'em away with style."),
            ShopItem(name: "Deep Dive",       rarity: .rare,     type: .glider,  price: 1000, description: "An experimental submersible turned paraglider."),
            ShopItem(name: "Trident Blade",   rarity: .epic,     type: .pickaxe, price: 1500, description: "Forged in the depths of the ocean."),
        ]
    }

    func purchase(_ item: ShopItem) {
        purchasedItemID = item.id
        withAnimation(.spring(duration: 0.4, bounce: 0.5)) {
            showPurchaseAnim = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            self.showPurchaseAnim = false
            self.purchasedItemID = nil
        }
        // Mark owned in both arrays
        if let i = featuredItems.firstIndex(where: { $0.id == item.id }) {
            featuredItems[i].isOwned = true
        }
        if let i = dailyItems.firstIndex(where: { $0.id == item.id }) {
            dailyItems[i].isOwned = true
        }
    }
}

// MARK: - Leaderboard ViewModel

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let wins: Int
    let eliminations: Int
    let matches: Int
    var winRate: Double { Double(wins) / Double(matches) * 100 }
    var kd: Double { Double(eliminations) / Double(max(matches - wins, 1)) }
}

final class FernetLeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []

    init() {
        entries = [
            LeaderboardEntry(rank: 1,  name: "StormKing_X",     wins: 847, eliminations: 9241, matches: 1104),
            LeaderboardEntry(rank: 2,  name: "AquaSniper",       wins: 731, eliminations: 8107, matches: 1052),
            LeaderboardEntry(rank: 3,  name: "FloodedSoul",      wins: 698, eliminations: 7834, matches: 1021),
            LeaderboardEntry(rank: 4,  name: "TideRunner99",     wins: 612, eliminations: 6901, matches: 988),
            LeaderboardEntry(rank: 5,  name: "CoralGhost",       wins: 589, eliminations: 6543, matches: 971),
            LeaderboardEntry(rank: 6,  name: "NauticalNova",     wins: 541, eliminations: 6102, matches: 950),
            LeaderboardEntry(rank: 7,  name: "DeepBlueElite",    wins: 503, eliminations: 5887, matches: 920),
            LeaderboardEntry(rank: 8,  name: "WaveRider_Z",      wins: 477, eliminations: 5540, matches: 905),
            LeaderboardEntry(rank: 9,  name: "SharkBait",        wins: 452, eliminations: 5231, matches: 882),
            LeaderboardEntry(rank: 10, name: "Driftwood",        wins: 431, eliminations: 4998, matches: 860),
            LeaderboardEntry(rank: 11, name: "BubbleWrapped",    wins: 410, eliminations: 4780, matches: 841),
            LeaderboardEntry(rank: 12, name: "AbyssalArcher",    wins: 388, eliminations: 4521, matches: 820),
            LeaderboardEntry(rank: 13, name: "TempestFury",      wins: 361, eliminations: 4310, matches: 800),
            LeaderboardEntry(rank: 14, name: "CrashWave",        wins: 344, eliminations: 4097, matches: 783),
            LeaderboardEntry(rank: 15, name: "SaltSpray",        wins: 320, eliminations: 3870, matches: 760),
        ]
    }
}
