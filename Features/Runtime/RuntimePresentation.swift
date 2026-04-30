import Foundation

struct RuntimeMachineCapabilities: Equatable {
  let canStart: Bool
  let canRequestStop: Bool
  let canForceStop: Bool
}

struct RuntimeControlAvailability: Equatable {
  let canOpenWindow: Bool
  let canStart: Bool
  let canRequestStop: Bool
  let canForceStop: Bool

  static func make(record: VirtualMachineRecord?, capabilities: RuntimeMachineCapabilities?)
    -> RuntimeControlAvailability
  {
    guard let record else {
      return RuntimeControlAvailability(
        canOpenWindow: false,
        canStart: false,
        canRequestStop: false,
        canForceStop: false
      )
    }

    if let capabilities {
      return RuntimeControlAvailability(
        canOpenWindow: true,
        canStart: capabilities.canStart,
        canRequestStop: capabilities.canRequestStop,
        canForceStop: capabilities.canForceStop
      )
    }

    let canStart = [.draft, .installing, .stopped, .error].contains(record.state)
    return RuntimeControlAvailability(
      canOpenWindow: true,
      canStart: canStart,
      canRequestStop: false,
      canForceStop: false
    )
  }
}

struct VirtualMachineRuntimeDetailSnapshot: Equatable {
  let title: String
  let stateLine: String
  let resourceLine: String
  let bootSourceLine: String
  let installImageLine: String
  let bundleLine: String
  let logsLine: String
  let latestMessageLine: String?

  init(record: VirtualMachineRecord, bundleURL: URL, logURL: URL, latestMessage: String?) {
    self.title = record.name
    self.stateLine = "State: \(record.stateDisplayName)"
    self.resourceLine = "Resources: \(record.resourceSummary)"
    self.bootSourceLine = "Boot source: \(record.bootSource.displayName)"
    self.installImageLine = "Install image: \(record.installImagePath ?? "Not attached")"
    self.bundleLine = "Bundle: \(bundleURL.path)"
    self.logsLine = "Logs: \(logURL.path)"
    self.latestMessageLine = latestMessage.map { "Latest issue: \($0)" }
  }

  var detailLines: [String] {
    [
      stateLine,
      resourceLine,
      bootSourceLine,
      installImageLine,
      bundleLine,
      logsLine,
    ] + [latestMessageLine].compactMap { $0 }
  }
}

extension VirtualMachineBootSource {
  fileprivate var displayName: String {
    switch self {
    case .installationImage:
      return "Installation Image"
    case .diskImage:
      return "Disk Image"
    }
  }
}
