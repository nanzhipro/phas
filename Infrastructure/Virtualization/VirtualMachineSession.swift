import Foundation
import Virtualization

enum VirtualMachineSessionError: LocalizedError {
  case cannotPersistState(Error)

  var errorDescription: String? {
    switch self {
    case .cannotPersistState(let error):
      return L10n.format(
        "error.session.persistState",
        fallback: "Couldn't save the virtual machine state. %@",
        error.localizedDescription
      )
    }
  }
}

@MainActor
final class VirtualMachineSession: NSObject, ObservableObject, VZVirtualMachineDelegate {
  @Published private(set) var record: VirtualMachineRecord
  @Published private(set) var virtualMachineState: VZVirtualMachine.State
  @Published private(set) var latestSummary: String?

  let machine: VZVirtualMachine
  let bundleLayout: VirtualMachineBundleLayout

  var canStart: Bool {
    machine.canStart
  }

  var canRequestStop: Bool {
    machine.canRequestStop
  }

  var canForceStop: Bool {
    machine.canStop
  }

  private let bundleStore: VirtualMachineBundleStore
  private let lifecycleController: VirtualMachineLifecycleController
  private let logger: any VirtualMachineEventLogging
  private let now: () -> Date

  init(
    record: VirtualMachineRecord,
    machine: VZVirtualMachine,
    bundleLayout: VirtualMachineBundleLayout,
    bundleStore: VirtualMachineBundleStore,
    lifecycleController: VirtualMachineLifecycleController,
    logger: any VirtualMachineEventLogging,
    now: @escaping () -> Date = Date.init
  ) {
    self.record = record
    self.machine = machine
    self.bundleLayout = bundleLayout
    self.bundleStore = bundleStore
    self.lifecycleController = lifecycleController
    self.logger = logger
    self.now = now
    self.virtualMachineState = machine.state
    super.init()
    self.machine.delegate = self
    appendLog(.sessionCreated, summary: "Virtual machine session created.")
  }

  func start() async throws {
    let updatedRecord = try lifecycleController.recordByPreparingToStart(record, at: now())
    try persistRecord(updatedRecord)
    record = updatedRecord
    appendLog(
      .startRequested, summary: "Start requested using \(updatedRecord.bootSource.rawValue).")

    do {
      try await machine.start()
      virtualMachineState = machine.state
      appendLog(
        .startSucceeded, summary: "Virtual machine entered \(machine.state.logDescription).")
    } catch {
      let failedRecord = lifecycleController.recordByHandlingRuntimeFailure(
        updatedRecord, at: now())
      do {
        try persistRecord(failedRecord)
      } catch {
        latestSummary = error.localizedDescription
        throw VirtualMachineSessionError.cannotPersistState(error)
      }
      record = failedRecord
      virtualMachineState = machine.state
      latestSummary = error.localizedDescription
      appendLog(.stoppedWithError, summary: error.localizedDescription)
      throw error
    }
  }

  func requestStop() throws {
    try machine.requestStop()
    appendLog(.stopRequested, summary: "Guest stop requested.")
  }

