import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var name = ""
    @FocusState private var focused: Bool

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        trimmed.count >= 2
    }

    var body: some View {
        ZStack {
            OGFNBackground()

            VStack(alignment: .leading, spacing: 22) {
                Spacer()

                OGFNLogo()

                VStack(alignment: .leading, spacing: 8) {
                    Text("WELCOME")
                        .font(.system(size: 34, weight: .black, design: .rounded))

                    Text("Choose a player name to get started.")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }

                TextField("Your name", text: $name)
                    .focused($focused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.continue)
                    .onSubmit { finish() }
                    .padding(16)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                    .onChange(of: name) { newValue in
                        if newValue.count > 20 {
                            name = String(newValue.prefix(20))
                        }
                    }

                Button {
                    finish()
                } label: {
                    HStack {
                        Text("CONTINUE")
                            .tracking(2)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.black)
                    .padding(18)
                    .background(Color(red: 0.25, green: 0.72, blue: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                }
                .disabled(!isValid)
                .opacity(isValid ? 1 : 0.4)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear { focused = true }
    }

    private func finish() {
        guard isValid else { return }
        settings.playerName = trimmed
        settings.hasOnboarded = true
    }
}
