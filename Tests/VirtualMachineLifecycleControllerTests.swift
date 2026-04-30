import XCTest

@testable import phas

final class VirtualMachineLifecycleControllerTests: XCTestCase {
  private let controller = VirtualMachineLifecycleController()

  func testPreparingToStartInstallMediaMovesDraftToInstalling() throws {
    let record = makeRecord(state: .draft, bootSource: .installationImage)

    let updated = try controller.recordByPreparingToStart(
      record, at: Date(timeIntervalSince1970: 1_700_000_001))

    XCTAssertEqual(updated.state, .installing)
    XCTAssertEqual(updated.bootSource, .installationImage)
  }

  func testGuestStopAfterInstallSwitchesToDiskBoot() {
    let record = makeRecord(state: .installing, bootSource: .installationImage)

    let updated = controller.recordByHandlingGuestStop(
      record, at: Date(timeIntervalSince1970: 1_700_000_002))

    XCTAssertEqual(updated.state, .stopped)
    XCTAssertEqual(updated.bootSource, .diskImage)
  }

  func testPreparingToStartInstalledVMMovesToRunning() throws {
    let record = makeRecord(state: .stopped, bootSource: .diskImage)

    let updated = try controller.recordByPreparingToStart(
      record, at: Date(timeIntervalSince1970: 1_700_000_003))

    XCTAssertEqual(updated.state, .running)
    XCTAssertEqual(updated.bootSource, .diskImage)
  }

  func testRuntimeFailureMovesToError() {
    let record = makeRecord(state: .running, bootSource: .diskImage)

    let updated = controller.recordByHandlingRuntimeFailure(
      record, at: Date(timeIntervalSince1970: 1_700_000_004))

    XCTAssertEqual(updated.state, .error)
  }

  func testNetworkDisconnectMovesToError() {
    let record = makeRecord(state: .running, bootSource: .diskImage)

    let updated = controller.recordByHandlingNetworkDisconnect(
      record, at: Date(timeIntervalSince1970: 1_700_000_005))

    XCTAssertEqual(updated.state, .error)
  }

  private func makeRecord(state: VirtualMachineState, bootSource: VirtualMachineBootSource)
    -> VirtualMachineRecord
  {
    let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
    return VirtualMachineRecord(
      id: VirtualMachineID(rawValue: "vm-lifecycle"),
      name: "Ubuntu",
      installImagePath: "/tmp/ubuntu-arm64.iso",
      resources: VirtualMachineResources(cpuCount: 4, memoryMiB: 8 * 1024, diskGiB: 64),
      bootSource: bootSource,
      distributionSupport: .primaryValidated,
      state: state,
      createdAt: timestamp,
      updatedAt: timestamp
    )
  }
}
