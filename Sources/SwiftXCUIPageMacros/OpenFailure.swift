#if canImport(XCTest)
  import XCTest

  /// Error thrown by ``PageNavigation/open(from:to:timeout:retries:backoff:file:line:perform:)``
  /// (and its overloads) when all retry attempts fail to verify the destination
  /// screen. Wraps the final ``PageTimeoutError`` so callers can inspect the
  /// underlying timeout reason.
  public struct OpenFailure: Error, Sendable, CustomStringConvertible {
    public let attempts: Int
    public let underlying: PageTimeoutError

    public init(attempts: Int, underlying: PageTimeoutError) {
      self.attempts = attempts
      self.underlying = underlying
    }

    public var description: String {
      "PageNavigation.open failed after \(attempts) attempt(s): \(underlying)"
    }
  }
#endif
