import Foundation
import Testing

@Suite("Package Test Conventions")
struct PackageTestConventionsTests {
  @Test("SwiftPM package tests use Swift Testing")
  func packageTestsUseSwiftTestingInsteadOfXCTest() throws {
    let rootDirectory = packageRootDirectory(from: #filePath)
    let testsDirectory = rootDirectory.appending(path: "Tests")
    let testFiles = try swiftFiles(in: testsDirectory)
    // `import XCTest` is allowed: tests may reference `XCUIElement` types even
    // when they themselves are authored with Swift Testing. The actual ban is
    // on XCTest's assertion + base-class machinery.
    let forbiddenMarkers = [
      ["XCTest", "Case"],
      ["XCT", "Assert"],
    ].map { $0.joined() }

    let violations = try testFiles.flatMap { fileURL in
      let source = try String(contentsOf: fileURL, encoding: .utf8)

      return forbiddenMarkers.compactMap { marker in
        source.contains(marker) ? "\(fileURL.lastPathComponent): \(marker)" : nil
      }
    }

    #expect(
      violations.isEmpty,
      """
      SwiftPM test targets must use Swift Testing. Found legacy XCTest usage:
      \(violations.joined(separator: "\n"))
      """
    )
  }
}

extension PackageTestConventionsTests {
  fileprivate func packageRootDirectory(from filePath: StaticString) -> URL {
    URL(filePath: "\(filePath)")
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
  }

  fileprivate func swiftFiles(in directory: URL) throws -> [URL] {
    let enumerator = FileManager.default.enumerator(
      at: directory,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    )

    var files: [URL] = []

    while let fileURL = enumerator?.nextObject() as? URL {
      guard fileURL.pathExtension == "swift" else { continue }
      files.append(fileURL)
    }

    return files.sorted { $0.path < $1.path }
  }
}
