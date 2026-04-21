import SwiftUI

struct SplashScreen: View {
  @Binding var path: [Screen]

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        FlowPathLabel(pathLabel: "Splash")

        Text("Welcome to SampleApp")
          .font(.title.bold())

        Text("Choose a Flow")
          .font(.title3)

        Button("Open Login") {
          path.append(.login)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("openLogin")

        Button("Open Sign Up") {
          path.append(.signUp)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("openSignUp")

        Button("Open Checkout Demo") {
          path.append(.checkout)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("openCheckout")
      }
      .padding()
    }
    .accessibilityIdentifier("splashScroll")
  }
}
