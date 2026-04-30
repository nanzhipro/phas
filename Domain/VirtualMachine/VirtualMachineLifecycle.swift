import Foundation

enum VirtualMachineLifecycleControllerError: LocalizedError {
  case missingInstallImagePath

  var errorDescription: String? {
    switch self {
    case .missingInstallImagePath:
      return L10n.text(
        "error.lifecycle.missingInstallImage",
        fallback: "Attach an installer image before starting from the installer.")
    }
  }
}

struct VirtualMachineLaunchPlan: Equatable, Sendable {
  let nextState: VirtualMachineState
  let attachInstallImage: Bool
}

struct VirtualMachineLifecycleController {
  func launchPlan(for record: VirtualMachineRecord) throws -> VirtualMachineLaunchPlan {
    let attachInstallImage = record.bootSource == .installationImage

    if attachInstallImage {
      let installImagePath =
        record.installImagePath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !installImagePath.isEmpty else {
        throw VirtualMachineLifecycleControllerError.missingInstallImagePath
      }
    }

    return VirtualMachineLaunchPlan(
      nextState: attachInstallImage ? .installing : .running,
      attachInstallImage: attachInstallImage
    )
  }

  func recordByPreparingToStart(_ record: VirtualMachineRecord, at timestamp: Date) throws
    -> VirtualMachineRecord
  {
    let plan = try launchPlan(for: record)
    return record.updatingState(plan.nextState, at: timestamp)
  }

  func recordByHandlingGuestStop(_ record: VirtualMachineRecord, at timestamp: Date)
    -> VirtualMachineRecord
  {
    var copy = record
    copy.state = .stopped
    copy.updatedAt = timestamp

    if copy.bootSource == .installationImage {
      copy.bootSource = .diskImage
    }

    return copy
  }

  func recordByHandlingRuntimeFailure(_ record: VirtualMachineRecord, at timestamp: Date)
    -> VirtualMachineRecord
  {
    record.updatingState(.error, at: timestamp)
  }

  func recordByHandlingNetworkDisconnect(_ record: VirtualMachineRecord, at timestamp: Date)
    -> VirtualMachineRecord
  {
    record.updatingState(.error, at: timestamp)
  }
}
