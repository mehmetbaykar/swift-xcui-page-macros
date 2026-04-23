import SwiftSyntax
import SwiftSyntaxMacros

enum ParsedLocator {
  case id(String, index: Int?)
  case label(String, index: Int?)
  case labelContains(String, index: Int?)
  case predicate(String, index: Int?)
  case index(Int)
}

struct ParsedElementParams {
  let typeName: String
  let queryProperty: String
  let locator: ParsedLocator?
  let actions: [String]?
}

struct ParsedElementType {
  let typeName: String
  let queryProperty: String
}

func parseType(from argArray: [LabeledExprSyntax]) throws -> ParsedElementType {
  guard !argArray.isEmpty else { throw MacroError.invalidArguments }
  guard let member = argArray[0].expression.as(MemberAccessExprSyntax.self) else {
    throw MacroError.invalidElementType
  }
  let typeName = member.declName.baseName.text
  let queryProperty = try elementTypeToQueryProperty(typeName)
  return ParsedElementType(typeName: typeName, queryProperty: queryProperty)
}

/// Returns `nil` when the second argument is labeled — i.e. the caller omitted the locator.
func parseLocator(from argArray: [LabeledExprSyntax]) throws -> ParsedLocator? {
  guard argArray.count >= 2, argArray[1].label == nil else { return nil }
  return try parseLocatorExpr(argArray[1].expression)
}

func parseActions(from argArray: [LabeledExprSyntax]) throws -> [String]? {
  for arg in argArray {
    guard arg.label?.text == "actions" else { continue }
    guard let arrayExpr = arg.expression.as(ArrayExprSyntax.self) else {
      throw invalidActionDiagnostic(for: arg.expression)
    }
    return try arrayExpr.elements.map { element in
      guard let member = element.expression.as(MemberAccessExprSyntax.self) else {
        throw invalidActionDiagnostic(for: arg.expression)
      }
      let actionName = member.declName.baseName.text
      guard supportedActions.contains(actionName) else {
        throw invalidActionDiagnostic(for: arg.expression)
      }
      return actionName
    }
  }
  return nil
}

func parseElementArgs(from node: AttributeSyntax) throws -> ParsedElementParams {
  guard let args = node.arguments?.as(LabeledExprListSyntax.self), !args.isEmpty else {
    throw MacroError.invalidArguments
  }
  let argArray = Array(args)
  let type = try parseType(from: argArray)
  let locator = try parseLocator(from: argArray)
  let actions = try parseActions(from: argArray)
  return ParsedElementParams(
    typeName: type.typeName,
    queryProperty: type.queryProperty,
    locator: locator,
    actions: actions
  )
}

func parseLocatorExpr(_ expr: ExprSyntax) throws -> ParsedLocator {
  guard
    let call = expr.as(FunctionCallExprSyntax.self),
    let member = call.calledExpression.as(MemberAccessExprSyntax.self)
  else { throw invalidLocatorDiagnostic(for: expr) }

  let caseName = member.declName.baseName.text
  let callArgs = Array(call.arguments)

  switch caseName {
  case "index":
    if let intLit = callArgs.first?.expression.as(IntegerLiteralExprSyntax.self),
      let n = Int(intLit.literal.text)
    {
      return .index(n)
    }
  case "id", "label", "labelContains", "predicate":
    guard let str = callArgs.first.flatMap({ extractString(from: $0.expression) }) else {
      throw invalidLocatorDiagnostic(for: expr)
    }
    var index: Int? = nil
    for arg in callArgs.dropFirst() {
      guard arg.label?.text == "index" else { continue }
      guard let intLit = arg.expression.as(IntegerLiteralExprSyntax.self),
        let parsedIndex = Int(intLit.literal.text)
      else { throw invalidLocatorDiagnostic(for: expr) }
      index = parsedIndex
    }
    switch caseName {
    case "id": return .id(str, index: index)
    case "label": return .label(str, index: index)
    case "labelContains": return .labelContains(str, index: index)
    case "predicate": return .predicate(str, index: index)
    default: break
    }
  default: break
  }

  throw invalidLocatorDiagnostic(for: expr)
}

func extractString(from expr: ExprSyntax) -> String? {
  guard let strLit = expr.as(StringLiteralExprSyntax.self) else { return nil }
  // Reject string interpolation like "btn_\(suffix)" — the macro runs at
  // expansion time and cannot evaluate the interpolated expression, so
  // accepting the literal prefix would silently truncate the identifier.
  guard strLit.segments.count == 1,
    let seg = strLit.segments.first?.as(StringSegmentSyntax.self)
  else { return nil }
  return seg.content.text
}

// MARK: - ContainerType parsing

