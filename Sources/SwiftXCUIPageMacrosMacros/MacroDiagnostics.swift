import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct MacroDiagnosticError: Error {
  let diagnostic: Diagnostic
}

func invalidLocatorDiagnostic(for node: some SyntaxProtocol) -> MacroDiagnosticError {
  MacroDiagnosticError(
    diagnostic: Diagnostic(
      node: node,
      message: MacroExpansionErrorMessage(MacroError.invalidLocator.description),
      fixIt: .replace(
        message: MacroExpansionFixItMessage("Replace with .id(\"<#identifier#>\")"),
        oldNode: node,
        newNode: ExprSyntax(stringLiteral: #".id("<#identifier#>")"#)
      )
    )
  )
}

func invalidContainerDiagnostic(for node: some SyntaxProtocol) -> MacroDiagnosticError {
  MacroDiagnosticError(
    diagnostic: Diagnostic(
      node: node,
      message: MacroExpansionErrorMessage(MacroError.invalidContainer.description),
      fixIt: .replace(
        message: MacroExpansionFixItMessage("Replace with .scrollView(id: \"<#identifier#>\")"),
        oldNode: node,
        newNode: ExprSyntax(stringLiteral: #".scrollView(id: "<#identifier#>")"#)
      )
    )
  )
}

func invalidActionDiagnostic(for node: some SyntaxProtocol) -> MacroDiagnosticError {
  MacroDiagnosticError(
    diagnostic: Diagnostic(
      node: node,
      message: MacroExpansionErrorMessage(MacroError.invalidAction.description),
      fixIt: .replace(
        message: MacroExpansionFixItMessage("Replace with [.tap]"),
        oldNode: node,
        newNode: ExprSyntax(stringLiteral: "[.tap]")
      )
    )
  )
}

func bundleIgnoredWithCustomInitDiagnostic(for node: some SyntaxProtocol) -> Diagnostic {
  Diagnostic(
    node: node,
    message: MacroExpansionWarningMessage(
      "`bundle:` is ignored because this struct declares its own initializer"
    )
  )
}

func conflictingScopeLocatorsDiagnostic(
  for node: some SyntaxProtocol,
  containerTypeName: String,
  id: String?,
  label: String?,
  index: Int?
) -> MacroDiagnosticError {
  // Preserve the first locator the user actually supplied (preference
  // id > label > index), so the fix-it doesn't discard valid intent
  // when the conflict involved label/index only.
  let fixItLabel: String
  let replacement: String
  if let id {
    fixItLabel = "Keep only `id:` and drop the others"
    replacement = ".\(containerTypeName)(id: \(swiftStringLiteral(id)))"
  } else if let label {
    fixItLabel = "Keep only `label:` and drop the others"
    replacement = ".\(containerTypeName)(label: \(swiftStringLiteral(label)))"
  } else if let index {
    fixItLabel = "Keep only `index:` and drop the others"
    replacement = ".\(containerTypeName)(index: \(index))"
  } else {
    fixItLabel = "Keep only `id:` and drop the others"
    replacement = ".\(containerTypeName)(id: \"<#identifier#>\")"
  }
  return MacroDiagnosticError(
    diagnostic: Diagnostic(
      node: node,
      message: MacroExpansionErrorMessage(
        "`scope:` accepts at most one of `id:`, `label:`, `index:` — pick one"
      ),
      fixIt: .replace(
        message: MacroExpansionFixItMessage(fixItLabel),
        oldNode: node,
        newNode: ExprSyntax(stringLiteral: replacement)
      )
    )
  )
}

func nonLiteralVerifyWarning(
  for node: some SyntaxProtocol,
  propertyName: String
) -> Diagnostic {
  Diagnostic(
    node: node,
    message: MacroExpansionWarningMessage(
      "`verify:` on `\(propertyName)` is not a `true`/`false` literal, so "
        + "`\(propertyName)` is excluded from the generated `isReady()` readiness probe. "
        + "Use `verify: true` to include it."
    )
  )
}

func invalidContainerLocatorDiagnostic(
  for node: some SyntaxProtocol,
  label: String
) -> MacroDiagnosticError {
  let expected = label == "index" ? "an integer literal" : "a plain string literal"
  return MacroDiagnosticError(
    diagnostic: Diagnostic(
      node: node,
      message: MacroExpansionErrorMessage(
        "`\(label):` in a container scope must be \(expected) — the macro "
          + "evaluates it at expansion time and cannot see interpolation or variables."
      )
    )
  )
}

func invalidParentNameDiagnostic(for node: some SyntaxProtocol) -> MacroDiagnosticError {
  MacroDiagnosticError(
    diagnostic: Diagnostic(
      node: node,
      message: MacroExpansionErrorMessage(
        "`in:` must be a plain string literal naming another property on the same type (for example, `in: \"parentScope\"`)."
      ),
      fixIt: .replace(
        message: MacroExpansionFixItMessage("Replace with a string literal"),
        oldNode: node,
        newNode: ExprSyntax(stringLiteral: #""<#parent#>""#)
      )
    )
  )
}
