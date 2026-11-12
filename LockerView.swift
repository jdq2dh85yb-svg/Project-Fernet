import SwiftUI
import UIKit

// MARK: - Model

struct CosmeticItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    let rarity: String
    let icon: String?
    let featured: String?
    let chapter: String?
    let season: String?
}

// MARK: - Source parsing (fortnite-api.com)

private struct Lossy<T: Decodable>: Decodable {
    let value: T?

    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

private struct FlexString: Decodable {
    let value: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            value = text
        } else if let number = try? container.decode(Int.self) {
            value = String(number)
        } else {
            value = nil
        }
    }
}

private struct SourceItem: Decodable {
    struct Valued: Decodable { let value: String? }
    struct Intro: Decodable {
        let chapter: FlexString?
        let season: FlexString?
    }
    struct Images: Decodable {
        let smallIcon: String?
        let featured: String?
    }

    let id: String
    let name: String?
    let type: Valued?
    let rarity: Valued?
    let introduction: Intro?
    let images: Images?
}

private struct SourceResponse: Decodable {
    let data: [Lossy<SourceItem>]
}

struct CachedCosmetics {
    let items: [CosmeticItem]
    let date: Date
}

enum CosmeticsParser {
    static let cacheURL: URL = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("cosmetics-v2.json")

    static func parse(_ data: Data) throws -> [CosmeticItem] {
        let response = try JSONDecoder().decode(SourceResponse.self, from: data)

        return response.data.compactMap { entry in
            guard let item = entry.value,
                  let intro = item.introduction,
                  let chapter = intro.chapter?.value,
                  let icon = item.images?.smallIcon else { return nil }

            return CosmeticItem(
                id: item.id,
                name: item.name ?? "Unknown",
                type: item.type?.value ?? "other",
                rarity: item.rarity?.value ?? "common",
                icon: icon,
                featured: item.images?.featured,
                chapter: chapter,
                season: intro.season?.value
            )
        }
    }

    static func writeCache(_ items: [CosmeticItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }

    static func readCache() -> CachedCosmetics? {
        guard let data = try? Data(contentsOf: cacheURL),
              let items = try? JSONDecoder().decode([CosmeticItem].self, from: data),
              !items.isEmpty,
              let attributes = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
              let date = attributes[.modificationDate] as? Date else { return nil }

        return CachedCosmetics(items: items, date: date)
    }
}

// MARK: - Shared cosmetics repository

@MainActor
final class CosmeticsRepository {
    static let shared = CosmeticsRepository()

    private static let source = URL(string: "https://fortnite-api.com/v2/cosmetics/br")!
    private static let maxAge: TimeInterval = 6 * 60 * 60

    private var items: [CosmeticItem] = []
    private var loadedAt: Date?
    private var inFlight: Task<[CosmeticItem], Error>?

    private init() {}

    func all() async throws -> [CosmeticItem] {
        if !items.isEmpty, let loadedAt,
           Date().timeIntervalSince(loadedAt) < Self.maxAge {
            return items
        }

        if let inFlight {
            return try await inFlight.value
        }

        let task = Task<[CosmeticItem], Error> {
            try await self.fetch()
        }
        inFlight = task
        defer { inFlight = nil }

        return try await task.value
    }

    /// A season outfit image, used when the season artwork cannot be loaded.
    func heroImageURL(for season: Season) async -> URL? {
        guard let key = season.cosmeticsKey,
              let list = try? await all() else { return nil }

        let rank = [
            "mythic": 6, "legendary": 5, "epic": 4,
            "rare": 3, "uncommon": 2, "common": 1
        ]

        let pool = list
            .filter {
                $0.chapter == key.chapter &&
                $0.season == key.season &&
                $0.type == "outfit" &&
                ($0.featured ?? $0.icon) != nil
            }
            .sorted { $0.id < $1.id }

        guard let best = pool.max(by: {
            (rank[$0.rarity.lowercased()] ?? 0) < (rank[$1.rarity.lowercased()] ?? 0)
        }) else { return nil }

        return URL(string: best.featured ?? best.icon ?? "")
    }