struct ParsedContainer {
  let typeName: String
  let id: String?
  let label: String?
  let index: Int?

  var locatorCount: Int {
    (id == nil ? 0 : 1) + (label == nil ? 0 : 1) + (index == nil ? 0 : 1)
  }
}

func parseContainerExpr(_ expr: ExprSyntax) throws -> ParsedContainer {
  if let call = expr.as(FunctionCallExprSyntax.self),
    let member = call.calledExpression.as(MemberAccessExprSyntax.self)
  {
    let typeName = member.declName.baseName.text
    _ = try containerTypeToQueryProperty(typeName)
    var id: String? = nil
    var label: String? = nil
    var index: Int? = nil
    for arg in call.arguments {
      switch arg.label?.text {
      case "id":
        guard let value = extractString(from: arg.expression) else {
          throw invalidContainerLocatorDiagnostic(for: arg.expression, label: "id")
        }
        id = value
      case "label":
        guard let value = extractString(from: arg.expression) else {
          throw invalidContainerLocatorDiagnostic(for: arg.expression, label: "label")
        }
        label = value
      case "index":
        guard let intLit = arg.expression.as(IntegerLiteralExprSyntax.self),
          let n = Int(intLit.literal.text)
        else {
          throw invalidContainerLocatorDiagnostic(for: arg.expression, label: "index")
        }
        index = n
      default: break
      }
    }
    return ParsedContainer(typeName: typeName, id: id, label: label, index: index)
  }

  if let member = expr.as(MemberAccessExprSyntax.self) {
    let typeName = member.declName.baseName.text
    _ = try containerTypeToQueryProperty(typeName)
    return ParsedContainer(typeName: typeName, id: nil, label: nil, index: nil)
  }

  throw invalidContainerDiagnostic(for: expr)
}

func containerTypeToQueryProperty(_ name: String) throws -> String {
  switch name {
  case "scrollView": return "scrollViews"
  case "table": return "tables"
  case "collectionView": return "collectionViews"
  case "outline": return "outlines"
  case "cell": return "cells"
  case "navigationBar": return "navigationBars"
  case "tabBar": return "tabBars"
  case "toolbar": return "toolbars"
  case "menuBar": return "menuBars"
  case "menu": return "menus"
  case "alert": return "alerts"
  case "sheet": return "sheets"
  case "popover": return "popovers"
  case "window": return "windows"
  case "webView": return "webViews"
  case "picker": return "pickers"
  case "datePicker": return "datePickers"
  case "view": return "otherElements"
  default: throw MacroError.invalidContainer
  }
}

func buildQuery(root: String, queryProp: String, locator: ParsedLocator?) -> String {
  switch locator {
  case nil:
    return "\(root).\(queryProp).firstMatch"
  case .id(let str, let index):
    let access = index.map { ".element(boundBy: \($0))" } ?? ".firstMatch"
    return "\(root).\(queryProp).matching(identifier: \(swiftStringLiteral(str)))\(access)"
  case .label(let str, let index):
    let access = index.map { ".element(boundBy: \($0))" } ?? ".firstMatch"
    return
      "\(root).\(queryProp).matching(NSPredicate(format: \"label == %@\", \(swiftStringLiteral(str))))\(access)"
  case .labelContains(let str, let index):
    let access = index.map { ".element(boundBy: \($0))" } ?? ".firstMatch"
    return
      "\(root).\(queryProp).matching(NSPredicate(format: \"label CONTAINS %@\", \(swiftStringLiteral(str))))\(access)"
  case .predicate(let str, let index):
    let access = index.map { ".element(boundBy: \($0))" } ?? ".firstMatch"
    return "\(root).\(queryProp).matching(NSPredicate(format: \(swiftStringLiteral(str))))\(access)"
  case .index(let n):
    return "\(root).\(queryProp).element(boundBy: \(n))"
  }
}

func swiftStringLiteral(_ value: String) -> String {
  String(reflecting: value)
}

/// Returns a host decl's access-level modifier as a keyword prefix like `"public "`.
///
/// Only `public` and `package` need explicit propagation: without them, generated
/// members default to internal and consumers of a public/package page object cannot
/// reach them. For `internal`, `fileprivate`, `private`, and the no-modifier case
/// we return `""` — emitted members stay at the enclosing scope's effective access
/// (internal or tighter), which keeps protocol-conformance rules happy even when
/// the host struct is declared `private` at file scope.
func accessLevelPrefix(from modifiers: DeclModifierListSyntax) -> String {
  for modifier in modifiers {
    switch modifier.name.tokenKind {
    case .keyword(.public), .keyword(.package):
      return "\(modifier.name.text) "
    default:
      continue
    }
  }
  return ""
}

