import Foundation

enum VirtualMachineRecoverySeverity: String, Equatable {
  case healthy
  case warning
  case error
}

struct VirtualMachineRecoveryActions: Equatable {
  let canRetryStart: Bool
  let canRecoverToStopped: Bool
  let canReloadFromDisk: Bool
}

struct VirtualMachineRecoveryReport: Equatable {
  let severity: VirtualMachineRecoverySeverity
  let headline: String
  let summary: String
  let actions: VirtualMachineRecoveryActions
  let shouldRestoreRuntimeWindow: Bool
}

struct VirtualMachineRecoveryEvaluation: Equatable {
  let correctedRecord: VirtualMachineRecord?
  let report: VirtualMachineRecoveryReport?
}

struct VirtualMachineRecoveryEvaluator {
  func evaluate(
    record: VirtualMachineRecord?,
    restoreRuntimeWindowRequested: Bool,
    hasLiveSession: Bool,
    at timestamp: Date
  ) -> VirtualMachineRecoveryEvaluation {
    guard let record else {
      return VirtualMachineRecoveryEvaluation(correctedRecord: nil, report: nil)
    }

    if hasLiveSession {
      return VirtualMachineRecoveryEvaluation(
        correctedRecord: nil,
        report: VirtualMachineRecoveryReport(
          severity: .healthy,
          headline: "Runtime Session Attached",
          summary:
            "The VM is backed by a live runtime session, so the current state can be trusted.",
          actions: VirtualMachineRecoveryActions(
            canRetryStart: false,
            canRecoverToStopped: false,
            canReloadFromDisk: true
          ),
          shouldRestoreRuntimeWindow: false
        )
      )
    }

    switch record.state {
    case .running, .installing:
      let correctedRecord = record.updatingState(.error, at: timestamp)
      return VirtualMachineRecoveryEvaluation(
        correctedRecord: correctedRecord,
        report: VirtualMachineRecoveryReport(
          severity: .error,
          headline: "Interrupted Runtime Detected",
          summary:
            "The app relaunched without a live Virtualization session. The persisted transient state is no longer trusted, so the VM has been moved to Error until you inspect logs and retry or recover it to Stopped.",
          actions: VirtualMachineRecoveryActions(
            canRetryStart: true,
            canRecoverToStopped: true,
            canReloadFromDisk: true
          ),
          shouldRestoreRuntimeWindow: false
        )
      )

    case .error:
      return VirtualMachineRecoveryEvaluation(
        correctedRecord: nil,
        report: VirtualMachineRecoveryReport(
          severity: .warning,
          headline: "Recovery Required",
          summary:
            "Inspect the logs, then retry start or move the VM back to Stopped before continuing.",
          actions: VirtualMachineRecoveryActions(
            canRetryStart: true,
            canRecoverToStopped: true,
            canReloadFromDisk: true
          ),
          shouldRestoreRuntimeWindow: false
        )
      )

    case .draft, .stopped:
      return VirtualMachineRecoveryEvaluation(
        correctedRecord: nil,
        report: VirtualMachineRecoveryReport(
          severity: .healthy,
          headline: "Relaunch Ready",
          summary: restoreRuntimeWindowRequested
            ? "The runtime window can be restored for this VM because the persisted state is stable."
            : "The persisted VM state is stable and ready for the next explicit action.",
          actions: VirtualMachineRecoveryActions(
            canRetryStart: true,
            canRecoverToStopped: false,
            canReloadFromDisk: true
          ),
          shouldRestoreRuntimeWindow: restoreRuntimeWindowRequested
        )
      )
    }
  }
}
