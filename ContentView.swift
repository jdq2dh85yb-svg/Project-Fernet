import SwiftUI
import UIKit

// MARK: - Theme

struct OGFNBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.025, green: 0.035, blue: 0.065)

            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.16, blue: 0.29),
                    .clear,
                    Color(red: 0.13, green: 0.055, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [.cyan.opacity(0.10), .clear],
                center: .topTrailing,
                startRadius: 5,
                endRadius: 370
            )
        }
        .ignoresSafeArea()
    }
}

struct OGFNLogo: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("OG")
                .font(.system(size: 19, weight: .black).italic())
                .foregroundStyle(.black)
                .padding(.horizontal, 9)
                .frame(height: 34)
                .background(Color(red: 0.25, green: 0.72, blue: 1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text("MANAGER")
                .font(.system(size: 15, weight: .heavy))
                .tracking(4)
        }
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 25, weight: .black, design: .rounded))
                .tracking(1)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }
}

struct StatusIndicator: View {
    let online: Bool

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(online ? Color.green : Color.orange)
                .frame(width: 7, height: 7)

            Text(online ? "ONLINE" : "OFFLINE")
                .font(.system(size: 10, weight: .black))
                .tracking(1)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Artwork

final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()
    private var failed = Set<URL>()
    private let lock = NSLock()

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func store(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    func markFailed(_ url: URL) {
        lock.lock()
        failed.insert(url)
        lock.unlock()
    }

    func didFail(_ url: URL) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return failed.contains(url)
    }
}

/// Fills whatever space the parent gives it (set the size with .frame).
/// The image is only an overlay, so it can never change the layout size.
/// If the season artwork cannot be loaded, an outfit of that season is shown.
struct SeasonArtwork: View {
    let season: Season

    @State private var uiImage: UIImage?
    @State private var isCutout = false
    @State private var isLoading = false

