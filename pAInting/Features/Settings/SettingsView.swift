import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.Keys.appearance) private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage(AppSettings.Keys.hasCompletedOnboarding) private var hasCompletedOnboarding = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearanceRaw) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.title).tag(option.rawValue)
                        }
                    }
                }
                Section {
                    Button("Show onboarding again") { hasCompletedOnboarding = false }
                }
                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
}
