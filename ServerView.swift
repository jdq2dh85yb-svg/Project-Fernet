import SwiftUI

struct ServerView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var backend: BackendManager

    var body: some View {
        ZStack {
            OGFNBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 21) {
                    OGFNLogo()
                        .padding(.top, 12)

                    SectionHeading(
                        title: "Server",
                        subtitle: "Connect to your OGFN backend"
                    )

                    configurationCard
                    statusCard
                    requirementsCard
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var configurationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("BACKEND", systemImage: "server.rack")
                .font(.system(size: 11, weight: .black))
                .tracking(2)
                .foregroundStyle(.cyan)

            Text("BACKEND URL")
                .font(.system(size: 9, weight: .black))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))

            TextField("https://your-backend.example.com", text: $settings.backendURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(13)
                .background(.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 11))

            Button {
                Task {
                    await backend.checkBackend(urlString: settings.backendURL)
                }
            } label: {
                HStack(spacing: 8) {
                    if backend.isChecking {
                        ProgressView()
                            .tint(.black)
                    }

                    Text(backend.isChecking ? "CONNECTING..." : "CONNECT")
                        .tracking(2)
                }
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(backend.isChecking || settings.backendURL.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(settings.backendURL.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
        .padding(16)
        .background(.white.opacity(0.055))
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(backend.isOnline ? Color.green : Color.orange)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(backend.statusMessage)
                    .font(.system(size: 13, weight: .semibold))

                if let last = backend.lastChecked {
                    Text("Last checked \(last.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }

            Spacer()

            StatusIndicator(online: backend.isOnline)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var requirementsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("BACKEND REQUIREMENTS", systemImage: "list.bullet.rectangle")
                .font(.system(size: 11, weight: .black))
                .tracking(2)
                .foregroundStyle(.cyan)

            HStack {
                Text("GET /health")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                Spacer()
                Text("Status check")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Text("The app currently uses only this endpoint. It must return HTTP 200. Use an https:// address, because iOS blocks plain http://.")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(16)
        .background(.white.opacity(0.055))
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }
}
