import Virtualization
import XCTest

@testable import phas

final class VirtualMachineConfigurationFactoryTests: XCTestCase {
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

  func testInstallConfigurationAttachesISOAndCreatesNVRAM() throws {
    let factory = makeFactory()
    let isoURL = try makeInstallMedia(named: "ubuntu-24.04-arm64.img")
    let record = makeRecord(
      state: .draft, bootSource: .installationImage, installImagePath: isoURL.path)

    let prepared = try factory.prepareConfiguration(for: record)

    XCTAssertEqual(prepared.launchPlan.nextState, .installing)
    XCTAssertEqual(prepared.configuration.storageDevices.count, 2)
    XCTAssertTrue(fileManager.fileExists(atPath: prepared.layout.nvramURL.path))
    XCTAssertTrue(prepared.configuration.bootLoader is VZEFIBootLoader)
  }

  func testDiskBootConfigurationOmitsInstallMedia() throws {
    let factory = makeFactory()
    let record = makeRecord(state: .stopped, bootSource: .diskImage, installImagePath: nil)

    let prepared = try factory.prepareConfiguration(for: record)

    XCTAssertEqual(prepared.launchPlan.nextState, .running)
    XCTAssertEqual(prepared.configuration.storageDevices.count, 1)
  }

  func testFactoryReusesMachineIdentifierData() throws {
    let factory = makeFactory()
    let isoURL = try makeInstallMedia(named: "ubuntu-24.04-arm64.img")
    let record = makeRecord(
      state: .draft, bootSource: .installationImage, installImagePath: isoURL.path)

    let first = try factory.prepareConfiguration(for: record)
    let firstData = try Data(contentsOf: first.layout.machineIdentifierURL)
    let second = try factory.prepareConfiguration(for: record)
    let secondData = try Data(contentsOf: second.layout.machineIdentifierURL)

    XCTAssertEqual(firstData, secondData)
  }

  private func makeFactory() -> VirtualMachineConfigurationFactory {
    let rootResolver = VirtualMachineBundleRootResolver(
      fileManager: fileManager, baseDirectoryURL: temporaryRootURL)
    let bundleStore = VirtualMachineBundleStore(
      fileManager: fileManager, rootResolver: rootResolver)
    return VirtualMachineConfigurationFactory(
      bundleStore: bundleStore,
      machineIdentifierStore: MachineIdentifierStore(fileManager: fileManager),
      variableStoreManager: EFIVariableStoreManager(fileManager: fileManager),
      configurationValidator: { _ in }
    )
  }

  private func makeInstallMedia(named fileName: String) throws -> URL {
    let url = temporaryRootURL.appendingPathComponent(fileName, isDirectory: false)
    fileManager.createFile(atPath: url.path, contents: nil)
    let handle = try FileHandle(forWritingTo: url)
    try handle.truncate(atOffset: 8 * 1_024 * 1_024)
    try handle.close()
    return url
  }

  private func makeRecord(
    state: VirtualMachineState,
    bootSource: VirtualMachineBootSource,
    installImagePath: String?
  ) -> VirtualMachineRecord {
    let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
    return VirtualMachineRecord(
      id: VirtualMachineID(rawValue: "vm-config"),
      name: "Ubuntu",
      installImagePath: installImagePath,
      resources: VirtualMachineResources(cpuCount: 4, memoryMiB: 8 * 1024, diskGiB: 64),
      bootSource: bootSource,
      distributionSupport: .primaryValidated,
      state: state,
      createdAt: timestamp,
      updatedAt: timestamp
    )
  }
}
