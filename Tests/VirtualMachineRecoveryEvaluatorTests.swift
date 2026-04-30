import XCTest

@testable import phas

final class VirtualMachineRecoveryEvaluatorTests: XCTestCase {
  private let evaluator = VirtualMachineRecoveryEvaluator()

  func testTransientRuntimeStateWithoutLiveSessionMovesToError() {
    let record = makeRecord(state: .running)

    let evaluation = evaluator.evaluate(
      record: record,
      restoreRuntimeWindowRequested: true,
      hasLiveSession: false,
      at: Date(timeIntervalSince1970: 1_700_000_100)
    )

    XCTAssertEqual(evaluation.correctedRecord?.state, .error)
    XCTAssertEqual(evaluation.report?.severity, .error)
    XCTAssertEqual(evaluation.report?.actions.canRecoverToStopped, true)
    XCTAssertEqual(evaluation.report?.shouldRestoreRuntimeWindow, false)
  }

  func testStoppedRecordCanRestoreRuntimeWindowAfterRelaunch() {
    let record = makeRecord(state: .stopped)

    let evaluation = evaluator.evaluate(
      record: record,
      restoreRuntimeWindowRequested: true,
      hasLiveSession: false,
      at: Date(timeIntervalSince1970: 1_700_000_101)
    )

    XCTAssertNil(evaluation.correctedRecord)
    XCTAssertEqual(evaluation.report?.severity, .healthy)
    XCTAssertEqual(evaluation.report?.shouldRestoreRuntimeWindow, true)
    XCTAssertEqual(evaluation.report?.actions.canRetryStart, true)
  }

  func testErrorStateStaysRecoverableWithoutLiveSession() {
    let record = makeRecord(state: .error)

    let evaluation = evaluator.evaluate(
      record: record,
      restoreRuntimeWindowRequested: false,
      hasLiveSession: false,
      at: Date(timeIntervalSince1970: 1_700_000_102)
    )

    XCTAssertNil(evaluation.correctedRecord)
    XCTAssertEqual(evaluation.report?.severity, .warning)
    XCTAssertEqual(evaluation.report?.actions.canRetryStart, true)
    XCTAssertEqual(evaluation.report?.actions.canRecoverToStopped, true)
  }

  private func makeRecord(state: VirtualMachineState) -> VirtualMachineRecord {
    let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
    return VirtualMachineRecord(
      id: VirtualMachineID(rawValue: "vm-recovery"),
      name: "Ubuntu",
      installImagePath: "/tmp/ubuntu-arm64.img",
      resources: VirtualMachineResources(cpuCount: 4, memoryMiB: 8 * 1024, diskGiB: 64),
      bootSource: .diskImage,
      distributionSupport: .primaryValidated,
      state: state,
      createdAt: timestamp,
      updatedAt: timestamp
    )
  }
}
