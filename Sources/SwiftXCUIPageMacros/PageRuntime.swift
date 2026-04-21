#if canImport(XCTest)
  import XCTest

  @MainActor
  public enum PageAssertions {
    /// Direction ``PageAssertions/scrollToVisible(_:in:axis:timeout:maxSwipes:)``
    /// swipes the container while waiting for an element to become hittable.
    public enum ScrollAxis: Sendable {
      case vertical
      case horizontal
    }

    public static func assertElementsExist(
      _ elements: [XCUIElement],
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      for element in elements {
        element.assertExists(timeout: timeout, file: file, line: line)
      }
    }

    /// Varargs convenience forwarder for ``assertElementsExist(_:timeout:file:line:)``.
    public static func assertElementsExist(
      _ elements: XCUIElement...,
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      assertElementsExist(elements, timeout: timeout, file: file, line: line)
    }

    /// Scrolls the nearest scroll/table/collection/outline container under `app`
    /// up to `maxSwipes` times along `axis`, waiting up to `timeout` seconds in
    /// total for `element.isHittable` to become true.
    public static func scrollToVisible(
      _ element: XCUIElement,
      in app: XCUIApplication,
      axis: ScrollAxis = .vertical,
      timeout: TimeInterval = 5,
      maxSwipes: Int = 10
    ) {
      let container = activeScrollContainer(in: app)
      scrollToVisible(
        element,
        in: container,
        axis: axis,
        timeout: timeout,
        maxSwipes: maxSwipes
      )
    }

    /// Scrolls `container` up to `maxSwipes` times along `axis`, waiting up to
    /// `timeout` seconds in total for `element.isHittable` to become true.
    ///
    /// Unlike the `XCUIApplication`-rooted overload, this overload performs no
    /// app-global search — swipes are applied directly to `container`. Pass
    /// `_scope`, a `@Scope` property, or any `XCUIElement` that represents the
    /// scrollable region.
    public static func scrollToVisible(
      _ element: XCUIElement,
      in container: XCUIElement,
      axis: ScrollAxis = .vertical,
      timeout: TimeInterval = 5,
      maxSwipes: Int = 10
    ) {
      guard element.exists else { return }
      if element.isHittable { return }

      let deadline = Date().addingTimeInterval(timeout)
      let perSwipeBudget = maxSwipes > 0 ? (timeout / TimeInterval(maxSwipes)) : timeout
      var remainingSwipes = maxSwipes

      while !element.isHittable && remainingSwipes > 0 && Date() < deadline {
        switch axis {
        case .vertical:
          container.swipeUp()
        case .horizontal:
          container.swipeLeft()
        }
        remainingSwipes -= 1

        if element.isHittable { break }

        let waitBudget = min(perSwipeBudget, max(0, deadline.timeIntervalSinceNow))
        if waitBudget > 0 {
          let predicate = NSPredicate(format: "isHittable == true")
          let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
          _ = XCTWaiter().wait(for: [expectation], timeout: waitBudget)
        }
      }
    }

    private static func activeScrollContainer(in app: XCUIApplication) -> XCUIElement {
      let candidates = [
        app.scrollViews.firstMatch,
        app.tables.firstMatch,
        app.collectionViews.firstMatch,
        app.outlines.firstMatch,
      ]

      return candidates.first(where: \.exists) ?? app
    }
  }

  @MainActor
  extension XCUIElement {
    /// Captures a screenshot of this element and returns it as an `XCTAttachment`
    /// with `.keepAlways` lifetime. By default the attachment is added to the
    /// current `XCTContext` activity so it appears in the Xcode test report.
    /// Pass `autoAttach: false` for the legacy behavior (return only; caller
    /// is responsible for attaching via `XCTContext.runActivity` or
    /// `XCTestCase.add(_:)`).
    @discardableResult
    public func snapshot(named name: String? = nil, autoAttach: Bool = true) -> XCTAttachment {
      let attachment = XCTAttachment(screenshot: screenshot())
      attachment.name = name
      attachment.lifetime = .keepAlways
      if autoAttach {
        XCTContext.runActivity(named: name ?? "Snapshot") { activity in
          activity.add(attachment)
        }
      }
      return attachment
    }

    @discardableResult
    public func clearText() -> XCUIElement {
      guard let currentText = value as? String, !currentText.isEmpty else { return self }
      tap()
      typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentText.count))
      return self
    }

    public func assertExists(
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      if let timeout {
        XCTAssertTrue(waitForExistence(timeout: timeout), file: file, line: line)
      } else {
        XCTAssertTrue(exists, file: file, line: line)
      }
    }

    /// Throwing variant of ``assertExists(timeout:file:line:)`` that reports a
    /// ``PageTimeoutError`` when the element does not appear within `timeout`.
    ///
    /// Named with an `OrThrow` suffix so it does not shadow the non-throwing
    /// overload; in a `throws` calling context Swift would otherwise prefer the
    /// throwing variant and force callers to write `try` on the non-throwing
    /// call. `timeout: 0` performs a single existence check and throws
    /// immediately on mismatch — no wait loop.
    @discardableResult
    public func assertExistsOrThrow(
      timeout: TimeInterval,
      file: StaticString = #filePath,
      line: UInt = #line
    ) throws(PageTimeoutError) -> XCUIElement {
      precondition(timeout >= 0, "timeout must be non-negative")
      if waitForExistence(timeout: timeout) { return self }
      throw PageTimeoutError(
        elementDescription: debugDescription,
        waited: timeout,
        expectation: .exists
      )
    }

    public func assertNotExists(
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      wait(until: NSPredicate(format: "exists == false"), timeout: timeout)
      XCTAssertFalse(exists, file: file, line: line)
    }

    public func assertDisappear(
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      assertNotExists(timeout: timeout, file: file, line: line)
    }

    /// Throwing variant of ``assertDisappear(timeout:file:line:)`` that reports a
    /// ``PageTimeoutError`` when the element does not disappear within `timeout`.
    @discardableResult
    public func assertDisappearOrThrow(
      timeout: TimeInterval,
      file: StaticString = #filePath,
      line: UInt = #line
    ) throws(PageTimeoutError) -> XCUIElement {
      try waitOrThrow(
        NSPredicate(format: "exists == false"),
        timeout: timeout,
        expectation: .disappears
      )
      return self
    }

    public func assertEnabled(
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      wait(until: NSPredicate(format: "enabled == true"), timeout: timeout)
      XCTAssertTrue(isEnabled, file: file, line: line)
    }

    public func assertDisabled(
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      wait(until: NSPredicate(format: "enabled == false"), timeout: timeout)
      XCTAssertFalse(isEnabled, file: file, line: line)
    }

    public func assertSelected(
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      wait(until: NSPredicate(format: "selected == true"), timeout: timeout)
      XCTAssertTrue(isSelected, file: file, line: line)
    }

    public func assertNotSelected(
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      wait(until: NSPredicate(format: "selected == false"), timeout: timeout)
      XCTAssertFalse(isSelected, file: file, line: line)
    }

    public func assertLabel(
      _ expected: String,
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      wait(until: NSPredicate(format: "label == %@", expected), timeout: timeout)
      XCTAssertEqual(label, expected, file: file, line: line)
    }

    /// Throwing variant of ``assertLabel(_:timeout:file:line:)`` that reports a
    /// ``PageTimeoutError`` when the predicate wait times out.
    @discardableResult
    public func assertLabelOrThrow(
      _ expected: String,
      timeout: TimeInterval,
      file: StaticString = #filePath,
      line: UInt = #line
    ) throws(PageTimeoutError) -> XCUIElement {
      try waitOrThrow(
        NSPredicate(format: "label == %@", expected),
        timeout: timeout,
        expectation: .hasLabel(expected)
      )
      return self
    }

    public func assertValue(
      _ expected: String,
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      wait(until: NSPredicate(format: "value == %@", expected), timeout: timeout)
      XCTAssertEqual(value as? String ?? "", expected, file: file, line: line)
    }

    /// Throwing variant of ``assertValue(_:timeout:file:line:)`` that reports a
    /// ``PageTimeoutError`` when the predicate wait times out.
    @discardableResult
    public func assertValueOrThrow(
      _ expected: String,
      timeout: TimeInterval,
      file: StaticString = #filePath,
      line: UInt = #line
    ) throws(PageTimeoutError) -> XCUIElement {
      try waitOrThrow(
        NSPredicate(format: "value == %@", expected),
        timeout: timeout,
        expectation: .hasValue(expected)
      )
      return self
    }

    public func assertPlaceholder(
      _ expected: String,
      timeout: TimeInterval? = nil,
      file: StaticString = #filePath,
      line: UInt = #line
    ) {
      wait(until: NSPredicate(format: "placeholderValue == %@", expected), timeout: timeout)
      XCTAssertEqual(placeholderValue, expected, file: file, line: line)
    }

    /// Throwing variant of ``assertPlaceholder(_:timeout:file:line:)`` that waits
    /// for `placeholderValue == expected` up to `timeout` seconds and throws
    /// ``PageTimeoutError`` on mismatch.
    @discardableResult
    public func assertPlaceholderOrThrow(
      _ expected: String,
      timeout: TimeInterval,
      file: StaticString = #filePath,
      line: UInt = #line
    ) throws(PageTimeoutError) -> XCUIElement {
      try waitOrThrow(
        NSPredicate(format: "placeholderValue == %@", expected),
        timeout: timeout,
        expectation: .predicate("placeholderValue == \(expected)")
      )
      return self
    }

    private func wait(until predicate: NSPredicate, timeout: TimeInterval?) {
      guard let timeout else { return }

      let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
      _ = XCTWaiter().wait(for: [expectation], timeout: timeout)
    }

    private func waitOrThrow(
      _ predicate: NSPredicate,
      timeout: TimeInterval,
      expectation: PageTimeoutError.Expectation
    ) throws(PageTimeoutError) {
      precondition(timeout >= 0, "timeout must be non-negative")
      let predicateExpectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
      let result = XCTWaiter().wait(for: [predicateExpectation], timeout: timeout)
      guard result != .completed else { return }
      throw PageTimeoutError(
        elementDescription: debugDescription,
        waited: timeout,
        expectation: expectation
      )
    }
  }
#endif
