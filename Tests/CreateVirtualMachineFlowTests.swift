import XCTest

@testable import phas

final class CreateVirtualMachineFlowTests: XCTestCase {
  private struct StubHostSnapshotProvider: HostMachineSnapshotProviding {
    let currentSnapshot: HostMachineSnapshot

    func snapshot() -> HostMachineSnapshot {
      currentSnapshot
    }
  }

  private var fileManager: FileManager!
  private var temporaryRootURL: URL!

  override func setUpWithError() throws {
    try super.setUpWithError()
    fileManager = FileManager()
    temporaryRootURL = fileManager.temporaryDirectory.appendingPathComponent(
      UUID().uuidString, isDirectory: true)
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

  func testValidatorBlocksSecondVMAndExplicitX86Image() throws {
    let validator = makeValidator()
    let request = try makeRequest(fileName: "ubuntu-24.04-amd64.iso")
    let existingRecord = makeExistingRecord()

    let report = validator.validate(request: request, existingRecords: [existingRecord])

    XCTAssertFalse(report.canCreate)
    XCTAssertTrue(report.blockingIssues.contains(where: { $0.id == "single-vm" }))
    XCTAssertTrue(report.blockingIssues.contains(where: { $0.id == "iso-arch" }))
  }

  func testValidatorAllowsUnverifiedArmImageWithWarning() throws {
    let validator = makeValidator()
    let request = try makeRequest(fileName: "my-lab-linux-arm64.iso")

    let report = validator.validate(request: request, existingRecords: [])

    XCTAssertTrue(report.canCreate)
    XCTAssertEqual(report.inferredDistributionSupport, .unverified)
    XCTAssertTrue(report.warnings.contains(where: { $0.id == "distribution-unverified" }))
  }

  func testCreateUseCaseBootstrapsDraftBundleWhenAdmissionPasses() throws {
    let validator = makeValidator()
    let resolver = VirtualMachineBundleRootResolver(
      fileManager: fileManager,
      baseDirectoryURL: temporaryRootURL.appendingPathComponent("Bundles", isDirectory: true))
    let bundleStore = VirtualMachineBundleStore(fileManager: fileManager, rootResolver: resolver)
    let useCase = CreateVirtualMachineUseCase(
      bundleStore: bundleStore,
      admissionValidator: validator,
      now: { Date(timeIntervalSince1970: 1_700_000_100) }
    )
    let request = try makeRequest(fileName: "ubuntu-24.04-arm64.iso")

    let record = try useCase.execute(request: request, existingRecords: [])
    let storedRecords = try bundleStore.listRecords()

    XCTAssertEqual(record.state, .draft)
    XCTAssertEqual(record.distributionSupport, .primaryValidated)
    XCTAssertEqual(storedRecords.count, 1)
    XCTAssertEqual(storedRecords.first?.name, request.trimmedName)
  }

  func testCreateUseCaseDoesNotWriteBundleWhenBlocked() throws {
    let validator = makeValidator()
    let resolver = VirtualMachineBundleRootResolver(
      fileManager: fileManager,
      baseDirectoryURL: temporaryRootURL.appendingPathComponent("Bundles", isDirectory: true))
    let bundleStore = VirtualMachineBundleStore(fileManager: fileManager, rootResolver: resolver)
    let useCase = CreateVirtualMachineUseCase(
      bundleStore: bundleStore, admissionValidator: validator)
    let request = CreateVirtualMachineRequest(
      name: "",
      installImagePath: temporaryRootURL.appendingPathComponent("missing.iso").path,
      resources: VirtualMachineResources(cpuCount: 1, memoryMiB: 1024, diskGiB: 8)
    )

    XCTAssertThrowsError(try useCase.execute(request: request, existingRecords: []))
    XCTAssertTrue(try bundleStore.listRecords().isEmpty)
  }

  private func makeValidator() -> VirtualMachineAdmissionValidator {
    VirtualMachineAdmissionValidator(
      fileManager: fileManager,
      hostSnapshotProvider: StubHostSnapshotProvider(
        currentSnapshot: HostMachineSnapshot(
          architecture: .appleSilicon,
          operatingSystemVersion: HostOperatingSystemVersion(major: 14, minor: 5, patch: 0),
          totalMemoryBytes: 16 * 1_073_741_824,
          activeCPUCount: 8,
          availableDiskBytes: 200 * 1_073_741_824
        ))
    )
  }

  private func makeRequest(fileName: String) throws -> CreateVirtualMachineRequest {
    let url = temporaryRootURL.appendingPathComponent(fileName, isDirectory: false)
    fileManager.createFile(atPath: url.path, contents: Data("fake-iso".utf8))
    return CreateVirtualMachineRequest(
      name: "Ubuntu Draft",
      installImagePath: url.path,
      resources: VirtualMachineResources(cpuCount: 4, memoryMiB: 8 * 1024, diskGiB: 64)
    )
  }

  private func makeExistingRecord() -> VirtualMachineRecord {
    let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
    return VirtualMachineRecord(
      id: VirtualMachineID(rawValue: "existing-vm"),
      name: "Existing VM",
      installImagePath: "/tmp/existing.iso",
      resources: VirtualMachineResources(cpuCount: 4, memoryMiB: 8 * 1024, diskGiB: 64),
      bootSource: .installationImage,
      distributionSupport: .primaryValidated,
      state: .draft,
      createdAt: timestamp,
      updatedAt: timestamp
    )
  }
}
