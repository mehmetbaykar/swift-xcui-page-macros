import SwiftUI

struct SignUpScreen: View {
  @Binding var path: [Screen]
  @Binding var name: String
  @Binding var email: String
  @Binding var password: String
  @Binding var acceptTerms: Bool

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        FlowPathLabel(pathLabel: "Splash / Sign Up")

        Text("Sign Up")
          .font(.title.bold())

        TextField("Sign Up Name", text: $name)
          .textContentType(.name)
          .padding()
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .accessibilityIdentifier("signUpName")

        TextField("Sign Up Email", text: $email)
          .textContentType(.emailAddress)
          .textInputAutocapitalization(.never)
          .padding()
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .accessibilityIdentifier("signUpEmail")

        SecureField("Sign Up Password", text: $password)
          .padding()
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .accessibilityIdentifier("signUpPassword")

        Text(Self.termsText)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)

        Toggle("Accept terms", isOn: $acceptTerms)
          .accessibilityIdentifier("acceptTerms")

        Button("Create Account") {}
          .buttonStyle(.borderedProminent)
          .disabled(!acceptTerms)
          .accessibilityIdentifier("signUpSubmit")

        Button("Back") {
          guard !path.isEmpty else { return }
          path.removeLast()
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("back")
      }
      .padding()
    }
    .accessibilityIdentifier("signUpScroll")
    .navigationTitle("Sign Up")
    .navigationBarTitleDisplayMode(.inline)
  }

  // Long enough to push the `acceptTerms` toggle below the fold on the
  // default simulator, exercising the macro-generated scroll-to-visible
  // helper end-to-end in the sample UI tests.
  private static let termsText: String = String(
    repeating: """
      By creating an account you agree to our placeholder terms of service. \
      These terms are intentionally verbose so that the accept-terms toggle \
      sits below the fold and must be scrolled into view. This paragraph \
      exists solely to exercise the macro-generated scroll-to-visible helper \
      end to end in the sample UI tests.


      """,
    count: 6
  )
}