    var body: some View {
        Color.clear
            .overlay {
                ZStack {
                    fallback

                    if let uiImage {
                        if isCutout {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .padding(.horizontal, 12)
                                .padding(.top, 20)
                        } else {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        }
                    } else if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
            .clipped()
            .task(id: season.id) {
                await load()
            }
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [.cyan.opacity(0.4), .blue.opacity(0.5), .purple.opacity(0.65), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if uiImage == nil {
                Image(systemName: season.symbol)
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        if let url = season.artworkURL, let image = await Self.fetch(url) {
            isCutout = false
            uiImage = image
            return
        }

        if let url = await CosmeticsRepository.shared.heroImageURL(for: season),
           let image = await Self.fetch(url) {
            isCutout = true
            uiImage = image
        }
    }

    private static func fetch(_ url: URL) async -> UIImage? {
        if let cached = ImageCache.shared.image(for: url) {
            return cached
        }
        if ImageCache.shared.didFail(url) {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let image = UIImage(data: data) else {
                ImageCache.shared.markFailed(url)
                return nil
            }

            ImageCache.shared.store(image, for: url)
            return image
        } catch {
            if (error as? URLError)?.code != .cancelled {
                ImageCache.shared.markFailed(url)
            }
            return nil
        }
    }
}

// MARK: - Home

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings

    private var selectedSeason: Season {
        Season.all.first { $0.id == settings.selectedSeasonID }
            ?? Season.all[4]
    }

    private var displayVersion: String {
        selectedSeason.versions.contains(settings.selectedVersion)
            ? settings.selectedVersion
            : (selectedSeason.versions.last ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OGFNBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header

                        VStack(alignment: .leading, spacing: 8) {
                            Text("WELCOME BACK")
                                .font(.system(size: 11, weight: .black))
                                .tracking(3)
                                .foregroundStyle(.cyan)

                            Text(settings.playerName.uppercased())
                                .font(.system(size: 29, weight: .black, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)

                            Text("Pick a season and version to get started.")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.55))
                        }

                        featuredSeason

                        SectionHeading(
                            title: "Your Hub",
                            subtitle: "Everything in one place"
                        )

                        HStack(spacing: 12) {
                            hubCard(
                                title: "VERSIONS",
                                subtitle: "Search every build",
                                icon: "tag.fill",
                                tab: 2
                            )

                            hubCard(
                                title: "LOCKER",
                                subtitle: "All items unlocked",
                                icon: "tshirt.fill",
                                tab: 4
                            )
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack {
            OGFNLogo()
            Spacer()

            HStack(spacing: 7) {
                Image(systemName: "person.fill")
                    .font(.system(size: 10))

                Text(settings.playerName)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }

    private var featuredSeason: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                SeasonArtwork(season: selectedSeason)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.1), .black.opacity(0.88)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("SELECTED SEASON")
                        .font(.system(size: 10, weight: .black))
                        .tracking(3)
                        .foregroundStyle(.cyan)

                    Text(selectedSeason.chapterTitle)
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)

                    Text(selectedSeason.title.uppercased())
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)

                    Text(selectedSeason.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))

                    HStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                        Text(displayVersion.isEmpty ? "NO VERSION" : displayVersion.uppercased())
                    }
                    .font(.system(size: 11, weight: .black))
                    .tracking(1)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.cyan)
                    .clipShape(Capsule())
                }
                .padding(20)
            }
            .frame(height: 390)
            .clipShape(RoundedRectangle(cornerRadius: 23))

            Button {
                settings.selectedTab = 2
            } label: {
                HStack {
                    Image(systemName: "tag.fill")
                    Text("CHOOSE VERSION")
                        .tracking(2)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.black)
                .padding(18)
                .background(
                    LinearGradient(
                        colors: [Color.cyan, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(color: .cyan.opacity(0.25), radius: 15, y: 6)
            }
            .padding(.top, 11)
        }
    }

    private func hubCard(
        title: String,
        subtitle: String,
        icon: String,
        tab: Int
    ) -> some View {
        Button {
            settings.selectedTab = tab
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 25))
                    .foregroundStyle(.cyan)

                Text(title)
                    .font(.system(size: 14, weight: .black))

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(17)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Season Library

struct SeasonLibraryView: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var selectedChapter = 1
    @State private var searchText = ""

    private var filteredSeasons: [Season] {
        Season.all.filter {
            $0.chapter == selectedChapter &&
            (
                searchText.isEmpty ||
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(searchText)
            )
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OGFNBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 21) {
                        OGFNLogo()
                            .padding(.top, 12)

                        SectionHeading(
                            title: "Season Library",
                            subtitle: "Explore every chapter"
                        )

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 9) {
                                ForEach(Season.chapters, id: \.self) { chapter in
                                    Button {
                                        selectedChapter = chapter
                                    } label: {
                                        Text("CHAPTER \(chapter)")
                                            .font(.system(size: 10, weight: .black))
                                            .tracking(1)
                                            .foregroundStyle(selectedChapter == chapter ? Color.black : Color.white)
                                            .padding(.horizontal, 15)
                                            .padding(.vertical, 12)
                                            .background(
                                                selectedChapter == chapter
                                                ? Color.cyan
                                                : Color.white.opacity(0.08)
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        TextField("Search seasons...", text: $searchText)
                            .padding(15)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 13))

                        HStack {
                            Text("CHAPTER \(selectedChapter)")
                                .font(.system(size: 18, weight: .black))

                            Spacer()

                            Text("\(filteredSeasons.count) SEASONS")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.cyan)
                        }

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 14
                        ) {
                            ForEach(filteredSeasons) { season in
                                NavigationLink {
                                    SeasonDetailView(season: season)
                                } label: {
                                    SeasonCard(
                                        season: season,
                                        isSelected: settings.selectedSeasonID == season.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct SeasonCard: View {
    let season: Season
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            SeasonArtwork(season: season)

            LinearGradient(
                colors: [.clear, .black.opacity(0.9)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 5) {
                Text("CHAPTER \(season.chapter)")
                    .font(.system(size: 8, weight: .black))
                    .tracking(2)
                    .foregroundStyle(.cyan)

                Text(season.title.uppercased())
                    .font(.system(size: 17, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(season.subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .padding(11)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 21))
                    .foregroundStyle(.cyan)
                    .padding(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? Color.cyan : Color.white.opacity(0.08),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}
