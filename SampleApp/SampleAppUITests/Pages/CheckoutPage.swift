import SwiftXCUIPageMacros
import XCTest

@Page(scope: .scrollView(id: "checkoutScroll"))
struct CheckoutPage<Origin: VerifiablePageObject>: OriginTrackedPage {
  let origin: Origin

  init(app: XCUIApplication, origin: Origin) {
    self.app = app
    self.origin = origin
  }

  init(app: XCUIApplication) {
    self.init(app: app, origin: Origin(app: app))
  }

  @Element(.staticText, .id("total"), verify: true)
  var grandTotal: XCUIElement

  @Scope(.collectionView(id: "checkoutResults"))
  var resultsRegion: XCUIElement

  @Element(.staticText, .id("total"), in: "resultsRegion")
  var firstLineTotal: XCUIElement
}
