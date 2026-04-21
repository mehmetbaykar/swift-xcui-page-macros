import SwiftUI

struct FlowPathLabel: View {
  let pathLabel: String

  var body: some View {
    Text(pathLabel)
      .font(.caption.monospaced())
      .foregroundStyle(.secondary)
      .accessibilityIdentifier("flowPath")
  }
}
