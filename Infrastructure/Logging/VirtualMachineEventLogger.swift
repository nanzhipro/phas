import Foundation

enum VirtualMachineLogEventKind: String, Codable, Sendable {
    case configurationPrepared
    case sessionCreated
    case startRequested
    case startSucceeded
    case guestStopped
    case stoppedWithError
    case networkDisconnected
    case stopRequested
    case forceStopRequested
}

struct VirtualMachineLogEntry: Codable, Equatable, Sendable {
    let timestamp: Date
    let event: VirtualMachineLogEventKind
    let vmID: String
    let state: String
    let bootSource: String
    let summary: String
    let appVersion: String
    let hostSystemVersion: String
}

protocol VirtualMachineEventLogging {
    func append(event: VirtualMachineLogEventKind, summary: String, record: VirtualMachineRecord, layout: VirtualMachineBundleLayout) throws
    func logFileURL(for layout: VirtualMachineBundleLayout) -> URL
}

struct VirtualMachineEventLogger: VirtualMachineEventLogging {
    let fileManager: FileManager
    let hostSystemVersionProvider: () -> String

    init(
        fileManager: FileManager = .default,
        hostSystemVersionProvider: @escaping () -> String = {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            return "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        }
    ) {
        self.fileManager = fileManager
        self.hostSystemVersionProvider = hostSystemVersionProvider
    }

    func logFileURL(for layout: VirtualMachineBundleLayout) -> URL {
        layout.logsDirectoryURL.appendingPathComponent("runtime.log", isDirectory: false)
    }

    func append(event: VirtualMachineLogEventKind, summary: String, record: VirtualMachineRecord, layout: VirtualMachineBundleLayout) throws {
        try fileManager.createDirectory(at: layout.logsDirectoryURL, withIntermediateDirectories: true)

        let entry = VirtualMachineLogEntry(
            timestamp: Date(),
            event: event,
            vmID: record.id.rawValue,
            state: record.state.rawValue,
            bootSource: record.bootSource.rawValue,
            summary: summary,
            appVersion: BuildInfo.appVersion,
            hostSystemVersion: hostSystemVersionProvider()
        )

        var data = try encoder.encode(entry)
        data.append(0x0A)

        let logURL = logFileURL(for: layout)
        if fileManager.fileExists(atPath: logURL.path) {
            let handle = try FileHandle(forWritingTo: logURL)
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.close()
        } else {
            try data.write(to: logURL, options: .atomic)
        }
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}