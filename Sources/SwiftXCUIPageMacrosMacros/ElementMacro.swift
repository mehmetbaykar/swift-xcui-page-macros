import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct ElementMacro: AccessorMacro, PeerMacro {

  // MARK: - AccessorMacro

  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    let params: ParsedElementParams
    let parent: String?
    do {
      params = try parseElementArgs(from: node)
      parent = try parseParentName(labeled: "in", from: node)
    } catch let error as MacroDiagnosticError {
      context.diagnose(error.diagnostic)
      return []
    }

    let root = parent ?? "_scope"
    let query = buildQuery(root: root, queryProp: params.queryProperty, locator: params.locator)
    let accessor: AccessorDeclSyntax = """
      @MainActor
      get {
          \(raw: query)
      }
      """
    return [accessor]
  }

  // MARK: - PeerMacro

  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard
      let varDecl = declaration.as(VariableDeclSyntax.self),
      let binding = varDecl.bindings.first,
      let namePattern = binding.pattern.as(IdentifierPatternSyntax.self)
    else { return [] }

    let propName = namePattern.identifier.text
    guard let params = try? parseElementArgs(from: node) else { return [] }
    let actions = params.actions ?? defaultActions(for: params.typeName)
    let access = accessLevelPrefix(from: varDecl.modifiers)

    return actions.compactMap { buildMethod(action: $0, propName: propName, access: access) }
  }

  // MARK: - Default actions per element type

  private static func defaultActions(for typeName: String) -> [String] {
    switch typeName {
    case "textField", "searchField", "comboBox":
      return ["tap", "typeText", "clearText", "assertExists", "assertValue", "assertPlaceholder"]
    case "secureTextField":
      return ["tap", "typeText", "clearText", "assertExists", "assertPlaceholder"]
    case "textView":
      return ["tap", "typeText", "clearText", "assertExists", "assertValue"]
    case "button", "link", "menuItem", "popUpButton", "disclosureTriangle", "tab":
      return ["tap", "assertExists", "assertEnabled", "assertDisabled"]
    case "staticText":
      return ["assertExists", "assertLabel"]
    case "cell":
      return ["tap", "assertExists"]
    case "toggle", "checkBox", "radioButton":
      return ["tap", "assertExists", "assertSelected", "assertNotSelected"]
    case "stepper", "slider":
      return ["assertExists", "assertValue"]
    case "scrollView", "table", "collectionView", "outline":
      return ["swipeUp", "swipeDown", "assertExists"]
    case "activityIndicator", "progressIndicator", "image", "window", "menuBar", "sheet", "popover",
      "alert", "menu":
      return ["assertExists"]
    default:
      return ["tap", "assertExists"]
    }
  }
}
