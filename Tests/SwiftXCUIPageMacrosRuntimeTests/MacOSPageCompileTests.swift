#if canImport(XCTest) && os(macOS)
  import SwiftXCUIPageMacros
  import Testing
  import XCTest

  @Page(scope: .window(id: "main"))
  private struct SettingsPage: PageObject {
    @Element(.checkBox, .id("enableSync"))
    var enableSyncBox: XCUIElement

    @Element(.textField, .id("username"))
    var usernameField: XCUIElement

    @Element(.popUpButton, .id("theme"))
    var themePicker: XCUIElement

    @Element(.button, .id("save"), actions: [.tap, .assertEnabled])
    var saveButton: XCUIElement

    @Scope(.menu(id: "context"))
    var contextMenu: XCUIElement

    @Element(.menuItem, .id("duplicate"), in: "contextMenu")
    var duplicateItem: XCUIElement

    @Scope(.outline(id: "sidebar"))
    var sidebar: XCUIElement

    @Element(.disclosureTriangle, .id("expand"), in: "sidebar")
    var expandToggle: XCUIElement
  }

  @Suite("macOS page compile-check")
  struct MacOSPageCompileTests {
    @Test
    func settingsPageTypeChecks() {
      _ = SettingsPage.self
    }
  }
#endif
