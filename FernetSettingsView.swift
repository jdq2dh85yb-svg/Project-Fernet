import SwiftUI

struct FernetSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    @State private var playerName = ""
    @State private var animationsEnabled = true
    @State private var particlesEnabled  = true
    @State private var soundEnabled      = false
    @State private var notificationsEnabled = true
    @State private var selectedTheme = 0
    @State private var saved = false

    let themes = ["Fernet Dark", "Ocean Deep", "Midnight Pink"]

    var body: some View {
        NavigationStack {
            ZStack {
                FernetBackground().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Logo
                        FernetLogo(size: 40)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)

                        // General
                        settingsGroup(title: "GENERAL", icon: "gearshape.fill") {
                            VStack(spacing: 0) {
                                settingsRow {
                                    Text("Player Name")
                                        .font(FernetFont.label(14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    TextField("Enter name", text: $playerName)
                                        .multilineTextAlignment(.trailing)
                                        .font(FernetFont.caption(13))
                                        .foregroundStyle(.fernetCyan)
                                        .frame(maxWidth: 140)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                }
                                divider
                                settingsRow {
                                    Label("Notifications", systemImage: "bell.fill")
                                        .font(FernetFont.label(14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Toggle("", isOn: $notificationsEnabled)
                                        .tint(.fernetPink)
                                }
                            }
                        }

                        // Appearance
                        settingsGroup(title: "APPEARANCE", icon: "paintpalette.fill") {
                            VStack(spacing: 0) {
                                settingsRow {
                                    Text("Theme")
                                        .font(FernetFont.label(14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Picker("", selection: $selectedTheme) {
                                        ForEach(0..<themes.count, id: \.self) { i in
                                            Text(themes[i]).tag(i)
                                        }
                                    }
                                    .tint(.fernetCyan)
                                }
                                divider
                                settingsRow {
                                    Label("Cinematic Gradients", systemImage: "sparkles")
                                        .font(FernetFont.label(14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Toggle("", isOn: .constant(true))
                                        .tint(.fernetPink)
                                        .disabled(true)
                                }
                            }
                        }

                        // Animations
                        settingsGroup(title: "ANIMATIONS", icon: "wand.and.stars") {
                            VStack(spacing: 0) {
                                settingsRow {
                                    Label("UI Animations", systemImage: "motion.effects")
                                        .font(FernetFont.label(14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Toggle("", isOn: $animationsEnabled)
                                        .tint(.fernetPink)
                                }
                                divider
                                settingsRow {
                                    Label("Floating Particles", systemImage: "circle.dotted")
                                        .font(FernetFont.label(14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Toggle("", isOn: $particlesEnabled)
                                        .tint(.fernetPink)
                                }
                                divider
                                settingsRow {
                                    Label("Launch Animation", systemImage: "sparkle")
                                        .font(FernetFont.label(14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Toggle("", isOn: .constant(true))
                                        .tint(.fernetPink)
                                }
                            }
                        }

                        // Sound
                        settingsGroup(title: "SOUND", icon: "speaker.wave.2.fill") {
                            settingsRow {
                                Label("UI Sound Effects", systemImage: "music.note")
                                    .font(FernetFont.label(14))
                                    .foregroundStyle(.white)
                                Spacer()
                                Toggle("", isOn: $soundEnabled)
                                    .tint(.fernetPink)
                            }
                        }

                        // Save button
                        Button {
                            let trimmed = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
                            settings.playerName = trimmed.isEmpty ? "Player" : trimmed
                            settings.showNotifications = notificationsEnabled
                            withAnimation { saved = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { saved = false }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: saved ? "checkmark" : "square.and.arrow.down")
                                    .font(.system(size: 14, weight: .bold))
                                Text(saved ? "SAVED" : "SAVE SETTINGS")
                                    .font(FernetFont.display(14))
                                    .tracking(2)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(saved ? AnyShapeStyle(FernetGradients.cyanAccent) : AnyShapeStyle(FernetGradients.pinkAccent))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)

                        // About
                        settingsGroup(title: "ABOUT", icon: "info.circle.fill") {
                            VStack(spacing: 0) {
                                settingsRow {
                                    Text("Application")
                                        .font(FernetFont.label(14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("Project Fernet")
                                        .font(FernetFont.caption(13))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                divider
                                settingsRow {
                                    Text("Version")
                                        .font(FernetFont.label(14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("1.0.0 (Build 1)")
                                        .font(FernetFont.mono(12))
                                        .foregroundStyle(.fernetCyan)
                                }
                                divider
                                settingsRow {
                                    Text("Season")
                                        .font(FernetFont.label(14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("Chapter 2 • Season 3")
                                        .font(FernetFont.caption(13))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                divider
                                settingsRow {
                                    Text("Client Build")
                                        .font(FernetFont.label(14))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("v13.40.0")
                                        .font(FernetFont.mono(12))
                                        .foregroundStyle(.fernetCyan)
                                }
                            }
                        }

                        // Disclaimer
                        VStack(spacing: 6) {
                            Text("Project Fernet")
                                .font(FernetFont.display(13))
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.4))
                            Text("Unofficial community launcher")
                                .font(FernetFont.caption(11))
                                .foregroundStyle(.white.opacity(0.25))
                            Text("Not affiliated with Epic Games, Inc.")
                                .font(FernetFont.caption(10))
                                .foregroundStyle(.white.opacity(0.2))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.fernetPink)
                        .font(FernetFont.label(15))
                }
            }
            .onAppear {
                playerName = settings.playerName
                notificationsEnabled = settings.showNotifications
            }
        }
    }

    // MARK: Helpers

    private func settingsGroup<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(FernetFont.caption(10))
                .tracking(2.5)
                .foregroundStyle(.fernetPink)

            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .glassCard(cornerRadius: 16)
        }
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack { content() }
            .padding(.vertical, 14)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
    }
}
