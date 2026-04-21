# Navigation

Compose linear flows with `transition(_:)` and branching flows with
``PageNavigation``.

## Linear flows: `transition(_:)`

`@Page` emits a `transition<Next>(_:)` helper on every page. Use it when
the next screen is a direct, non-branching continuation of the current
one. The closure receives the same `XCUIApplication`:

```swift
let home = splash.transition { app -> HomePage in
    splash.tapContinueButton()
    return HomePage(app: app)
}
```

`transition` does not verify the destination. Pair it with
`home.verifyDefaultScreen()` if you need that guarantee.

## Branching flows: `PageNavigation.open(...)`

For flows that branch (splash → login vs. splash → sign-up), use one of
the three ``PageNavigation/open(from:to:timeout:retries:backoff:file:line:perform:)``
overloads. All three accept `retries:` (default `0`) and `backoff:`
(default `0.25`) and throw typed ``OpenFailure``.

### Convenience overload

The destination conforms to ``VerifiablePageObject`` and is constructed
from the shared `XCUIApplication`:

```swift
let home: HomePage = try PageNavigation.open(from: splash) {
    splash.tapContinueButton()
}
```

### Custom destination builder

Supply a builder when the destination needs more than `XCUIApplication`
to initialize:

```swift
let form = try PageNavigation.open(
    from: splash,
    perform: { splash.tapOpenForm() },
    destination: { app in FormPage(app: app, mode: .create) }
)
```

### Origin-tracked destination

When the destination is an ``OriginTrackedPage`` (carries a `let origin`),
the three-argument builder receives both the app and the origin:

```swift
let login = try PageNavigation.open(
    from: splash,
    perform: { splash.tapOpenLogin() },
    destination: { app, origin in LoginPage(app: app, origin: origin) }
)
```

## Returning to origin: `returnToOrigin(...)`

``PageNavigation/returnToOrigin(from:timeout:file:line:perform:)`` verifies
the `origin` page after running the navigation action. It does not retry —
back-navigation is expected to succeed on the first attempt:

```swift
let splashAgain = PageNavigation.returnToOrigin(from: login) {
    login.tapBackButton()
}
```

## The `OriginTrackedPage` protocol

`OriginTrackedPage` refines `VerifiablePageObject` with an associated
`Origin: VerifiablePageObject` and a `var origin: Origin`. Pages modeled
this way can be composed into branching flows that return to their
origin without losing the concrete origin type.

```swift
@Page
struct LoginPage<Origin: VerifiablePageObject>: OriginTrackedPage {
    let origin: Origin

    init(app: XCUIApplication, origin: Origin) {
        self.app = app
        self.origin = origin
    }

    init(app: XCUIApplication) {
        self.init(app: app, origin: Origin(app: app))
    }
}
```

## See Also

- <doc:Concurrency> — why `perform` and `destination:` closures are
  `@MainActor`.
