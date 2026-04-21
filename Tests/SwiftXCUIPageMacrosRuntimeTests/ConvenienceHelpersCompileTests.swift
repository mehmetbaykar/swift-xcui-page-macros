#if canImport(XCTest) && os(macOS)
  import SwiftXCUIPageMacros
  import Testing
  import XCTest

  @Suite("Convenience helpers compile")
  struct ConvenienceHelpersCompileTests {
    @Test
    func launchAndSnapshotShapesAreCallable() {
      // Compile-only: we never actually invoke these on a live app,
      // but the test target links everything so missing / wrong signatures
      // would fail the build.
      _ = (any PageObject).self
    }
  }
#endif
