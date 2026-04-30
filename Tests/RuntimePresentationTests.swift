import XCTest
@testable import phas

final class RuntimePresentationTests: XCTestCase {
    func testControlAvailabilityFallsBackToRecordStateBeforeSessionExists() {
        let draftRecord = makeRecord(state: .draft, bootSource: .installationImage)
        let runningRecord = makeRecord(state: .running, bootSource: .diskImage)

        let draftAvailability = RuntimeControlAvailability.make(record: draftRecord, capabilities: nil)
        let runningAvailability = RuntimeControlAvailability.make(record: runningRecord, capabilities: nil)

        XCTAssertTrue(draftAvailability.canOpenWindow)
        XCTAssertTrue(draftAvailability.canStart)
        XCTAssertFalse(draftAvailability.canRequestStop)
        XCTAssertFalse(draftAvailability.canForceStop)

        XCTAssertTrue(runningAvailability.canOpenWindow)
        XCTAssertFalse(runningAvailability.canStart)
        XCTAssertFalse(runningAvailability.canRequestStop)
        XCTAssertFalse(runningAvailability.canForceStop)
    }

    func testControlAvailabilityUsesRuntimeCapabilitiesWhenSessionExists() {
        let runningRecord = makeRecord(state: .running, bootSource: .diskImage)
        let availability = RuntimeControlAvailability.make(
            record: runningRecord,
            capabilities: RuntimeMachineCapabilities(canStart: false, canRequestStop: true, canForceStop: true)
        )

        XCTAssertTrue(availability.canOpenWindow)
        XCTAssertFalse(availability.canStart)
        XCTAssertTrue(availability.canRequestStop)
        XCTAssertTrue(availability.canForceStop)
    }

    func testRuntimeDetailSnapshotIncludesBundleLogsAndLatestMessage() {
        let record = makeRecord(state: .stopped, bootSource: .diskImage)
        let snapshot = VirtualMachineRuntimeDetailSnapshot(
            record: record,
            bundleURL: URL(fileURLWithPath: "/tmp/phas/VMs/vm-runtime.vmbundle"),
            logURL: URL(fileURLWithPath: "/tmp/phas/VMs/vm-runtime.vmbundle/logs/runtime.log"),
            latestMessage: "Guest stopped unexpectedly."
        )

        XCTAssertEqual(snapshot.title, "Ubuntu")
        XCTAssertEqual(snapshot.stateLine, "State: Stopped")
        XCTAssertTrue(snapshot.bundleLine.contains("vm-runtime.vmbundle"))
        XCTAssertTrue(snapshot.logsLine.contains("runtime.log"))
        XCTAssertEqual(snapshot.latestMessageLine, "Latest issue: Guest stopped unexpectedly.")
        XCTAssertTrue(snapshot.detailLines.contains(snapshot.bootSourceLine))
    }

    private func makeRecord(state: VirtualMachineState, bootSource: VirtualMachineBootSource) -> VirtualMachineRecord {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        return VirtualMachineRecord(
            id: VirtualMachineID(rawValue: "vm-runtime"),
            name: "Ubuntu",
            installImagePath: "/tmp/ubuntu-arm64.img",
            resources: VirtualMachineResources(cpuCount: 4, memoryMiB: 8 * 1024, diskGiB: 64),
            bootSource: bootSource,
            distributionSupport: .primaryValidated,
            state: state,
            createdAt: timestamp,
            updatedAt: timestamp
        )
    }
}