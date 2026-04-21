import XCTest

@MainActor
final class LoginFlowTests: XCTestCase {
  private var app: XCUIApplication!
  private var splash: SplashPage!

  override func setUp() async throws {
    try await super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments.append("UI-Testing")
    app.launch()
    splash = SplashPage(app: app)
  }

  override func tearDown() async throws {
    app.terminate()
    try await super.tearDown()
  }

  func testSplashOpensLogin() throws {
    try splash
      .assertFlowPathLabel("Splash")
      .openLogin()
      .assertFlowPathLabel("Splash / Login")
      .assertEmailPlaceholder("Login Email")
      .assertPasswordPlaceholder("Login Password")
  }

  func testSplashOpensSignUp() throws {
    try splash
      .assertFlowPathLabel("Splash")
      .openSignUp()
      .assertFlowPathLabel("Splash / Sign Up")
      .assertNamePlaceholder("Sign Up Name")
      .assertEmailPlaceholder("Sign Up Email")
      .assertPasswordPlaceholder("Sign Up Password")
  }

  func testLoginCanReturnToSplashAndOpenSignUp() throws {
    try splash
      .openLogin()
      .backToOrigin()
      .assertFlowPathLabel("Splash")
      .openSignUp()
      .assertFlowPathLabel("Splash / Sign Up")
      .assertSubmitButtonExists()
  }

  func testSignUpCanReturnToSplashAndOpenLogin() throws {
    try splash
      .openSignUp()
      .backToOrigin()
      .assertFlowPathLabel("Splash")
      .openLogin()
      .assertFlowPathLabel("Splash / Login")
      .assertSubmitButtonExists()
  }

  func testSignUpScrollsToAcceptTermsToggle() throws {
    let signUp = try splash.openSignUp()
    signUp.scrollToVisibleAcceptTermsToggle(in: signUp._scope)
    signUp.tapAcceptTermsToggle()
    signUp.assertAcceptTermsToggleValue("1")
  }

  func testLoginUsesTransitionForLinearFlow() throws {
    let login = splash.transition { app -> LoginPage<SplashPage> in
      splash.tapOpenLoginButton()
      return LoginPage(app: app, origin: splash)
    }
    login
      .assertFlowPathLabel("Splash / Login")
      .assertSubmitButtonExists()
  }

  func testSplashOpenLoginSupportsPredicateLocator() throws {
    splash.assertWelcomeTextExists()
  }

  func testCheckoutNestedScopes() throws {
    let app = XCUIApplication()
    let splash = SplashPage(app: app).launch(arguments: ["-uiTestMode"])

    let checkout = try splash.openCheckout()
    checkout.verifyDefaultScreen(timeout: 5)
    checkout.grandTotal.assertExists(timeout: 5)
    checkout.firstLineTotal.assertExists(timeout: 5)
    add(splash.snapshot(named: "final-splash"))
  }
}
