import SwiftUI

enum Screen: Hashable {
  case login
  case signUp
  case checkout
}

struct ContentView: View {
  @State private var path: [Screen] = []
  @State private var loginEmail = ""
  @State private var loginPassword = ""
  @State private var signUpName = ""
  @State private var signUpEmail = ""
  @State private var signUpPassword = ""
  @State private var signUpAcceptTerms = false

  var body: some View {
    NavigationStack(path: $path) {
      SplashScreen(path: $path)
        .navigationTitle("Splash")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Screen.self) { screen in
          switch screen {
          case .login:
            LoginScreen(
              path: $path,
              email: $loginEmail,
              password: $loginPassword
            )
          case .signUp:
            SignUpScreen(
              path: $path,
              name: $signUpName,
              email: $signUpEmail,
              password: $signUpPassword,
              acceptTerms: $signUpAcceptTerms
            )
          case .checkout:
            CheckoutScreen()
          }
        }
    }
  }
}
