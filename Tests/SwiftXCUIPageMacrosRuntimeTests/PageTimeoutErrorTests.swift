#if canImport(XCTest)
  import Foundation
  import Testing
  @testable import SwiftXCUIPageMacros

  @Suite
  struct PageTimeoutErrorTests {
    @Test
    func pageTimeoutErrorAndExpectationAreSendable() {
      requireSendable(PageTimeoutError.self)
      requireSendable(PageTimeoutError.Expectation.self)
    }

    @Test
    func elementTypeAndContainerTypeAreSendable() {
      requireSendable(ElementType.self)
      requireSendable(ContainerType.self)
    }

    @Test
    func descriptionRendersForEveryExpectation() {
      let cases: [(PageTimeoutError.Expectation, String)] = [
        (.exists, "to exist"),
        (.disappears, "to disappear"),
        (.hasLabel("Submit"), "to have label \"Submit\""),
        (.hasValue("42"), "to have value \"42\""),
        (.predicate("enabled == true"), "to match predicate enabled == true"),
      ]

      for (expectation, clause) in cases {
        let error = PageTimeoutError(
          elementDescription: "Button(id: \"submit\")",
          waited: 1.5,
          expectation: expectation
        )
        let description = error.description
        #expect(description.contains("1.5"))
        #expect(description.contains("Button(id: \"submit\")"))
        #expect(description.contains(clause))
      }
    }
  }

  private func requireSendable<T: Sendable>(_ type: T.Type) {}
#endif
