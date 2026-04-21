#if canImport(XCTest)
  import XCTest

  /// Error thrown by the throwing overloads of ``XCUIElement`` assertions when a
  /// predicate wait expires. Carries enough context to produce an actionable
  /// failure message.
  public struct PageTimeoutError: Error, Sendable, CustomStringConvertible {
    public let elementDescription: String
    public let waited: TimeInterval
    public let expectation: Expectation

    public enum Expectation: Sendable {
      case exists
      case disappears
      case hasLabel(String)
      case hasValue(String)
      case predicate(String)
    }

    public init(elementDescription: String, waited: TimeInterval, expectation: Expectation) {
      self.elementDescription = elementDescription
      self.waited = waited
      self.expectation = expectation
    }

    public var description: String {
      let clause: String
      switch expectation {
      case .exists:
        clause = "to exist"
      case .disappears:
        clause = "to disappear"
      case .hasLabel(let expected):
        clause = "to have label \"\(expected)\""
      case .hasValue(let expected):
        clause = "to have value \"\(expected)\""
      case .predicate(let format):
        clause = "to match predicate \(format)"
      }
      return "Timed out after \(waited)s waiting for \(elementDescription) \(clause)"
    }
  }
#endif
