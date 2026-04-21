/// A container element type used with `@Page(scope:)` or `@Scope`.
///
/// Only element types that can contain child elements are available here.
/// The locator (id, label, index) is embedded directly as associated values.
///
/// ```swift
/// @Page(scope: .scrollView(id: "loginScroll"))
/// struct LoginPage { ... }
///
/// @Scope(.table(id: "results"))
/// var resultsRegion: XCUIElement
/// ```
public enum ContainerType: Sendable {
  case scrollView(id: String? = nil, label: String? = nil, index: Int? = nil)
  case table(id: String? = nil, label: String? = nil, index: Int? = nil)
  case collectionView(id: String? = nil, label: String? = nil, index: Int? = nil)
  case outline(id: String? = nil, label: String? = nil, index: Int? = nil)
  case cell(id: String? = nil, label: String? = nil, index: Int? = nil)
  case navigationBar(id: String? = nil, label: String? = nil, index: Int? = nil)
  case tabBar(id: String? = nil, label: String? = nil, index: Int? = nil)
  case toolbar(id: String? = nil, label: String? = nil, index: Int? = nil)
  case menuBar(id: String? = nil, label: String? = nil, index: Int? = nil)
  case menu(id: String? = nil, label: String? = nil, index: Int? = nil)
  case alert(id: String? = nil, label: String? = nil, index: Int? = nil)
  case sheet(id: String? = nil, label: String? = nil, index: Int? = nil)
  case popover(id: String? = nil, label: String? = nil, index: Int? = nil)
  case window(id: String? = nil, label: String? = nil, index: Int? = nil)
  case webView(id: String? = nil, label: String? = nil, index: Int? = nil)
  case picker(id: String? = nil, label: String? = nil, index: Int? = nil)
  case datePicker(id: String? = nil, label: String? = nil, index: Int? = nil)
  case view(id: String? = nil, label: String? = nil, index: Int? = nil)
}
