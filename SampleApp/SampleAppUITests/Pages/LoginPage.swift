import SwiftXCUIPageMacros
import XCTest

@Page(scope: .scrollView(id: "loginScroll"))
struct LoginPage<Origin: VerifiablePageObject>: OriginTrackedPage {
  let origin: Origin

  init(app: XCUIApplication, origin: Origin) {
    self.app = app
    self.origin = origin
  }

  init(app: XCUIApplication) {
    self.init(app: app, origin: Origin(app: app))
  }

  @Element(.textField, .id("loginEmail"), verify: true)
  var email: XCUIElement

  @Element(.secureTextField, .id("loginPassword"), verify: true)
  var password: XCUIElement

  @Element(.button, .id("loginSubmit"), verify: true)
  var submitButton: XCUIElement

  @Element(.button, .id("back"), verify: true)
  var backButton: XCUIElement

  @Element(.staticText, .id("flowPath"), verify: true)
  var flowPath: XCUIElement

  @discardableResult
  func backToOrigin(
    timeout: TimeInterval? = 5,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> Origin {
    PageNavigation.returnToOrigin(from: self, timeout: timeout, file: file, line: line) {
      tapBackButton()
    }
  }
}
