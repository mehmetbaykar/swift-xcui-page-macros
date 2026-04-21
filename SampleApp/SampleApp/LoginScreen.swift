import SwiftUI

struct LoginScreen: View {
  @Binding var path: [Screen]
  @Binding var email: String
  @Binding var password: String

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        FlowPathLabel(pathLabel: "Splash / Login")

        Text("Login")
          .font(.title.bold())

        TextField("Login Email", text: $email)
          .textContentType(.emailAddress)
          .textInputAutocapitalization(.never)
          .padding()
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .accessibilityIdentifier("loginEmail")

        SecureField("Login Password", text: $password)
          .padding()
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .accessibilityIdentifier("loginPassword")

        Button("Submit Login") {}
          .buttonStyle(.borderedProminent)
          .accessibilityIdentifier("loginSubmit")

        Button("Back") {
          guard !path.isEmpty else { return }
          path.removeLast()
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("back")
      }
      .padding()
    }
    .accessibilityIdentifier("loginScroll")
    .navigationTitle("Login")
    .navigationBarTitleDisplayMode(.inline)
  }
}
