# ``SwiftXCUIPageMacros``

@Metadata {
    @DisplayName("SwiftXCUIPageMacros")
}

Typed XCUITest page objects via Swift macros.

## Overview

`SwiftXCUIPageMacros` removes the hand-written boilerplate of XCUITest page
objects. Three macros, one runtime, zero reflection:

- `@Page` expands a struct into a `@MainActor` page object: an `XCUIApplication`
  reference, an optional scope container, synthesized initializers, a
  `transition(_:)` helper, a `verifyDefaultScreen(timeout:file:line:)`
  helper when any element is marked `verify: true`, and an `isReady()`
  readiness probe used by `PageNavigation.open(..., retries:)`.
- `@Element` expands a stored property into a typed `XCUIElement` accessor
  plus fluent peer helpers (`tapFoo()`, `typeTextIntoFoo(_:)`, `assertFooExists(...)`,
  and more).
- `@Scope` declares additional sub-roots on individual properties, so a
  page can nest several stable regions and chain elements off them via
  `@Element(..., in: "parent")`.
- ``PageNavigation`` provides `open(...)` overloads for branching flows and
  `returnToOrigin(...)` for back-navigation. The `open(...)` overloads accept
  `retries:` and `backoff:` and throw a typed ``OpenFailure``.
- ``PageAssertions`` bundles multi-element existence checks and
  `scrollToVisible(_:in:axis:timeout:maxSwipes:)`.
- `PageObject.snapshot(named:autoAttach:)` and
  `XCUIElement.snapshot(named:autoAttach:)` return an `XCTAttachment` and,
  by default (`autoAttach: true`), add it to the current
  `XCTContext.runActivity` so screenshots appear in the Xcode test report
  without extra wiring.
- ``PageTimeoutError`` and ``OpenFailure`` carry structured failure context
  from the throwing assertion overloads and from `open(...)` retries.

## Topics

### Getting started

- <doc:GettingStarted>

### Elements

- <doc:Elements>

### Navigation

- <doc:Navigation>

### Concurrency

- <doc:Concurrency>

### Macros

- ``Page(bundle:scope:)``
- ``Element(_:_:actions:verify:in:)``
- ``Scope(_:in:)``

### Runtime

- ``PageObject``
- ``VerifiablePageObject``
- ``OriginTrackedPage``
- ``PageNavigation``
- ``PageAssertions``

### Errors

- ``PageTimeoutError``
- ``OpenFailure``

### Value types

- ``ElementType``
- ``ContainerType``
- ``ElementAction``
- ``Locator``

