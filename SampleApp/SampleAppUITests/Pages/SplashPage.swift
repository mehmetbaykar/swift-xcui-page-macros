import SwiftXCUIPageMacros
import XCTest

@Page(scope: .scrollView(id: "splashScroll"))
struct SplashPage: VerifiablePageObject {
  @Element(.staticText, .id("flowPath"), verify: true)
  var flowPath: XCUIElement

  @Element(.staticText, .predicate("label CONTAINS 'Welcome'"))
  var welcomeText: XCUIElement

  @Element(.button, .id("openLogin"), verify: true)
  var openLoginButton: XCUIElement

  @Element(.button, .id("openSignUp"), verify: true)
  var openSignUpButton: XCUIElement

  @Element(.button, .id("openCheckout"), verify: true)
  var openCheckoutButton: XCUIElement

  @discardableResult
  func openLogin(
    timeout: TimeInterval? = 5,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws(OpenFailure) -> LoginPage<Self> {
    try PageNavigation.open(
      from: self, timeout: timeout, file: file, line: line,
      perform: {
        tapOpenLoginButton()
      }
    ) { app, origin in
      LoginPage(app: app, origin: origin)
    }
  }

  @discardableResult
  func openSignUp(
    timeout: TimeInterval? = 5,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws(OpenFailure) -> SignUpPage<Self> {
    try PageNavigation.open(
      from: self, timeout: timeout, file: file, line: line,
      perform: {
        tapOpenSignUpButton()
      }
    ) { app, origin in
      SignUpPage(app: app, origin: origin)
    }
  }

  @discardableResult
  func openCheckout(
    timeout: TimeInterval? = 5,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws(OpenFailure) -> CheckoutPage<Self> {
    try PageNavigation.open(
      from: self, timeout: timeout, file: file, line: line,
      perform: {
        tapOpenCheckoutButton()
      }
    ) { app, origin in
      CheckoutPage(app: app, origin: origin)
    }
  }
}
