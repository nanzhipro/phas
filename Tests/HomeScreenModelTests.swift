import XCTest
@testable import phas

final class HomeScreenModelTests: XCTestCase {
    func testDefaultModelExposesCreateActionAndTargets() {
        let model = HomeScreenModel.default

        XCTAssertEqual(model.primaryActionTitle, "Create Virtual Machine")
        XCTAssertEqual(model.secondaryActionTitle, "Open Build Notes")
        XCTAssertEqual(model.acceptanceTargets.count, 3)
        XCTAssertTrue(model.supportMatrix.contains(where: { $0.contains(BuildInfo.primaryDistribution) }))
    }

    func testSidebarSectionsStayAnchoredToPhaseZeroShell() {
        let model = HomeScreenModel.default

        XCTAssertEqual(model.sidebarSections.count, 3)
        XCTAssertTrue(model.sidebarSections.contains(where: { $0.detail.contains("Phase-0") }))
        XCTAssertTrue(model.sidebarSections.contains(where: { $0.detail.contains("Single VM") }))
    }
}
