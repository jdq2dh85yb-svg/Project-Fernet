import SwiftUI

// MARK: - Color Palette

extension Color {
    static let fernetBlack      = Color(red: 0.04,  green: 0.04,  blue: 0.06)
    static let fernetNavy       = Color(red: 0.05,  green: 0.07,  blue: 0.14)
    static let fernetDeepNavy   = Color(red: 0.03,  green: 0.04,  blue: 0.10)
    static let fernetCharcoal   = Color(red: 0.10,  green: 0.11,  blue: 0.16)
    static let fernetPink       = Color(red: 0.90,  green: 0.30,  blue: 0.65)
    static let fernetPinkLight  = Color(red: 1.00,  green: 0.45,  blue: 0.75)
    static let fernetPinkDeep   = Color(red: 0.70,  green: 0.15,  blue: 0.48)
    static let fernetViolet     = Color(red: 0.40,  green: 0.20,  blue: 0.75)
    static let fernetCyan       = Color(red: 0.30,  green: 0.85,  blue: 0.95)
    static let fernetCyanDim    = Color(red: 0.20,  green: 0.60,  blue: 0.75)
    static let fernetGold       = Color(red: 1.00,  green: 0.80,  blue: 0.20)
    static let fernetSilver     = Color(red: 0.75,  green: 0.80,  blue: 0.90)
    static let fernetBronze     = Color(red: 0.80,  green: 0.50,  blue: 0.20)
}

// MARK: - Gradients

struct FernetGradients {
    static let background = LinearGradient(
        colors: [.fernetBlack, .fernetDeepNavy, Color(red: 0.06, green: 0.04, blue: 0.12)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let heroBanner = LinearGradient(
        colors: [.fernetPinkDeep.opacity(0.9), .fernetViolet.opacity(0.7), .fernetDeepNavy],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let pinkAccent = LinearGradient(
        colors: [.fernetPink, .fernetPinkDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cyanAccent = LinearGradient(
        colors: [.fernetCyan, .fernetCyanDim],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let cardSurface = LinearGradient(
        colors: [Color.white.opacity(0.07), Color.white.opacity(0.03)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldPodium = LinearGradient(
        colors: [.fernetGold, Color(red: 1, green: 0.6, blue: 0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let navBar = LinearGradient(
        colors: [Color.black.opacity(0.95), Color(red: 0.04, green: 0.04, blue: 0.10).opacity(0.98)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography

struct FernetFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .default)
    }
    static func headline(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }
    static func label(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }
    static func caption(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var borderOpacity: CGFloat = 0.15

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(FernetGradients.cardSurface)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.white.opacity(borderOpacity), lineWidth: 0.5)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16, borderOpacity: CGFloat = 0.15) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }
}

// MARK: - Fernet Background

struct FernetBackground: View {
    @State private var animOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color.fernetBlack.ignoresSafeArea()

            // Deep gradient
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.10),
                    Color(red: 0.06, green: 0.03, blue: 0.12),
                    Color.fernetBlack
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Atmospheric glow — top left (pink)
            RadialGradient(
                colors: [.fernetPinkDeep.opacity(0.18), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 350
            )
            .ignoresSafeArea()

            // Atmospheric glow — bottom right (violet/cyan)
            RadialGradient(
                colors: [.fernetViolet.opacity(0.12), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Fernet Logo View

struct FernetLogo: View {
    var size: CGFloat = 32

    var body: some View {
        HStack(spacing: 8) {
            Image("OGFNLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.2))

            VStack(alignment: .leading, spacing: 1) {
                Text("PROJECT")
                    .font(FernetFont.caption(size * 0.28))
                    .tracking(3)
                    .foregroundStyle(.fernetPink)
                Text("FERNET")
                    .font(FernetFont.display(size * 0.44))
                    .tracking(2)
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Play Button

struct FernetPlayButton: View {
    var action: () -> Void = {}
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
            }
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .black))
                Text("PLAY NOW")
                    .font(FernetFont.display(16))
                    .tracking(2)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(FernetGradients.pinkAccent)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(color: .fernetPink.opacity(0.4), radius: isPressed ? 4 : 12, y: isPressed ? 2 : 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header

struct FernetSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(FernetFont.display(13))
                .tracking(3)
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(FernetFont.caption(12))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let label: String
    let value: String
    var accent: Color = .fernetCyan

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(FernetFont.display(15))
                .foregroundStyle(accent)
            Text(label.uppercased())
                .font(FernetFont.caption(9))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 12)
    }
}

// MARK: - Floating Particles

struct FloatingParticle: View {
    let size: CGFloat
    let color: Color
    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double

    init(size: CGFloat = 2, color: Color = .fernetPink, initialOpacity: Double = Double.random(in: 0.2...0.6)) {
        self.size = size
        self.color = color
        self._opacity = State(initialValue: initialOpacity)
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size * 0.3)
            .opacity(opacity)
            .offset(y: yOffset)
            .onAppear {
                let duration = Double.random(in: 3...7)
                withAnimation(
                    .easeInOut(duration: duration).repeatForever(autoreverses: true)
                ) {
                    yOffset = CGFloat.random(in: -15...15)
                    opacity = Double.random(in: 0.1...0.5)
                }
            }
    }
}

struct ParticleField: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<18, id: \.self) { i in
                    FloatingParticle(
                        size: CGFloat.random(in: 1.5...3.5),
                        color: i % 3 == 0 ? .fernetCyan : (i % 3 == 1 ? .fernetPink : .fernetViolet),
                        initialOpacity: Double.random(in: 0.15...0.5)
                    )
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
                }
            }
        }
    }
}

// MARK: - Tab Item

enum FernetTab: Int, CaseIterable {
    case home = 0, download, library, itemShop, leaderboard

    var title: String {
        switch self {
        case .home:        return "Home"
        case .download:    return "Download"
        case .library:     return "Library"
        case .itemShop:    return "Shop"
        case .leaderboard: return "Ranks"
        }
    }

    var icon: String {
        switch self {
        case .home:        return "house.fill"
        case .download:    return "arrow.down.circle.fill"
        case .library:     return "books.vertical.fill"
        case .itemShop:    return "sparkles"
        case .leaderboard: return "trophy.fill"
        }
    }
}

// MARK: - Custom Tab Bar

struct FernetTabBar: View {
    @Binding var selected: FernetTab
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FernetTab.allCases, id: \.rawValue) { tab in
                tabButton(tab)
            }

            // Settings gear
            Button {
                showSettings = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Settings")
                        .font(FernetFont.caption(9))
                        .tracking(0.5)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(
            ZStack {
                FernetGradients.navBar
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
                // Top border glow
                VStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.fernetPink.opacity(0.6), .fernetViolet.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 0.5)
                    Spacer()
                }
            }
        )
    }

    private func tabButton(_ tab: FernetTab) -> some View {
        let isSelected = selected == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(FernetGradients.pinkAccent.opacity(0.2))
                            .frame(width: 44, height: 28)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? .fernetPink : .white.opacity(0.4))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                Text(tab.title)
                    .font(FernetFont.caption(9))
                    .tracking(0.5)
                    .foregroundStyle(isSelected ? .fernetPink : .white.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
