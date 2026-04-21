import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct ScopeMacro: AccessorMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    guard
      let args = node.arguments?.as(LabeledExprListSyntax.self),
      let firstArg = args.first
    else {
      throw MacroError.invalidArguments
    }

    let container: ParsedContainer
    do {
      container = try parseContainerExpr(firstArg.expression)
    } catch let error as MacroDiagnosticError {
      context.diagnose(error.diagnostic)
      return []
    }

    if container.locatorCount > 1 {
      context.diagnose(
        conflictingScopeLocatorsDiagnostic(
          for: firstArg.expression,
          containerTypeName: container.typeName,
          id: container.id,
          label: container.label,
          index: container.index
        ).diagnostic
      )
      return []
    }

    let parent: String?
    do {
      parent = try parseParentName(labeled: "in", from: node)
    } catch let error as MacroDiagnosticError {
      context.diagnose(error.diagnostic)
      return []
    }

    let queryProp = try containerTypeToQueryProperty(container.typeName)
    let locator: ParsedLocator? = {
      if let id = container.id { return .id(id, index: container.index) }
      if let label = container.label { return .label(label, index: container.index) }
      if let index = container.index { return .index(index) }
      return nil
    }()

    let root = parent ?? "_scope"
    let query = buildQuery(root: root, queryProp: queryProp, locator: locator)
    let accessor: AccessorDeclSyntax = """
      @MainActor
      get {
          \(raw: query)
      }
      """
    return [accessor]
  }
}
