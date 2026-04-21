# Getting Started

Install the package and write your first `@Page` struct.

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/mehmetbaykar/swift-xcui-page-macros.git",
        branch: "main"
    )
]
```

And add `SwiftXCUIPageMacros` to your UI-test target:

```swift
.testTarget(
    name: "MyAppUITests",
    dependencies: [
        .product(name: "SwiftXCUIPageMacros", package: "swift-xcui-page-macros")
    ]
)
```

For Xcode projects, add the package under
**File > Add Package Dependencies…** and link the `SwiftXCUIPageMacros`
library into your UI-test target.

## Your first page

```swift
import SwiftXCUIPageMacros
import XCTest

@Page
struct LoginPage: VerifiablePageObject {
    @Element(.textField, .id("email"), verify: true)
    var email: XCUIElement

    @Element(.secureTextField, .id("password"), verify: true)
    var password: XCUIElement

    @Element(.button, .id("submit"), verify: true)
    var submitButton: XCUIElement
}
```

The `@Page` macro synthesizes `let app: XCUIApplication`,
`init(app:)` / `init()`, a `transition(_:)` helper, and
`verifyDefaultScreen(timeout:file:line:)` (because at least one element
is marked `verify: true`). `@Element` emits the typed `XCUIElement`
accessor plus the default action helpers for the element type.

## Your first test

```swift
import XCTest

@MainActor
final class LoginTests: XCTestCase {
    func testSubmitIsEnabled() {
        let app = XCUIApplication()
        app.launch()

        LoginPage(app: app)
            .verifyDefaultScreen()
            .typeTextIntoEmail("user@example.com")
            .typeTextIntoPassword("hunter2")
            .assertSubmitButtonEnabled()
    }
}
```

From here, read <doc:Elements> for locators, scoping with `@Page(scope:)`,
and per-type action defaults, <doc:Navigation> for branching flows, and
<doc:Concurrency> for the `@MainActor` contract.