    private func fetch() async throws -> [CosmeticItem] {
        let cached: CachedCosmetics? = await Task.detached(priority: .userInitiated) {
            CosmeticsParser.readCache()
        }.value

        if let cached, Date().timeIntervalSince(cached.date) < Self.maxAge {
            items = cached.items
            loadedAt = cached.date
            return cached.items
        }

        do {
            var request = URLRequest(url: Self.source)
            request.timeoutInterval = 60
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let parsed = try await Task.detached(priority: .userInitiated) { () -> [CosmeticItem] in
                let result = try CosmeticsParser.parse(data)
                CosmeticsParser.writeCache(result)
                return result
            }.value

            guard !parsed.isEmpty else {
                throw URLError(.cannotParseResponse)
            }

            items = parsed
            loadedAt = Date()
            return parsed
        } catch {
            if let cached {
                items = cached.items
                loadedAt = cached.date
                return cached.items
            }
            if !items.isEmpty { return items }
            throw error
        }
    }
}

// MARK: - Local profile (V-Bucks and equipped items per version)

struct LockerProfile: Codable {
    var vbucks: Int = 13_500
    var equipped: [String: CosmeticItem] = [:]
}

@MainActor
final class ProfileStore: ObservableObject {
    static let shared = ProfileStore()

    @Published private(set) var profiles: [String: LockerProfile] = [:]

    private let storageKey = "ogfn_profiles_v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: LockerProfile].self, from: data) {
            profiles = decoded
        }
    }

    func profile(_ key: String) -> LockerProfile {
        profiles[key] ?? LockerProfile()
    }

    func isEquipped(_ item: CosmeticItem, key: String) -> Bool {
        profile(key).equipped[item.type]?.id == item.id
    }

    func toggle(_ item: CosmeticItem, key: String) {
        var current = profile(key)

        if current.equipped[item.type]?.id == item.id {
            current.equipped[item.type] = nil
        } else {
            current.equipped[item.type] = item
        }

        profiles[key] = current
        save()
    }

    func addVBucks(_ amount: Int, key: String) {
        var current = profile(key)
        current.vbucks = max(0, current.vbucks + amount)
        profiles[key] = current
        save()
    }

    func reset() {
        profiles = [:]
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

extension AppSettings {
    var activeSeason: Season {
        Season.all.first { $0.id == selectedSeasonID } ?? Season.all[4]
    }

    var activeVersion: String {
        let season = activeSeason
        return season.versions.contains(selectedVersion)
            ? selectedVersion
            : (season.versions.last ?? "")
    }
}

// MARK: - Store (filtered list for the grid)

@MainActor
final class LockerStore: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published var items: [CosmeticItem] = []
    @Published var total = 0
    @Published var state: State = .idle

    func load(
        chapter: Int,
        season: String?,
        type: String,
        query: String
    ) async {
        if items.isEmpty {
            state = .loading
        }

        let all: [CosmeticItem]

        do {
            all = try await CosmeticsRepository.shared.all()
        } catch {
            if (error as? URLError)?.code == .cancelled || error is CancellationError {
                return
            }
            state = .failed(Self.message(for: error))
            return
        }

        let chapterText = String(chapter)
        let needle = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let filtered = all.filter { item in
            if item.chapter != chapterText { return false }
            if let season, item.season != season { return false }
            if type != "all", item.type != type { return false }
            if !needle.isEmpty, !item.name.lowercased().contains(needle) { return false }
            return true
        }

        total = filtered.count
        items = Array(filtered.prefix(400))
        state = .loaded
    }

    private static func message(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection."
            case .timedOut:
                return "The item list took too long to load. Try again."
            default:
                return "Could not load items (\(urlError.localizedDescription))."
            }
        }
        return "Could not read the item list."
    }
}

// MARK: - Views

struct CosmeticIcon: View {
    let urlString: String?

    @State private var uiImage: UIImage?

    var body: some View {
        Color.clear
            .overlay {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                } else {
                    ProgressView()
                        .tint(.white.opacity(0.5))
                }
            }
            .clipped()
            .task(id: urlString) {
                await load()
            }
    }

    private func load() async {
        guard let urlString, let url = URL(string: urlString) else { return }

        if let cached = ImageCache.shared.image(for: url) {
            uiImage = cached
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let image = UIImage(data: data) else { return }

            ImageCache.shared.store(image, for: url)
            uiImage = image
        } catch {
            // Placeholder stays visible.
        }
    }
}

