import Foundation

enum CreateVirtualMachineUseCaseError: LocalizedError {
  case blockingIssues([String])

  var errorDescription: String? {
    switch self {
    case .blockingIssues(let messages):
      return messages.joined(separator: "\n")
    }
  }
}

struct CreateVirtualMachineUseCase {
  let bundleStore: VirtualMachineBundleStore
  let admissionValidator: any VirtualMachineAdmissionValidating
  let now: () -> Date

  init(
    bundleStore: VirtualMachineBundleStore = VirtualMachineBundleStore(),
    admissionValidator: any VirtualMachineAdmissionValidating = VirtualMachineAdmissionValidator(),
    now: @escaping () -> Date = Date.init
  ) {
    self.bundleStore = bundleStore
    self.admissionValidator = admissionValidator
    self.now = now
  }

  func execute(
    request: CreateVirtualMachineRequest,
    existingRecords: [VirtualMachineRecord]
  ) throws -> VirtualMachineRecord {
    let report = admissionValidator.validate(request: request, existingRecords: existingRecords)

    guard report.canCreate else {
      throw CreateVirtualMachineUseCaseError.blockingIssues(report.blockingIssues.map(\.message))
    }

    let timestamp = now()
    let record = VirtualMachineRecord(
      id: VirtualMachineID(),
      name: request.trimmedName,
      installImagePath: request.normalizedInstallImagePath,
      resources: request.resources,
      bootSource: .installationImage,
      distributionSupport: report.inferredDistributionSupport,
      state: .draft,
      createdAt: timestamp,
      updatedAt: timestamp
    )

    try bundleStore.bootstrapBundle(for: record)
    return record
  }
}
