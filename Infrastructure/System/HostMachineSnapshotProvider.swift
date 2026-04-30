import Darwin
import Foundation

protocol HostMachineSnapshotProviding {
    func snapshot() -> HostMachineSnapshot
}

struct HostMachineSnapshotProvider: HostMachineSnapshotProviding {
    let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func snapshot() -> HostMachineSnapshot {
        let processInfo = ProcessInfo.processInfo
        let version = processInfo.operatingSystemVersion
        let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let capacityValues = try? applicationSupportURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        let availableCapacity = capacityValues?.volumeAvailableCapacityForImportantUsage ?? 0

        return HostMachineSnapshot(
            architecture: isAppleSilicon ? .appleSilicon : .unsupported,
            operatingSystemVersion: HostOperatingSystemVersion(
                major: version.majorVersion,
                minor: version.minorVersion,
                patch: version.patchVersion
            ),
            totalMemoryBytes: processInfo.physicalMemory,
            activeCPUCount: processInfo.activeProcessorCount,
            availableDiskBytes: availableCapacity
        )
    }

    private var isAppleSilicon: Bool {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        let result = sysctlbyname("hw.optional.arm64", &value, &size, nil, 0)
        return result == 0 && value == 1
    }
}