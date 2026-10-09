import SwiftUI
import SwiftData

@main
struct pAIntingApp: App {
    @AppStorage(AppSettings.Keys.appearance) private var appearanceRaw = AppAppearance.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(AppAppearance(rawValue: appearanceRaw)?.colorScheme)
        }
        .modelContainer(for: Artwork.self)
    }
}