  func forceStop() async throws {
    appendLog(.forceStopRequested, summary: "Force stop requested.")
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      machine.stop { error in
        Task { @MainActor in
          self.virtualMachineState = self.machine.state
          if let error {
            self.latestSummary = error.localizedDescription
            self.appendLog(.stoppedWithError, summary: error.localizedDescription)
            continuation.resume(throwing: error)
          } else {
            continuation.resume(returning: ())
          }
        }
      }
    }
  }

  nonisolated func guestDidStop(_ virtualMachine: VZVirtualMachine) {
    Task { @MainActor in
      let updatedRecord = self.lifecycleController.recordByHandlingGuestStop(
        self.record, at: self.now())
      self.record = updatedRecord
      self.virtualMachineState = virtualMachine.state
      do {
        try self.persistRecord(updatedRecord)
      } catch {
        self.latestSummary = error.localizedDescription
      }
      self.appendLog(
        .guestStopped,
        summary: "Guest stopped. Next boot source: \(updatedRecord.bootSource.rawValue).")
    }
  }

  nonisolated func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error)
  {
    Task { @MainActor in
      let updatedRecord = self.lifecycleController.recordByHandlingRuntimeFailure(
        self.record, at: self.now())
      self.record = updatedRecord
      self.virtualMachineState = virtualMachine.state
      self.latestSummary = error.localizedDescription
      do {
        try self.persistRecord(updatedRecord)
      } catch {
        self.latestSummary = error.localizedDescription
      }
      self.appendLog(.stoppedWithError, summary: error.localizedDescription)
    }
  }

  nonisolated func virtualMachine(
    _ virtualMachine: VZVirtualMachine, networkDevice: VZNetworkDevice,
    attachmentWasDisconnectedWithError error: Error
  ) {
    Task { @MainActor in
      let updatedRecord = self.lifecycleController.recordByHandlingNetworkDisconnect(
        self.record, at: self.now())
      self.record = updatedRecord
      self.virtualMachineState = virtualMachine.state
      self.latestSummary = error.localizedDescription
      do {
        try self.persistRecord(updatedRecord)
      } catch {
        self.latestSummary = error.localizedDescription
      }
      self.appendLog(.networkDisconnected, summary: error.localizedDescription)
    }
  }

  private func persistRecord(_ record: VirtualMachineRecord) throws {
    do {
      try bundleStore.save(record)
    } catch {
      throw VirtualMachineSessionError.cannotPersistState(error)
    }
  }

  private func appendLog(_ event: VirtualMachineLogEventKind, summary: String) {
    do {
      try logger.append(event: event, summary: summary, record: record, layout: bundleLayout)
    } catch {
      latestSummary = error.localizedDescription
    }
  }
}

@MainActor
struct VirtualMachineSessionFactory {
  let bundleStore: VirtualMachineBundleStore
  let configurationFactory: VirtualMachineConfigurationFactory
  let lifecycleController: VirtualMachineLifecycleController
  let logger: any VirtualMachineEventLogging
  let now: () -> Date

  init(
    bundleStore: VirtualMachineBundleStore = VirtualMachineBundleStore(),
    configurationFactory: VirtualMachineConfigurationFactory? = nil,
    lifecycleController: VirtualMachineLifecycleController = VirtualMachineLifecycleController(),
    logger: any VirtualMachineEventLogging = VirtualMachineEventLogger(),
    now: @escaping () -> Date = Date.init
  ) {
    self.bundleStore = bundleStore
    self.configurationFactory =
      configurationFactory
      ?? VirtualMachineConfigurationFactory(
        bundleStore: bundleStore, lifecycleController: lifecycleController)
    self.lifecycleController = lifecycleController
    self.logger = logger
    self.now = now
  }

  func makeSession(for record: VirtualMachineRecord) throws -> VirtualMachineSession {
    let preparedConfiguration = try configurationFactory.prepareConfiguration(for: record)
    try logger.append(
      event: .configurationPrepared,
      summary:
        "Configuration prepared for \(preparedConfiguration.launchPlan.attachInstallImage ? "installation media" : "disk boot").",
      record: record,
      layout: preparedConfiguration.layout
    )

    let machine = VZVirtualMachine(configuration: preparedConfiguration.configuration)
    return VirtualMachineSession(
      record: record,
      machine: machine,
      bundleLayout: preparedConfiguration.layout,
      bundleStore: bundleStore,
      lifecycleController: lifecycleController,
      logger: logger,
      now: now
    )
  }
}

extension VZVirtualMachine.State {
  fileprivate var logDescription: String {
    switch self {
    case .stopped:
      return "stopped"
    case .running:
      return "running"
    case .paused:
      return "paused"
    case .error:
      return "error"
    case .starting:
      return "starting"
    case .pausing:
      return "pausing"
    case .resuming:
      return "resuming"
    case .stopping:
      return "stopping"
    case .saving:
      return "saving"
    case .restoring:
      return "restoring"
    @unknown default:
      return "unknown"
    }
  }
}
