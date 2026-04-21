/// Describes how to locate an element within a query.
///
/// Pass as the second argument to `@Element`:
///
/// ```swift
/// @Element(.textField,    .id("email"))
/// @Element(.staticText,   .label("Welcome"))
/// @Element(.staticText,   .labelContains("Welcome"))
/// @Element(.cell,         .predicate("enabled == true AND label CONTAINS 'Item'"))
/// @Element(.button,       .index(2))                   // third button in scope
/// @Element(.button,       .id("ok", index: 1))         // second "ok" button
/// ```
public enum Locator: Sendable {
    /// Matches by accessibility identifier. `index` disambiguates when multiple elements share the same id.
    case id(String, index: Int? = nil)
    /// Matches by exact accessibility label using `NSPredicate(format: "label == %@", ...)`.
    case label(String, index: Int? = nil)
    /// Matches by accessibility label substring using `NSPredicate(format: "label CONTAINS %@", ...)`.
    case labelContains(String, index: Int? = nil)
    /// Matches using a raw NSPredicate format string (e.g. `"enabled == true AND value BEGINSWITH 'foo'"`).
    case predicate(String, index: Int? = nil)
    /// Selects the nth element (zero-based) with no string filter.
    case index(Int)
}
