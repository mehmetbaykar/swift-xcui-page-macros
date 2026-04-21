# swift-xcui-page-macros

[![Swift 6.2](https://img.shields.io/badge/Swift-6.3-orange.svg)](https://swift.org)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2017%20%7C%20macOS%2014%20%7C%20tvOS%2017%20%7C%20visionOS%201-blue.svg)](#requirements)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Swift macro library for XCUITest page objects. Small `@Page`, `@Element`, `@Scope` declarations expand into typed element accessors, fluent action helpers, screen verification methods, and typed branching navigation — all sharing one `XCUIApplication`.

## Demo

The `SampleApp` auth flow driven end-to-end by the generated page objects:

<video src="https://github.com/mehmetbaykar/swift-xcui-page-macros/raw/main/SampleApp/auth-flow-demo.mp4" controls muted playsinline width="640"></video>

If the embed does not render in your client, [see the SampleApp demo](SampleApp/README.md).

## Table of contents

- [Why](#why)
- [Install](#install)
- [Quick start](#quick-start)
- [Codebase](#codebase)
- [`@Page`](#page)
- [`@Element`](#element)
- [`@Scope`](#scope)
- [Navigation](#navigation)
- [Error handling](#error-handling)
- [Locators](#locators)
- [Testing](#testing)
- [Requirements](#requirements)

## Why

Manual XCUITest page objects repeat the same code: query an element, tap it, type into it, assert it exists, pass the same `XCUIApplication` through every screen, rebuild branching navigation glue. This package keeps the declarations and generates the boilerplate.

## Install

```swift
.package(url: "https://github.com/mehmetbaykar/swift-xcui-page-macros.git", branch: "main")
```

Add `SwiftXCUIPageMacros` to your UI test target dependencies and import it from your UI test pages.

The first time you build against a macro target, Xcode asks you to "Trust & Enable" the compiler plugin. Approve it once; otherwise `@Page`, `@Element`, and `@Scope` expand to nothing and your test target fails to compile.

## Quick start

```swift
import XCTest
import SwiftXCUIPageMacros

@Page(scope: .scrollView(id: "splashScroll"))
struct SplashPage: VerifiablePageObject {
    @Element(.button, .id("openLogin"), verify: true)
    var openLoginButton: XCUIElement

    func openLogin() throws -> LoginPage<Self> {
        try PageNavigation.open(from: self, perform: {
            tapOpenLoginButton()
        }) { app, origin in
            LoginPage(app: app, origin: origin)
        }
    }
}

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

    @Element(.button, .id("back"), verify: true)
    var backButton: XCUIElement

    func backToOrigin() -> Origin {
        PageNavigation.returnToOrigin(from: self) { tapBackButton() }
    }
}

@MainActor
final class AuthFlowTests: XCTestCase {
    func testBranchSwitching() throws {
        let app = XCUIApplication()
        app.launch()

        try SplashPage(app: app)
            .openLogin()
            .backToOrigin()
    }
}
```

## Codebase

```
.
├── Sources/
│   ├── SwiftXCUIPageMacros/              runtime library (import target)
│   │   ├── Macros.swift                  @Page, @Element, @Scope declarations
│   │   ├── PageRuntime.swift             PageAssertions, XCUIElement extensions
│   │   ├── PageNavigation.swift          open(...), returnToOrigin(...)
│   │   ├── ElementType.swift             41 element kinds (.button, .textField, …)
│   │   ├── ContainerType.swift           18 container kinds (.scrollView, .table, …)
│   │   ├── ElementAction.swift           33 action helpers (.tap, .typeText, …)
│   │   ├── Locator.swift                 .id, .label, .predicate, .index
│   │   ├── OpenFailure.swift             retry-aware typed error
│   │   ├── PageTimeoutError.swift        typed assertion timeout
│   │   ├── PlatformSupport.swift         platform availability shims
│   │   └── Documentation.docc/           DocC catalog
│   └── SwiftXCUIPageMacrosMacros/        compiler plugin (macro implementations)
│       ├── Plugin.swift                  CompilerPlugin registration
│       ├── PageObjectMacro.swift         @Page expansion
│       ├── ElementMacro.swift            @Element expansion
│       ├── ScopeMacro.swift              @Scope expansion
│       ├── QueryHelpers.swift            shared codegen + action allowlist
│       └── MacroDiagnostics.swift        fix-it diagnostics
├── Tests/
│   ├── SwiftXCUIPageMacrosMacroTests/    Point-Free MacroTesting snapshots
│   └── SwiftXCUIPageMacrosRuntimeTests/  runtime + navigation tests (Swift Testing)
├── SampleApp/
│   ├── SampleApp/                        SwiftUI auth-flow demo app
│   └── SampleAppUITests/                 end-to-end XCUITest coverage
├── skills/swift-xcui-page-macros/        Claude Code skill for this package
├── .github/workflows/pr.yml              build + test CI on PR
├── Package.swift                         SPM manifest (macro + library + tests)
└── README.md
```

## `@Page`

Applied to a `struct`. Generates:

- `let app: XCUIApplication`
- `var _scope: XCUIElement`
- `init(app:)` and `init()` when the struct declares none
- `transition(_:)` for linear composition
- `verifyDefaultScreen(timeout:file:line:)` when any element uses `verify: true`
- `isReady() -> Bool` used as the `PageNavigation.open(retries:)` probe
- `@MainActor` on every emitted member and every custom method that does not already declare it

Use `scope:` to root queries in a container:

```swift
@Page(scope: .scrollView(id: "checkoutScroll"))
struct CheckoutPage { … }
```

Use `bundle:` when the page targets another app.

## `@Element`

Emits a computed `XCUIElement` accessor plus action helpers chosen via `actions:` (or a per-element-type default when omitted):

```swift
@Element(.button, .id("submit"), actions: [.tap, .scrollToVisible, .assertExists])
var submitButton: XCUIElement
```

Expands to:

- `submitButton`
- `tapSubmitButton()`
- `scrollToVisibleSubmitButton()`
- `assertSubmitButtonExists(timeout:file:line:)`

Mark `verify: true` on the handful of elements that define screen readiness — they become the AND'd contract inside `verifyDefaultScreen` and `isReady`.

## `@Scope`

Typed sub-root inside a page. Lets you declare multiple stable regions and chain elements off them:

```swift
@Page
struct CheckoutPage: VerifiablePageObject {
    @Scope(.scrollView(id: "checkoutScroll"))
    var checkoutRegion: XCUIElement

    @Scope(.table(id: "results"), in: "checkoutRegion")
    var resultsRegion: XCUIElement

    @Element(.staticText, .id("total"), in: "resultsRegion")
    var lineTotal: XCUIElement
}
```

`in:` takes a plain string literal naming a sibling property. Typos and missing properties surface as ordinary Swift compile errors on the emitted code; non-string-literal args fail with `invalidParentName`.

## Navigation

Three protocols, emitted by `@Page` conformance:

```swift
@MainActor public protocol PageObject {
    var app: XCUIApplication { get }
    init(app: XCUIApplication)
}

@MainActor public protocol VerifiablePageObject: PageObject {
    @discardableResult
    func verifyDefaultScreen(timeout: TimeInterval?, file: StaticString, line: UInt) -> Self
    func isReady() -> Bool
}

@MainActor public protocol OriginTrackedPage: VerifiablePageObject {
    associatedtype Origin: VerifiablePageObject
    var origin: Origin { get }
}
```

`PageNavigation` bridges them. Every `open(...)` is `throws(OpenFailure)` and accepts `retries:` / `backoff:`:

- `open(from:to:perform:)` — default destination built with `init(app:)`
- `open(from:perform:destination:)` — custom destination factory
- `open(from:perform:destination:)` — origin-tracked destination factory
- `returnToOrigin(from:perform:)` — typed back navigation (non-throwing)

Each helper returns an already-verified destination.

## Error handling

```swift
do {
    let login = try splash.openLogin(retries: 2, backoff: 0.5)
    try login.email.assertExistsOrThrow(timeout: 5).assertLabel("Email")
} catch let failure as OpenFailure {
    XCTFail("openLogin gave up after \(failure.attempts) attempt(s): \(failure.underlying)")
} catch let timeout as PageTimeoutError {
    XCTFail("\(timeout.elementDescription) timed out after \(timeout.waited)s")
}
```

Throwing `XCUIElement` assertions (`assertExistsOrThrow`, `assertDisappearOrThrow`, `assertLabelOrThrow`, `assertValueOrThrow`, `assertPlaceholderOrThrow`) return `XCUIElement` for fluent chaining. Non-throwing counterparts stay `XCTFail`-based.

## Locators

Prefer accessibility identifiers. Fall back to label, predicate, or index:

```swift
@Element(.button, .id("login"))
@Element(.staticText, .label("Welcome"))
@Element(.staticText, .labelContains("Welcome"))
@Element(.cell, .predicate("enabled == true AND label CONTAINS 'Item'"))
@Element(.button, .index(2))
```

## Testing

Three layers:

| Target | Framework | Scope |
|---|---|---|
| `SwiftXCUIPageMacrosMacroTests` | MacroTesting snapshots | macro expansions, diagnostics, fix-its |
| `SwiftXCUIPageMacrosRuntimeTests` | Swift Testing | `PageNavigation`, `PageAssertions`, error types |
| `SampleAppUITests` | XCTest / XCUITest | generated API end-to-end against the SwiftUI demo app |

Only `SampleAppUITests` uses XCTest; everything under `Tests/` stays on Swift Testing.

```bash
# package tests
swift test

# refresh macro snapshots after an expansion change
SNAPSHOT_TESTING_RECORD=all swift test

# sample UI tests
xcodebuild test \
  -project SampleApp/SampleApp.xcodeproj \
  -scheme SampleApp \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4'
```

## Requirements

- Swift 6.2
- Xcode 26.4+
- iOS 17+ / macOS 14+ / tvOS 17+ / visionOS 1+

## Acknowledgments

Inspired by [PageMacro](https://github.com/peppperrroni/PageMacro) by @peppperrroni.
