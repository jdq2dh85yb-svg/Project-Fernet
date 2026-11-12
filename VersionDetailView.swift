import SwiftUI

struct VersionDetailView: View {
    let season: Season

    @EnvironmentObject private var settings: AppSettings
    @State private var version: String

    init(entry: VersionEntry) {
        season = entry.season
        _version = State(initialValue: entry.version)
    }

    private var isSelected: Bool {
        settings.selectedSeasonID == season.id && settings.selectedVersion == version
    }

    var body: some View {
        ZStack {
            OGFNBackground()

            SeasonArtwork(season: season)
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.15), .black.opacity(0.55), .black.opacity(0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Color.clear.frame(height: 210)

                    titleBlock
                    actionPanel
                    otherVersions

                    Text(season.summary)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineSpacing(4)

                    infoCard
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(season.title)
                .font(.system(size: 44, weight: .bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(season.subtitle)
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))

            Text(version)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: Actions

    private var actionPanel: some View {
        VStack(spacing: 12) {
            Button {
                settings.selectedSeasonID = season.id
                settings.selectedVersion = version
            } label: {
                HStack(spacing: 8) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                    }

                    Text(isSelected ? "SELECTED" : "SELECT VERSION")
                        .tracking(2)
                }
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(isSelected ? Color.green : Color.white)
                .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                if let url = season.trailerSearchURL {
                    Link(destination: url) {
                        outlineLabel("TRAILER", icon: "play.fill")
                    }
                }

                NavigationLink {
                    LockerView(initialSeason: season, version: version)
                } label: {
                    outlineLabel("LOCKER", icon: "tshirt.fill")
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        }
    }

    private func outlineLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 13, weight: .heavy))
            .tracking(1)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
            }
    }

    // MARK: Other versions

    private var otherVersions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OTHER VERSIONS")
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.55))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(season.versions, id: \.self) { value in
                        Button {
                            version = value
                        } label: {
                            Text(value)
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(version == value ? Color.black : Color.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(version == value ? Color.cyan : Color.white.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: Info

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("VERSION INFORMATION")
                .font(.system(size: 12, weight: .black))
                .tracking(2)
                .foregroundStyle(.cyan)

            infoRow("Version", version)
            infoRow("Season", season.subtitle)
            infoRow("Chapter", "Chapter \(season.chapter)")
            infoRow("Theme", season.theme)
            infoRow("Start", season.startDate)
            infoRow("End", season.endDate)
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
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
