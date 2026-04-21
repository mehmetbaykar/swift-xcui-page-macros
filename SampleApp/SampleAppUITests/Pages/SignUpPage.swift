import SwiftXCUIPageMacros
import XCTest

@Page(scope: .scrollView(id: "signUpScroll"))
struct SignUpPage<Origin: VerifiablePageObject>: OriginTrackedPage {
  let origin: Origin

  init(app: XCUIApplication, origin: Origin) {
    self.app = app
    self.origin = origin
  }

  init(app: XCUIApplication) {
    self.init(app: app, origin: Origin(app: app))
  }

  @Element(.textField, .id("signUpName"), verify: true)
  var name: XCUIElement

  @Element(.textField, .id("signUpEmail"), verify: true)
  var email: XCUIElement

  @Element(.secureTextField, .id("signUpPassword"), verify: true)
  var password: XCUIElement

  @Element(.button, .id("signUpSubmit"), verify: true)
  var submitButton: XCUIElement

  @Element(
    .toggle,
    .id("acceptTerms"),
    actions: [.tap, .scrollToVisible, .assertValue]
  )
  var acceptTermsToggle: XCUIElement

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
