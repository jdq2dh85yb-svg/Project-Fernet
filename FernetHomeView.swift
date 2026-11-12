import SwiftUI

struct FernetHomeView: View {
    @State private var heroScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.5
    @State private var statusOnline = true
    @State private var showPlayFlash = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroSection
                    .frame(height: 420)

                contentSection
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
            }
        }
        .background(FernetBackground())
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                heroScale = 1.06
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowOpacity = 0.9
            }
        }
    }

    // MARK: Hero Section
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Cinematic background — flooded island gradient
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.35),
                        Color(red: 0.12, green: 0.22, blue: 0.45),
                        Color(red: 0.60, green: 0.30, blue: 0.55),
                        Color(red: 0.80, green: 0.45, blue: 0.65),
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )

                // Ocean shimmer
                RadialGradient(
                    colors: [.fernetCyan.opacity(0.25), .clear],
                    center: UnitPoint(x: 0.3, y: 0.8),
                    startRadius: 5,
                    endRadius: 220
                )

                // Sun bloom
                RadialGradient(
                    colors: [Color.white.opacity(0.15), .fernetPinkLight.opacity(0.25), .clear],
                    center: UnitPoint(x: 0.7, y: 0.15),
                    startRadius: 5,
                    endRadius: 200
                )

                // Atmospheric haze layers
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.fernetDeepNavy, .fernetDeepNavy.opacity(0.6), .clear],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: 180)
                }

                // Floating island shapes
                islandArtwork
            }
            .scaleEffect(heroScale)
            .clipped()

            // Top bar overlay
            VStack {
                HStack {
                    FernetLogo(size: 36)
                    Spacer()
                    StatusIndicator(online: statusOnline)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                Spacer()
            }

            // Hero content overlay
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CHAPTER 2 • SEASON 3")
                        .font(FernetFont.caption(11))
                        .tracking(3)
                        .foregroundStyle(.fernetCyan)

                    Text("SPLASHDOWN")
                        .font(FernetFont.display(38))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4)

                    Text("The island has flooded. Explore the new world.")
                        .font(FernetFont.caption(13))
                        .foregroundStyle(.white.opacity(0.7))
                }

                FernetPlayButton {
                    withAnimation(.easeInOut(duration: 0.15)) { showPlayFlash = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPlayFlash = false
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Flash overlay on play
            if showPlayFlash {
                Color.white.opacity(0.08)
                    .transition(.opacity)
            }
        }
        .clipped()
    }

    // Procedural island art
    private var islandArtwork: some View {
        GeometryReader { geo in
            ZStack {
                // Water surface
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.fernetCyan.opacity(0.3), .fernetCyanDim.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 160
                        )
                    )
                    .frame(width: geo.size.width * 1.3, height: 80)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.78)
                    .blur(radius: 4)

                // Island landmass
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.25, green: 0.45, blue: 0.25),
                                Color(red: 0.15, green: 0.30, blue: 0.18)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geo.size.width * 0.5, height: 60)
                    .position(x: geo.size.width * 0.45, y: geo.size.height * 0.72)

                // Floating debris
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.3, green: 0.22, blue: 0.14).opacity(0.7))
                        .frame(
                            width: CGFloat([20, 14, 18, 10, 24][i]),
                            height: CGFloat([6, 5, 7, 4, 6][i])
                        )
                        .position(
                            x: geo.size.width * [0.2, 0.55, 0.75, 0.35, 0.65][i],
                            y: geo.size.height * [0.76, 0.75, 0.74, 0.77, 0.73][i]
                        )
                        .rotationEffect(.degrees([−12, 8, −5, 15, −9][i]))
                }

                // Clouds
                cloudShape(width: 120, opacity: 0.5)
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.25)
                cloudShape(width: 160, opacity: 0.4)
                    .position(x: geo.size.width * 0.75, y: geo.size.height * 0.18)
                cloudShape(width: 90, opacity: 0.35)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.30)

                // Stars / sparkles
                ForEach(0..<12, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.4...0.9)))
                        .frame(width: CGFloat.random(in: 1.5...3), height: CGFloat.random(in: 1.5...3))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height * 0.5)
                        )
                }
            }
        }
    }

    private func cloudShape(width: CGFloat, opacity: Double) -> some View {
        Capsule()
            .fill(Color.white.opacity(opacity))
            .frame(width: width, height: width * 0.35)
            .blur(radius: 8)
    }

    // MARK: Content Section
    private var contentSection: some View {
        VStack(spacing: 24) {
            // Server status bar
            serverStatusBar

            // Announcements
            announcementsSection

            // Featured Updates
            featuredUpdatesSection

            // Recent Activity
            recentActivitySection
        }
    }

    private var serverStatusBar: some View {
        HStack(spacing: 16) {
            statBadge(label: "PLAYERS ONLINE", value: "14,821", color: .fernetCyan)
            statBadge(label: "SERVER STATUS", value: "ONLINE", color: .green)
            statBadge(label: "SEASON", value: "C2 S3", color: .fernetPink)
        }
    }

    private func statBadge(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(FernetFont.display(13))
                .foregroundStyle(color)
            Text(label)
                .font(FernetFont.caption(8))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 12)
    }

    private var announcementsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FernetSectionHeader(title: "Announcements", subtitle: "Latest from the team")

            VStack(spacing: 10) {
                announcementRow(
                    icon: "megaphone.fill",
                    color: .fernetPink,
                    title: "Chapter 2 Season 3 Is Live",
                    body: "Dive into the flooded island. Swim, explore new POIs, and ride sharks.",
                    time: "2 hours ago"
                )
                announcementRow(
                    icon: "wrench.and.screwdriver.fill",
                    color: .fernetCyan,
                    title: "Server Maintenance Completed",
                    body: "All systems are stable. Backend v2.4.1 deployed successfully.",
                    time: "5 hours ago"
                )
                announcementRow(
                    icon: "star.fill",
                    color: .fernetGold,
                    title: "New Cosmetics in the Item Shop",
                    body: "Aqua Commander bundle and Shark Rider glider are now available.",
                    time: "1 day ago"
                )
            }
        }
    }

    private func announcementRow(icon: String, color: Color, title: String, body: String, time: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FernetFont.label(13))
                    .foregroundStyle(.white)
                Text(body)
                    .font(FernetFont.caption(12))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)
                Text(time)
                    .font(FernetFont.caption(10))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }

    private var featuredUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FernetSectionHeader(title: "Featured Updates", subtitle: "What's new this season")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    updateCard(title: "New POIs", subtitle: "7 locations flooded", icon: "map.fill", color: .fernetCyan)
                    updateCard(title: "Shark Riding", subtitle: "New mechanics", icon: "water.waves", color: .fernetPink)
                    updateCard(title: "Ocean Weapons", subtitle: "Water-themed loot", icon: "bolt.fill", color: .fernetGold)
                    updateCard(title: "New Outfits", subtitle: "12 cosmetics added", icon: "tshirt.fill", color: .fernetViolet)
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func updateCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(FernetFont.label(13))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(FernetFont.caption(11))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(14)
        .frame(width: 140)
        .glassCard(cornerRadius: 14)
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FernetSectionHeader(title: "Recent Activity", subtitle: "Your session history")

            VStack(spacing: 8) {
                activityRow(icon: "trophy.fill", color: .fernetGold,   text: "Victory Royale — Solos",          meta: "14 elims · 18 min")
                activityRow(icon: "xmark.circle.fill", color: .fernetPinkDeep, text: "Eliminated — Duos",       meta: "6 elims · 9 min")
                activityRow(icon: "trophy.fill", color: .fernetGold,   text: "Victory Royale — Squads",          meta: "8 elims · 22 min")
                activityRow(icon: "xmark.circle.fill", color: .fernetPinkDeep, text: "Top 5 — Solos",           meta: "11 elims · 16 min")
            }
        }
    }

    private func activityRow(icon: String, color: Color, text: String, meta: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 30)

            Text(text)
                .font(FernetFont.label(13))
                .foregroundStyle(.white)

            Spacer()

            Text(meta)
                .font(FernetFont.caption(11))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 12)
    }
}
