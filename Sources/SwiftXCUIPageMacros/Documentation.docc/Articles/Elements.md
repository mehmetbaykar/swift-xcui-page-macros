# Elements

Declare typed `XCUIElement` accessors with `@Element` and compose them with
locator strategies.

## Overview

`@Element` takes an `ElementType`, an optional `Locator`, an optional
`actions:` list, and an optional `verify:` flag. The macro emits a `get`
accessor that builds the underlying `XCUIElementQuery` against the page's
`_scope`, then emits peer helper methods for each action.

```swift
@Page
struct SearchPage: VerifiablePageObject {
    @Element(.searchField, .id("search"), verify: true)
    var searchField: XCUIElement
}
```

## Locator strategies

| Case | Matching |
|------|----------|
| `.id(_:index:)` | accessibility identifier match; `index` disambiguates duplicates |
| `.label(_:index:)` | exact, case-sensitive label match |
| `.labelContains(_:index:)` | substring match; case- and diacritic-sensitive |
| `.predicate(_:index:)` | caller-owned NSPredicate format string |
| `.index(_:)` | zero-based positional match with no string filter |

Strings passed to `.label`, `.labelContains`, and `.predicate` are escaped
in the generated source.

## Default actions per element type

`@Element` emits a default action set based on the `ElementType`:

| ElementType | Default actions |
|-------------|-----------------|
| `.textField`, `.searchField`, `.comboBox` | tap, typeText, clearText, assertExists, assertValue, assertPlaceholder |
| `.secureTextField` | tap, typeText, clearText, assertExists, assertPlaceholder |
| `.textView` | tap, typeText, clearText, assertExists, assertValue |
| `.button`, `.link`, `.menuItem`, `.popUpButton`, `.disclosureTriangle`, `.tab` | tap, assertExists, assertEnabled, assertDisabled |
| `.staticText` | assertExists, assertLabel |
| `.cell` | tap, assertExists |
| `.toggle`, `.checkBox`, `.radioButton` | tap, assertExists, assertSelected, assertNotSelected |
| `.stepper`, `.slider` | assertExists, assertValue |
| `.scrollView`, `.table`, `.collectionView`, `.outline` | swipeUp, swipeDown, assertExists |
| `.activityIndicator`, `.progressIndicator`, `.image`, `.window`, `.menuBar`, `.sheet`, `.popover`, `.alert`, `.menu` | assertExists |
| all others | tap, assertExists |

Override with `actions:` when you only want a subset, or pass
`actions: []` to emit the accessor without any peer helpers.
`ElementAction` conforms to `CaseIterable`, so `ElementAction.allCases`
is available for reflection-driven tooling.

```swift
@Element(.button, .id("submit"), actions: [.tap, .assertEnabled])
var submitButton: XCUIElement
```

## `verify: true`

Mark elements that define the "this screen is ready" contract. When any
`@Element` on a page is marked `verify: true`, `@Page` synthesizes
`verifyDefaultScreen(timeout:file:line:)` and `isReady() -> Bool`. The
first asserts every verify-tagged element exists before returning `self`;
the second is used by `PageNavigation.open(..., retries:)` as the retry
probe, so picking the right elements here directly controls how reliably
retries recover from slow transitions.

`verify:` must be a `true`/`false` literal. Passing a variable, flag, or
computed expression triggers a macro warning (`nonLiteralVerify`), and the
property is silently excluded from the generated `isReady()` — because the
macro runs at expansion time and cannot evaluate runtime values.

## Scoping

Every `@Element` query chains off the page's `_scope`. Without `@Page(scope:)`,
`_scope` forwards to `app`, so queries run against the entire application
accessibility tree. Pass `scope:` to root every query inside a specific
container:

```swift
@Page(scope: .scrollView(id: "loginScroll"))
struct LoginPage {
    @Element(.textField, .id("email"))
    var email: XCUIElement
    // emits: _scope.textFields["email"].firstMatch
    // rooted at: app.scrollViews["loginScroll"].firstMatch
}
```

Four reasons to scope deliberately:

1. **Disambiguation across screens.** If Login and SignUp both expose a
   field with `accessibilityIdentifier("email")` and they coexist in the
   view tree during a push transition, `app.textFields["email"]` can
   resolve to the wrong one. A scoped query cannot.
2. **Modal / sheet / alert overlays.** When a sheet covers the page
   underneath, both trees are live. A scoped query stays on the screen
   you meant.
3. **Speed.** XCUITest walks the accessibility tree. Rooting at a smaller
   subtree is measurably faster on large screens (long lists, deep stacks,
   iPad split view).
4. **SwiftUI convention.** Forms, login, and signup views are usually
   wrapped in a `ScrollView` so the keyboard doesn't cover inputs.
   Tagging the `ScrollView` once gives every field inside it a stable
   anchor — no per-element ceremony.

`.scrollView` is one of eighteen container cases. `ContainerType` also
includes `.alert`, `.navigationBar`, `.tabBar`, `.toolbar`, `.cell`,
`.table`, `.collectionView`, `.webView`, `.picker`, `.datePicker`, and
`.view`. Pick the one that matches your actual container. If your screen
is a plain `VStack` with no identifying container, skip `scope:` — using
it forces you to invent an element with no UX purpose.

`@Page(scope:)` accepts at most one of `id:`, `label:`, `index:` per
container case. Specifying more than one is a `conflictingScopeLocators`
error.

### Nested scopes

`@Page(scope:)` applies one scope to the whole page. `@Scope` declares
additional sub-roots on individual properties, and `@Element(..., in:)`
lets an element hang off one of those sub-roots:

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

`in:` takes a plain string literal naming a sibling property. The
macro reads the string at expansion time and emits a direct reference
to that property in the generated accessor. Swift's type checker then
validates the emitted code end-to-end, so typos, missing properties,
and wrong types surface as ordinary compile errors — not macro-time
diagnostics.

A non-string-literal argument (variable, computed expression,
interpolation) is rejected with `invalidParentName`.

## Generated helper names

The naming convention is `<action><PropertyName>(...)` with the property
name capitalized. Examples:

- `@Element(.button, .id("send")) var sendButton: XCUIElement` generates
  `tapSendButton()`, `assertSendButtonExists(...)`, etc.
- `@Element(.textField, .id("email")) var email: XCUIElement` generates
  `tapEmail()`, `typeTextIntoEmail(_:)`, `clearEmail()`,
  `assertEmailExists(...)`, `assertEmailValue(_:)`,
  `assertEmailPlaceholder(_:)`.

## See Also

- <doc:Navigation> — branching flows between pages.
