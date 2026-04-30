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
          headline: L10n.text("recovery.headline.connected", fallback: "Connected"),
          summary: L10n.text(
            "recovery.summary.connected",
            fallback: "The virtual machine is connected and its state is current."),
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
          headline: L10n.text("recovery.headline.sessionLost", fallback: "Session Lost"),
          summary: L10n.text(
            "recovery.summary.sessionLost",
            fallback:
              "The app reopened without an active VM session. Check the logs, then restart or mark the VM as stopped."
          ),
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
          headline: L10n.text("recovery.headline.actionNeeded", fallback: "Action Needed"),
          summary: L10n.text(
            "recovery.summary.actionNeeded",
            fallback: "Check the logs, then restart or mark the VM as stopped."),
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
          headline: L10n.text("recovery.headline.ready", fallback: "Ready"),
          summary: restoreRuntimeWindowRequested
            ? L10n.text(
              "recovery.summary.readyRestore",
              fallback: "This virtual machine is ready, and its window can be reopened.")
            : L10n.text(
              "recovery.summary.ready",
              fallback: "This virtual machine is ready for the next action."),
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
