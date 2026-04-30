import Combine
import SwiftUI

enum VirtualMachineLibraryError: LocalizedError {
  case missingVirtualMachine

  var errorDescription: String? {
    switch self {
    case .missingVirtualMachine:
      return "Create a virtual machine before opening the runtime window or lifecycle controls."
    }
  }
}

@MainActor
final class VirtualMachineLibrary: ObservableObject {
  private static let runtimeWindowRestoreDefaultsKey = "phas.runtime.restore-window"

  @Published private(set) var records: [VirtualMachineRecord] = []
  @Published private(set) var runtimeSession: VirtualMachineSession?
  @Published private(set) var recoveryReport: VirtualMachineRecoveryReport?
  @Published private(set) var pendingRuntimeWindowRestoration = false
  @Published var isPresentingCreateWizard = false
  @Published var activeErrorMessage: String?

  private let bundleStore: VirtualMachineBundleStore
  private let hostSnapshotProvider: any HostMachineSnapshotProviding
  private let admissionValidator: any VirtualMachineAdmissionValidating
  private let createUseCase: CreateVirtualMachineUseCase
  private let sessionFactory: VirtualMachineSessionFactory
  private let recoveryEvaluator: VirtualMachineRecoveryEvaluator
  private let userDefaults: UserDefaults
  private let now: () -> Date

  private var runtimeSessionObservation: AnyCancellable?

  init(
    bundleStore: VirtualMachineBundleStore = VirtualMachineBundleStore(),
    hostSnapshotProvider: any HostMachineSnapshotProviding = HostMachineSnapshotProvider(),
    admissionValidator: any VirtualMachineAdmissionValidating = VirtualMachineAdmissionValidator(),
    createUseCase: CreateVirtualMachineUseCase? = nil,
    sessionFactory: VirtualMachineSessionFactory? = nil,
    recoveryEvaluator: VirtualMachineRecoveryEvaluator = VirtualMachineRecoveryEvaluator(),
    userDefaults: UserDefaults = .standard,
    now: @escaping () -> Date = Date.init
  ) {
    self.bundleStore = bundleStore
    self.hostSnapshotProvider = hostSnapshotProvider
    self.admissionValidator = admissionValidator
    self.createUseCase =
      createUseCase
      ?? CreateVirtualMachineUseCase(
        bundleStore: bundleStore,
        admissionValidator: admissionValidator
      )
    self.sessionFactory = sessionFactory ?? VirtualMachineSessionFactory(bundleStore: bundleStore)
    self.recoveryEvaluator = recoveryEvaluator
    self.userDefaults = userDefaults
    self.now = now
    reload()
  }

  var currentRecord: VirtualMachineRecord? {
    runtimeSession?.record ?? records.first
  }

  var hostSnapshot: HostMachineSnapshot {
    hostSnapshotProvider.snapshot()
  }

  var bundleRootURL: URL {
    bundleStore.bundleRootURL
  }

  var canCreateVirtualMachine: Bool {
    records.isEmpty
  }

  var runtimeControlAvailability: RuntimeControlAvailability {
    RuntimeControlAvailability.make(
      record: currentRecord,
      capabilities: runtimeSession.map {
        RuntimeMachineCapabilities(
          canStart: $0.canStart,
          canRequestStop: $0.canRequestStop,
          canForceStop: $0.canForceStop
        )
      }
    )
  }

  var latestRuntimeSummary: String? {
    runtimeSession?.latestSummary ?? activeErrorMessage
  }

  var shouldShowDiagnostics: Bool {
    recoveryReport != nil
  }

  func presentCreateWizard() {
    isPresentingCreateWizard = true
  }

  func dismissCreateWizard() {
    isPresentingCreateWizard = false
  }

  func clearError() {
    activeErrorMessage = nil
  }

  func admissionReport(for request: CreateVirtualMachineRequest) -> VirtualMachineAdmissionReport {
    admissionValidator.validate(request: request, existingRecords: records)
  }

  func bundleLocation(for record: VirtualMachineRecord) -> URL {
    bundleStore.layout(for: record.id).rootURL
  }

  func logFileURL(for record: VirtualMachineRecord) -> URL {
    bundleStore.layout(for: record.id).logsDirectoryURL.appendingPathComponent(
      "runtime.log", isDirectory: false)
  }

  func runtimeDetailSnapshot(for record: VirtualMachineRecord)
    -> VirtualMachineRuntimeDetailSnapshot
  {
    VirtualMachineRuntimeDetailSnapshot(
      record: record,
      bundleURL: bundleLocation(for: record),
      logURL: logFileURL(for: record),
      latestMessage: latestRuntimeSummary
    )
  }

  func prepareRuntimeWindow() -> Bool {
    do {
      _ = try ensureRuntimeSession()
      return true
    } catch {
      activeErrorMessage = error.localizedDescription
      return false
    }
  }

