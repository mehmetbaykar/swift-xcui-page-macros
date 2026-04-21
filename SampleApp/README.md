# SampleApp

End-to-end demo for the `SwiftXCUIPageMacros` library. A small SwiftUI
auth-flow app exercised by XCUITest page objects generated with `@Page`,
`@Element`, and `@Scope`.

## Demo

<video src="https://github.com/mehmetbaykar/swift-xcui-page-macros/raw/main/SampleApp/auth-flow-demo.mp4" controls muted playsinline width="640"></video>

Library docs: [root README](../README.md).

## Run the UI tests

```bash
xcodebuild test \
  -project SampleApp/SampleApp.xcodeproj \
  -scheme SampleApp \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4'
```

## Layout

- `SampleApp/` — SwiftUI app (`ContentView` + per-screen files: `SplashScreen`, `LoginScreen`, `SignUpScreen`, `CheckoutScreen`, `FlowPathLabel`).
- `SampleAppUITests/` — XCUITest target with page objects under `Pages/` (`SplashPage`, `LoginPage`, `SignUpPage`, `CheckoutPage`) and `LoginFlowTests` driving the full flow.