/// Parses a string-literal value passed via a labeled argument
/// (e.g. `in: "parentScope"`) and returns the contained property name.
/// Returns `nil` if the label is absent; throws `invalidParentName` if the
/// expression is not a bare string literal.
func parseParentName(labeled label: String, from node: AttributeSyntax) throws -> String? {
  guard let args = node.arguments?.as(LabeledExprListSyntax.self) else { return nil }
  for arg in args where arg.label?.text == label {
    guard let name = extractString(from: arg.expression) else {
      throw invalidParentNameDiagnostic(for: arg.expression)
    }
    return name
  }
  return nil
}

func elementTypeToQueryProperty(_ name: String) throws -> String {
  switch name {
  case "textField": return "textFields"
  case "secureTextField": return "secureTextFields"
  case "button": return "buttons"
  case "staticText": return "staticTexts"
  case "image": return "images"
  case "cell": return "cells"
  case "toggle": return "switches"
  case "slider": return "sliders"
  case "segmentedControl": return "segmentedControls"
  case "datePicker": return "datePickers"
  case "picker": return "pickers"
  case "pickerWheel": return "pickerWheels"
  case "scrollView": return "scrollViews"
  case "table": return "tables"
  case "collectionView": return "collectionViews"
  case "navigationBar": return "navigationBars"
  case "tabBar": return "tabBars"
  case "toolbar": return "toolbars"
  case "activityIndicator": return "activityIndicators"
  case "progressIndicator": return "progressIndicators"
  case "alert": return "alerts"
  case "sheet": return "sheets"
  case "popover": return "popovers"
  case "menu": return "menus"
  case "menuItem": return "menuItems"
  case "menuBar": return "menuBars"
  case "window": return "windows"
  case "searchField": return "searchFields"
  case "textView": return "textViews"
  case "link": return "links"
  case "webView": return "webViews"
  case "other": return "otherElements"
  case "any": return "descendants(matching: .any)"
  case "outline": return "outlines"
  case "stepper": return "steppers"
  case "tab": return "tabs"
  case "checkBox": return "checkBoxes"
  case "radioButton": return "radioButtons"
  case "comboBox": return "comboBoxes"
  case "popUpButton": return "popUpButtons"
  case "disclosureTriangle": return "disclosureTriangles"
  default: throw MacroError.invalidElementType
  }
}

