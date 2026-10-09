import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            Text("Welcome to pAInting")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Describe what you imagine and let AI paint it for you.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button(action: onFinish) {
                Text("Get started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("onboarding.start")
        }
        .padding(24)
    }
}

#Preview {
    OnboardingView {}
}
