import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    @State private var apiKeyInput = ""
    @State private var keySaved = false
    @State private var showRemoveConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                apiKeySection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Sections

    private var apiKeySection: some View {
        Section {
            if appState.apiKey.isEmpty {
                SecureField("sk-ant-api03-...", text: $apiKeyInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button(keySaved ? "Saved!" : "Save Key") {
                    let trimmed = apiKeyInput.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    appState.saveAPIKey(trimmed)
                    keySaved = true
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        keySaved = false
                    }
                }
                .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .foregroundStyle(keySaved ? .green : .blue)
            } else {
                HStack {
                    Label("Key saved", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Text("\(appState.apiKey.prefix(16))...")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                Button("Remove Key", role: .destructive) {
                    showRemoveConfirm = true
                }
                .confirmationDialog("Remove API Key?", isPresented: $showRemoveConfirm, titleVisibility: .visible) {
                    Button("Remove", role: .destructive) {
                        appState.removeAPIKey()
                        apiKeyInput = ""
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        } header: {
            Text("Anthropic API Key")
        }
    }

    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your API key is stored locally on this device only. It is never sent anywhere except directly to Anthropic's API.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Each post costs roughly $0.001–$0.003 depending on length.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Link("Get a key at console.anthropic.com →",
                     destination: URL(string: "https://console.anthropic.com")!)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        } header: {
            Text("About")
        }
    }
}
