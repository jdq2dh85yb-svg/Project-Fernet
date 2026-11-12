import SwiftUI

struct FernetLeaderboardView: View {
    @EnvironmentObject var vm: FernetLeaderboardViewModel
    @State private var selectedSort: SortMode = .wins

    enum SortMode: String, CaseIterable {
        case wins = "Wins", eliminations = "Elims", winRate = "Win %", kd = "K/D"
    }

    var sorted: [LeaderboardEntry] {
        switch selectedSort {
        case .wins:         return vm.entries.sorted { $0.wins > $1.wins }
        case .eliminations: return vm.entries.sorted { $0.eliminations > $1.eliminations }
        case .winRate:      return vm.entries.sorted { $0.winRate > $1.winRate }
        case .kd:           return vm.entries.sorted { $0.kd > $1.kd }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    FernetSectionHeader(title: "Leaderboard", subtitle: "Top 15 — Season Rankings")
                    Spacer()
                }
                .padding(.top, 60)

                // Podium
                podiumSection

                // Sort picker
                sortPicker

                // List
                leaderboardList

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
        }
        .background(FernetBackground())
    }

    // MARK: Podium
    private var podiumSection: some View {
        let top = Array(sorted.prefix(3))
        return HStack(alignment: .bottom, spacing: 8) {
            if top.count > 1 { podiumPlayer(top[1], podiumHeight: 90, rank: 2) }
            if top.count > 0 { podiumPlayer(top[0], podiumHeight: 120, rank: 1) }
            if top.count > 2 { podiumPlayer(top[2], podiumHeight: 70, rank: 3) }
        }
        .padding(.horizontal, 4)
    }

    private func podiumPlayer(_ entry: LeaderboardEntry, podiumHeight: CGFloat, rank: Int) -> some View {
        let gradient = rank == 1 ? FernetGradients.goldPodium
            : rank == 2 ? LinearGradient(colors: [.fernetSilver, Color(red:0.55,green:0.6,blue:0.7)], startPoint: .top, endPoint: .bottom)
            : LinearGradient(colors: [.fernetBronze, Color(red:0.55,green:0.3,blue:0.1)], startPoint: .top, endPoint: .bottom)

        let rankColor: Color = rank == 1 ? .fernetGold : rank == 2 ? .fernetSilver : .fernetBronze

        return VStack(spacing: 6) {
            // Crown for #1
            if rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.fernetGold)
                    .shadow(color: .fernetGold.opacity(0.6), radius: 6)
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: rank == 1 ? 56 : 46, height: rank == 1 ? 56 : 46)
                Text(String(entry.name.prefix(2)).uppercased())
                    .font(FernetFont.display(rank == 1 ? 18 : 14))
                    .foregroundStyle(.black.opacity(0.8))
            }
            .shadow(color: rankColor.opacity(0.5), radius: 8)

            Text(entry.name)
                .font(FernetFont.label(10))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: 90)

            Text("\(entry.wins) W")
                .font(FernetFont.mono(11))
                .foregroundStyle(rankColor)

            // Podium block
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(gradient.opacity(0.25))
                    .frame(height: podiumHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(rankColor.opacity(0.4), lineWidth: 0.8)
                    )

                Text("#\(rank)")
                    .font(FernetFont.display(22))
                    .foregroundStyle(rankColor)
                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Sort Picker
    private var sortPicker: some View {
        HStack(spacing: 6) {
            ForEach(SortMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSort = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(FernetFont.label(11))
                        .tracking(1)
                        .foregroundStyle(selectedSort == mode ? .black : .white.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedSort == mode
                                ? AnyShapeStyle(FernetGradients.pinkAccent)
                                : AnyShapeStyle(Color.white.opacity(0.07))
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: List
    private var leaderboardList: some View {
        VStack(spacing: 6) {
            // Column headers
            HStack {
                Text("RANK")
                    .frame(width: 44, alignment: .leading)
                Text("PLAYER")
                Spacer()
                Text("WINS")
                    .frame(width: 44, alignment: .trailing)
                Text("ELIMS")
                    .frame(width: 44, alignment: .trailing)
                Text("W%")
                    .frame(width: 36, alignment: .trailing)
            }
            .font(FernetFont.caption(9))
            .tracking(1.5)
            .foregroundStyle(.white.opacity(0.35))
            .padding(.horizontal, 14)
            .padding(.bottom, 4)

            ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, entry in
                LeaderboardRow(entry: entry, displayRank: idx + 1, sortMode: selectedSort)
            }
        }
    }
}

// MARK: - Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let displayRank: Int
    let sortMode: FernetLeaderboardView.SortMode

    private var rankColor: Color {
        switch displayRank {
        case 1: return .fernetGold
        case 2: return .fernetSilver
        case 3: return .fernetBronze
        default: return .white.opacity(0.4)
        }
    }

    private var highlightedValue: String {
        switch sortMode {
        case .wins:         return "\(entry.wins)"
        case .eliminations: return "\(entry.eliminations)"
        case .winRate:      return String(format: "%.1f%%", entry.winRate)
        case .kd:           return String(format: "%.2f", entry.kd)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Rank
            Text("#\(displayRank)")
                .font(FernetFont.mono(13))
                .foregroundStyle(rankColor)
                .frame(width: 44, alignment: .leading)

            // Avatar
            ZStack {
                Circle()
                    .fill(displayRank <= 3
                        ? (displayRank == 1 ? FernetGradients.goldPodium : LinearGradient(colors: [rankColor, rankColor.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                        : LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 30, height: 30)
                Text(String(entry.name.prefix(2)).uppercased())
                    .font(FernetFont.display(10))
                    .foregroundStyle(displayRank <= 3 ? .black.opacity(0.8) : .white.opacity(0.7))
            }
            .padding(.trailing, 10)

            Text(entry.name)
                .font(FernetFont.label(13))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Text("\(entry.wins)")
                .font(FernetFont.mono(12))
                .foregroundStyle(sortMode == .wins ? .fernetCyan : .white.opacity(0.6))
                .frame(width: 44, alignment: .trailing)

            Text("\(entry.eliminations)")
                .font(FernetFont.mono(12))
                .foregroundStyle(sortMode == .eliminations ? .fernetCyan : .white.opacity(0.6))
                .frame(width: 44, alignment: .trailing)

            Text(String(format: "%.0f%%", entry.winRate))
                .font(FernetFont.mono(12))
                .foregroundStyle(sortMode == .winRate ? .fernetCyan : .white.opacity(0.6))
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            displayRank <= 3
                ? AnyShapeStyle(LinearGradient(
                    colors: [rankColor.opacity(0.08), Color.clear],
                    startPoint: .leading, endPoint: .trailing
                  ))
                : AnyShapeStyle(Color.white.opacity(0.03))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    displayRank <= 3 ? rankColor.opacity(0.2) : Color.white.opacity(0.05),
                    lineWidth: 0.5
                )
        )
    }
}
