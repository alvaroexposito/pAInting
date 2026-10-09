import Testing
@testable import pAInting

struct ImageGenerationServiceTests {
    @Test func mockServiceIsDeterministicForSamePrompt() async throws {
        let service = MockImageGenerationService(delay: .milliseconds(1))
        let first = try await service.generate(prompt: "a cat")
        let second = try await service.generate(prompt: "a cat")
        #expect(first.prompt == "a cat")
        #expect((0...1).contains(first.hue))
        // hashValue varía entre ejecuciones, pero no dentro de la misma.
        #expect(first == second)
    }

    @Test func appearanceMapsToColorScheme() {
        #expect(AppAppearance.system.colorScheme == nil)
        #expect(AppAppearance.light.colorScheme == .light)
        #expect(AppAppearance.dark.colorScheme == .dark)
    }
}
