import SwiftUI
struct BackendDashboardView: View {
    var body: some View {
        TabView {
            GeneralPanel()
                .tabItem {
                    Label("General", systemImage: "server.rack")
                }
            BackendLockerPanel()
                .tabItem {
                    Label("Locker", systemImage: "person.crop.square")
                }
            BackendEventsPanel()
                .tabItem {
                    Label("Events", systemImage: "bolt.horizontal")
                }
            BackendConsolePanel()
                .tabItem {
                    Label("Console", systemImage: "terminal")
                }
        }
    }
}
// MARK: - General
struct GeneralPanel: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var backend = BackendManager()
    @State private var showingURLSheet = false
    @State private var isChecking = false
    @State private var message = ""
    @State private var isReachable = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    backendStatusCard
                    serverControlCard
                    gameserverCard
                    profileCard
                    scopeCard
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Backend")
            .sheet(isPresented: $showingURLSheet) {
                backendURLSheet
            }
        }
    }
    // MARK: Backend Status
    private var backendStatusCard: some View {
        dashboardCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "server.rack")
                        .font(.title2)
                    Text("Backend Connection")
                        .font(.headline)
                    Spacer()
                    statusIndicator
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Backend URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(
                        settings.backendURL.isEmpty
                        ? "Not configured"
                        : settings.backendURL
                    )
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(2)
                }
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 10) {
                    Button {
                        Task {
                            await checkBackend()
                        }
                    } label: {
                        HStack {
                            if isChecking {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(
                                isChecking
                                ? "Checking..."
                                : "Test Connection"
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        isChecking ||
                        settings.backendURL.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                    Button {
                        showingURLSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                            .frame(width: 42, height: 36)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    // MARK: Status Indicator
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isReachable ? Color.green : Color.gray)
                .frame(width: 9, height: 9)
            Text(isReachable ? "Reachable" : "Not tested")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    // MARK: Server Control
    private var serverControlCard: some View {
        dashboardCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "power")
                        .font(.title2)
                    Text("Server Control")
                        .font(.headline)
                    Spacer()
                }
                Text(
                    "Start or stop the configured backend server endpoint."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Button {
                        Task {
                            await startServer()
                        }
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    Button {
                        Task {
                            await stopServer()
                        }
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    // MARK: Game Server
    private var gameserverCard: some View {
        dashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "gamecontroller")
                        .font(.title2)
                    Text("Game Server")
                        .font(.headline)
                    Spacer()
                }
                infoRow(
                    title: "Host",
                    value: settings.gameserverHost.isEmpty
                        ? "Not configured"
                        : settings.gameserverHost
                )
                infoRow(
                    title: "Port",
                    value: settings.gameserverPort.isEmpty
                        ? "Not configured"
                        : settings.gameserverPort
                )
                Text(
                    "Gameserver integration will be connected in a later step."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
    // MARK: Profile
    private var profileCard: some View {
        dashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                    Text("Profile")
                        .font(.headline)
                    Spacer()
                }
                Text(
                    "Login and profile synchronization are not connected yet."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                Text(
                    "Current scope: backend connectivity only."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
    // MARK: Scope
    private var scopeCard: some View {
        dashboardCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                    Text("Current Scope")
                        .font(.headline)
                }
                scopeRow("Backend connection", true)
                scopeRow("Backend reachability test", true)
                scopeRow("Login", false)
                scopeRow("Profile", false)
                scopeRow("Friends / XMPP", false)
                scopeRow("Party / Lobby", false)
                scopeRow("Matchmaking", false)
                scopeRow("Gameserver", false)
            }
        }
    }
    // MARK: URL Sheet
    private var backendURLSheet: some View {
        NavigationStack {
            Form {
                Section("Backend URL") {
                    TextField(
                        "https://example.com",
                        text: $settings.backendURL
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                }
                Section {
                    Text(
                        "Enter the base URL of your LawinServerV2 instance."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Text(
                        "The connection test checks whether the server responds over HTTP. It does not perform login."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Backend URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingURLSheet = false
                    }
                }
            }
        }
    }
    // MARK: Async Actions
    private func checkBackend() async {
        await MainActor.run {
            isChecking = true
            message = ""
        }
        await backend.checkBackend(
            urlString: settings.backendURL,
            token: settings.apiToken
        )
        await MainActor.run {
            isChecking = false
            isReachable = true
            if message.isEmpty {
                message = "Backend request completed."
            }
        }
    }
    private func startServer() async {
        await backend.start(settings: settings)
        await MainActor.run {
            message = "Start request sent."
        }
    }
    private func stopServer() async {
        await backend.stop(settings: settings)
        await MainActor.run {
            message = "Stop request sent."
        }
    }
    // MARK: UI Helpers
    private func dashboardCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.08))
        )
    }
    private func infoRow(
        title: String,
        value: String
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
        }
    }
    private func scopeRow(
        _ title: String,
        _ enabled: Bool
    ) -> some View {
        HStack {
            Image(
                systemName: enabled
                ? "checkmark.circle.fill"
                : "circle"
            )
            .foregroundStyle(
                enabled
                ? .green
                : .secondary
            )
            Text(title)
            Spacer()
            if !enabled {
                Text("Later")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
// MARK: - Locker
struct BackendLockerPanel: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.square")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)
                Text("Locker")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(
                    "Locker integration will be connected after authentication and profile support are implemented."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .navigationTitle("Locker")
        }
    }
}
// MARK: - Events
struct BackendEventsPanel: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "bolt.horizontal")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)
                Text("Events")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(
                    "Backend event streaming will be connected after the core backend connection is stable."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .navigationTitle("Events")
        }
    }
}
// MARK: - Console
struct BackendConsolePanel: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Console")
                        .font(.headline)
                    Text(
                        "Backend logging is currently handled by ConsoleLog."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    Text(
                        "A live console view will be added once the backend connection layer is stable."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    Text(
                        "Use the GitHub Actions build log for compile-time diagnostics."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding()
            }
            .navigationTitle("Console")
        }
    }
}