func buildMethod(action: String, propName: String, access: String = "") -> DeclSyntax? {
  let cap = propName.prefix(1).uppercased() + propName.dropFirst()
  switch action {
  case "tap":
    return """
      /// Taps the `\(raw: propName)` element.
      @discardableResult
      @MainActor
      \(raw: access)func tap\(raw: cap)() -> Self {
          \(raw: propName).tap()
          return self
      }
      """
  case "doubleTap":
    return """
      /// Double-taps the `\(raw: propName)` element.
      @discardableResult
      @MainActor
      \(raw: access)func doubleTap\(raw: cap)() -> Self {
          \(raw: propName).doubleTap()
          return self
      }
      """
  case "longPress":
    return """
      /// Long-presses the `\(raw: propName)` element (1 second).
      @discardableResult
      @MainActor
      \(raw: access)func longPress\(raw: cap)() -> Self {
          \(raw: propName).press(forDuration: 1)
          return self
      }
      """
  case "press":
    return """
      /// Presses the `\(raw: propName)` element for the given duration.
      @discardableResult
      @MainActor
      \(raw: access)func press\(raw: cap)(forDuration duration: TimeInterval) -> Self {
          \(raw: propName).press(forDuration: duration)
          return self
      }
      """
  case "twoFingerTap":
    return """
      /// Performs a two-finger tap on the `\(raw: propName)` element.
      @discardableResult
      @MainActor
      \(raw: access)func twoFingerTap\(raw: cap)() -> Self {
          \(raw: propName).twoFingerTap()
          return self
      }
      """
  case "rightClick":
    return """
      /// Sends a Control-click (right-click) to the `\(raw: propName)` element.
      @discardableResult
      @MainActor
      \(raw: access)func rightClick\(raw: cap)() -> Self {
          \(raw: propName).rightClick()
          return self
      }
      """
  case "hover":
    return """
      /// Moves the pointer over the `\(raw: propName)` element.
      @discardableResult
      @MainActor
      \(raw: access)func hover\(raw: cap)() -> Self {
          \(raw: propName).hover()
          return self
      }
      """
  case "pinch":
    return """
      /// Performs a pinch on the `\(raw: propName)` element with the given scale and velocity.
      @discardableResult
      @MainActor
      \(raw: access)func pinch\(raw: cap)(withScale scale: CGFloat, velocity: CGFloat) -> Self {
          \(raw: propName).pinch(withScale: scale, velocity: velocity)
          return self
      }
      """
  case "rotate":
    return """
      /// Rotates the `\(raw: propName)` element by the given rotation (radians) and velocity.
      @discardableResult
      @MainActor
      \(raw: access)func rotate\(raw: cap)(_ rotation: CGFloat, withVelocity velocity: CGFloat) -> Self {
          \(raw: propName).rotate(rotation, withVelocity: velocity)
          return self
      }
      """
  case "swipeUp":
    return """
      /// Swipes up on the `\(raw: propName)` element.
      @discardableResult
      @MainActor
      \(raw: access)func swipeUp\(raw: cap)() -> Self {
          \(raw: propName).swipeUp()
          return self
      }
      """
  case "swipeDown":
    return """
      /// Swipes down on the `\(raw: propName)` element.
      @discardableResult
      @MainActor
      \(raw: access)func swipeDown\(raw: cap)() -> Self {
          \(raw: propName).swipeDown()
          return self
      }
      """
  case "swipeLeft":
    return """
      /// Swipes left on the `\(raw: propName)` element.
      @discardableResult
      @MainActor
      \(raw: access)func swipeLeft\(raw: cap)() -> Self {
          \(raw: propName).swipeLeft()
          return self
      }
      """
  case "swipeRight":
    return """
      /// Swipes right on the `\(raw: propName)` element.
      @discardableResult
      @MainActor
      \(raw: access)func swipeRight\(raw: cap)() -> Self {
          \(raw: propName).swipeRight()
          return self
      }
      """
  case "scrollToVisible":
    return """
      /// Scrolls until `\(raw: propName)` is hittable inside the nearest scroll container in `app`.
      /// Override `in:` to pin the scroll container (for nested scroll views or @Scope roots).
      @discardableResult
      @MainActor
      \(raw: access)func scrollToVisible\(raw: cap)(in container: XCUIElement? = nil, axis: PageAssertions.ScrollAxis = .vertical, timeout: TimeInterval = 5, maxSwipes: Int = 10) -> Self {
          if let container {
              PageAssertions.scrollToVisible(\(raw: propName), in: container, axis: axis, timeout: timeout, maxSwipes: maxSwipes)
          } else {
              PageAssertions.scrollToVisible(\(raw: propName), in: app, axis: axis, timeout: timeout, maxSwipes: maxSwipes)
          }
          return self
      }
      """
  case "adjustSliderPosition":
    return """
      /// Adjusts `\(raw: propName)` to the given normalized slider position (0...1).
      @discardableResult
      @MainActor
      \(raw: access)func adjust\(raw: cap)SliderPosition(_ position: CGFloat) -> Self {
          \(raw: propName).adjust(toNormalizedSliderPosition: position)
          return self
      }
      """
  case "adjustPickerWheelValue":
    return """
      /// Adjusts `\(raw: propName)` to the given picker-wheel value.
      @discardableResult
      @MainActor
      \(raw: access)func adjust\(raw: cap)PickerWheelValue(_ value: String) -> Self {
          \(raw: propName).adjust(toPickerWheelValue: value)
          return self
      }
      """
  case "typeText":
    return """
      /// Types `text` into the `\(raw: propName)` element.
      @discardableResult
      @MainActor
      \(raw: access)func typeTextInto\(raw: cap)(_ text: String) -> Self {
          \(raw: propName).typeText(text)
          return self
      }
      """
  case "clearText":
    return """
      /// Clears all text from the `\(raw: propName)` element.
      @discardableResult
      @MainActor
      \(raw: access)func clear\(raw: cap)() -> Self {
          \(raw: propName).clearText()
          return self
      }
      """
  case "assertExists":
    return """
      /// Asserts that `\(raw: propName)` exists. Pass `timeout` to wait up to that many seconds before asserting.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)Exists(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
          \(raw: propName).assertExists(timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertNotExists":
    return """
      /// Asserts that `\(raw: propName)` does not exist. Pass `timeout` to wait for it to disappear first.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)NotExists(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
          \(raw: propName).assertNotExists(timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertDisappear":
    return """
      /// Waits for `\(raw: propName)` to disappear, then asserts it is gone.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)Disappear(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
          \(raw: propName).assertDisappear(timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertEnabled":
    return """
      /// Asserts that `\(raw: propName)` is enabled. Pass `timeout` to poll until the condition is met.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)Enabled(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
          \(raw: propName).assertEnabled(timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertDisabled":
    return """
      /// Asserts that `\(raw: propName)` is disabled. Pass `timeout` to poll until the condition is met.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)Disabled(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
          \(raw: propName).assertDisabled(timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertSelected":
    return """
      /// Asserts that `\(raw: propName)` is selected. Pass `timeout` to poll until the condition is met.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)Selected(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
          \(raw: propName).assertSelected(timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertNotSelected":
    return """
      /// Asserts that `\(raw: propName)` is not selected. Pass `timeout` to poll until the condition is met.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)NotSelected(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
          \(raw: propName).assertNotSelected(timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertLabel":
    return """
      /// Asserts that `\(raw: propName)`'s label equals `expected`. Pass `timeout` to wait for the label first.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)Label(_ expected: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
          \(raw: propName).assertLabel(expected, timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertValue":
    return """
      /// Asserts that `\(raw: propName)`'s value equals `expected`. Pass `timeout` to wait for the value first.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)Value(_ expected: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
          \(raw: propName).assertValue(expected, timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertPlaceholder":
    return """
      /// Asserts that `\(raw: propName)`'s placeholder equals `expected`. Pass `timeout` to wait for the placeholder first.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)Placeholder(_ expected: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
          \(raw: propName).assertPlaceholder(expected, timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertExistsThrowing":
    return """
      /// Asserts that `\(raw: propName)` exists within `timeout`; throws ``PageTimeoutError`` otherwise.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)ExistsThrowing(timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) throws(PageTimeoutError) -> Self {
          try \(raw: propName).assertExistsOrThrow(timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertDisappearThrowing":
    return """
      /// Waits for `\(raw: propName)` to disappear within `timeout`; throws ``PageTimeoutError`` otherwise.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)DisappearThrowing(timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) throws(PageTimeoutError) -> Self {
          try \(raw: propName).assertDisappearOrThrow(timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertLabelThrowing":
    return """
      /// Asserts that `\(raw: propName)`'s label equals `expected` within `timeout`; throws ``PageTimeoutError`` otherwise.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)LabelThrowing(_ expected: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) throws(PageTimeoutError) -> Self {
          try \(raw: propName).assertLabelOrThrow(expected, timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertValueThrowing":
    return """
      /// Asserts that `\(raw: propName)`'s value equals `expected` within `timeout`; throws ``PageTimeoutError`` otherwise.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)ValueThrowing(_ expected: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) throws(PageTimeoutError) -> Self {
          try \(raw: propName).assertValueOrThrow(expected, timeout: timeout, file: file, line: line)
          return self
      }
      """
  case "assertPlaceholderThrowing":
    return """
      /// Asserts that `\(raw: propName)`'s placeholder equals `expected` within `timeout`; throws ``PageTimeoutError`` otherwise.
      @discardableResult
      @MainActor
      \(raw: access)func assert\(raw: cap)PlaceholderThrowing(_ expected: String, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) throws(PageTimeoutError) -> Self {
          try \(raw: propName).assertPlaceholderOrThrow(expected, timeout: timeout, file: file, line: line)
          return self
      }
      """
  default:
    return nil
  }
}

let supportedActions: Set<String> = [
  "tap",
  "doubleTap",
  "longPress",
  "press",
  "twoFingerTap",
  "rightClick",
  "hover",
  "pinch",
  "rotate",
  "swipeUp",
  "swipeDown",
  "swipeLeft",
  "swipeRight",
  "scrollToVisible",
  "adjustSliderPosition",
  "adjustPickerWheelValue",
  "typeText",
  "clearText",
  "assertExists",
  "assertNotExists",
  "assertDisappear",
  "assertEnabled",
  "assertDisabled",
  "assertSelected",
  "assertNotSelected",
  "assertValue",
  "assertLabel",
  "assertPlaceholder",
  "assertExistsThrowing",
  "assertDisappearThrowing",
  "assertLabelThrowing",
  "assertValueThrowing",
  "assertPlaceholderThrowing",
]

enum MacroError: Error, CustomStringConvertible {
  case invalidArguments
  case invalidElementType
  case invalidLocator
  case invalidContainer
  case invalidAction

  var description: String {
    switch self {
    case .invalidArguments:
      return "Macro requires at least an element type argument"
    case .invalidElementType:
      return "First argument must be an ElementType member (for example, .button)"
    case .invalidLocator:
      return "Second argument must be a Locator expression (for example, .id(\"login\"))"
    case .invalidContainer:
      return "`scope:` must be a ContainerType expression (for example, .scrollView(id: \"form\"))"
    case .invalidAction:
      return "`actions:` must contain valid ElementAction members"
    }
  }
}