private func rarityColor(_ rarity: String) -> Color {
    switch rarity.lowercased() {
    case "uncommon": return Color(red: 0.35, green: 0.75, blue: 0.25)
    case "rare": return Color(red: 0.2, green: 0.55, blue: 0.95)
    case "epic": return Color(red: 0.65, green: 0.3, blue: 0.9)
    case "legendary": return Color(red: 0.95, green: 0.6, blue: 0.15)
    case "mythic": return Color(red: 0.95, green: 0.8, blue: 0.2)
    case "transcendent": return Color(red: 0.3, green: 0.9, blue: 0.9)
    case "common": return Color(red: 0.55, green: 0.6, blue: 0.68)
    default: return Color(red: 0.25, green: 0.72, blue: 1)
    }
}

struct CosmeticCell: View {
    let item: CosmeticItem
    let equipped: Bool

    var body: some View {
        let color = rarityColor(item.rarity)

        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    LinearGradient(
                        colors: [color.opacity(0.75), color.opacity(0.25), .black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    CosmeticIcon(urlString: item.icon)
                }
            }
            .overlay(alignment: .bottom) {
                Text(item.name)
                    .font(.system(size: 9, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.6))
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: equipped ? "checkmark.circle.fill" : "lock.open.fill")
                    .font(.system(size: equipped ? 16 : 9, weight: .bold))
                    .foregroundStyle(equipped ? Color.cyan : Color.white.opacity(0.85))
                    .padding(6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        equipped ? Color.cyan : color.opacity(0.6),
                        lineWidth: equipped ? 2.5 : 1
                    )
            }
    }
}

