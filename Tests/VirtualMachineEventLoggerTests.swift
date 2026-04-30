import XCTest

@testable import phas

final class VirtualMachineEventLoggerTests: XCTestCase {
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

  func testLoggerAppendsStructuredEntries() throws {
    let logger = VirtualMachineEventLogger(
      fileManager: fileManager,
      hostSystemVersionProvider: { "macOS 14.5.0" }
    )
    let layout = VirtualMachineBundleLayout(
      rootURL: temporaryRootURL.appendingPathComponent("vm-log.vmbundle", isDirectory: true))
    let record = makeRecord()

    try logger.append(
      event: .startRequested, summary: "Starting install boot.", record: record, layout: layout)
    try logger.append(
      event: .guestStopped, summary: "Guest powered off.", record: record, layout: layout)

    let contents = try String(contentsOf: logger.logFileURL(for: layout))
    let lines = contents.split(separator: "\n")

    XCTAssertEqual(lines.count, 2)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let firstEntry = try decoder.decode(VirtualMachineLogEntry.self, from: Data(lines[0].utf8))

    XCTAssertEqual(firstEntry.event, .startRequested)
    XCTAssertEqual(firstEntry.vmID, record.id.rawValue)
    XCTAssertEqual(firstEntry.bootSource, record.bootSource.rawValue)
    XCTAssertEqual(firstEntry.appVersion, BuildInfo.appVersion)
    XCTAssertEqual(firstEntry.hostSystemVersion, "macOS 14.5.0")
  }

  private func makeRecord() -> VirtualMachineRecord {
    let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
    return VirtualMachineRecord(
      id: VirtualMachineID(rawValue: "vm-log"),
      name: "Ubuntu",
      installImagePath: "/tmp/ubuntu.iso",
      resources: VirtualMachineResources(cpuCount: 4, memoryMiB: 8 * 1024, diskGiB: 64),
      bootSource: .installationImage,
      distributionSupport: .primaryValidated,
      state: .draft,
      createdAt: timestamp,
      updatedAt: timestamp
    )
  }
}
