#if os(macOS)
  import Testing
  @testable import SwiftXCUIPageMacros
  @testable import SwiftXCUIPageMacrosMacros

  @Suite
  struct ElementActionSyncTests {
    /// Asserts the macro's `supportedActions` allowlist names every `ElementAction`
    /// case. Drift here means the macro silently refuses to emit helpers for a
    /// newly-added action. When this test fails, add the new case's `String(describing:)`
    /// to `supportedActions` in `QueryHelpers.swift`.
    @Test
    func supportedActionsMatchElementActionCases() {
      let enumCaseNames = Set(ElementAction.allCases.map { String(describing: $0) })
      #expect(enumCaseNames == supportedActions)
    }
  }
#endif
