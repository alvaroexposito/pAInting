import SwiftUI

/// Claves de `UserDefaults` / `@AppStorage` usadas en toda la app.
enum AppSettings {
    enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let appearance = "appearance"
    }

    /// Launch arguments used by the UI tests to start the app in a known state.
    enum LaunchArguments {
        /// Clears the onboarding flag so the onboarding is shown, while still
        /// letting the app persist it when the child finishes (unlike passing
        /// `-hasCompletedOnboarding NO`, which overrides every later write).
        static let resetOnboarding = "--reset-onboarding"
        /// Uses the template prompt and the mock image generator, skipping
        /// Foundation Models and Image Playground.
        static let mockServices = "--mock-services"
        /// Like `mockServices`, but image generation always fails.
        static let failingImageGeneration = "--failing-image-generation"
    }

    /// Applies the launch arguments that change persisted state. Call once at launch.
    static func applyLaunchArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) {
        if arguments.contains(LaunchArguments.resetOnboarding) {
            UserDefaults.standard.removeObject(forKey: Keys.hasCompletedOnboarding)
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}
