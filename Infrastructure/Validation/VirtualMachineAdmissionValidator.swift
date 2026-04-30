import Foundation

protocol VirtualMachineAdmissionValidating {
  func validate(
    request: CreateVirtualMachineRequest,
    existingRecords: [VirtualMachineRecord]
  ) -> VirtualMachineAdmissionReport
}

struct VirtualMachineAdmissionValidator: VirtualMachineAdmissionValidating {
  private enum InstallImageArchitecture {
    case arm64
    case x86_64
    case unknown
  }

  let fileManager: FileManager
  let hostSnapshotProvider: any HostMachineSnapshotProviding

  init(
    fileManager: FileManager = .default,
    hostSnapshotProvider: any HostMachineSnapshotProviding = HostMachineSnapshotProvider()
  ) {
    self.fileManager = fileManager
    self.hostSnapshotProvider = hostSnapshotProvider
  }

  func validate(
    request: CreateVirtualMachineRequest,
    existingRecords: [VirtualMachineRecord]
  ) -> VirtualMachineAdmissionReport {
    let snapshot = hostSnapshotProvider.snapshot()
    let inspection = inspectInstallImage(path: request.normalizedInstallImagePath)
    var issues = inspection.issues

    if snapshot.architecture != .appleSilicon {
      issues.append(
        blocking(
          "host-arch",
          L10n.text("admission.hostArch", fallback: "Only Apple silicon Macs are supported.")
        ))
    }

    if snapshot.operatingSystemVersion < HostMachineSnapshot.minimumSupportedSystem {
      issues.append(
        blocking(
          "host-os",
          L10n.text("admission.hostOS", fallback: "macOS 14 or later is required.")
        ))
    }

    if !existingRecords.isEmpty {
      issues.append(
        blocking(
          "single-vm",
          L10n.text(
            "admission.singleVM",
            fallback: "Only one virtual machine is supported in this version.")
        ))
    }

    if request.trimmedName.isEmpty {
      issues.append(
        blocking(
          "name-empty",
          L10n.text("admission.nameRequired", fallback: "Enter a virtual machine name.")
        ))
    }

    if request.resources.cpuCount < VirtualMachineResources.minimumCPUCount {
      issues.append(
        blocking(
          "cpu-min",
          L10n.format(
            "admission.cpuMin",
            fallback: "Allocate at least %d vCPU.",
            VirtualMachineResources.minimumCPUCount
          )
        )
      )
    }

    if request.resources.memoryMiB < VirtualMachineResources.minimumMemoryMiB {
      issues.append(
        blocking(
          "memory-min",
          L10n.text("admission.memoryMin", fallback: "Allocate at least 4 GiB of memory.")
        ))
    }

    if request.resources.diskGiB < VirtualMachineResources.minimumDiskGiB {
      issues.append(
        blocking(
          "disk-min",
          L10n.text("admission.diskMin", fallback: "Allocate at least 32 GiB of disk space.")
        ))
    }

    if request.resources.cpuCount > snapshot.maximumSafeCPUCount {
      issues.append(
        blocking(
          "cpu-safe-max",
          L10n.text("admission.cpuSafeMax", fallback: "Reduce CPU allocation for this Mac."))
      )
    }

    if request.resources.memoryMiB > snapshot.maximumSafeMemoryMiB {
      issues.append(
        blocking(
          "memory-safe-max",
          L10n.text(
            "admission.memorySafeMax",
            fallback: "Reduce memory allocation for this Mac."))
      )
    }

    let requiredDiskBytes = Int64(request.resources.diskSizeBytes) + 8 * 1_073_741_824
    if snapshot.availableDiskBytes > 0 && snapshot.availableDiskBytes < requiredDiskBytes {
      issues.append(
        blocking(
          "disk-space",
          L10n.text(
            "admission.diskSpace",
            fallback: "Not enough free disk space for setup and installation."))
      )
    }

    return VirtualMachineAdmissionReport(
      hostSnapshot: snapshot,
      inferredDistributionSupport: inspection.distributionSupport,
      issues: deduplicated(issues)
    )
  }

  private func inspectInstallImage(path: String) -> (
    distributionSupport: DistributionSupportLevel, issues: [VirtualMachineAdmissionIssue]
  ) {
    let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedPath.isEmpty else {
      return (
        .unverified,
        [
          blocking(
            "iso-missing",
            L10n.text("admission.isoMissing", fallback: "Choose a Linux ARM64 installer image.")
          )
        ]
      )
    }

    let url = URL(fileURLWithPath: trimmedPath)
    var issues: [VirtualMachineAdmissionIssue] = []

    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
      !isDirectory.boolValue
    else {
      return (
        .unverified,
        [
          blocking(
            "iso-not-found",
            L10n.text(
              "admission.isoNotFound",
              fallback: "The selected installer image can't be found.")
          )
        ]
      )
    }

    guard fileManager.isReadableFile(atPath: url.path) else {
      return (
        .unverified,
        [
          blocking(
            "iso-unreadable",
            L10n.text(
              "admission.isoUnreadable",
              fallback: "The selected installer image can't be read.")
          )
        ]
      )
    }

    let allowedExtensions = ["iso", "img"]
    if !allowedExtensions.contains(url.pathExtension.lowercased()) {
      issues.append(
        blocking(
          "iso-extension",
          L10n.text("admission.isoExtension", fallback: "Select an ISO or IMG installer image.")
        ))
    }

    let fileName = url.lastPathComponent.lowercased()
    let architecture = inferredArchitecture(from: fileName)

    if architecture == .x86_64 {
      issues.append(
        blocking(
          "iso-arch",
          L10n.text(
            "admission.isoArch",
            fallback: "The selected image appears to be x86_64/amd64, not ARM64.")
        ))
    } else if architecture == .unknown {
      issues.append(
        warning(
          "iso-arch-unknown",
          L10n.text(
            "admission.isoArchUnknown",
            fallback: "The image architecture couldn't be confirmed. Make sure it is ARM64.")
        ))
    }

    let supportLevel: DistributionSupportLevel
    if fileName.contains("ubuntu") {
      supportLevel = .primaryValidated
    } else if fileName.contains("fedora") {
      supportLevel = .secondaryValidated
      issues.append(
        warning(
          "distribution-secondary",
          L10n.text(
            "admission.distributionSecondary",
            fallback:
              "Fedora Workstation ARM64 has been tested, but Ubuntu Desktop ARM64 is recommended."
          )
        ))
    } else {
      supportLevel = .unverified
      issues.append(
        warning(
          "distribution-unverified",
          L10n.text(
            "admission.distributionUnverified",
            fallback: "Compatibility with this image hasn't been verified.")
        ))
    }

    return (supportLevel, issues)
  }

  private func inferredArchitecture(from fileName: String) -> InstallImageArchitecture {
    if fileName.contains("amd64") || fileName.contains("x86_64") || fileName.contains("x64") {
      return .x86_64
    }

    if fileName.contains("arm64") || fileName.contains("aarch64") {
      return .arm64
    }

    return .unknown
  }

  private func blocking(_ id: String, _ message: String) -> VirtualMachineAdmissionIssue {
    VirtualMachineAdmissionIssue(id: id, severity: .blocking, message: message)
  }

  private func warning(_ id: String, _ message: String) -> VirtualMachineAdmissionIssue {
    VirtualMachineAdmissionIssue(id: id, severity: .warning, message: message)
  }

  private func deduplicated(_ issues: [VirtualMachineAdmissionIssue])
    -> [VirtualMachineAdmissionIssue]
  {
    var seen = Set<String>()
    return issues.filter { seen.insert($0.id).inserted }
  }
}