  func startCurrentVirtualMachine() async {
    do {
      let session = try ensureRuntimeSession()
      try await session.start()
      synchronizeRuntimeState(from: session)
    } catch {
      activeErrorMessage = error.localizedDescription
    }
  }

  func requestCurrentVirtualMachineStop() {
    do {
      let session = try ensureRuntimeSession()
      try session.requestStop()
      synchronizeRuntimeState(from: session)
    } catch {
      activeErrorMessage = error.localizedDescription
    }
  }

  func forceStopCurrentVirtualMachine() async {
    do {
      let session = try ensureRuntimeSession()
      try await session.forceStop()
      synchronizeRuntimeState(from: session)
    } catch {
      activeErrorMessage = error.localizedDescription
    }
  }

  func recoverCurrentVirtualMachineToStopped() {
    guard let record = currentRecord else {
      activeErrorMessage = VirtualMachineLibraryError.missingVirtualMachine.localizedDescription
      return
    }

    let recoveredRecord = record.updatingState(.stopped, at: now())

    do {
      try bundleStore.save(recoveredRecord)
      runtimeSessionObservation = nil
      runtimeSession = nil
      activeErrorMessage = nil
      upsertRecord(recoveredRecord)
      refreshRecoveryState(persistChanges: false)
    } catch {
      activeErrorMessage = error.localizedDescription
    }
  }

  func consumePendingRuntimeWindowRestoration() -> Bool {
    guard pendingRuntimeWindowRestoration else {
      return false
    }

    pendingRuntimeWindowRestoration = false
    return true
  }

  func noteRuntimeWindowOpened() {
    userDefaults.set(true, forKey: Self.runtimeWindowRestoreDefaultsKey)
    pendingRuntimeWindowRestoration = false
  }

  func noteRuntimeWindowClosed() {
    userDefaults.set(false, forKey: Self.runtimeWindowRestoreDefaultsKey)
    pendingRuntimeWindowRestoration = false
  }

  func reload() {
    do {
      records = try bundleStore.listRecords()
      if let runtimeSession {
        synchronizeRuntimeState(from: runtimeSession)
      } else {
        refreshRecoveryState(persistChanges: true)
      }
    } catch {
      activeErrorMessage = "Failed to load VM bundles. \(error.localizedDescription)"
    }
  }

  func createVirtualMachine(from request: CreateVirtualMachineRequest) {
    do {
      _ = try createUseCase.execute(request: request, existingRecords: records)
      reload()
      isPresentingCreateWizard = false
    } catch {
      activeErrorMessage = error.localizedDescription
    }
  }

  private func ensureRuntimeSession() throws -> VirtualMachineSession {
    if let runtimeSession {
      return runtimeSession
    }

    guard let record = records.first else {
      throw VirtualMachineLibraryError.missingVirtualMachine
    }

    let session = try sessionFactory.makeSession(for: record)
    runtimeSession = session
    observeRuntimeSession(session)
    synchronizeRuntimeState(from: session)
    return session
  }

  private func observeRuntimeSession(_ session: VirtualMachineSession) {
    runtimeSessionObservation = session.objectWillChange.sink { [weak self, weak session] _ in
      Task { @MainActor in
        guard let self, let session else {
          return
        }

        self.synchronizeRuntimeState(from: session)
      }
    }
  }

  private func synchronizeRuntimeState(from session: VirtualMachineSession) {
    upsertRecord(session.record)

    if let latestSummary = session.latestSummary, !latestSummary.isEmpty {
      activeErrorMessage = latestSummary
    }

    refreshRecoveryState(persistChanges: false)
  }

  private func upsertRecord(_ record: VirtualMachineRecord) {
    if let index = records.firstIndex(where: { $0.id == record.id }) {
      records[index] = record
    } else {
      records = [record]
    }
  }

  private func refreshRecoveryState(persistChanges: Bool) {
    let evaluation = recoveryEvaluator.evaluate(
      record: records.first,
      restoreRuntimeWindowRequested: userDefaults.bool(
        forKey: Self.runtimeWindowRestoreDefaultsKey),
      hasLiveSession: runtimeSession != nil,
      at: now()
    )

    if let correctedRecord = evaluation.correctedRecord {
      upsertRecord(correctedRecord)

      if persistChanges {
        do {
          try bundleStore.save(correctedRecord)
        } catch {
          activeErrorMessage = error.localizedDescription
        }
      }
    }

    recoveryReport = evaluation.report
    pendingRuntimeWindowRestoration = evaluation.report?.shouldRestoreRuntimeWindow ?? false

    if !pendingRuntimeWindowRestoration {
      userDefaults.set(false, forKey: Self.runtimeWindowRestoreDefaultsKey)
    }
  }
}