struct LockerView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var profiles = ProfileStore.shared
    @StateObject private var store = LockerStore()

    private let initialSeason: Season?
    private let versionOverride: String?

    @State private var chapter: Int
    @State private var seasonNumber: String?
    @State private var type = "outfit"
    @State private var search = ""
    @State private var reloadToken = 0
    @State private var didApplyDefault = false

    private struct LockerQuery: Hashable {
        let chapter: Int
        let season: String?
        let type: String
        let search: String
        let token: Int
    }

    private let types: [(value: String, label: String)] = [
        ("all", "ALL"),
        ("outfit", "OUTFITS"),
        ("pickaxe", "PICKAXES"),
        ("glider", "GLIDERS"),
        ("backpack", "BACK BLINGS"),
        ("emote", "EMOTES"),
        ("wrap", "WRAPS")
    ]

    private let slots: [(type: String, icon: String)] = [
        ("outfit", "person.fill"),
        ("pickaxe", "hammer.fill"),
        ("glider", "paperplane.fill"),
        ("backpack", "bag.fill"),
        ("emote", "face.smiling")
    ]

    init(initialSeason: Season? = nil, version: String? = nil) {
        self.initialSeason = initialSeason
        self.versionOverride = version

        let usable = (initialSeason?.lockerSupported ?? false) ? initialSeason : nil
        _chapter = State(initialValue: usable?.chapter ?? initialSeason?.chapter ?? 1)
        _seasonNumber = State(initialValue: usable?.number)
    }

    // MARK: Context

    private var contextSeason: Season {
        initialSeason ?? settings.activeSeason
    }

    private var contextVersion: String {
        versionOverride ?? settings.activeVersion
    }

    private var profileKey: String {
        contextSeason.id + "|" + contextVersion
    }

    private var seasonsInChapter: [Season] {
        Season.all.filter { $0.chapter == chapter && $0.lockerSupported }
    }

    private var currentQuery: LockerQuery {
        LockerQuery(
            chapter: chapter,
            season: seasonNumber,
            type: type,
            search: search,
            token: reloadToken
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            OGFNBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionHeading(
                        title: "Locker",
                        subtitle: "All items unlocked"
                    )
                    .padding(.top, 8)

                    profileCard
                    loadoutRow
                    chapterChips
                    seasonMenu
                    typeChips

                    TextField("Search items...", text: $search)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 13))

                    content
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Locker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            guard initialSeason == nil, !didApplyDefault else { return }
            didApplyDefault = true

            let season = settings.activeSeason
            chapter = season.chapter
            seasonNumber = season.lockerSupported ? season.number : nil
        }
        .task(id: currentQuery) {
            do {
                try await Task.sleep(nanoseconds: 250_000_000)
            } catch {
                return
            }

            await store.load(
                chapter: chapter,
                season: seasonNumber,
                type: type,
                query: search
            )
        }
    }

    // MARK: Profile

    private var profileCard: some View {
        let profile = profiles.profile(profileKey)

        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("LOCKER FOR")
                    .font(.system(size: 9, weight: .black))
                    .tracking(2)
                    .foregroundStyle(.cyan)

                Text(contextVersion.isEmpty ? contextSeason.subtitle : contextVersion)
                    .font(.system(size: 26, weight: .black, design: .rounded))

                Text("\(contextSeason.chapterTitle.capitalized) • \(contextSeason.subtitle)")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("V-BUCKS")
                    .font(.system(size: 9, weight: .black))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.5))

                Text(profile.vbucks.formatted())
                    .font(.system(size: 20, weight: .black, design: .rounded))

                HStack(spacing: 8) {
                    vbucksButton("−") {
                        profiles.addVBucks(-1000, key: profileKey)
                    }
                    vbucksButton("+") {
                        profiles.addVBucks(1000, key: profileKey)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func vbucksButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 34, height: 28)
                .background(.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var loadoutRow: some View {
        let equipped = profiles.profile(profileKey).equipped

        return VStack(alignment: .leading, spacing: 10) {
            Text("EQUIPPED")
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: 8) {
                ForEach(slots, id: \.type) { slot in
                    Button {
                        type = slot.type
                    } label: {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                ZStack {
                                    Color.white.opacity(0.07)

                                    if let item = equipped[slot.type] {
                                        CosmeticIcon(urlString: item.icon)
                                    } else {
                                        Image(systemName: slot.icon)
                                            .font(.system(size: 18))
                                            .foregroundStyle(.white.opacity(0.35))
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                            .overlay {
                                RoundedRectangle(cornerRadius: 11)
                                    .stroke(
                                        type == slot.type ? Color.cyan : Color.white.opacity(0.08),
                                        lineWidth: type == slot.type ? 2 : 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Filters

    private var chapterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(Season.chapters, id: \.self) { value in
                    chip("CHAPTER \(value)", selected: chapter == value) {
                        chapter = value
                        seasonNumber = nil
                    }
                }
            }
        }
    }

    private var typeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(types, id: \.value) { entry in
                    chip(entry.label, selected: type == entry.value) {
                        type = entry.value
                    }
                }
            }
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .tracking(1)
                .foregroundStyle(selected ? Color.black : Color.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(selected ? Color.cyan : Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    private var seasonMenu: some View {
        Menu {
            Button("All seasons") {
                seasonNumber = nil
            }

            ForEach(seasonsInChapter) { season in
                Button("Season \(season.number) • \(season.subtitle)") {
                    seasonNumber = season.number
                }
            }
        } label: {
            HStack {
                Image(systemName: "calendar")
                Text(seasonNumber.map { "SEASON \($0)" } ?? "ALL SEASONS")
                    .tracking(1)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
            }
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(.white)
            .padding(14)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 13))
        }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading:
            VStack(spacing: 12) {
                ProgressView()
                    .tint(.cyan)

                Text("Loading items... The first start downloads the item list and can take a moment.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)

        case .failed(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.orange)

                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Button {
                    reloadToken += 1
                } label: {
                    Text("TRY AGAIN")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(Color.cyan)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)

        case .loaded:
            if store.items.isEmpty {
                Text("No items found for this selection.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(store.total) ITEMS • TAP TO EQUIP")
                            .font(.system(size: 10, weight: .black))
                            .tracking(1)
                            .foregroundStyle(.cyan)

                        Spacer()

                        if store.total > store.items.count {
                            Text("SHOWING FIRST \(store.items.count)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }

                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: 10),
                            count: 3
                        ),
                        spacing: 10
                    ) {
                        ForEach(store.items) { item in
                            Button {
                                profiles.toggle(item, key: profileKey)
                            } label: {
                                CosmeticCell(
                                    item: item,
                                    equipped: profiles.isEquipped(item, key: profileKey)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
