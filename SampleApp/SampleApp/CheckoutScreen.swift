import SwiftUI

struct CheckoutScreen: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("Grand Total: $42")
          .accessibilityIdentifier("total")

        List {
          ForEach(["Apple", "Banana", "Cherry"], id: \.self) { name in
            VStack(alignment: .leading) {
              Text(name)
              Text("$14")
                .accessibilityIdentifier("total")
            }
          }
        }
        .accessibilityIdentifier("checkoutResults")
        .frame(minHeight: 240)
      }
      .padding()
    }
    .accessibilityIdentifier("checkoutScroll")
    .navigationTitle("Checkout")
    .navigationBarTitleDisplayMode(.inline)
  }
}
