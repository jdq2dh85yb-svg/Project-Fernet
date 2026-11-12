import SwiftUI

struct FernetDownloadView: View {
    @EnvironmentObject var vm: FernetDownloadViewModel
    @State private var ringRotation: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    FernetSectionHeader(title: "Download", subtitle: "Chapter 2 Season 3 Client")
                    Spacer()
                }
                .padding(.top, 60)

                // Game art card
                gameArtCard

                // Progress card
                progressCard

                // Info grid
                infoGrid

                // Install notes
                installNotes

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
        }
        .background(FernetBackground())
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }
    }

    private var gameArtCard: some View {
        ZStack(alignment: .bottomLeading) {
            // Art background
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.35),
                        Color(red: 0.60, green: 0.25, blue: 0.50),
                        Color(red: 0.80, green: 0.40, blue: 0.60),
                    ],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )

                // Water shine
                RadialGradient(
                    colors: [.fernetCyan.opacity(0.2), .clear],
                    center: UnitPoint(x: 0.2, y: 0.8),
                    startRadius: 5,
                    endRadius: 150
                )

                // Logo large
                Image("OGFNLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 140)
                    .opacity(0.15)
                    .offset(x: 60, y: -10)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
            )

            // Overlay info
            VStack(alignment: .leading, spacing: 4) {
                Text("CHAPTER 2 • SEASON 3")
                    .font(FernetFont.caption(10))
                    .tracking(2.5)
                    .foregroundStyle(.fernetCyan)
                Text("Splashdown")
                    .font(FernetFont.display(22))
                    .foregroundStyle(.white)
                Text("v13.40.0 · 26.4 GB")
                    .font(FernetFont.caption(12))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(16)
        }
    }

    private var progressCard: some View {
        VStack(spacing: 20) {
            // State header
            HStack {
                Text(stateLabel)
                    .font(FernetFont.display(14))
                    .tracking(2)
                    .foregroundStyle(stateColor)
                Spacer()
                Text("\(Int(vm.progress * 100))%")
                    .font(FernetFont.mono(28))
                    .foregroundStyle(.white)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.fernetPink, .fernetViolet, .fernetCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * vm.progress, height: 8)
                        .animation(.linear(duration: 0.3), value: vm.progress)

                    // Shimmer pulse on active download
                    if vm.state == .downloading {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 60, height: 8)
                            .offset(x: (geo.size.width * vm.progress) - 30)
                            .blur(radius: 4)
                    }
                }
            }
            .frame(height: 8)

            // Stats row
            HStack(spacing: 20) {
                downloadStat(label: "DOWNLOADED", value: String(format: "%.1f GB", vm.downloadedGB))
                Divider().frame(height: 30).background(Color.white.opacity(0.1))
                downloadStat(label: "SPEED", value: vm.state == .downloading ? vm.speedText : "—")
                Divider().frame(height: 30).background(Color.white.opacity(0.1))
                downloadStat(label: "ETA", value: vm.state == .downloading ? vm.etaText : "—")
            }

            // Buttons
            HStack(spacing: 12) {
                if vm.state == .idle || vm.state == .complete {
                    actionButton(
                        label: vm.state == .complete ? "REINSTALL" : "START DOWNLOAD",
                        icon: "arrow.down.circle.fill",
                        gradient: FernetGradients.pinkAccent
                    ) {
                        vm.state == .complete ? vm.reset() : vm.start()
                        if vm.state == .idle { vm.start() }
                    }
                } else if vm.state == .downloading {
                    actionButton(
                        label: "PAUSE",
                        icon: "pause.circle.fill",
                        gradient: LinearGradient(colors: [.fernetCyanDim, .fernetCyan], startPoint: .leading, endPoint: .trailing)
                    ) { vm.pause() }
                } else if vm.state == .paused {
                    actionButton(
                        label: "RESUME",
                        icon: "play.circle.fill",
                        gradient: FernetGradients.pinkAccent
                    ) { vm.resume() }

                    Button {
                        vm.reset()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 52, height: 52)
                            .glassCard(cornerRadius: 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 16)
    }

    private func downloadStat(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(FernetFont.mono(14))
                .foregroundStyle(.white)
            Text(label)
                .font(FernetFont.caption(9))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private func actionButton(label: String, icon: String, gradient: LinearGradient, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                Text(label)
                    .font(FernetFont.display(13))
                    .tracking(1.5)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var stateLabel: String {
        switch vm.state {
        case .idle:        return "READY TO DOWNLOAD"
        case .downloading: return "DOWNLOADING"
        case .paused:      return "PAUSED"
        case .complete:    return "INSTALLED"
        }
    }

    private var stateColor: Color {
        switch vm.state {
        case .idle:        return .white.opacity(0.6)
        case .downloading: return .fernetCyan
        case .paused:      return .fernetGold
        case .complete:    return .green
        }
    }

    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            infoCell(label: "VERSION",    value: "v13.40.0",    icon: "tag.fill")
            infoCell(label: "SIZE",       value: "26.4 GB",     icon: "internaldrive.fill")
            infoCell(label: "PLATFORM",   value: "iOS",         icon: "iphone")
            infoCell(label: "ENGINE",     value: "UE 4.25",     icon: "cpu.fill")
        }
    }

    private func infoCell(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.fernetPink)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(FernetFont.caption(9))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.4))
                Text(value)
                    .font(FernetFont.label(13))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(14)
        .glassCard(cornerRadius: 12)
    }

    private var installNotes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Installation Notes", systemImage: "info.circle.fill")
                .font(FernetFont.label(12))
                .foregroundStyle(.fernetCyan)

            Text("This is a simulated download. No actual game files are transferred. Project Fernet is an unofficial community launcher not affiliated with Epic Games.")
                .font(FernetFont.caption(12))
                .foregroundStyle(.white.opacity(0.45))
                .lineSpacing(4)
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }
}
