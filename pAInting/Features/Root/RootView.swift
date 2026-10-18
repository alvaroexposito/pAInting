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
            createView
                .tabItem { Label("Create", systemImage: "paintbrush.pointed") }
            GalleryView()
                .tabItem { Label("Gallery", systemImage: "photo.on.rectangle") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }

    /// Create tab with the real services, or deterministic ones when a UI test
    /// asks for them through the launch arguments.
    private var createView: CreateView {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(AppSettings.LaunchArguments.failingImageGeneration) {
            return CreateView(
                fallbackService: FailingImageGenerationService(),
                promptAssistant: TemplatePromptAssistant(),
                usesImagePlayground: false
            )
        }
        if arguments.contains(AppSettings.LaunchArguments.mockServices) {
            return CreateView(
                fallbackService: MockImageGenerationService(delay: .milliseconds(200)),
                promptAssistant: TemplatePromptAssistant(),
                usesImagePlayground: false
            )
        }
        return CreateView()
    }
}

#Preview {
    RootView()
        .modelContainer(for: Artwork.self, inMemory: true)
}
