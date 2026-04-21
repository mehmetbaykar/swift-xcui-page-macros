import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftXCUIPageMacrosPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    PageObjectMacro.self,
    ElementMacro.self,
    ScopeMacro.self,
  ]
}
