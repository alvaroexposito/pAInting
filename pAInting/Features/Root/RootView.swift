import SwiftUI

struct RootView: View {
    @AppStorage(AppSettings.Keys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView { hasCompletedOnboarding = true }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            CreateView()
                .tabItem { Label("Create", systemImage: "paintbrush.pointed") }
            GalleryView()
                .tabItem { Label("Gallery", systemImage: "photo.on.rectangle") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: Artwork.self, inMemory: true)
}
