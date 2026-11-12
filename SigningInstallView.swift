
import SwiftUI

struct SigningInstallView: View {
    @StateObject private var downloader = IPADownloadManager()

    private let fortnite541URL =
        "https://dl.fortforge.co.uk/t/2c64f47adbeffbca5435125c5da2ed4712831403344a001c"

    private let accent = Color(
        red: 0.25,
        green: 0.72,
        blue: 1.0
    )

    var body: some View {
        NavigationStack {
            ZStack {
                Color(
                    red: 0.025,
                    green: 0.04,
                    blue: 0.075
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        downloadSection

                        if let file = downloader.downloadedFile {
                            downloadedFileSection(file: file)
                        }

                        if let error = downloader.errorMessage {
                            errorSection(error)
                        }

                        nextStepSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Install")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OGFN INSTALLER")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(accent)

            Text("Download. Sign. Install.")
                .font(.system(size: 29, weight: .bold))
                .foregroundStyle(.white)

            Text(
                "Your game builds are stored inside OGFN Manager."
            )
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.vertical, 8)
    }

    // MARK: - Download

    private var downloadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("01", "Available Build")

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(accent.opacity(0.15))
                        .frame(width: 68, height: 68)

                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 29))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Fortnite")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Version 5.41")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accent)

                    Text("Chapter 1 · Season 5")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                Text("IPA")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }

            Button {
                downloader.startDownload(from: fortnite541URL)
            } label: {
                HStack(spacing: 10) {
                    if downloader.isDownloading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }

                    Text(
                        downloader.isDownloading
                        ? "Downloading..."
                        : "Download Fortnite 5.41"
                    )
                    .fontWeight(.bold)

                    Spacer()

                    if !downloader.isDownloading {
                        Image(systemName: "arrow.right")
                    }
                }
                .foregroundStyle(.white)
                .padding(16)
                .background(accent)
                .clipShape(RoundedRectangle(cornerRadius: 13))
            }
            .disabled(downloader.isDownloading)

            if downloader.isDownloading {
                ProgressView(value: downloader.progress)
                    .tint(accent)

                HStack {
                    Text(downloader.status)
                    Spacer()
                    Text("\(Int(downloader.progress * 100))%")
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))

                Button {
                    downloader.cancelDownload()
                } label: {
                    Label("Cancel Download", systemImage: "xmark.circle")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                }
            } else {
                Text(downloader.status)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Label {
                Text(
                    "If the download fails, wait 30 seconds and try again."
                )
            } icon: {
                Image(systemName: "info.circle.fill")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.6))
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(17)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Downloaded File

    private func downloadedFileSection(file: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("02", "Build Saved")

            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Fortnite 5.41")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Saved inside OGFN Manager")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))

                    Text(file.lastPathComponent)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(2)
                }

                Spacer()
            }

            Text(
                "Your IPA is stored locally. Signing and installation will be added in the next step."
            )
            .font(.caption)
            .foregroundStyle(.white.opacity(0.6))
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(17)
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Next Step

    private var nextStepSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("03", "Signing & Installation")

            Text(
                "After the download system is tested, we will connect the saved build to the signing profile and supported iOS installation process."
            )
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.65))
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(17)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Error

    private func errorSection(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                "Download Error",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.headline)
            .foregroundStyle(.red)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Section Title

    private func sectionTitle(
        _ number: String,
        _ title: String
    ) -> some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(accent)

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
}
