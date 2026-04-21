# Concurrency

Understand the `@MainActor` contract that binds pages, helpers, and
navigation closures.

## Pages are `@MainActor`, not `Sendable`

Every protocol in this package is `@MainActor`:

- `PageObject`
- `VerifiablePageObject`
- `OriginTrackedPage`

`@Page` additionally applies `@MainActor` to every user-declared function,
initializer, subscript, and computed property on the struct that does not
already carry the attribute. You never annotate pages manually.

Pages are deliberately **not** `Sendable`. `XCUIApplication` and
`XCUIElement` are not `Sendable`, and any `Sendable` conformance on a
page would be a lie. Consequently:

- Do not store page objects in Swift-Testing `@Suite` globals unless the
  suite itself is `@MainActor`.
- Do not capture page objects in non-`@MainActor` tasks.

Value types used by the macros and runtime (`ContainerType`, `ElementType`,
`ElementAction`, `Locator`, ``PageTimeoutError``, ``OpenFailure``) are
`Sendable` and safe to pass across isolation boundaries.

## Navigation closures are `@MainActor` closures

The `perform:` action and the `destination:` builder passed to
``PageNavigation/open(from:to:timeout:retries:backoff:file:line:perform:)``
are declared as `@MainActor` closures. That matches the isolation of the
page APIs they call — `tapButton()`, `verifyDefaultScreen(...)`, and so on.
No additional annotation is needed on your side when the call site is
already `@MainActor`.

## Running `open(...)` from Swift Testing

If you use Swift Testing for UI tests, mark the suite (or the test
function) `@MainActor` before touching a page object:

```swift
import Testing
import SwiftXCUIPageMacros

@MainActor
@Suite
struct LoginSuite {
    @Test
    func openLoginFromSplash() throws {
        let app = XCUIApplication()
        app.launch()
        let splash = SplashPage(app: app)
        let login = try PageNavigation.open(
            from: splash,
            perform: { splash.tapOpenLoginButton() },
            destination: { app, origin in LoginPage(app: app, origin: origin) }
        )
        login.assertFlowPathLabel("Splash / Login")
    }
}
```

## Retry semantics

The retry loop built into ``PageNavigation/open(from:to:timeout:retries:backoff:file:line:perform:)``:

- Between attempts, the helper sleeps `backoff` seconds via
  `Thread.sleep(forTimeInterval:)`. UI tests already block the main
  thread during waits, so the short sleep is acceptable here.
- The retry probe calls `destination.isReady()`, which the `@Page` macro
  synthesizes as the logical AND of `.exists` over every element marked
  `@Element(verify: true)`. Picking the right `verify:` set directly
  controls how reliably retries recover from slow transitions.

Callers that omit `retries:` get a single attempt with no probe — the
pre-retry baseline behavior.

## Strict concurrency

The library target passes
`swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors`
in CI.

## See Also

- <doc:Navigation> — where the `@MainActor` closures live.
