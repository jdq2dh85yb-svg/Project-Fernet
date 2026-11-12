import SwiftUI

struct FernetLibraryView: View {
    @EnvironmentObject var downloadVM: FernetDownloadViewModel
    @State private var showGameInfo = false

    var isInstalled: Bool { downloadVM.state == .complete }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                HStack {
                    FernetSectionHeader(title: "Library", subtitle: "Your installed games")
                    Spacer()
                }
                .padding(.top, 60)

                // Game cover card
                gameCoverCard

                // Action buttons
                actionButtons

                // Game details
                gameDetailsSection

                // Version info
                versionSection

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
        }
        .background(FernetBackground())
        .sheet(isPresented: $showGameInfo) {
            gameInfoSheet
        }
    }

    private var gameCoverCard: some View {
        ZStack(alignment: .bottomLeading) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.12, blue: 0.30),
                        Color(red: 0.55, green: 0.22, blue: 0.48),
                        Color(red: 0.75, green: 0.38, blue: 0.58),
                    ],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
                RadialGradient(
                    colors: [.fernetCyan.opacity(0.18), .clear],
                    center: UnitPoint(x: 0.25, y: 0.75),
                    startRadius: 5, endRadius: 160
                )
                Image("OGFNLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 160)
                    .opacity(0.18)
                    .offset(x: 70)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image("OGFNLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PROJECT FERNET")
                            .font(FernetFont.display(16))
                            .foregroundStyle(.white)
                        Text("Chapter 2 • Season 3 — Splashdown")
                            .font(FernetFont.caption(11))
                            .foregroundStyle(.fernetCyan)
                    }
                }

                HStack(spacing: 8) {
                    statusBadge(isInstalled ? "INSTALLED" : "NOT INSTALLED",
                                color: isInstalled ? .green : .fernetPink)
                    statusBadge("v13.40.0", color: .fernetCyan)
                    statusBadge("26.4 GB",  color: .white.opacity(0.5))
                }
            }
            .padding(16)
        }
    }

    private func statusBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(FernetFont.caption(9))
            .tracking(1.5)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 0.5))
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Play
            Button {
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isInstalled ? "play.fill" : "lock.fill")
                        .font(.system(size: 15, weight: .black))
                    Text(isInstalled ? "LAUNCH GAME" : "DOWNLOAD TO PLAY")
                        .font(FernetFont.display(15))
                        .tracking(2)
                }
                .foregroundStyle(isInstalled ? .black : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    isInstalled
                        ? AnyShapeStyle(FernetGradients.pinkAccent)
                        : AnyShapeStyle(Color.white.opacity(0.07))
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isInstalled ? Color.fernetPink.opacity(0.3) : Color.white.opacity(0.1),
                            lineWidth: 0.5
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(!isInstalled)

            HStack(spacing: 10) {
                // Update button
                Button {
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 13))
                        Text("CHECK UPDATES")
                            .font(FernetFont.display(11))
                            .tracking(1.5)
                    }
                    .foregroundStyle(.fernetCyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .glassCard(cornerRadius: 12)
                }
                .buttonStyle(.plain)

                // Info button
                Button {
                    showGameInfo = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13))
                        Text("GAME INFO")
                            .font(FernetFont.display(11))
                            .tracking(1.5)
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .glassCard(cornerRadius: 12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var gameDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FernetSectionHeader(title: "About This Season")

            Text("Chapter 2 Season 3 brought a dramatic flood to the island after the Device event. The entire map was submerged under water, introducing new aquatic gameplay including swimming, loot sharks, and water-based mechanics. Players competed to outlast opponents across a flooded battlefield filled with new points of interest.")
                .font(FernetFont.caption(13))
                .foregroundStyle(.white.opacity(0.6))
                .lineSpacing(5)
                .padding(16)
                .glassCard(cornerRadius: 14)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                detailCell(label: "SEASON",    value: "Chapter 2 S3", icon: "calendar")
                detailCell(label: "DURATION",  value: "Jun–Aug 2020", icon: "clock")
                detailCell(label: "THEME",     value: "Flood / Ocean", icon: "water.waves")
                detailCell(label: "BATTLE PASS", value: "100 Tiers", icon: "ticket.fill")
            }
        }
    }

    private func detailCell(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.fernetPink)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(FernetFont.caption(9))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.4))
                Text(value)
                    .font(FernetFont.label(12))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(12)
        .glassCard(cornerRadius: 12)
    }

    private var versionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FernetSectionHeader(title: "Version History")

            VStack(spacing: 8) {
                versionRow(version: "v13.40.0", label: "Current", note: "Final patch — season end", isCurrent: true)
                versionRow(version: "v13.30.0", label: "", note: "Coral Castle added", isCurrent: false)
                versionRow(version: "v13.20.0", label: "", note: "Sharks & new weapons", isCurrent: false)
                versionRow(version: "v13.00.0", label: "", note: "Season launch", isCurrent: false)
            }
        }
    }

    private func versionRow(version: String, label: String, note: String, isCurrent: Bool) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(isCurrent ? Color.fernetPink : Color.white.opacity(0.15))
                .frame(width: 8, height: 8)

            Text(version)
                .font(FernetFont.mono(13))
                .foregroundStyle(isCurrent ? .fernetCyan : .white.opacity(0.6))

            if !label.isEmpty {
                Text(label)
                    .font(FernetFont.caption(10))
                    .tracking(1)
                    .foregroundStyle(.fernetPink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.fernetPink.opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer()

            Text(note)
                .font(FernetFont.caption(11))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 12)
    }

    private var gameInfoSheet: some View {
        NavigationStack {
            ZStack {
                FernetBackground().ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        infoSheetRow(label: "Title", value: "Chapter 2 Season 3 — Splashdown")
                        infoSheetRow(label: "Developer", value: "Epic Games (original)")
                        infoSheetRow(label: "Launcher", value: "Project Fernet — Community")
                        infoSheetRow(label: "Engine", value: "Unreal Engine 4.25")
                        infoSheetRow(label: "Build", value: "v13.40.0-14516044")
                        infoSheetRow(label: "Install Size", value: "26.4 GB")
                        infoSheetRow(label: "Platform", value: "iOS 16.0+")
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Game Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showGameInfo = false }
                        .foregroundStyle(.fernetPink)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func infoSheetRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(FernetFont.caption(13))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(FernetFont.label(13))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 12)
    }
}
