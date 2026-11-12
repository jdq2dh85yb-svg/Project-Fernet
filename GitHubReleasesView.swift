
import SwiftUI
import Foundation
import Security

// MARK: - GitHub Models

struct OGFNRelease: Decodable, Identifiable {
    let id: Int
    let name: String?
    let tagName: String
    let publishedAt: String?
    let htmlURL: String
    let assets: [OGFNReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case tagName = "tag_name"
        case publishedAt = "published_at"
        case htmlURL = "html_url"
        case assets
    }
}

struct OGFNReleaseAsset: Decodable, Identifiable {
    let id: Int
    let name: String
    let size: Int
    let downloadCount: Int
    let contentType: String
    let apiURL: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case size
        case downloadCount = "download_count"
        case contentType = "content_type"
        case apiURL = "url"
    }

    var isIPA: Bool {
        name.lowercased().hasSuffix(".ipa")
    }

    var formattedSize: String {
        ByteCountFormatter.string(
            fromByteCount: Int64(size),
            countStyle: .file
        )
    }
}

// MARK: - Secure Token Storage

enum GitHubTokenStorage {
    private static let service = "app.lemur8898.ximenia4838.github"
    private static let account = "private-repository-token"

    static func save(_ token: String) -> Bool {
        let data = Data(token.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        var newItem = query
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] =
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        return SecItemAdd(newItem as CFDictionary, nil) == errSecSuccess
    }

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        guard SecItemCopyMatching(
            query as CFDictionary,
            &result
        ) == errSecSuccess,
        let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - GitHub Manager

@MainActor
final class GitHubReleaseManager: ObservableObject {

    @Published var releases: [OGFNRelease] = []
    @Published var isLoading = false
    @Published var isDownloading = false
    @Published var status = "Connect your GitHub account."
    @Published var errorMessage: String?
    @Published var downloadedFile: URL?
    @Published var hasToken = false
    @Published var downloadProgress = 0.0

    private let owner = "jdq2dh85yb-svg"
    private let repository = "OGFNManager-iOS"

    init() {
        hasToken = GitHubTokenStorage.load() != nil
    }

    func saveToken(_ token: String) {
        let cleaned = token.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleaned.isEmpty else {
            errorMessage = "Enter a GitHub token first."
            return
        }

        guard GitHubTokenStorage.save(cleaned) else {
            errorMessage = "The token could not be saved."
            return
        }

        hasToken = true
        errorMessage = nil
        status = "GitHub token saved securely."
    }

    func removeToken() {
        GitHubTokenStorage.delete()
        hasToken = false
        releases = []
        downloadedFile = nil
        status = "GitHub account disconnected."
        errorMessage = nil
    }

    private func makeRequest(
        url: URL,
        token: String,
        accept: String = "application/vnd.github+json"
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            accept,
            forHTTPHeaderField: "Accept"
        )
        request.setValue(
            "2022-11-28",
            forHTTPHeaderField: "X-GitHub-Api-Version"
        )
        request.setValue(
            "OGFNManager-iOS",
            forHTTPHeaderField: "User-Agent"
        )
        return request
    }

    func fetchReleases() async {
        guard let token = GitHubTokenStorage.load() else {
            errorMessage = "Connect your GitHub account first."
            return
        }

        guard let url = URL(
            string: "https://api.github.com/repos/\(owner)/\(repository)/releases?per_page=30"
        ) else {
            errorMessage = "Invalid GitHub URL."
            return
        }

        isLoading = true
        errorMessage = nil
        status = "Loading private releases..."

        defer { isLoading = false }

        do {
            let request = makeRequest(url: url, token: token)
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let http = response as? HTTPURLResponse else {
                throw NSError(
                    domain: "GitHub",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Invalid server response."
                    ]
                )
            }

            guard http.statusCode == 200 else {
                if http.statusCode == 401 || http.statusCode == 403 {
                    throw NSError(
                        domain: "GitHub",
                        code: http.statusCode,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "GitHub rejected the token. Check its permissions."
                        ]
                    )
                }

                if http.statusCode == 404 {
                    throw NSError(
                        domain: "GitHub",
                        code: 404,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Repository not found or token has no access."
                        ]
                    )
                }

