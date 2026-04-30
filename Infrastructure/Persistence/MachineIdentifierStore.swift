import Foundation
import Virtualization

enum MachineIdentifierStoreError: Error {
  case invalidIdentifierData(URL)
}

struct MachineIdentifierStore {
  let fileManager: FileManager

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  func loadOrCreateData(at url: URL) throws -> Data {
    if fileManager.fileExists(atPath: url.path) {
      return try Data(contentsOf: url)
    }

    try fileManager.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

    let data = VZGenericMachineIdentifier().dataRepresentation
    try data.write(to: url, options: .atomic)
    return data
  }

  func loadMachineIdentifier(at url: URL) throws -> VZGenericMachineIdentifier {
    let data = try Data(contentsOf: url)

    guard let identifier = VZGenericMachineIdentifier(dataRepresentation: data) else {
      throw MachineIdentifierStoreError.invalidIdentifierData(url)
    }

    return identifier
  }

  func loadOrCreateMachineIdentifier(at url: URL) throws -> VZGenericMachineIdentifier {
    let data = try loadOrCreateData(at: url)

    guard let identifier = VZGenericMachineIdentifier(dataRepresentation: data) else {
      throw MachineIdentifierStoreError.invalidIdentifierData(url)
    }

    return identifier
  }
}
