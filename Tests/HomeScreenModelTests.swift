import XCTest

@testable import phas

final class HomeScreenModelTests: XCTestCase {
  func testDefaultModelExposesPrimaryActionsAndHighlights() {
    let model = HomeScreenModel.default

    XCTAssertEqual(model.primaryActionTitle, "Create VM")
    XCTAssertEqual(model.secondaryActionTitle, "Open Storage")
    XCTAssertEqual(model.gettingStartedHighlights.count, 3)
    XCTAssertTrue(
      model.compatibilityHighlights.contains(where: { $0.contains(BuildInfo.primaryDistribution) }))
  }
}
