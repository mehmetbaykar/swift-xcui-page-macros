import Foundation
import Testing

@testable import SwiftXCUIPageMacros

@Suite
@MainActor
struct PageNavigationTests {
  @Test
  func openConvenienceVerifiesDestinationAndPreservesApplication() throws {
    let recorder = VerificationRecorder()
    let application = ApplicationSession()
    let origin = LinearOriginPage(app: application, recorder: recorder)
    let timeout = 2.5
    let expectedLine: UInt = #line + 1

    let destination = try PageNavigation.performOpen(
      using: origin.app,
      origin: origin,
      timeout: timeout,
      retries: 0,
      backoff: 0,
      file: #filePath,
      line: expectedLine,
      perform: {
        recorder.events.append("openLinearDestination")
      },
      destination: { application, _ in
        LinearDestinationPage(app: application, recorder: recorder)
      },
      verify: { destination, timeout, file, line in
        destination.verify(timeout: timeout, file: file, line: line)
      },
      existsCheck: { _ in true }
    )

    #expect(destination.app === origin.app)
    #expect(recorder.events == ["openLinearDestination", "linearDestination"])
    #expect(recorder.lastTimeout == timeout)
    #expect(recorder.lastLine == expectedLine)
  }

  @Test
  func backToOriginReturnsExactOriginType() throws {
    let recorder = VerificationRecorder()
    let application = ApplicationSession()
    let splash = SplashTestPage(app: application, recorder: recorder)

    let returnedPage =
      try splash
      .openLogin()
      .backToOrigin()

    #expect(returnedPage.app === splash.app)
    #expect(recorder.events == ["openLogin", "login", "backFromLogin", "splash"])
  }

  @Test
  func branchingCompositionCanReenterAnotherRoute() throws {
    let recorder = VerificationRecorder()
    let application = ApplicationSession()
    let splash = SplashTestPage(app: application, recorder: recorder)

    let signUp =
      try splash
      .openLogin()
      .backToOrigin()
      .openSignUp()

    #expect(signUp.app === splash.app)
    #expect(
      recorder.events == [
        "openLogin",
        "login",
        "backFromLogin",
        "splash",
        "openSignUp",
        "signUp",
      ]
    )
  }

  @Test
  func openThrowsOpenFailureAfterRetriesExhausted() {
    let recorder = VerificationRecorder()
    let application = ApplicationSession()
    let origin = LinearOriginPage(app: application, recorder: recorder)
    let retries = 2

    do {
      _ = try PageNavigation.performOpen(
        using: origin.app,
        origin: origin,
        timeout: nil,
        retries: retries,
        backoff: 0,
        file: #filePath,
        line: #line,
        perform: {
          recorder.events.append("attempt")
        },
        destination: { application, _ in
          LinearDestinationPage(app: application, recorder: recorder)
        },
        verify: { destination, timeout, file, line in
          destination.verify(timeout: timeout, file: file, line: line)
        },
        existsCheck: { _ in false }
      )
      Issue.record("Expected PageNavigation.performOpen to throw OpenFailure")
    } catch {
      #expect(error.attempts == retries + 1)
      if case .exists = error.underlying.expectation {
        // ok
      } else {
        Issue.record("Expected .exists expectation, got \(error.underlying.expectation)")
      }
      #expect(recorder.events == ["attempt", "attempt", "attempt"])
    }
  }

  @Test
  func openVerifiesOnlyAfterReadinessProbeSucceeds() throws {
    let recorder = VerificationRecorder()
    let application = ApplicationSession()
    let origin = LinearOriginPage(app: application, recorder: recorder)
    var readinessChecks = 0

    let destination = try PageNavigation.performOpen(
      using: origin.app,
      origin: origin,
      timeout: nil,
      retries: 2,
      backoff: 0,
      file: #filePath,
      line: #line,
      perform: {
        recorder.events.append("attempt")
      },
      destination: { application, _ in
        LinearDestinationPage(app: application, recorder: recorder)
      },
      verify: { destination, timeout, file, line in
        destination.verify(timeout: timeout, file: file, line: line)
      },
      existsCheck: { _ in
        readinessChecks += 1
        return readinessChecks == 3
      }
    )

    #expect(destination.app === origin.app)
    #expect(readinessChecks == 3)
    #expect(recorder.events == ["attempt", "attempt", "attempt", "linearDestination"])
  }

  @Test
  func openWithoutRetriesDoesNotVerifyWhenReadinessProbeFails() {
    let recorder = VerificationRecorder()
    let application = ApplicationSession()
    let origin = LinearOriginPage(app: application, recorder: recorder)

    do {
      _ = try PageNavigation.performOpen(
        using: origin.app,
        origin: origin,
        timeout: nil,
        retries: 0,
        backoff: 0,
        file: #filePath,
        line: #line,
        perform: {
          recorder.events.append("attempt")
        },
        destination: { application, _ in
          LinearDestinationPage(app: application, recorder: recorder)
        },
        verify: { destination, timeout, file, line in
          destination.verify(timeout: timeout, file: file, line: line)
        },
        existsCheck: { _ in false }
      )
      Issue.record("Expected PageNavigation.performOpen to throw OpenFailure")
    } catch {
      #expect(error.attempts == 1)
      #expect(recorder.events == ["attempt"])
    }
  }
}

