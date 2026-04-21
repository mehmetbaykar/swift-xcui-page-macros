// swift-tools-version: 6.2
import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-xcui-page-macros",
  platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .visionOS(.v1)],
  products: [
    .library(name: "SwiftXCUIPageMacros", targets: ["SwiftXCUIPageMacros"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.5"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
  ],
  targets: [
    .macro(
      name: "SwiftXCUIPageMacrosMacros",
      dependencies: [
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "SwiftXCUIPageMacros",
      dependencies: ["SwiftXCUIPageMacrosMacros"]
    ),
    .testTarget(
      name: "SwiftXCUIPageMacrosMacroTests",
      dependencies: [
        "SwiftXCUIPageMacrosMacros",
        "SwiftXCUIPageMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftXCUIPageMacrosRuntimeTests",
      dependencies: ["SwiftXCUIPageMacros"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
