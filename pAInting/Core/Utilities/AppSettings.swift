import SwiftUI

/// Claves de `UserDefaults` / `@AppStorage` usadas en toda la app.
enum AppSettings {
    enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let appearance = "appearance"
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
