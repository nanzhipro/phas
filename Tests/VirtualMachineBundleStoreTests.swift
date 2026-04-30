import XCTest
@testable import phas

final class VirtualMachineBundleStoreTests: XCTestCase {
    private var temporaryRootURL: URL!
    private var fileManager: FileManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        fileManager = FileManager()
        temporaryRootURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: temporaryRootURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryRootURL, fileManager.fileExists(atPath: temporaryRootURL.path) {
            try fileManager.removeItem(at: temporaryRootURL)
        }

        temporaryRootURL = nil
        fileManager = nil
        try super.tearDownWithError()
    }

    func testBootstrapCreatesBundleLayoutAndRoundTripsConfiguration() throws {
        let store = makeStore()
        let record = makeRecord()

        let layout = try store.bootstrapBundle(for: record)
        let loaded = try store.loadRecord(for: record.id)
        let machineIdentifier = try store.machineIdentifierStore.loadMachineIdentifier(at: layout.machineIdentifierURL)

        XCTAssertEqual(loaded, record)
        XCTAssertTrue(fileManager.fileExists(atPath: layout.rootURL.path))
        XCTAssertTrue(fileManager.fileExists(atPath: layout.logsDirectoryURL.path))
        XCTAssertTrue(fileManager.fileExists(atPath: layout.configurationURL.path))
        XCTAssertTrue(fileManager.fileExists(atPath: layout.diskImageURL.path))
        XCTAssertTrue(fileManager.fileExists(atPath: layout.machineIdentifierURL.path))
        XCTAssertEqual(machineIdentifier.dataRepresentation.count, 70)
    }

    func testBundleRootUsesFixedApplicationSupportLocationByDefault() {
        let resolver = VirtualMachineBundleRootResolver()
        let path = resolver.baseDirectoryURL.path

        XCTAssertTrue(path.hasSuffix("/Library/Application Support/phas/VMs"))
    }

    func testSparseDiskUsesRequestedLogicalSize() throws {
        let store = makeStore()
        let record = makeRecord(resources: VirtualMachineResources(cpuCount: 4, memoryMiB: 8 * 1024, diskGiB: 32))

        let layout = try store.bootstrapBundle(for: record)
        let resourceValues = try layout.diskImageURL.resourceValues(forKeys: [.fileSizeKey, .fileAllocatedSizeKey])

        XCTAssertEqual(resourceValues.fileSize, Int(record.resources.diskSizeBytes))
        if let allocatedSize = resourceValues.fileAllocatedSize, let fileSize = resourceValues.fileSize {
            XCTAssertLessThanOrEqual(allocatedSize, fileSize)
        }
    }

    func testDeleteRejectsPathsOutsideManagedBundleRoot() throws {
        let store = makeStore()
        let rogueURL = temporaryRootURL.appendingPathComponent("rogue", isDirectory: true)
        try fileManager.createDirectory(at: rogueURL, withIntermediateDirectories: true)

        XCTAssertThrowsError(try store.deleteBundle(at: rogueURL)) { error in
            guard case VirtualMachineBundleStoreError.unsupportedBundleURL(let rejectedURL) = error else {
                return XCTFail("unexpected error: \(error)")
            }

            XCTAssertEqual(rejectedURL.standardizedFileURL, rogueURL.standardizedFileURL)
        }

        XCTAssertTrue(fileManager.fileExists(atPath: rogueURL.path))
    }

    func testStatePermissionsReflectPRDRules() {
        XCTAssertTrue(VirtualMachineState.draft.allowsConfigurationEditing)
        XCTAssertTrue(VirtualMachineState.error.allowsConfigurationEditing)
        XCTAssertFalse(VirtualMachineState.installing.allowsConfigurationEditing)
        XCTAssertTrue(VirtualMachineState.installing.allowsInstallImageSelection)
        XCTAssertFalse(VirtualMachineState.stopped.allowsInstallImageSelection)
        XCTAssertFalse(VirtualMachineState.running.allowsInstallImageSelection)
    }

    private func makeStore() -> VirtualMachineBundleStore {
        let resolver = VirtualMachineBundleRootResolver(fileManager: fileManager, baseDirectoryURL: temporaryRootURL)
        return VirtualMachineBundleStore(fileManager: fileManager, rootResolver: resolver)
    }

    private func makeRecord(
        id: VirtualMachineID = VirtualMachineID(rawValue: "vm-001"),
        resources: VirtualMachineResources = VirtualMachineResources(cpuCount: 4, memoryMiB: 8 * 1024, diskGiB: 64)
    ) -> VirtualMachineRecord {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        return VirtualMachineRecord(
            id: id,
            name: "Ubuntu ARM64",
            installImagePath: "/tmp/ubuntu.iso",
            resources: resources,
            bootSource: .installationImage,
            distributionSupport: .primaryValidated,
            state: .draft,
            createdAt: timestamp,
            updatedAt: timestamp
        )
    }
}