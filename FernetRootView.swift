import SwiftUI

struct FernetRootView: View {
    @State private var selectedTab: FernetTab = .home
    @State private var showSettings = false
    @State private var showLaunch   = true

    var body: some View {
        ZStack {
            FernetBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Tab content
                ZStack {
                    FernetHomeView()
                        .opacity(selectedTab == .home ? 1 : 0)
                        .allowsHitTesting(selectedTab == .home)

                    FernetDownloadView()
                        .opacity(selectedTab == .download ? 1 : 0)
                        .allowsHitTesting(selectedTab == .download)

                    FernetLibraryView()
                        .opacity(selectedTab == .library ? 1 : 0)
                        .allowsHitTesting(selectedTab == .library)

                    FernetItemShopView()
                        .opacity(selectedTab == .itemShop ? 1 : 0)
                        .allowsHitTesting(selectedTab == .itemShop)

                    FernetLeaderboardView()
                        .opacity(selectedTab == .leaderboard ? 1 : 0)
                        .allowsHitTesting(selectedTab == .leaderboard)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.2), value: selectedTab)

                // Custom tab bar
                FernetTabBar(selected: $selectedTab, showSettings: $showSettings)
            }
            .ignoresSafeArea(edges: .bottom)

            // Launch screen overlay
            if showLaunch {
                FernetLaunchScreen()
                    .transition(.opacity)
                    .zIndex(99)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                showLaunch = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showSettings) {
            FernetSettingsView()
        }
    }
}

// MARK: - Launch Screen

struct FernetLaunchScreen: View {
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.fernetBlack.ignoresSafeArea()

            RadialGradient(
                colors: [.fernetPinkDeep.opacity(0.35), .fernetViolet.opacity(0.2), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 350
            )
            .ignoresSafeArea()

            ParticleField()
                .opacity(0.6)

            VStack(spacing: 24) {
                ZStack {
                    // Glow halo
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.fernetPink.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 1,
                                endRadius: glowRadius
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)

                    Image("OGFNLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(.fernetPink.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: .fernetPink.opacity(0.5), radius: 20)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 6) {
                    Text("PROJECT")
                        .font(FernetFont.caption(14))
                        .tracking(8)
                        .foregroundStyle(.fernetPink)
                    Text("FERNET")
                        .font(FernetFont.display(36))
                        .tracking(6)
                        .foregroundStyle(.white)
                }
                .opacity(subtitleOpacity)

                Text("UNOFFICIAL COMMUNITY LAUNCHER")
                    .font(FernetFont.caption(10))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.35))
                    .opacity(subtitleOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                logoScale = 1.0
                logoOpacity = 1.0
                glowRadius = 90
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
                subtitleOpacity = 1.0
            }
        }
    }
}
