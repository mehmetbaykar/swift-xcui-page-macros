/// Marks a struct as a Page Object for XCUITest.
///
/// Generates:
/// - `let app: XCUIApplication`
/// - `var _scope: XCUIElement` — the root all `@Element` queries chain from.
///   Forwards to `app` unless `scope:` is set.
/// - `@MainActor` on custom page methods, initializers, and computed properties.
/// - `init(app:)` and `init()` when the page does not declare its own initializer
/// - `transition(_:)` to move into another page object with the same app instance.
///
/// **Parameters**
/// - `bundle:` pins the page to a specific app by bundle identifier.
/// - `scope:` narrows every element query to a specific container using a `ContainerType`
///   with the locator embedded (e.g. `.scrollView(id: "formContainer")`). All `@Element`
///   accessors in the struct will root their queries in this element.
///
/// ```swift
/// // Standard — caller provides the app
/// @Page
/// struct LoginPage {
///     @Element(.textField, id: "email")
///     var email: XCUIElement
/// }
///
/// // Scoped — all elements query within the "formContainer" scroll view
/// @Page(scope: .scrollView(id: "formContainer"))
/// struct RegistrationPage {
///     @Element(.textField, id: "name")
///     var nameField: XCUIElement
/// }
///
/// // Bundle-pinned — useful for Safari or other system apps
/// @Page(bundle: "com.apple.mobilesafari")
/// struct SafariPage {
///     @Element(.button, id: "done")
///     var doneButton: XCUIElement
/// }
///
/// // Custom construction — generated convenience initializers are suppressed
/// @Page
/// struct LoginPage<Origin: VerifiablePageObject>: OriginTrackedPage {
///     let origin: Origin
///
///     init(app: XCUIApplication, origin: Origin) {
///         self.app = app
///         self.origin = origin
///     }
///
///     init(app: XCUIApplication) {
///         self.init(app: app, origin: Origin(app: app))
///     }
/// }
/// ```
@attached(
  member, names: named(app), named(_scope), named(init), named(transition),
  named(verifyDefaultScreen), named(isReady))
@attached(memberAttribute)
public macro Page(
  bundle: String? = nil,
  scope: ContainerType? = nil
) = #externalMacro(module: "SwiftXCUIPageMacrosMacros", type: "PageObjectMacro")

/// Generates a computed `XCUIElement` accessor and fluent helper methods.
///
/// Queries relative to the page's `_scope` (set by `@Page(scope:)`, or `app` by default).
/// The second argument is a `Locator` that describes how to find the element.
///
/// ```swift
/// @Element(.textField,  .id("email"))
/// var email: XCUIElement
///
/// @Element(.button,     .id("submit"), actions: [.tap, .assertExists, .assertEnabled])
/// var submitButton: XCUIElement
///
/// @Element(.staticText, .labelContains("Welcome"))
/// var welcomeLabel: XCUIElement
///
/// @Element(.cell,       .predicate("enabled == true AND label CONTAINS 'Item'"))
/// var featuredCell: XCUIElement
///
/// @Element(.button,     .index(2))
/// var thirdButton: XCUIElement
///
/// @Element(.button,     .id("ok", index: 1))
/// var secondOkButton: XCUIElement
/// ```
@attached(accessor, names: named(get))
@attached(peer, names: arbitrary)
public macro Element(
  _ type: ElementType,
  _ locator: Locator? = nil,
  actions: [ElementAction]? = nil,
  verify: Bool = false,
  in parent: String? = nil
) = #externalMacro(module: "SwiftXCUIPageMacrosMacros", type: "ElementMacro")

/// Declares a typed `XCUIElement` accessor rooted in a specific `ContainerType`.
///
/// `@Page(scope:)` applies one scope to every element on the page. `@Scope`
/// lets a single page declare multiple sub-roots for distinct regions.
///
/// ```swift
/// @Page
/// struct CheckoutPage: VerifiablePageObject {
///     @Scope(.scrollView(id: "checkoutScroll"))
///     var checkoutRegion: XCUIElement
/// }
/// ```
///
/// The emitted accessor chains off the page's `_scope`. `ContainerType`
/// accepts at most one of `id:`, `label:`, `index:`; specifying more than
/// one is a `conflictingScopeLocators` error.
@attached(accessor, names: named(get))
public macro Scope(
  _ type: ContainerType,
  in parent: String? = nil
) = #externalMacro(module: "SwiftXCUIPageMacrosMacros", type: "ScopeMacro")
