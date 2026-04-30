import Foundation
import Virtualization

struct EFIVariableStoreManager {
  let fileManager: FileManager

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  func loadOrCreate(at url: URL) throws -> VZEFIVariableStore {
    try fileManager.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

    if fileManager.fileExists(atPath: url.path) {
      return VZEFIVariableStore(url: url)
    }

    return try VZEFIVariableStore(creatingVariableStoreAt: url)
  }
}
