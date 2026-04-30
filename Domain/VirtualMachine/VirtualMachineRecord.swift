import Foundation

struct VirtualMachineID: RawRepresentable, Hashable, Codable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init() {
        self.rawValue = UUID().uuidString.lowercased()
    }
}

enum VirtualMachineState: String, Codable, CaseIterable, Sendable {
    case draft
    case installing
    case stopped
    case running
    case error

    var allowsInstallImageSelection: Bool {
        switch self {
        case .draft, .installing, .error:
            return true
        case .stopped, .running:
            return false
        }
    }

    var allowsConfigurationEditing: Bool {
        switch self {
        case .draft, .error:
            return true
        case .installing, .stopped, .running:
            return false
        }
    }
}

enum VirtualMachineBootSource: String, Codable, CaseIterable, Sendable {
    case installationImage
    case diskImage
}

enum VirtualMachineNetworkMode: String, Codable, CaseIterable, Sendable {
    case nat
}

enum DistributionSupportLevel: String, Codable, CaseIterable, Sendable {
    case primaryValidated
    case secondaryValidated
    case unverified
}

struct VirtualMachineResources: Codable, Equatable, Sendable {
    static let minimumCPUCount = 2
    static let minimumMemoryMiB = 4 * 1024
    static let minimumDiskGiB = 32

    let cpuCount: Int
    let memoryMiB: Int
    let diskGiB: Int

    var diskSizeBytes: UInt64 {
        UInt64(diskGiB) * 1_073_741_824
    }
}

struct VirtualMachineRecord: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let id: VirtualMachineID
    var name: String
    var installImagePath: String?
    var resources: VirtualMachineResources
    var bootSource: VirtualMachineBootSource
    var networkMode: VirtualMachineNetworkMode
    var distributionSupport: DistributionSupportLevel
    var state: VirtualMachineState
    var createdAt: Date
    var updatedAt: Date

    init(
        schemaVersion: Int = VirtualMachineRecord.currentSchemaVersion,
        id: VirtualMachineID = VirtualMachineID(),
        name: String,
        installImagePath: String?,
        resources: VirtualMachineResources,
        bootSource: VirtualMachineBootSource,
        networkMode: VirtualMachineNetworkMode = .nat,
        distributionSupport: DistributionSupportLevel,
        state: VirtualMachineState,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.name = name
        self.installImagePath = installImagePath
        self.resources = resources
        self.bootSource = bootSource
        self.networkMode = networkMode
        self.distributionSupport = distributionSupport
        self.state = state
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func updatingState(_ nextState: VirtualMachineState, at timestamp: Date) -> VirtualMachineRecord {
        var copy = self
        copy.state = nextState
        copy.updatedAt = timestamp
        return copy
    }
}