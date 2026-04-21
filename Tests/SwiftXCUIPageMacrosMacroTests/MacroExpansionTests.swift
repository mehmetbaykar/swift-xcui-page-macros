#if os(macOS)
  import MacroTesting
  import Testing
  @testable import SwiftXCUIPageMacrosMacros

  @Suite(
    .macros(
      [
        "Page": PageObjectMacro.self,
        "Element": ElementMacro.self,
        "Scope": ScopeMacro.self,
      ],
      record: .never
    )
  )
  struct MacroExpansionTests {
    @Test
    func pageAddsConvenienceInitializersWhenNoCustomInitializerExists() {
      assertMacro {
        """
        @Page
        struct SplashPage {
        }
        """
      } expansion: {
        """
        struct SplashPage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageAddsBundleInitializerAndRetainsInitWithApp() {
      assertMacro {
        """
        @Page(bundle: "com.apple.mobilesafari")
        struct SafariPage {
        }
        """
      } expansion: {
        """
        struct SafariPage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageRejectsClassDeclarations() {
      assertMacro {
        """
        @Page
        final class LoginPage {
        }
        """
      } diagnostics: {
        """
        @Page
        ┬────
        ╰─ 🛑 @Page can only be applied to a struct
        final class LoginPage {
        }
        """
      }
    }

    @Test
    func pageSkipsConvenienceInitializersWhenCustomInitializerExists() {
      assertMacro {
        """
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
        }
        """
      } expansion: {
        """
        struct LoginPage<Origin: VerifiablePageObject>: OriginTrackedPage {
            let origin: Origin
            @MainActor

            init(app: XCUIApplication, origin: Origin) {
                self.app = app
                self.origin = origin
            }
            @MainActor

            init(app: XCUIApplication) {
                self.init(app: app, origin: Origin(app: app))
            }
            var email: XCUIElement {
                @MainActor
                get {
                    _scope.textFields.matching(identifier: "loginEmail").firstMatch
                }
            }

            /// Taps the `email` element.
            @discardableResult
            @MainActor
            func tapEmail() -> Self {
                email.tap()
                return self
            }

            /// Types `text` into the `email` element.
            @discardableResult
            @MainActor
            func typeTextIntoEmail(_ text: String) -> Self {
                email.typeText(text)
                return self
            }

            /// Clears all text from the `email` element.
            @discardableResult
            @MainActor
            func clearEmail() -> Self {
                email.clearText()
                return self
            }

            /// Asserts that `email` exists. Pass `timeout` to wait up to that many seconds before asserting.
            @discardableResult
            @MainActor
            func assertEmailExists(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                email.assertExists(timeout: timeout, file: file, line: line)
                return self
            }

            /// Asserts that `email`'s value equals `expected`. Pass `timeout` to wait for the value first.
            @discardableResult
            @MainActor
            func assertEmailValue(_ expected: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                email.assertValue(expected, timeout: timeout, file: file, line: line)
                return self
            }

            /// Asserts that `email`'s placeholder equals `expected`. Pass `timeout` to wait for the placeholder first.
            @discardableResult
            @MainActor
            func assertEmailPlaceholder(_ expected: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                email.assertPlaceholder(expected, timeout: timeout, file: file, line: line)
                return self
            }

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.scrollViews.matching(identifier: "loginScroll").firstMatch
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }

            /// Asserts that all core elements of this page exist.
            /// Pass `timeout` to wait up to that many seconds for each element before asserting.
            @discardableResult
            @MainActor
            func verifyDefaultScreen(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                PageAssertions.assertElementsExist([email], timeout: timeout, file: file, line: line)
                return self
            }

            /// Boolean readiness probe used by `PageNavigation.open(..., retries:)`.
            /// Returns `true` only when every `@Element(verify: true)` on this page currently exists.
            @MainActor
            func isReady() -> Bool {
                email.exists
            }
        }
        """
      }
    }

    @Test
    func pageAppliesMainActorToCustomPageMethods() {
      assertMacro {
        """
        @Page
        struct SplashPage {
            func openLogin() -> Self {
                self
            }
        }
        """
      } expansion: {
        """
        struct SplashPage {
            @MainActor
            func openLogin() -> Self {
                self
            }

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageVerifiesMarkedElements() {
      assertMacro {
        """
        @Page
        struct CheckoutPage {
            @Element(.button, .id("pay"), verify: true, actions: [])
            var payButton: XCUIElement

            @Element(.staticText, .id("total"), verify: true, actions: [])
            var totalLabel: XCUIElement

            @Element(.button, .id("cancel"), actions: [])
            var cancelButton: XCUIElement
        }
        """
      } expansion: {
        """
        struct CheckoutPage {
            var payButton: XCUIElement {
                @MainActor
                get {
                    _scope.buttons.matching(identifier: "pay").firstMatch
                }
            }
            var totalLabel: XCUIElement {
                @MainActor
                get {
                    _scope.staticTexts.matching(identifier: "total").firstMatch
                }
            }
            var cancelButton: XCUIElement {
                @MainActor
                get {
                    _scope.buttons.matching(identifier: "cancel").firstMatch
                }
            }

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }

            /// Asserts that all core elements of this page exist.
            /// Pass `timeout` to wait up to that many seconds for each element before asserting.
            @discardableResult
            @MainActor
            func verifyDefaultScreen(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                PageAssertions.assertElementsExist([payButton, totalLabel], timeout: timeout, file: file, line: line)
                return self
            }

            /// Boolean readiness probe used by `PageNavigation.open(..., retries:)`.
            /// Returns `true` only when every `@Element(verify: true)` on this page currently exists.
            @MainActor
            func isReady() -> Bool {
                payButton.exists && totalLabel.exists
            }
        }
        """
      }
    }

    @Test
    func pageSupportsScopedQueries() {
      assertMacro {
        """
        @Page(scope: .scrollView(id: "formContainer"))
        struct RegistrationPage {
        }
        """
      } expansion: {
        """
        struct RegistrationPage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.scrollViews.matching(identifier: "formContainer").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageRejectsInvalidScope() {
      assertMacro {
        """
        @Page(scope: .dialog(id: "sheet"))
        struct RegistrationPage {
        }
        """
      } diagnostics: {
        """
        @Page(scope: .dialog(id: "sheet"))
        ┬─────────────────────────────────
        ╰─ 🛑 `scope:` must be a ContainerType expression (for example, .scrollView(id: "form"))
        struct RegistrationPage {
        }
        """
      }
    }

    @Test
    func elementBuildsHelpersFromActions() {
      assertMacro {
        """
        @Element(.button, .id("submit"), actions: [.tap, .scrollToVisible, .assertExists])
        var submitButton: XCUIElement
        """
      } expansion: {
        """
        var submitButton: XCUIElement {
            @MainActor
            get {
                _scope.buttons.matching(identifier: "submit").firstMatch
            }
        }

        /// Taps the `submitButton` element.
        @discardableResult
        @MainActor
        func tapSubmitButton() -> Self {
            submitButton.tap()
            return self
        }

        /// Scrolls until `submitButton` is hittable inside the nearest scroll container in `app`.
        /// Override `in:` to pin the scroll container (for nested scroll views or @Scope roots).
        @discardableResult
        @MainActor
        func scrollToVisibleSubmitButton(in container: XCUIElement? = nil, axis: PageAssertions.ScrollAxis = .vertical, timeout: TimeInterval = 5, maxSwipes: Int = 10) -> Self {
            if let container {
                PageAssertions.scrollToVisible(submitButton, in: container, axis: axis, timeout: timeout, maxSwipes: maxSwipes)
            } else {
                PageAssertions.scrollToVisible(submitButton, in: app, axis: axis, timeout: timeout, maxSwipes: maxSwipes)
            }
            return self
        }

        /// Asserts that `submitButton` exists. Pass `timeout` to wait up to that many seconds before asserting.
        @discardableResult
        @MainActor
        func assertSubmitButtonExists(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
            submitButton.assertExists(timeout: timeout, file: file, line: line)
            return self
        }
        """
      }
    }

    @Test
    func elementEscapesStringLocators() {
      assertMacro {
        """
        @Element(.staticText, .label("He said \\\"Hello\\\""), actions: [])
        var quoteLabel: XCUIElement
        """
      } expansion: {
        #"""
        var quoteLabel: XCUIElement {
            @MainActor
            get {
                _scope.staticTexts.matching(NSPredicate(format: "label == %@", "He said \\\"Hello\\\"")).firstMatch
            }
        }
        """#
      }
    }

    @Test
    func elementRejectsInvalidLocator() {
      assertMacro {
        """
        @Element(.button, invalidLocator("submit"), actions: [])
        var submitButton: XCUIElement
        """
      } diagnostics: {
        """
        @Element(.button, invalidLocator("submit"), actions: [])
                          ┬───────────────────────
                          ╰─ 🛑 Second argument must be a Locator expression (for example, .id("login"))
                             ✏️ Replace with .id("<#identifier#>")
        var submitButton: XCUIElement
        """
      } fixes: {
        """
        @Element(.button, .id("<#identifier#>"), actions: [])
        var submitButton: XCUIElement
        """
      } expansion: {
        """
        var submitButton: XCUIElement {
            @MainActor
            get {
                _scope.buttons.matching(identifier: "<#identifier#>").firstMatch
            }
        }
        """
      }
    }

    @Test
    func elementRejectsUnknownActions() {
      assertMacro {
        """
        @Element(.button, .id("submit"), actions: [.tap, .shake])
        var submitButton: XCUIElement
        """
      } diagnostics: {
        """
        @Element(.button, .id("submit"), actions: [.tap, .shake])
                                                  ┬─────────────
                                                  ╰─ 🛑 `actions:` must contain valid ElementAction members
                                                     ✏️ Replace with [.tap]
        var submitButton: XCUIElement
        """
      } fixes: {
        """
        @Element(.button, .id("submit"), actions: [.tap])
        var submitButton: XCUIElement
        """
      } expansion: {
        """
        var submitButton: XCUIElement {
            @MainActor
            get {
                _scope.buttons.matching(identifier: "submit").firstMatch
            }
        }

        /// Taps the `submitButton` element.
        @discardableResult
        @MainActor
        func tapSubmitButton() -> Self {
            submitButton.tap()
            return self
        }
        """
      }
    }

    // MARK: - Locator variants

    @Test
    func elementSupportsPredicateLocator() {
      assertMacro {
        """
        @Element(.button, .predicate("enabled == true"), actions: [])
        var okButton: XCUIElement
        """
      } expansion: {
        #"""
        var okButton: XCUIElement {
            @MainActor
            get {
                _scope.buttons.matching(NSPredicate(format: "enabled == true")).firstMatch
            }
        }
        """#
      }
    }

    @Test
    func elementSupportsBareIndexLocator() {
      assertMacro {
        """
        @Element(.cell, .index(2), actions: [])
        var thirdRow: XCUIElement
        """
      } expansion: {
        """
        var thirdRow: XCUIElement {
            @MainActor
            get {
                _scope.cells.element(boundBy: 2)
            }
        }
        """
      }
    }

    @Test
    func elementSupportsLabelContainsLocator() {
      assertMacro {
        """
        @Element(.staticText, .labelContains("Welcome"), actions: [])
        var greeting: XCUIElement
        """
      } expansion: {
        #"""
        var greeting: XCUIElement {
            @MainActor
            get {
                _scope.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Welcome")).firstMatch
            }
        }
        """#
      }
    }

    @Test
    func elementSupportsIdWithIndexLocator() {
      assertMacro {
        """
        @Element(.button, .id("ok", index: 1), actions: [])
        var secondOk: XCUIElement
        """
      } expansion: {
        """
        var secondOk: XCUIElement {
            @MainActor
            get {
                _scope.buttons.matching(identifier: "ok").element(boundBy: 1)
            }
        }
        """
      }
    }

    // MARK: - Action defaults

    @Test
    func elementDefaultsActionsWhenNil() {
      assertMacro {
        """
        @Element(.button, .id("submit"))
        var submit: XCUIElement
        """
      } expansion: {
        """
        var submit: XCUIElement {
            @MainActor
            get {
                _scope.buttons.matching(identifier: "submit").firstMatch
            }
        }

        /// Taps the `submit` element.
        @discardableResult
        @MainActor
        func tapSubmit() -> Self {
            submit.tap()
            return self
        }

        /// Asserts that `submit` exists. Pass `timeout` to wait up to that many seconds before asserting.
        @discardableResult
        @MainActor
        func assertSubmitExists(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
            submit.assertExists(timeout: timeout, file: file, line: line)
            return self
        }

        /// Asserts that `submit` is enabled. Pass `timeout` to poll until the condition is met.
        @discardableResult
        @MainActor
        func assertSubmitEnabled(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
            submit.assertEnabled(timeout: timeout, file: file, line: line)
            return self
        }

        /// Asserts that `submit` is disabled. Pass `timeout` to poll until the condition is met.
        @discardableResult
        @MainActor
        func assertSubmitDisabled(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
            submit.assertDisabled(timeout: timeout, file: file, line: line)
            return self
        }
        """
      }
    }

    @Test
    func elementEmitsAccessorOnlyWhenActionsEmpty() {
      assertMacro {
        """
        @Element(.button, .id("submit"), actions: [])
        var submit: XCUIElement
        """
      } expansion: {
        """
        var submit: XCUIElement {
            @MainActor
            get {
                _scope.buttons.matching(identifier: "submit").firstMatch
            }
        }
        """
      }
    }

    @Test
    func elementSupportsOmittedLocator() {
      assertMacro {
        """
        @Element(.button, actions: [])
        var anyButton: XCUIElement
        """
      } expansion: {
        """
        var anyButton: XCUIElement {
            @MainActor
            get {
                _scope.buttons.firstMatch
            }
        }
        """
      }
    }

    // MARK: - Scope variants

    @Test
    func pageSupportsScopeWithLabel() {
      assertMacro {
        """
        @Page(scope: .scrollView(label: "form"))
        struct LabelScopePage {
        }
        """
      } expansion: {
        #"""
        struct LabelScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.scrollViews.matching(NSPredicate(format: "label == %@", "form")).firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """#
      }
    }

    @Test
    func pageSupportsScopeWithIndex() {
      assertMacro {
        """
        @Page(scope: .scrollView(index: 0))
        struct IndexScopePage {
        }
        """
      } expansion: {
        """
        struct IndexScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.scrollViews.element(boundBy: 0)
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageSupportsScopeWithCell() {
      assertMacro {
        """
        @Page(scope: .cell(id: "row"))
        struct CellScopePage {
        }
        """
      } expansion: {
        """
        struct CellScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.cells.matching(identifier: "row").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageSupportsScopeWithAlert() {
      assertMacro {
        """
        @Page(scope: .alert(id: "confirm"))
        struct AlertScopePage {
        }
        """
      } expansion: {
        """
        struct AlertScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.alerts.matching(identifier: "confirm").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageSupportsScopeWithTable() {
      assertMacro {
        """
        @Page(scope: .table(id: "results"))
        struct TableScopePage {
        }
        """
      } expansion: {
        """
        struct TableScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.tables.matching(identifier: "results").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageSupportsScopeWithCollectionView() {
      assertMacro {
        """
        @Page(scope: .collectionView(id: "grid"))
        struct CollectionScopePage {
        }
        """
      } expansion: {
        """
        struct CollectionScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.collectionViews.matching(identifier: "grid").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageSupportsScopeWithChromeBars() {
      assertMacro {
        """
        @Page(scope: .navigationBar(id: "nav"))
        struct NavScopePage {
        }
        """
      } expansion: {
        """
        struct NavScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.navigationBars.matching(identifier: "nav").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }

      assertMacro {
        """
        @Page(scope: .tabBar(id: "tab"))
        struct TabScopePage {
        }
        """
      } expansion: {
        """
        struct TabScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.tabBars.matching(identifier: "tab").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }

      assertMacro {
        """
        @Page(scope: .toolbar(id: "bar"))
        struct ToolbarScopePage {
        }
        """
      } expansion: {
        """
        struct ToolbarScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.toolbars.matching(identifier: "bar").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageSupportsScopeWithWebViewAndPickers() {
      assertMacro {
        """
        @Page(scope: .webView(id: "web"))
        struct WebScopePage {
        }
        """
      } expansion: {
        """
        struct WebScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.webViews.matching(identifier: "web").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }

      assertMacro {
        """
        @Page(scope: .picker(id: "p"))
        struct PickerScopePage {
        }
        """
      } expansion: {
        """
        struct PickerScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.pickers.matching(identifier: "p").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }

      assertMacro {
        """
        @Page(scope: .datePicker(id: "d"))
        struct DatePickerScopePage {
        }
        """
      } expansion: {
        """
        struct DatePickerScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.datePickers.matching(identifier: "d").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageSupportsScopeWithView() {
      assertMacro {
        """
        @Page(scope: .view(id: "v"))
        struct ViewScopePage {
        }
        """
      } expansion: {
        """
        struct ViewScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.otherElements.matching(identifier: "v").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageCombinesBundleAndScope() {
      assertMacro {
        """
        @Page(bundle: "com.example", scope: .scrollView(id: "s"))
        struct BundleScopePage {
        }
        """
      } expansion: {
        """
        struct BundleScopePage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.scrollViews.matching(identifier: "s").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication(bundleIdentifier: "com.example")
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    // MARK: - New diagnostics

    @Test
    func pageDiagnosesConflictingScopeLocators() {
      assertMacro {
        """
        @Page(scope: .scrollView(id: "x", label: "y"))
        struct ConflictPage {
        }
        """
      } diagnostics: {
        """
        @Page(scope: .scrollView(id: "x", label: "y"))
                     ┬───────────────────────────────
                     ╰─ 🛑 `scope:` accepts at most one of `id:`, `label:`, `index:` — pick one
                        ✏️ Keep only `id:` and drop the others
        struct ConflictPage {
        }
        """
      } fixes: {
        """
        @Page(scope: .scrollView(id: "x"))
        struct ConflictPage {
        }
        """
      } expansion: {
        """
        struct ConflictPage {

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.scrollViews.matching(identifier: "x").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageDiagnosesBundleIgnoredWithCustomInit() {
      assertMacro {
        """
        @Page(bundle: "com.example.app")
        struct CustomInitPage {
            init(app: XCUIApplication) {
                self.app = app
            }
        }
        """
      } diagnostics: {
        """
        @Page(bundle: "com.example.app")
              ┬────────────────────────
              ╰─ ⚠️ `bundle:` is ignored because this struct declares its own initializer
        struct CustomInitPage {
            init(app: XCUIApplication) {
                self.app = app
            }
        }
        """
      } expansion: {
        """
        struct CustomInitPage {
            @MainActor
            init(app: XCUIApplication) {
                self.app = app
            }

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func pageSkipsDuplicateMainActor() {
      assertMacro {
        """
        @Page
        struct AlreadyAnnotatedPage {
            @MainActor
            func helper() -> Self {
                self
            }
        }
        """
      } expansion: {
        """
        struct AlreadyAnnotatedPage {
            @MainActor
            func helper() -> Self {
                self
            }

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    // MARK: - @Scope interactions

    @Test
    func elementHonorsInParentScope() {
      assertMacro {
        """
        @Element(.button, .id("pay"), actions: [.tap], in: "resultsRegion")
        var payButton: XCUIElement
        """
      } expansion: {
        """
        var payButton: XCUIElement {
            @MainActor
            get {
                resultsRegion.buttons.matching(identifier: "pay").firstMatch
            }
        }

        /// Taps the `payButton` element.
        @discardableResult
        @MainActor
        func tapPayButton() -> Self {
            payButton.tap()
            return self
        }
        """
      }
    }

    @Test
    func scopeCombinedWithPageScope() {
      assertMacro {
        """
        @Page(scope: .scrollView(id: "checkoutScroll"))
        struct CheckoutPage {
            @Scope(.table(id: "results"))
            var resultsRegion: XCUIElement
        }
        """
      } expansion: {
        """
        struct CheckoutPage {
            var resultsRegion: XCUIElement {
                @MainActor
                get {
                    _scope.tables.matching(identifier: "results").firstMatch
                }
            }

            let app: XCUIApplication

            @MainActor
            var _scope: XCUIElement {
                app.scrollViews.matching(identifier: "checkoutScroll").firstMatch
            }

            init(app: XCUIApplication) {
                self.app = app
            }

            init() {
                self.app = XCUIApplication()
            }

            @MainActor
            func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    // MARK: - Expanded element types

    @Test
    func elementSupportsNewElementTypes() {
      assertMacro {
        """
        @Element(.textView, .id("notes"), actions: [.tap])
        var notesField: XCUIElement
        """
      } expansion: {
        """
        var notesField: XCUIElement {
            @MainActor
            get {
                _scope.textViews.matching(identifier: "notes").firstMatch
            }
        }

        /// Taps the `notesField` element.
        @discardableResult
        @MainActor
        func tapNotesField() -> Self {
            notesField.tap()
            return self
        }
        """
      }

      assertMacro {
        """
        @Element(.checkBox, .id("agree"), actions: [])
        var agreeBox: XCUIElement
        """
      } expansion: {
        """
        var agreeBox: XCUIElement {
            @MainActor
            get {
                _scope.checkBoxes.matching(identifier: "agree").firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Element(.window, .id("main"), actions: [])
        var mainWindow: XCUIElement
        """
      } expansion: {
        """
        var mainWindow: XCUIElement {
            @MainActor
            get {
                _scope.windows.matching(identifier: "main").firstMatch
            }
        }
        """
      }
    }

    @Test
    func elementSupportsAnyType() {
      assertMacro {
        """
        @Element(.any, .id("x"), actions: [])
        var anything: XCUIElement
        """
      } expansion: {
        """
        var anything: XCUIElement {
            @MainActor
            get {
                _scope.descendants(matching: .any).matching(identifier: "x").firstMatch
            }
        }
        """
      }
    }

    // MARK: - Parameterized gesture actions

    @Test
    func elementSupportsAdditionalElementTypes() {
      assertMacro {
        """
        @Element(.searchField, .id("s"), actions: [])
        var s: XCUIElement
        """
      } expansion: {
        """
        var s: XCUIElement {
            @MainActor
            get {
                _scope.searchFields.matching(identifier: "s").firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Element(.pickerWheel, .id("wheel"), actions: [])
        var w: XCUIElement
        """
      } expansion: {
        """
        var w: XCUIElement {
            @MainActor
            get {
                _scope.pickerWheels.matching(identifier: "wheel").firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Element(.segmentedControl, .id("seg"), actions: [])
        var seg: XCUIElement
        """
      } expansion: {
        """
        var seg: XCUIElement {
            @MainActor
            get {
                _scope.segmentedControls.matching(identifier: "seg").firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Element(.radioButton, .id("r"), actions: [])
        var r: XCUIElement
        """
      } expansion: {
        """
        var r: XCUIElement {
            @MainActor
            get {
                _scope.radioButtons.matching(identifier: "r").firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Element(.comboBox, .id("c"), actions: [])
        var c: XCUIElement
        """
      } expansion: {
        """
        var c: XCUIElement {
            @MainActor
            get {
                _scope.comboBoxes.matching(identifier: "c").firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Element(.menuItem, .id("m"), actions: [])
        var m: XCUIElement
        """
      } expansion: {
        """
        var m: XCUIElement {
            @MainActor
            get {
                _scope.menuItems.matching(identifier: "m").firstMatch
            }
        }
        """
      }
    }

    @Test
    func elementEmitsCodegenForEveryBareAction() {
      assertMacro {
        """
        @Element(.button, .id("b"), actions: [.doubleTap, .longPress, .swipeLeft, .swipeRight])
        var b: XCUIElement
        """
      } expansion: {
        """
        var b: XCUIElement {
            @MainActor
            get {
                _scope.buttons.matching(identifier: "b").firstMatch
            }
        }

        /// Double-taps the `b` element.
        @discardableResult
        @MainActor
        func doubleTapB() -> Self {
            b.doubleTap()
            return self
        }

        /// Long-presses the `b` element (1 second).
        @discardableResult
        @MainActor
        func longPressB() -> Self {
            b.press(forDuration: 1)
            return self
        }

        /// Swipes left on the `b` element.
        @discardableResult
        @MainActor
        func swipeLeftB() -> Self {
            b.swipeLeft()
            return self
        }

        /// Swipes right on the `b` element.
        @discardableResult
        @MainActor
        func swipeRightB() -> Self {
            b.swipeRight()
            return self
        }
        """
      }
    }

    @Test
    func elementEmitsCodegenForEveryStateAssertion() {
      assertMacro {
        """
        @Element(
          .toggle, .id("t"),
          actions: [.assertNotExists, .assertDisappear, .assertSelected, .assertNotSelected]
        )
        var t: XCUIElement
        """
      } expansion: {
        """
        var t: XCUIElement {
          @MainActor
          get {
              _scope.switches.matching(identifier: "t").firstMatch
          }
        }

        /// Asserts that `t` does not exist. Pass `timeout` to wait for it to disappear first.
        @discardableResult
        @MainActor
        func assertTNotExists(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
            t.assertNotExists(timeout: timeout, file: file, line: line)
            return self
        }

        /// Waits for `t` to disappear, then asserts it is gone.
        @discardableResult
        @MainActor
        func assertTDisappear(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
            t.assertDisappear(timeout: timeout, file: file, line: line)
            return self
        }

        /// Asserts that `t` is selected. Pass `timeout` to poll until the condition is met.
        @discardableResult
        @MainActor
        func assertTSelected(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
            t.assertSelected(timeout: timeout, file: file, line: line)
            return self
        }

        /// Asserts that `t` is not selected. Pass `timeout` to poll until the condition is met.
        @discardableResult
        @MainActor
        func assertTNotSelected(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
            t.assertNotSelected(timeout: timeout, file: file, line: line)
            return self
        }
        """
      }
    }

    @Test
    func elementSupportsParameterizedGestureActions() {
      assertMacro {
        """
        @Element(.button, .id("submit"), actions: [.press])
        var submitButton: XCUIElement
        """
      } expansion: {
        """
        var submitButton: XCUIElement {
            @MainActor
            get {
                _scope.buttons.matching(identifier: "submit").firstMatch
            }
        }

        /// Presses the `submitButton` element for the given duration.
        @discardableResult
        @MainActor
        func pressSubmitButton(forDuration duration: TimeInterval) -> Self {
            submitButton.press(forDuration: duration)
            return self
        }
        """
      }

      assertMacro {
        """
        @Element(.image, .id("photo"), actions: [.pinch, .rotate])
        var photo: XCUIElement
        """
      } expansion: {
        """
        var photo: XCUIElement {
            @MainActor
            get {
                _scope.images.matching(identifier: "photo").firstMatch
            }
        }

        /// Performs a pinch on the `photo` element with the given scale and velocity.
        @discardableResult
        @MainActor
        func pinchPhoto(withScale scale: CGFloat, velocity: CGFloat) -> Self {
            photo.pinch(withScale: scale, velocity: velocity)
            return self
        }

        /// Rotates the `photo` element by the given rotation (radians) and velocity.
        @discardableResult
        @MainActor
        func rotatePhoto(_ rotation: CGFloat, withVelocity velocity: CGFloat) -> Self {
            photo.rotate(rotation, withVelocity: velocity)
            return self
        }
        """
      }

      assertMacro {
        """
        @Element(.staticText, .id("label"), actions: [.twoFingerTap, .rightClick, .hover])
        var label: XCUIElement
        """
      } expansion: {
        """
        var label: XCUIElement {
            @MainActor
            get {
                _scope.staticTexts.matching(identifier: "label").firstMatch
            }
        }

        /// Performs a two-finger tap on the `label` element.
        @discardableResult
        @MainActor
        func twoFingerTapLabel() -> Self {
            label.twoFingerTap()
            return self
        }

        /// Sends a Control-click (right-click) to the `label` element.
        @discardableResult
        @MainActor
        func rightClickLabel() -> Self {
            label.rightClick()
            return self
        }

        /// Moves the pointer over the `label` element.
        @discardableResult
        @MainActor
        func hoverLabel() -> Self {
            label.hover()
            return self
        }
        """
      }
    }

    @Test
    func elementEmitsAdjustHelpers() {
      assertMacro {
        """
        @Element(.slider, .id("volume"), actions: [.adjustSliderPosition])
        var volume: XCUIElement
        """
      } expansion: {
        """
        var volume: XCUIElement {
            @MainActor
            get {
                _scope.sliders.matching(identifier: "volume").firstMatch
            }
        }

        /// Adjusts `volume` to the given normalized slider position (0...1).
        @discardableResult
        @MainActor
        func adjustVolumeSliderPosition(_ position: CGFloat) -> Self {
            volume.adjust(toNormalizedSliderPosition: position)
            return self
        }
        """
      }

      assertMacro {
        """
        @Element(.pickerWheel, .id("year"), actions: [.adjustPickerWheelValue])
        var year: XCUIElement
        """
      } expansion: {
        """
        var year: XCUIElement {
            @MainActor
            get {
                _scope.pickerWheels.matching(identifier: "year").firstMatch
            }
        }

        /// Adjusts `year` to the given picker-wheel value.
        @discardableResult
        @MainActor
        func adjustYearPickerWheelValue(_ value: String) -> Self {
            year.adjust(toPickerWheelValue: value)
            return self
        }
        """
      }
    }

    // MARK: - Access-level propagation

    @Test
    func pagePropagatesPublicAccess() {
      assertMacro {
        """
        @Page
        public struct PublicPage: VerifiablePageObject {
            @Element(.button, .id("submit"), verify: true)
            public var submitButton: XCUIElement
        }
        """
      } expansion: {
        """
        public struct PublicPage: VerifiablePageObject {
            public var submitButton: XCUIElement {
                @MainActor
                get {
                    _scope.buttons.matching(identifier: "submit").firstMatch
                }
            }

            /// Taps the `submitButton` element.
            @discardableResult
            @MainActor
            public func tapSubmitButton() -> Self {
                submitButton.tap()
                return self
            }

            /// Asserts that `submitButton` exists. Pass `timeout` to wait up to that many seconds before asserting.
            @discardableResult
            @MainActor
            public func assertSubmitButtonExists(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                submitButton.assertExists(timeout: timeout, file: file, line: line)
                return self
            }

            /// Asserts that `submitButton` is enabled. Pass `timeout` to poll until the condition is met.
            @discardableResult
            @MainActor
            public func assertSubmitButtonEnabled(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                submitButton.assertEnabled(timeout: timeout, file: file, line: line)
                return self
            }

            /// Asserts that `submitButton` is disabled. Pass `timeout` to poll until the condition is met.
            @discardableResult
            @MainActor
            public func assertSubmitButtonDisabled(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                submitButton.assertDisabled(timeout: timeout, file: file, line: line)
                return self
            }

            public let app: XCUIApplication

            @MainActor
            public var _scope: XCUIElement {
                app
            }

            public init(app: XCUIApplication) {
                self.app = app
            }

            public init() {
                self.app = XCUIApplication()
            }

            @MainActor
            public func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }

            /// Asserts that all core elements of this page exist.
            /// Pass `timeout` to wait up to that many seconds for each element before asserting.
            @discardableResult
            @MainActor
            public func verifyDefaultScreen(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
                PageAssertions.assertElementsExist([submitButton], timeout: timeout, file: file, line: line)
                return self
            }

            /// Boolean readiness probe used by `PageNavigation.open(..., retries:)`.
            /// Returns `true` only when every `@Element(verify: true)` on this page currently exists.
            @MainActor
            public func isReady() -> Bool {
                submitButton.exists
            }
        }
        """
      }
    }

    @Test
    func pagePropagatesPackageAccess() {
      assertMacro {
        """
        @Page
        package struct PackagePage {
        }
        """
      } expansion: {
        """
        package struct PackagePage {

            package let app: XCUIApplication

            @MainActor
            package var _scope: XCUIElement {
                app
            }

            package init(app: XCUIApplication) {
                self.app = app
            }

            package init() {
                self.app = XCUIApplication()
            }

            @MainActor
            package func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
                build(app)
            }
        }
        """
      }
    }

    @Test
    func elementEmitsThrowingAssertionHelpers() {
      assertMacro {
        """
        @Element(
            .textField,
            .id("email"),
            actions: [
                .assertExistsThrowing,
                .assertDisappearThrowing,
                .assertLabelThrowing,
                .assertValueThrowing,
                .assertPlaceholderThrowing,
            ]
        )
        var email: XCUIElement
        """
      } expansion: {
        """
        var email: XCUIElement {
            @MainActor
            get {
                _scope.textFields.matching(identifier: "email").firstMatch
            }
        }

        /// Asserts that `email` exists within `timeout`; throws ``PageTimeoutError`` otherwise.
        @discardableResult
        @MainActor
        func assertEmailExistsThrowing(timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) throws(PageTimeoutError) -> Self {
            try email.assertExistsOrThrow(timeout: timeout, file: file, line: line)
            return self
        }

        /// Waits for `email` to disappear within `timeout`; throws ``PageTimeoutError`` otherwise.
        @discardableResult
        @MainActor
        func assertEmailDisappearThrowing(timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) throws(PageTimeoutError) -> Self {
            try email.assertDisappearOrThrow(timeout: timeout, file: file, line: line)
            return self
        }

        /// Asserts that `email`'s label equals `expected` within `timeout`; throws ``PageTimeoutError`` otherwise.
        @discardableResult
        @MainActor
        func assertEmailLabelThrowing(_ expected: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) throws(PageTimeoutError) -> Self {
            try email.assertLabelOrThrow(expected, timeout: timeout, file: file, line: line)
            return self
        }

        /// Asserts that `email`'s value equals `expected` within `timeout`; throws ``PageTimeoutError`` otherwise.
        @discardableResult
        @MainActor
        func assertEmailValueThrowing(_ expected: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) throws(PageTimeoutError) -> Self {
            try email.assertValueOrThrow(expected, timeout: timeout, file: file, line: line)
            return self
        }

        /// Asserts that `email`'s placeholder equals `expected` within `timeout`; throws ``PageTimeoutError`` otherwise.
        @discardableResult
        @MainActor
        func assertEmailPlaceholderThrowing(_ expected: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) throws(PageTimeoutError) -> Self {
            try email.assertPlaceholderOrThrow(expected, timeout: timeout, file: file, line: line)
            return self
        }
        """
      }
    }

    @Test
    func elementRejectsInterpolatedIdentifier() {
      assertMacro {
        #"""
        @Element(.button, .id("btn_\(suffix)"), actions: [])
        var submitButton: XCUIElement
        """#
      } diagnostics: {
        #"""
        @Element(.button, .id("btn_\(suffix)"), actions: [])
                          ┬───────────────────
                          ╰─ 🛑 Second argument must be a Locator expression (for example, .id("login"))
                             ✏️ Replace with .id("<#identifier#>")
        var submitButton: XCUIElement
        """#
      } fixes: {
        """
        @Element(.button, .id("<#identifier#>"), actions: [])
        var submitButton: XCUIElement
        """
      } expansion: {
        """
        var submitButton: XCUIElement {
            @MainActor
            get {
                _scope.buttons.matching(identifier: "<#identifier#>").firstMatch
            }
        }
        """
      }
    }

    @Test
    func pageRejectsNonLiteralScopeIdentifier() {
      assertMacro {
        """
        @Page(scope: .scrollView(id: someVar))
        struct CheckoutPage {
        }
        """
      } diagnostics: {
        """
        @Page(scope: .scrollView(id: someVar))
                                     ┬──────
                                     ╰─ 🛑 `id:` in a container scope must be a plain string literal — the macro evaluates it at expansion time and cannot see interpolation or variables.
        struct CheckoutPage {
        }
        """
      }
    }
  }
#endif
