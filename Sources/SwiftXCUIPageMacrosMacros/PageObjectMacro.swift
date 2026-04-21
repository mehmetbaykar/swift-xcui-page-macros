import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct PageObjectMacro: MemberMacro, MemberAttributeMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard declaration.is(StructDeclSyntax.self) else {
      throw PageObjectMacroError.onlyApplicableToStruct
    }

    let bundleArg = findArg(labeled: "bundle", from: node)
    let bundleID = bundleArg.flatMap { extractStringLiteral(from: $0.expression) }
    let scopeArg = findArg(labeled: "scope", from: node)
    let container: ParsedContainer?
    do {
      container = try scopeArg.map { try parseContainerExpr($0.expression) }
    } catch let error as MacroDiagnosticError {
      context.diagnose(error.diagnostic)
      return []
    }

    if let container, let scopeArg,
      container.locatorCount > 1
    {
      context.diagnose(
        conflictingScopeLocatorsDiagnostic(
          for: scopeArg.expression,
          containerTypeName: container.typeName,
          id: container.id,
          label: container.label,
          index: container.index
        ).diagnostic
      )
      return []
    }

    if bundleID != nil, hasDeclaredInitializer(in: declaration), let bundleArg {
      context.diagnose(bundleIgnoredWithCustomInitDiagnostic(for: bundleArg))
    }

    // Mirror the host struct's access-level modifier onto every emitted member
    // so `@Page public struct ...` exports its synthesized members across modules.
    let access = accessLevelPrefix(from: declaration.modifiers)

    let appProperty: DeclSyntax = "\(raw: access)let app: XCUIApplication"

    // `_scope` is always generated so `@Element` / `@Scope` can root their queries somewhere.
    let scopeProperty: DeclSyntax
    if let container {
      let queryProp = try containerTypeToQueryProperty(container.typeName)
      let locator: ParsedLocator? = {
        if let id = container.id { return .id(id, index: container.index) }
        if let lbl = container.label { return .label(lbl, index: container.index) }
        if let n = container.index { return .index(n) }
        return nil
      }()
      let query = buildQuery(root: "app", queryProp: queryProp, locator: locator)
      scopeProperty = """
        @MainActor
        \(raw: access)var _scope: XCUIElement {
            \(raw: query)
        }
        """
    } else {
      scopeProperty = """
        @MainActor
        \(raw: access)var _scope: XCUIElement {
            app
        }
        """
    }

    var decls: [DeclSyntax] = [appProperty, scopeProperty]

    if !hasDeclaredInitializer(in: declaration) {
      let initWithApp: DeclSyntax = """
        \(raw: access)init(app: XCUIApplication) {
            self.app = app
        }
        """

      if let bundleID {
        let initDefault: DeclSyntax = """
          \(raw: access)init() {
              self.app = XCUIApplication(bundleIdentifier: "\(raw: bundleID)")
          }
          """
        decls.append(contentsOf: [initWithApp, initDefault])
      } else {
        let initDefault: DeclSyntax = """
          \(raw: access)init() {
              self.app = XCUIApplication()
          }
          """
        decls.append(contentsOf: [initWithApp, initDefault])
      }
    }

    let transitionMethod: DeclSyntax = """
      @MainActor
      \(raw: access)func transition<NextPage>(_ build: (XCUIApplication) -> NextPage) -> NextPage {
          build(app)
      }
      """
    decls.append(transitionMethod)

    let verifyProps = collectVerifyProps(from: declaration, in: context)
    if !verifyProps.isEmpty {
      let verifyList = verifyProps.joined(separator: ", ")
      let readinessExpr = verifyProps.map { "\($0).exists" }.joined(separator: " && ")
      let verifyMethod: DeclSyntax = """
        /// Asserts that all core elements of this page exist.
        /// Pass `timeout` to wait up to that many seconds for each element before asserting.
        @discardableResult
        @MainActor
        \(raw: access)func verifyDefaultScreen(timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> Self {
            PageAssertions.assertElementsExist([\(raw: verifyList)], timeout: timeout, file: file, line: line)
            return self
        }
        """
      let isReadyMethod: DeclSyntax = """
        /// Boolean readiness probe used by `PageNavigation.open(..., retries:)`.
        /// Returns `true` only when every `@Element(verify: true)` on this page currently exists.
        @MainActor
        \(raw: access)func isReady() -> Bool {
            \(raw: readinessExpr)
        }
        """
      decls.append(contentsOf: [verifyMethod, isReadyMethod])
    }

    return decls
  }

  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AttributeSyntax] {
    guard shouldAddMainActor(to: member) else { return [] }
    return ["@MainActor"]
  }

  // MARK: - Helpers

  private static func findArg(labeled label: String, from node: AttributeSyntax)
    -> LabeledExprSyntax?
  {
    guard let args = node.arguments?.as(LabeledExprListSyntax.self) else { return nil }
    return args.first { $0.label?.text == label }
  }

  private static func extractStringLiteral(from expr: ExprSyntax) -> String? {
    extractString(from: expr)
  }

  /// Collects property names of all `@Element`-annotated vars that have `verify: true`.
  /// Emits a warning diagnostic when `verify:` is not a `true`/`false` literal, because
  /// those properties are silently excluded from the generated `isReady()` probe.
  private static func collectVerifyProps(
    from declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) -> [String] {
    var result: [String] = []
    for member in declaration.memberBlock.members {
      guard
        let varDecl = member.decl.as(VariableDeclSyntax.self),
        let binding = varDecl.bindings.first,
        let namePattern = binding.pattern.as(IdentifierPatternSyntax.self)
      else { continue }

      for attrElement in varDecl.attributes {
        guard
          let attr = attrElement.as(AttributeSyntax.self),
          attr.attributeName.trimmedDescription == "Element",
          let args = attr.arguments?.as(LabeledExprListSyntax.self)
        else { continue }

        for arg in args where arg.label?.text == "verify" {
          if let boolLit = arg.expression.as(BooleanLiteralExprSyntax.self) {
            if boolLit.literal.text == "true" {
              result.append(namePattern.identifier.text)
            }
          } else {
            context.diagnose(
              nonLiteralVerifyWarning(
                for: arg.expression,
                propertyName: namePattern.identifier.text
              )
            )
          }
        }
      }
    }
    return result
  }

  private static func hasDeclaredInitializer(in declaration: some DeclGroupSyntax) -> Bool {
    declaration.memberBlock.members.contains { member in
      member.decl.is(InitializerDeclSyntax.self)
    }
  }

  private static func shouldAddMainActor(to member: some DeclSyntaxProtocol) -> Bool {
    if let function = member.as(FunctionDeclSyntax.self) {
      return !hasMainActorAttribute(function.attributes)
    }

    if let initializer = member.as(InitializerDeclSyntax.self) {
      return !hasMainActorAttribute(initializer.attributes)
    }

    if let subscriptDeclaration = member.as(SubscriptDeclSyntax.self) {
      return !hasMainActorAttribute(subscriptDeclaration.attributes)
    }

    if let variable = member.as(VariableDeclSyntax.self) {
      let hasComputedBinding = variable.bindings.contains { binding in
        binding.accessorBlock != nil
      }

      return hasComputedBinding && !hasMainActorAttribute(variable.attributes)
    }

    return false
  }

  private static func hasMainActorAttribute(_ attributes: AttributeListSyntax) -> Bool {
    attributes.contains { attribute in
      guard let attribute = attribute.as(AttributeSyntax.self) else { return false }
      return attribute.attributeName.trimmedDescription == "MainActor"
    }
  }

}

enum PageObjectMacroError: Error, CustomStringConvertible {
  case onlyApplicableToStruct

  var description: String {
    "@Page can only be applied to a struct"
  }
}
