import SwiftUI

struct SeasonDetailView: View {
    let season: Season

    @EnvironmentObject private var settings: AppSettings

    private func isSelected(_ version: String) -> Bool {
        settings.selectedSeasonID == season.id && settings.selectedVersion == version
    }

    var body: some View {
        ZStack {
            OGFNBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    hero

                    if let url = season.trailerSearchURL {
                        Link(destination: url) {
                            Label("WATCH SEASON TRAILER", systemImage: "play.rectangle.fill")
                                .font(.system(size: 13, weight: .black))
                                .tracking(1)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(17)
                                .background(.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    versionsSection

                    VStack(alignment: .leading, spacing: 15) {
                        Text("SEASON INFORMATION")
                            .font(.system(size: 12, weight: .black))
                            .tracking(2)
                            .foregroundStyle(.cyan)

                        infoRow("Chapter", "Chapter \(season.chapter)")
                        infoRow("Season", season.number)
                        infoRow("Theme", season.theme)
                        infoRow("Start", season.startDate)
                        infoRow("End", season.endDate)
                    }
                    .padding(18)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding(18)
                .padding(.bottom, 30)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle(season.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            SeasonArtwork(season: season)

            LinearGradient(
                colors: [.clear, .black.opacity(0.1), .black.opacity(0.88)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(season.chapterTitle)
                    .font(.system(size: 11, weight: .black))
                    .tracking(3)
                    .foregroundStyle(.cyan)

                Text(season.title.uppercased())
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(season.subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text(season.theme.uppercased())
                }
                .font(.system(size: 9, weight: .black))
                .tracking(2)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.13))
                .clipShape(Capsule())
            }
            .padding(20)
        }
        .frame(height: 390)
        .clipShape(RoundedRectangle(cornerRadius: 23))
    }

    private var versionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("VERSIONS")
                    .font(.system(size: 12, weight: .black))
                    .tracking(2)
                    .foregroundStyle(.cyan)

                Spacer()

                Text("\(season.versions.count) LISTED")
                    .font(.system(size: 9, weight: .black))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.45))
            }

            if season.versions.isEmpty {
                Text("No iOS versions are listed for this season.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(season.versions.reversed(), id: \.self) { version in
                        NavigationLink {
                            VersionDetailView(
                                entry: VersionEntry(season: season, version: version)
                            )
                        } label: {
                            versionCard(version)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func versionCard(_ version: String) -> some View {
        let selected = isSelected(version)

        return ZStack(alignment: .bottomLeading) {
            SeasonArtwork(season: season)

            LinearGradient(
                colors: [.black.opacity(0.1), .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(version)
                        .font(.system(size: 30, weight: .black, design: .rounded))

                    Text(selected ? "SELECTED" : "TAP TO OPEN")
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundStyle(selected ? Color.green : Color.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(18)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    selected ? Color.green.opacity(0.8) : Color.white.opacity(0.08),
                    lineWidth: selected ? 2 : 1
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.white.opacity(0.55))

            Spacer()

            Text(value)
                .fontWeight(.bold)
        }
        .font(.system(size: 12))
    }
}