                throw NSError(
                    domain: "GitHub",
                    code: http.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "GitHub returned HTTP \(http.statusCode)."
                    ]
                )
            }

            let decoder = JSONDecoder()
            releases = try decoder.decode(
                [OGFNRelease].self,
                from: data
            )

            status = releases.isEmpty
                ? "No releases found yet."
                : "\(releases.count) releases loaded."

        } catch {
            errorMessage = error.localizedDescription
            status = "Could not load releases."
        }
    }

    func download(asset: OGFNReleaseAsset) async {
        guard let token = GitHubTokenStorage.load() else {
            errorMessage = "Connect your GitHub account first."
            return
        }

        guard let url = URL(string: asset.apiURL) else {
            errorMessage = "Invalid download URL."
            return
        }

        isDownloading = true
        downloadProgress = 0
        errorMessage = nil
        status = "Downloading \(asset.name)..."

        defer {
            isDownloading = false
        }

        do {
            let request = makeRequest(
                url: url,
                token: token,
                accept: "application/octet-stream"
            )

            let (temporaryURL, response) =
                try await URLSession.shared.download(for: request)

            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200 else {
                throw NSError(
                    domain: "GitHub",
                    code: 2,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "The IPA download failed."
                    ]
                )
            }

            let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

            let folder = documents.appendingPathComponent(
                "GitHub Downloads",
                isDirectory: true
            )

            try FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true
            )

            let destination = folder.appendingPathComponent(asset.name)

            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }

            try FileManager.default.moveItem(
                at: temporaryURL,
                to: destination
            )

            downloadedFile = destination
            downloadProgress = 1
            status = "Download completed."

        } catch {
            errorMessage = error.localizedDescription
            status = "Download failed."
        }
    }
}

// MARK: - Releases Interface

struct GitHubReleasesView: View {

    @StateObject private var manager = GitHubReleaseManager()
    @State private var tokenInput = ""

    private let accent = Color(
        red: 0.25,
        green: 0.55,
        blue: 1.0
    )

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        header

                        if !manager.hasToken {
                            connectionCard
                        } else {
                            connectedCard
                            releasesSection
                        }

                        if let error = manager.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 12)
                                )
                        }

                        if let file = manager.downloadedFile {
                            downloadedCard(file: file)
                        }
                    }
                    .padding()
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 28))
                    .foregroundColor(accent)

                Spacer()

                Text("PRIVATE STORAGE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.gray)
            }

            Text("GitHub Releases")
                .font(.system(size: 30, weight: .bold))

            Text("Download builds from your private repository.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Connect GitHub", systemImage: "lock.fill")
                .font(.headline)

            Text("Create a fine-grained token with read-only access to this repository.")
                .font(.footnote)
                .foregroundColor(.gray)

            SecureField("GitHub access token", text: $tokenInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                manager.saveToken(tokenInput)
                tokenInput = ""
            } label: {
                Label(
                    "Save Token Securely",
                    systemImage: "lock.shield.fill"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(accent)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Link(
                "Open GitHub Token Settings",
                destination: URL(
                    string: "https://github.com/settings/personal-access-tokens/new"
                )!
            )
            .font(.footnote)
            .foregroundColor(accent)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var connectedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    "GitHub Connected",
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundColor(.green)
                .font(.headline)

                Spacer()

                Button("Disconnect") {
                    manager.removeToken()
                }
                .font(.caption)
                .foregroundColor(.red)
            }

            Text("jdq2dh85yb-svg / OGFNManager-iOS")
                .font(.footnote)
                .foregroundColor(.gray)

            Button {
                Task {
                    await manager.fetchReleases()
                }
            } label: {
                HStack {
                    if manager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }

                    Text("Load Releases")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(accent)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(manager.isLoading)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var releasesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Available Releases")
                    .font(.title3.bold())

                Spacer()

                Text("\(manager.releases.count)")
                    .foregroundColor(.gray)
            }

            Text(manager.status)
                .font(.caption)
                .foregroundColor(.gray)

            if manager.releases.isEmpty && !manager.isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 38))
                        .foregroundColor(.gray)

                    Text("No Releases")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Load releases or publish your first GitHub release.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            ForEach(manager.releases) { release in
                releaseCard(release)
            }
        }
    }

    private func releaseCard(_ release: OGFNRelease) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(release.name ?? release.tagName)
                .font(.headline)

            Text(release.tagName)
                .font(.caption)
                .foregroundColor(accent)

            if let date = release.publishedAt {
                Text("Published: \(date)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Divider()
                .overlay(Color.white.opacity(0.1))

            let ipaAssets = release.assets.filter { $0.isIPA }

            if ipaAssets.isEmpty {
                Text("No IPA file in this release.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            ForEach(ipaAssets) { asset in
                HStack(spacing: 10) {
                    Image(systemName: "app.badge")
                        .foregroundColor(accent)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(asset.name)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)

                        Text(asset.formattedSize)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button {
                        Task {
                            await manager.download(asset: asset)
                        }
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(accent)
                    }
                    .disabled(manager.isDownloading)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func downloadedCard(file: URL) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                "Download Complete",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundColor(.green)
            .font(.headline)

            Text(file.lastPathComponent)
                .font(.footnote)
                .foregroundColor(.gray)

            ShareLink(item: file) {
                Label(
                    "Share IPA File",
                    systemImage: "square.and.arrow.up"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
