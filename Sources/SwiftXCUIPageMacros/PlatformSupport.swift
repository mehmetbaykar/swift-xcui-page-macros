// Platform-conditional helpers for XCUITest. The tvOS focus seam is the
// only platform-specific helper today — iOS, macOS, and visionOS do not
// need one.
#if canImport(XCTest)
  import XCTest

  #if os(tvOS)
    @MainActor
    public enum TVFocus {
      public static func focusIsOn(_ element: XCUIElement) -> Bool {
        element.hasFocus
      }
    }
  #endif
#endif
