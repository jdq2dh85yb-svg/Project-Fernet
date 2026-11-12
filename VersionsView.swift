import SwiftUI

struct VersionEntry: Identifiable, Hashable {
    let season: Season
    let version: String

    var id: String { season.id + "|" + version }
}

private struct VersionGroup: Identifiable {
    let season: Season
    let versions: [String]

    var id: String { season.id }
}

private func normalizedVersion(_ text: String) -> String {
    text.lowercased()
        .replacingOccurrences(of: "v", with: "")
        .replacingOccurrences(of: " ", with: "")
}

// MARK: - Versions tab

struct VersionsView: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var search = ""
    @State private var chapter: Int?

    private var currentEntry: VersionEntry? {
        let season = settings.activeSeason
        guard !season.versions.isEmpty else { return nil }
        return VersionEntry(season: season, version: settings.activeVersion)
    }

    private var groups: [VersionGroup] {
        let tokens = search
            .lowercased()
            .split(separator: " ")
            .map(String.init)

        return Season.all.compactMap { season -> VersionGroup? in
            guard !season.versions.isEmpty else { return nil }

            if let chapter, season.chapter != chapter { return nil }

            if tokens.isEmpty {
                return VersionGroup(season: season, versions: season.versions)
            }

            let text = "\(season.chapterTitle) \(season.title) \(season.subtitle) \(season.theme)"
                .lowercased()

            let matching = season.versions.filter { version in
                let number = normalizedVersion(version)
                return tokens.allSatisfy { token in
                    number.hasPrefix(normalizedVersion(token)) || text.contains(token)
                }
            }

            return matching.isEmpty
                ? nil
                : VersionGroup(season: season, versions: matching)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OGFNBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        OGFNLogo()
                            .padding(.top, 12)

                        SectionHeading(
                            title: "Versions",
                            subtitle: "Search any iOS build and open it"
                        )

                        if let currentEntry {
                            currentCard(currentEntry)
                        }

                        TextField("Search e.g. 5.40 or Worlds Collide", text: $search)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(15)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 13))

                        chapterChips

                        if groups.isEmpty {
                            Text("No versions found.")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else {
                            ForEach(groups) { group in
                                groupView(group)
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

    private func currentCard(_ entry: VersionEntry) -> some View {
        NavigationLink {
            VersionDetailView(entry: entry)
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("CURRENT VERSION")
                        .font(.system(size: 9, weight: .black))
                        .tracking(2)
                        .foregroundStyle(.cyan)

                    Text(entry.version)
                        .font(.system(size: 30, weight: .black, design: .rounded))

                    Text("\(entry.season.chapterTitle) • \(entry.season.subtitle)")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [.cyan.opacity(0.22), .blue.opacity(0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 17))
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var chapterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                chip("ALL", selected: chapter == nil) {
                    chapter = nil
                }

                ForEach(Season.chapters, id: \.self) { value in
                    chip("CHAPTER \(value)", selected: chapter == value) {
                        chapter = value
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

    private func isSelected(_ season: Season, _ version: String) -> Bool {
        settings.selectedSeasonID == season.id && settings.selectedVersion == version
    }

    private func groupView(_ group: VersionGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                SeasonArtwork(season: group.season)
                    .frame(width: 46, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(group.season.chapterTitle) • \(group.season.title.uppercased())")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1.5)
                        .foregroundStyle(.cyan)

                    Text(group.season.subtitle)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                }

                Spacer()
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 76), spacing: 8)],
                spacing: 8
            ) {
                ForEach(group.versions, id: \.self) { version in
                    NavigationLink {
                        VersionDetailView(
                            entry: VersionEntry(season: group.season, version: version)
                        )
                    } label: {
                        let selected = isSelected(group.season, version)

                        Text(version)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(selected ? Color.black : Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(selected ? Color.cyan : Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(.white.opacity(0.055))
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }
}
