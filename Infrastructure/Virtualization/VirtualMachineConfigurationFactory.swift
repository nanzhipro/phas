import Foundation
import Virtualization

enum VirtualMachineConfigurationFactoryError: LocalizedError {
  case missingInstallImage(VirtualMachineID)
  case unreadableInstallImage(URL)
  case unsupportedNetworkMode(VirtualMachineNetworkMode)

  var errorDescription: String? {
    switch self {
    case .missingInstallImage(let id):
      return
        "VM \(id.rawValue) is configured to boot from installation media, but no ISO path is available."
    case .unreadableInstallImage(let url):
      return "The installation image is not readable at \(url.path)."
    case .unsupportedNetworkMode(let mode):
      return
        "The network mode \(mode.rawValue) is not supported by the current configuration factory."
    }
  }
}

struct PreparedVirtualMachineConfiguration {
  let configuration: VZVirtualMachineConfiguration
  let layout: VirtualMachineBundleLayout
  let launchPlan: VirtualMachineLaunchPlan
}

struct VirtualMachineConfigurationFactory {
  let bundleStore: VirtualMachineBundleStore
  let machineIdentifierStore: MachineIdentifierStore
  let variableStoreManager: EFIVariableStoreManager
  let lifecycleController: VirtualMachineLifecycleController
  let configurationValidator: (VZVirtualMachineConfiguration) throws -> Void

  init(
    bundleStore: VirtualMachineBundleStore = VirtualMachineBundleStore(),
    machineIdentifierStore: MachineIdentifierStore? = nil,
    variableStoreManager: EFIVariableStoreManager? = nil,
    lifecycleController: VirtualMachineLifecycleController = VirtualMachineLifecycleController(),
    configurationValidator: @escaping (VZVirtualMachineConfiguration) throws -> Void = {
      configuration in
      try configuration.validate()
    }
  ) {
    self.bundleStore = bundleStore
    self.machineIdentifierStore = machineIdentifierStore ?? bundleStore.machineIdentifierStore
    self.variableStoreManager =
      variableStoreManager ?? EFIVariableStoreManager(fileManager: bundleStore.fileManager)
    self.lifecycleController = lifecycleController
    self.configurationValidator = configurationValidator
  }

  func prepareConfiguration(for record: VirtualMachineRecord) throws
    -> PreparedVirtualMachineConfiguration
  {
    let launchPlan = try lifecycleController.launchPlan(for: record)
    let layout = try bundleStore.ensureRuntimeArtifacts(for: record)
    let machineIdentifier = try machineIdentifierStore.loadOrCreateMachineIdentifier(
      at: layout.machineIdentifierURL)
    let variableStore = try variableStoreManager.loadOrCreate(at: layout.nvramURL)

    let bootLoader = VZEFIBootLoader()
    bootLoader.variableStore = variableStore

    let platform = VZGenericPlatformConfiguration()
    platform.machineIdentifier = machineIdentifier

    let configuration = VZVirtualMachineConfiguration()
    configuration.platform = platform
    configuration.bootLoader = bootLoader
    configuration.cpuCount = record.resources.cpuCount
    configuration.memorySize = UInt64(record.resources.memoryMiB) * 1_048_576
    configuration.storageDevices = try makeStorageDevices(
      for: record, layout: layout, attachInstallImage: launchPlan.attachInstallImage)
    configuration.networkDevices = [try makeNetworkDevice(for: record)]
    configuration.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
    configuration.memoryBalloonDevices = [VZVirtioTraditionalMemoryBalloonDeviceConfiguration()]
    configuration.graphicsDevices = [makeGraphicsDevice()]
    configuration.keyboards = [VZUSBKeyboardConfiguration()]
    configuration.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]

    try configurationValidator(configuration)

    return PreparedVirtualMachineConfiguration(
      configuration: configuration,
      layout: layout,
      launchPlan: launchPlan
    )
  }

  private func makeStorageDevices(
    for record: VirtualMachineRecord,
    layout: VirtualMachineBundleLayout,
    attachInstallImage: Bool
  ) throws -> [VZStorageDeviceConfiguration] {
    let diskAttachment = try VZDiskImageStorageDeviceAttachment(
      url: layout.diskImageURL, readOnly: false)
    var devices: [VZStorageDeviceConfiguration] = [
      VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)
    ]

    if attachInstallImage {
      devices.append(try makeInstallMediaDevice(for: record))
    }

    return devices
  }

  private func makeInstallMediaDevice(for record: VirtualMachineRecord) throws
    -> VZUSBMassStorageDeviceConfiguration
  {
    guard let path = record.installImagePath?.trimmingCharacters(in: .whitespacesAndNewlines),
      !path.isEmpty
    else {
      throw VirtualMachineConfigurationFactoryError.missingInstallImage(record.id)
    }

    let url = URL(fileURLWithPath: path)
    guard bundleStore.fileManager.isReadableFile(atPath: url.path) else {
      throw VirtualMachineConfigurationFactoryError.unreadableInstallImage(url)
    }

    let attachment = try VZDiskImageStorageDeviceAttachment(url: url, readOnly: true)
    return VZUSBMassStorageDeviceConfiguration(attachment: attachment)
  }

  private func makeNetworkDevice(for record: VirtualMachineRecord) throws
    -> VZVirtioNetworkDeviceConfiguration
  {
    switch record.networkMode {
    case .nat:
      let networkDevice = VZVirtioNetworkDeviceConfiguration()
      networkDevice.attachment = VZNATNetworkDeviceAttachment()
      return networkDevice
    }
  }

  private func makeGraphicsDevice() -> VZVirtioGraphicsDeviceConfiguration {
    let graphics = VZVirtioGraphicsDeviceConfiguration()
    graphics.scanouts = [
      VZVirtioGraphicsScanoutConfiguration(widthInPixels: 1280, heightInPixels: 800)
    ]
    return graphics
  }
}
