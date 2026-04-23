#if canImport(XCTest)
  import XCTest

  @MainActor
  public protocol PageObject {
    var app: XCUIApplication { get }
    init(app: XCUIApplication)
  }

  extension PageObject {
    /// Sets `launchArguments` / `launchEnvironment` on the page's app, then launches it.
    /// Returns `self` for chaining. Both values are always assigned: passing an empty
    /// array or dictionary clears any state set by a previous `launch(...)` call on
    /// the same `XCUIApplication` instance; non-empty values overwrite.
    @MainActor
    @discardableResult
    public func launch(
      arguments: [String] = [],
      environment: [String: String] = [:]
    ) -> Self {
      app.launchArguments = arguments
      app.launchEnvironment = environment
      app.launch()
      return self
    }

    /// Captures a whole-app screenshot of the page's app and returns it as an
    /// `XCTAttachment` with `.keepAlways` lifetime. By default the attachment is
    /// added to the current `XCTContext` activity so it appears in the Xcode test
    /// report. Pass `autoAttach: false` for the legacy behavior (return only).
    @MainActor
    @discardableResult
    public func snapshot(named name: String? = nil, autoAttach: Bool = true) -> XCTAttachment {
      app.snapshot(named: name, autoAttach: autoAttach)
    }
  }

  @MainActor
  public protocol VerifiablePageObject: PageObject {
    @discardableResult
    func verifyDefaultScreen(
      timeout: TimeInterval?,
      file: StaticString,
      line: UInt
    ) -> Self

    /// Returns `true` when every element the page considers part of its readiness contract
    /// currently exists. Used by `PageNavigation.open(..., retries:)` as the retry probe.
    /// The default implementation returns `true`; the `@Page` macro generates a concrete
    /// implementation when at least one `@Element(verify: true)` is declared.
    func isReady() -> Bool
  }

  extension VerifiablePageObject {
    public func isReady() -> Bool { true }
  }

  @MainActor
  public protocol OriginTrackedPage: VerifiablePageObject {
    associatedtype Origin: VerifiablePageObject
    var origin: Origin { get }
  }

  @MainActor
  public enum PageNavigation {
    @discardableResult
    static func performOpen<Application, Origin, Destination>(
      using application: Application,
      origin: Origin,
      timeout: TimeInterval?,
      retries: Int,
      backoff: TimeInterval,
      file: StaticString,
      line: UInt,
      perform action: () -> Void,
      destination build: (Application, Origin) -> Destination,
      verify: (Destination, TimeInterval?, StaticString, UInt) -> Destination,
      existsCheck: (Destination) -> Bool
    ) throws(OpenFailure) -> Destination {
      let totalAttempts = max(1, retries + 1)
      var lastDestination: Destination?
      let started = Date()

      for attempt in 1...totalAttempts {
        action()
        let destination = build(application, origin)
        lastDestination = destination

        if waitUntilReady(destination, timeout: timeout, existsCheck: existsCheck) {
          return verify(destination, timeout, file, line)
        }

        if attempt < totalAttempts && backoff > 0 {
          Thread.sleep(forTimeInterval: backoff)
        }
      }

      let description =
        lastDestination.map { String(describing: type(of: $0)) }
        ?? String(describing: Destination.self)
      throw OpenFailure(
        attempts: totalAttempts,
        underlying: PageTimeoutError(
          elementDescription: description,
          waited: Date().timeIntervalSince(started),
          expectation: .exists
        )
      )
    }

    private static func waitUntilReady<Destination>(
      _ destination: Destination,
      timeout: TimeInterval?,
      existsCheck: (Destination) -> Bool
    ) -> Bool {
      if existsCheck(destination) { return true }
      guard let timeout, timeout > 0 else { return false }

      let deadline = Date().addingTimeInterval(timeout)
      while Date() < deadline {
        let interval = min(0.05, max(0, deadline.timeIntervalSinceNow))
        if interval > 0 {
          RunLoop.current.run(until: Date().addingTimeInterval(interval))
        }
        if existsCheck(destination) { return true }
      }
      return false
    }

    @discardableResult
    static func performReturn<Origin>(
      to origin: Origin,
      timeout: TimeInterval?,
      file: StaticString,
      line: UInt,
      perform action: () -> Void,
      verify: (Origin, TimeInterval?, StaticString, UInt) -> Origin
    ) -> Origin {
      action()
      return verify(origin, timeout, file, line)
    }

    @discardableResult
    public static func open<Origin: PageObject, Destination: VerifiablePageObject>(
      from origin: Origin,
      to destinationType: Destination.Type = Destination.self,
      timeout: TimeInterval? = nil,
      retries: Int = 0,
      backoff: TimeInterval = 0.25,
      file: StaticString = #filePath,
      line: UInt = #line,
      perform action: @MainActor () -> Void
    ) throws(OpenFailure) -> Destination {
      try performOpen(
        using: origin.app,
        origin: origin,
        timeout: timeout,
        retries: retries,
        backoff: backoff,
        file: file,
        line: line,
        perform: action,
        destination: { application, _ in
          destinationType.init(app: application)
        },
        verify: { destination, timeout, file, line in
          destination.verifyDefaultScreen(timeout: timeout, file: file, line: line)
        },
        existsCheck: { destination in
          destination.isReady()
        }
      )
    }

    @discardableResult
    public static func open<Origin: PageObject, Destination: VerifiablePageObject>(
      from origin: Origin,
      timeout: TimeInterval? = nil,
      retries: Int = 0,
      backoff: TimeInterval = 0.25,
      file: StaticString = #filePath,
      line: UInt = #line,
      perform action: @MainActor () -> Void,
      destination build: @MainActor (XCUIApplication) -> Destination
    ) throws(OpenFailure) -> Destination {
      try performOpen(
        using: origin.app,
        origin: origin,
        timeout: timeout,
        retries: retries,
        backoff: backoff,
        file: file,
        line: line,
        perform: action,
        destination: { application, _ in
          build(application)
        },
        verify: { destination, timeout, file, line in
          destination.verifyDefaultScreen(timeout: timeout, file: file, line: line)
        },
        existsCheck: { destination in
          destination.isReady()
        }
      )
    }

    @discardableResult
    public static func open<Origin: VerifiablePageObject, Destination: OriginTrackedPage>(
      from origin: Origin,
      timeout: TimeInterval? = nil,
      retries: Int = 0,
      backoff: TimeInterval = 0.25,
      file: StaticString = #filePath,
      line: UInt = #line,
      perform action: @MainActor () -> Void,
      destination build: @MainActor (XCUIApplication, Origin) -> Destination
    ) throws(OpenFailure) -> Destination where Destination.Origin == Origin {
      try performOpen(
        using: origin.app,
        origin: origin,
        timeout: timeout,
        retries: retries,
        backoff: backoff,
        file: file,
        line: line,
        perform: action,
        destination: build,
        verify: { destination, timeout, file, line in
          destination.verifyDefaultScreen(timeout: timeout, file: file, line: line)
        },
        existsCheck: { destination in
          destination.isReady()
        }
      )
    }

    @discardableResult
    public static func returnToOrigin<Page: OriginTrackedPage>(
      from page: Page,
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line,
      perform action: @MainActor () -> Void
    ) -> Page.Origin {
      performReturn(
        to: page.origin,
        timeout: timeout,
        file: file,
        line: line,
        perform: action,
        verify: { origin, timeout, file, line in
          origin.verifyDefaultScreen(timeout: timeout, file: file, line: line)
        }
      )
    }
  }
#endif
