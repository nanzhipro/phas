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
      issues.append(blocking("host-arch", "phas MVP only supports Apple silicon hosts."))
    }

    if snapshot.operatingSystemVersion < HostMachineSnapshot.minimumSupportedSystem {
      issues.append(blocking("host-os", "macOS 14 or newer is required before creating a VM."))
    }

    if !existingRecords.isEmpty {
      issues.append(
        blocking(
          "single-vm",
          "phas MVP only supports one VM at a time. Delete the existing bundle before creating another."
        ))
    }

    if request.trimmedName.isEmpty {
      issues.append(blocking("name-empty", "A VM name is required."))
    }

    if request.resources.cpuCount < VirtualMachineResources.minimumCPUCount {
      issues.append(
        blocking("cpu-min", "CPU must be at least \(VirtualMachineResources.minimumCPUCount) vCPU.")
      )
    }

    if request.resources.memoryMiB < VirtualMachineResources.minimumMemoryMiB {
      issues.append(blocking("memory-min", "Memory must be at least 4 GiB for GUI Linux installs."))
    }

    if request.resources.diskGiB < VirtualMachineResources.minimumDiskGiB {
      issues.append(blocking("disk-min", "Disk must be at least 32 GiB."))
    }

    if request.resources.cpuCount > snapshot.maximumSafeCPUCount {
      issues.append(
        blocking(
          "cpu-safe-max",
          "This host should keep at least one CPU core for macOS. Reduce the VM CPU count."))
    }

    if request.resources.memoryMiB > snapshot.maximumSafeMemoryMiB {
      issues.append(
        blocking(
          "memory-safe-max",
          "This memory selection exceeds the safe threshold for the current host."))
    }

    let requiredDiskBytes = Int64(request.resources.diskSizeBytes) + 8 * 1_073_741_824
    if snapshot.availableDiskBytes > 0 && snapshot.availableDiskBytes < requiredDiskBytes {
      issues.append(
        blocking(
          "disk-space", "Available disk space is too low for bundle creation and OS installation."))
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
        [blocking("iso-missing", "Choose a Linux ARM64 installation ISO before creating the VM.")]
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
            "iso-not-found", "The selected ISO path does not exist or points to a directory.")
        ]
      )
    }

    guard fileManager.isReadableFile(atPath: url.path) else {
      return (
        .unverified, [blocking("iso-unreadable", "The selected ISO is not readable by the app.")]
      )
    }

    let allowedExtensions = ["iso", "img"]
    if !allowedExtensions.contains(url.pathExtension.lowercased()) {
      issues.append(
        blocking("iso-extension", "The selected file does not look like an install ISO or IMG."))
    }

    let fileName = url.lastPathComponent.lowercased()
    let architecture = inferredArchitecture(from: fileName)

    if architecture == .x86_64 {
      issues.append(
        blocking("iso-arch", "The selected image appears to target x86_64/amd64 instead of ARM64."))
    } else if architecture == .unknown {
      issues.append(
        warning(
          "iso-arch-unknown",
          "Could not confirm that the selected image is ARM64 from its filename. Proceed only if you know it matches Apple silicon."
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
          "Fedora Workstation ARM64 is part of the supplementary validation matrix, not the primary release target."
        ))
    } else {
      supportLevel = .unverified
      issues.append(
        warning(
          "distribution-unverified",
          "This image is outside the primary and secondary validation matrix. You can continue, but compatibility is not guaranteed."
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
