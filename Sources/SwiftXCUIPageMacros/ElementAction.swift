/// Actions that can be generated as fluent helper methods on a Page Object.
///
/// Pass to `@Element(actions:)` to specify which methods are generated.
/// If `actions:` is omitted, a sensible default set is chosen per element type.
public enum ElementAction: Sendable, CaseIterable {
  // MARK: - Gestures
  case tap
  case doubleTap
  case longPress
  case press
  case twoFingerTap
  case rightClick
  case hover
  case pinch
  case rotate
  case swipeUp
  case swipeDown
  case swipeLeft
  case swipeRight
  case scrollToVisible
  case adjustSliderPosition
  case adjustPickerWheelValue

  // MARK: - Text input
  case typeText
  case clearText

  // MARK: - Assertions
  case assertExists
  case assertNotExists
  case assertDisappear
  case assertEnabled
  case assertDisabled
  case assertSelected
  case assertNotSelected
  case assertValue
  case assertLabel
  case assertPlaceholder
  case assertExistsThrowing
  case assertDisappearThrowing
  case assertLabelThrowing
  case assertValueThrowing
  case assertPlaceholderThrowing
}
