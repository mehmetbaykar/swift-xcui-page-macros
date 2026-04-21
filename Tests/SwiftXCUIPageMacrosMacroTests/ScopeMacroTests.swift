#if os(macOS)
  import MacroTesting
  import Testing
  @testable import SwiftXCUIPageMacrosMacros

  @Suite(
    .macros(
      [
        "Scope": ScopeMacro.self
      ],
      record: .never
    )
  )
  struct ScopeMacroTests {
    @Test
    func scopeEmitsAccessorOffPageRoot() {
      assertMacro {
        """
        @Scope(.scrollView(id: "checkoutScroll"))
        var checkoutRegion: XCUIElement
        """
      } expansion: {
        """
        var checkoutRegion: XCUIElement {
            @MainActor
            get {
                _scope.scrollViews.matching(identifier: "checkoutScroll").firstMatch
            }
        }
        """
      }
    }

    @Test
    func scopeSupportsLabelAndIndex() {
      assertMacro {
        """
        @Scope(.scrollView(label: "Form"))
        var formScope: XCUIElement
        """
      } expansion: {
        """
        var formScope: XCUIElement {
            @MainActor
            get {
                _scope.scrollViews.matching(NSPredicate(format: "label == %@", "Form")).firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Scope(.scrollView(index: 0))
        var firstScroll: XCUIElement
        """
      } expansion: {
        """
        var firstScroll: XCUIElement {
            @MainActor
            get {
                _scope.scrollViews.element(boundBy: 0)
            }
        }
        """
      }
    }

    @Test
    func scopeSupportsEveryContainerType() {
      assertMacro {
        """
        @Scope(.table(id: "results"))
        var resultsRegion: XCUIElement
        """
      } expansion: {
        """
        var resultsRegion: XCUIElement {
            @MainActor
            get {
                _scope.tables.matching(identifier: "results").firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Scope(.alert(id: "confirm"))
        var confirmAlert: XCUIElement
        """
      } expansion: {
        """
        var confirmAlert: XCUIElement {
            @MainActor
            get {
                _scope.alerts.matching(identifier: "confirm").firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Scope(.view(id: "custom"))
        var customRegion: XCUIElement
        """
      } expansion: {
        """
        var customRegion: XCUIElement {
            @MainActor
            get {
                _scope.otherElements.matching(identifier: "custom").firstMatch
            }
        }
        """
      }
    }

    @Test
    func scopeNestsViaParentName() {
      assertMacro {
        """
        @Scope(.table(id: "results"), in: "checkoutRegion")
        var resultsRegion: XCUIElement
        """
      } expansion: {
        """
        var resultsRegion: XCUIElement {
            @MainActor
            get {
                checkoutRegion.tables.matching(identifier: "results").firstMatch
            }
        }
        """
      }
    }

    @Test
    func scopeSupportsNewContainerTypes() {
      assertMacro {
        """
        @Scope(.sheet(id: "s")) var sheetRegion: XCUIElement
        """
      } expansion: {
        """
        var sheetRegion: XCUIElement {
            @MainActor
            get {
                _scope.sheets.matching(identifier: "s").firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Scope(.popover(id: "p")) var popoverRegion: XCUIElement
        """
      } expansion: {
        """
        var popoverRegion: XCUIElement {
            @MainActor
            get {
                _scope.popovers.matching(identifier: "p").firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Scope(.window(id: "main")) var mainWindow: XCUIElement
        """
      } expansion: {
        """
        var mainWindow: XCUIElement {
            @MainActor
            get {
                _scope.windows.matching(identifier: "main").firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Scope(.outline(id: "tree")) var treeRegion: XCUIElement
        """
      } expansion: {
        """
        var treeRegion: XCUIElement {
            @MainActor
            get {
                _scope.outlines.matching(identifier: "tree").firstMatch
            }
        }
        """
      }

      assertMacro {
        """
        @Scope(.menu(id: "ctx")) var contextMenu: XCUIElement
        """
      } expansion: {
        """
        var contextMenu: XCUIElement {
            @MainActor
            get {
                _scope.menus.matching(identifier: "ctx").firstMatch
            }
        }
        """
      }
    }
  }
#endif
