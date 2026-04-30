import Foundation

enum VirtualMachineBundleStoreError: Error {
    case unsupportedBundleURL(URL)
}

struct VirtualMachineBundleLayout: Equatable {
    let rootURL: URL

    var diskImageURL: URL {
        rootURL.appendingPathComponent("Disk.img", isDirectory: false)
    }

    var machineIdentifierURL: URL {
        rootURL.appendingPathComponent("MachineIdentifier", isDirectory: false)
    }

    var nvramURL: URL {
        rootURL.appendingPathComponent("NVRAM", isDirectory: false)
    }

    var configurationURL: URL {
        rootURL.appendingPathComponent("config.json", isDirectory: false)
    }

    var logsDirectoryURL: URL {
        rootURL.appendingPathComponent("logs", isDirectory: true)
    }
}

struct VirtualMachineBundleRootResolver {
    let fileManager: FileManager
    let baseDirectoryURL: URL

    init(fileManager: FileManager = .default, baseDirectoryURL: URL? = nil) {
        self.fileManager = fileManager
        if let baseDirectoryURL {
            self.baseDirectoryURL = baseDirectoryURL.standardizedFileURL
        } else {
            let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.baseDirectoryURL = applicationSupportURL
                .appendingPathComponent("phas", isDirectory: true)
                .appendingPathComponent("VMs", isDirectory: true)
                .standardizedFileURL
        }
    }

    func bundleLayout(for id: VirtualMachineID) -> VirtualMachineBundleLayout {
        let bundleURL = baseDirectoryURL.appendingPathComponent("\(id.rawValue).vmbundle", isDirectory: true)
        return VirtualMachineBundleLayout(rootURL: bundleURL.standardizedFileURL)
    }
}

struct VirtualMachineBundleStore {
    let fileManager: FileManager
    let rootResolver: VirtualMachineBundleRootResolver
    let machineIdentifierStore: MachineIdentifierStore

    init(
        fileManager: FileManager = .default,
        rootResolver: VirtualMachineBundleRootResolver = VirtualMachineBundleRootResolver(),
        machineIdentifierStore: MachineIdentifierStore? = nil
    ) {
        self.fileManager = fileManager
        self.rootResolver = rootResolver
        self.machineIdentifierStore = machineIdentifierStore ?? MachineIdentifierStore(fileManager: fileManager)
    }

    var bundleRootURL: URL {
        rootResolver.baseDirectoryURL
    }

    func layout(for id: VirtualMachineID) -> VirtualMachineBundleLayout {
        rootResolver.bundleLayout(for: id)
    }

    @discardableResult
    func ensureRuntimeArtifacts(for record: VirtualMachineRecord) throws -> VirtualMachineBundleLayout {
        let layout = try ensureBundleStructure(for: record)
        _ = try machineIdentifierStore.loadOrCreateData(at: layout.machineIdentifierURL)
        return layout
    }

    @discardableResult
    func bootstrapBundle(for record: VirtualMachineRecord) throws -> VirtualMachineBundleLayout {
        return try ensureRuntimeArtifacts(for: record)
    }

    func save(_ record: VirtualMachineRecord) throws {
        let layout = layout(for: record.id)
        try fileManager.createDirectory(at: layout.rootURL, withIntermediateDirectories: true)
        try save(record, to: layout.configurationURL)
    }

    func loadRecord(for id: VirtualMachineID) throws -> VirtualMachineRecord {
        let configurationURL = layout(for: id).configurationURL
        let data = try Data(contentsOf: configurationURL)
        return try decoder.decode(VirtualMachineRecord.self, from: data)
    }

    func listRecords() throws -> [VirtualMachineRecord] {
        guard fileManager.fileExists(atPath: bundleRootURL.path) else {
            return []
        }

        let bundleURLs = try fileManager.contentsOfDirectory(
            at: bundleRootURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        return try bundleURLs
            .filter { $0.pathExtension == "vmbundle" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { url in
                let data = try Data(contentsOf: url.appendingPathComponent("config.json", isDirectory: false))
                return try decoder.decode(VirtualMachineRecord.self, from: data)
            }
    }

    func deleteBundle(for id: VirtualMachineID) throws {
        try deleteBundle(at: layout(for: id).rootURL)
    }

    func deleteBundle(at bundleURL: URL) throws {
        let standardizedURL = bundleURL.standardizedFileURL
        let expectedParent = bundleRootURL.standardizedFileURL

        guard standardizedURL.deletingLastPathComponent() == expectedParent,
              standardizedURL.pathExtension == "vmbundle" else {
            throw VirtualMachineBundleStoreError.unsupportedBundleURL(bundleURL)
        }

        if fileManager.fileExists(atPath: standardizedURL.path) {
            try fileManager.removeItem(at: standardizedURL)
        }
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func save(_ record: VirtualMachineRecord, to url: URL) throws {
        let data = try encoder.encode(record)
        try data.write(to: url, options: .atomic)
    }

    private func ensureBundleStructure(for record: VirtualMachineRecord) throws -> VirtualMachineBundleLayout {
        let layout = layout(for: record.id)

        try fileManager.createDirectory(at: bundleRootURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: layout.rootURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: layout.logsDirectoryURL, withIntermediateDirectories: true)
        try createSparseDiskIfNeeded(at: layout.diskImageURL, logicalSizeInBytes: record.resources.diskSizeBytes)
        try save(record, to: layout.configurationURL)

        return layout
    }

    private func createSparseDiskIfNeeded(at url: URL, logicalSizeInBytes: UInt64) throws {
        guard !fileManager.fileExists(atPath: url.path) else {
            return
        }

        fileManager.createFile(atPath: url.path, contents: Data())
        let handle = try FileHandle(forWritingTo: url)
        try handle.truncate(atOffset: logicalSizeInBytes)
        try handle.close()
    }
}