@MainActor
private final class ApplicationSession {}

@MainActor
private protocol VerifiableOrigin {
  var app: ApplicationSession { get }

  @discardableResult
  func verify(
    timeout: TimeInterval?,
    file: StaticString,
    line: UInt
  ) -> Self
}

@MainActor
private final class VerificationRecorder {
  var events: [String] = []
  var lastTimeout: TimeInterval?
  var lastFile: StaticString?
  var lastLine: UInt?
}

@MainActor
private struct LinearOriginPage {
  let app: ApplicationSession
  let recorder: VerificationRecorder

  init(app: ApplicationSession, recorder: VerificationRecorder) {
    self.app = app
    self.recorder = recorder
  }
}

@MainActor
private struct LinearDestinationPage {
  let app: ApplicationSession
  let recorder: VerificationRecorder

  init(app: ApplicationSession, recorder: VerificationRecorder) {
    self.app = app
    self.recorder = recorder
  }

  @discardableResult
  func verify(
    timeout: TimeInterval? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> Self {
    recorder.events.append("linearDestination")
    recorder.lastTimeout = timeout
    recorder.lastFile = file
    recorder.lastLine = line
    return self
  }
}

@MainActor
private struct SplashTestPage: VerifiableOrigin {
  let app: ApplicationSession
  let recorder: VerificationRecorder

  init(app: ApplicationSession, recorder: VerificationRecorder) {
    self.app = app
    self.recorder = recorder
  }

  @discardableResult
  func verify(
    timeout: TimeInterval? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> Self {
    recorder.events.append("splash")
    recorder.lastTimeout = timeout
    recorder.lastFile = file
    recorder.lastLine = line
    return self
  }

  func openLogin() throws(OpenFailure) -> LoginTestPage<Self> {
    let timeout = 5.0
    return try PageNavigation.performOpen(
      using: app,
      origin: self,
      timeout: timeout,
      retries: 0,
      backoff: 0,
      file: #filePath,
      line: #line,
      perform: {
        recorder.events.append("openLogin")
      },
      destination: { application, origin in
        LoginTestPage(app: application, origin: origin, recorder: recorder)
      },
      verify: { destination, timeout, file, line in
        destination.verify(timeout: timeout, file: file, line: line)
      },
      existsCheck: { _ in true }
    )
  }

  func openSignUp() throws(OpenFailure) -> SignUpTestPage<Self> {
    let timeout = 5.0
    return try PageNavigation.performOpen(
      using: app,
      origin: self,
      timeout: timeout,
      retries: 0,
      backoff: 0,
      file: #filePath,
      line: #line,
      perform: {
        recorder.events.append("openSignUp")
      },
      destination: { application, origin in
        SignUpTestPage(app: application, origin: origin, recorder: recorder)
      },
      verify: { destination, timeout, file, line in
        destination.verify(timeout: timeout, file: file, line: line)
      },
      existsCheck: { _ in true }
    )
  }
}

@MainActor
private struct LoginTestPage<Origin: VerifiableOrigin> {
  let app: ApplicationSession
  let origin: Origin
  let recorder: VerificationRecorder

  init(app: ApplicationSession, origin: Origin, recorder: VerificationRecorder) {
    self.app = app
    self.origin = origin
    self.recorder = recorder
  }

  @discardableResult
  func verify(
    timeout: TimeInterval? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> Self {
    recorder.events.append("login")
    recorder.lastTimeout = timeout
    recorder.lastFile = file
    recorder.lastLine = line
    return self
  }

  func backToOrigin() -> Origin {
    PageNavigation.performReturn(
      to: origin,
      timeout: 5,
      file: #filePath,
      line: #line,
      perform: {
        recorder.events.append("backFromLogin")
      },
      verify: { origin, timeout, file, line in
        origin.verify(timeout: timeout, file: file, line: line)
      }
    )
  }
}

@MainActor
private struct SignUpTestPage<Origin: VerifiableOrigin> {
  let app: ApplicationSession
  let origin: Origin
  let recorder: VerificationRecorder

  init(app: ApplicationSession, origin: Origin, recorder: VerificationRecorder) {
    self.app = app
    self.origin = origin
    self.recorder = recorder
  }

  @discardableResult
  func verify(
    timeout: TimeInterval? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> Self {
    recorder.events.append("signUp")
    recorder.lastTimeout = timeout
    recorder.lastFile = file
    recorder.lastLine = line
    return self
  }
}
