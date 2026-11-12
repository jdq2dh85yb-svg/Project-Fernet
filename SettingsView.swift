import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var editedPlayerName = ""
    @State private var showSaved = false
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                OGFNBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 23) {
                        OGFNLogo()
                            .padding(.top, 10)

                        SectionHeading(
                            title: "Settings",
                            subtitle: "Customize your OGFN Manager"
                        )

                        settingsSection("PROFILE", icon: "person.fill") {
                            VStack(alignment: .leading, spacing: 9) {
                                settingLabel("PLAYER NAME")

                                TextField("Enter player name", text: $editedPlayerName)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(13)
                                    .background(.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                            }
                        }

                        settingsSection("PREFERENCES", icon: "slider.horizontal.3") {
                            Toggle("Show notifications", isOn: $settings.showNotifications)
                                .tint(.cyan)
                        }

                        settingsSection("LOCAL DATA", icon: "externaldrive.fill") {
                            Text("Equipped items and V-Bucks are stored on this device for each version.")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.5))

                            Button {
                                showReset = true
                            } label: {
                                Label("RESET LOCKER DATA", systemImage: "trash")
                                    .font(.system(size: 11, weight: .black))
                                    .tracking(1)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(13)
                                    .background(.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                            }
                        }

                        Button {
                            let name = editedPlayerName.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            settings.playerName = name.isEmpty ? "Player" : name
                            editedPlayerName = settings.playerName
                            showSaved = true
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("SAVE SETTINGS")
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

                        if showSaved {
                            Text("Settings saved successfully.")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.green)
                        }

                        VStack(spacing: 7) {
                            OGFNLogo()

                            Text("Unofficial community launcher • Version 2.0")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.4))

                            Text("Not affiliated with Epic Games.")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                editedPlayerName = settings.playerName
            }
            .confirmationDialog(
                "Reset locker data?",
                isPresented: $showReset,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    ProfileStore.shared.reset()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all equipped items and V-Bucks for every version.")
            }
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .black))
                .tracking(2)
                .foregroundStyle(.cyan)

            content()
        }
        .padding(16)
        .background(.white.opacity(0.055))
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }

    private func settingLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .black))
            .tracking(2)
            .foregroundStyle(.white.opacity(0.5))
    }
}
