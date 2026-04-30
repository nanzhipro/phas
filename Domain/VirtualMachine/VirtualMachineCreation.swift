import Foundation

struct CreateVirtualMachineRequest: Equatable, Sendable {
  var name: String
  var installImagePath: String
  var resources: VirtualMachineResources

  var trimmedName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var normalizedInstallImagePath: String {
    installImagePath.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var installImageURL: URL? {
    let path = normalizedInstallImagePath
    guard !path.isEmpty else {
      return nil
    }

    return URL(fileURLWithPath: path)
  }
}

enum VirtualMachineResourcePreset: String, CaseIterable, Identifiable, Sendable {
  case light
  case standard

  var id: String {
    rawValue
  }

  var title: String {
    switch self {
    case .light:
      return L10n.text("preset.light", fallback: "Light")
    case .standard:
      return L10n.text("preset.standard", fallback: "Standard")
    }
  }

  var subtitle: String {
    switch self {
    case .light:
      return "2 vCPU / 4 GiB / 32 GiB"
    case .standard:
      return "4 vCPU / 8 GiB / 64 GiB"
    }
  }

  var resources: VirtualMachineResources {
    switch self {
    case .light:
      return VirtualMachineResources(cpuCount: 2, memoryMiB: 4 * 1024, diskGiB: 32)
    case .standard:
      return VirtualMachineResources(cpuCount: 4, memoryMiB: 8 * 1024, diskGiB: 64)
    }
  }
}

struct HostOperatingSystemVersion: Equatable, Comparable, Sendable {
  let major: Int
  let minor: Int
  let patch: Int

  static func < (lhs: HostOperatingSystemVersion, rhs: HostOperatingSystemVersion) -> Bool {
    if lhs.major != rhs.major {
      return lhs.major < rhs.major
    }
    if lhs.minor != rhs.minor {
      return lhs.minor < rhs.minor
    }
    return lhs.patch < rhs.patch
  }

  var displayString: String {
    "macOS \(major).\(minor).\(patch)"
  }
}

enum HostArchitecture: String, Sendable {
  case appleSilicon
  case unsupported

  var displayString: String {
    switch self {
    case .appleSilicon:
      return L10n.text("host.architecture.appleSilicon", fallback: "Apple silicon")
    case .unsupported:
      return L10n.text("host.architecture.unsupported", fallback: "Unsupported")
    }
  }
}

struct HostMachineSnapshot: Equatable, Sendable {
  let architecture: HostArchitecture
  let operatingSystemVersion: HostOperatingSystemVersion
  let totalMemoryBytes: UInt64
  let activeCPUCount: Int
  let availableDiskBytes: Int64

  static let minimumSupportedSystem = HostOperatingSystemVersion(major: 14, minor: 0, patch: 0)

  var totalMemoryGiB: Int {
    Int(totalMemoryBytes / 1_073_741_824)
  }

  var maximumSafeCPUCount: Int {
    let safeCeiling = max(activeCPUCount - 1, VirtualMachineResources.minimumCPUCount)
    return max(VirtualMachineResources.minimumCPUCount, safeCeiling)
  }

  var maximumSafeMemoryMiB: Int {
    let totalMemoryMiB = Int(totalMemoryBytes / 1_048_576)
    let reservedMemoryMiB = max(2 * 1024, totalMemoryMiB / 4)
    return max(VirtualMachineResources.minimumMemoryMiB, totalMemoryMiB - reservedMemoryMiB)
  }

  var recommendedPreset: VirtualMachineResourcePreset {
    if supportsResources(VirtualMachineResourcePreset.standard.resources) {
      return .standard
    }

    return .light
  }

  func supportsResources(_ resources: VirtualMachineResources) -> Bool {
    resources.cpuCount <= maximumSafeCPUCount && resources.memoryMiB <= maximumSafeMemoryMiB
  }
}

enum VirtualMachineAdmissionSeverity: String, Sendable {
  case blocking
  case warning
}

struct VirtualMachineAdmissionIssue: Equatable, Identifiable, Sendable {
  let id: String
  let severity: VirtualMachineAdmissionSeverity
  let message: String
}

struct VirtualMachineAdmissionReport: Equatable, Sendable {
  let hostSnapshot: HostMachineSnapshot
  let inferredDistributionSupport: DistributionSupportLevel
  let issues: [VirtualMachineAdmissionIssue]

  var blockingIssues: [VirtualMachineAdmissionIssue] {
    issues.filter { $0.severity == .blocking }
  }

  var warnings: [VirtualMachineAdmissionIssue] {
    issues.filter { $0.severity == .warning }
  }

  var canCreate: Bool {
    blockingIssues.isEmpty
  }
}
