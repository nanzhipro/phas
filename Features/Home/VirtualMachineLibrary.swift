import SwiftUI

@MainActor
final class VirtualMachineLibrary: ObservableObject {
    @Published private(set) var records: [VirtualMachineRecord] = []
    @Published var isPresentingCreateWizard = false
    @Published var activeErrorMessage: String?

    private let bundleStore: VirtualMachineBundleStore
    private let hostSnapshotProvider: any HostMachineSnapshotProviding
    private let admissionValidator: any VirtualMachineAdmissionValidating
    private let createUseCase: CreateVirtualMachineUseCase

    init(
        bundleStore: VirtualMachineBundleStore = VirtualMachineBundleStore(),
        hostSnapshotProvider: any HostMachineSnapshotProviding = HostMachineSnapshotProvider(),
        admissionValidator: any VirtualMachineAdmissionValidating = VirtualMachineAdmissionValidator(),
        createUseCase: CreateVirtualMachineUseCase? = nil
    ) {
        self.bundleStore = bundleStore
        self.hostSnapshotProvider = hostSnapshotProvider
        self.admissionValidator = admissionValidator
        self.createUseCase = createUseCase ?? CreateVirtualMachineUseCase(
            bundleStore: bundleStore,
            admissionValidator: admissionValidator
        )
        reload()
    }

    var currentRecord: VirtualMachineRecord? {
        records.first
    }

    var hostSnapshot: HostMachineSnapshot {
        hostSnapshotProvider.snapshot()
    }

    var bundleRootURL: URL {
        bundleStore.bundleRootURL
    }

    var canCreateVirtualMachine: Bool {
        records.isEmpty
    }

    func presentCreateWizard() {
        isPresentingCreateWizard = true
    }

    func dismissCreateWizard() {
        isPresentingCreateWizard = false
    }

    func clearError() {
        activeErrorMessage = nil
    }

    func admissionReport(for request: CreateVirtualMachineRequest) -> VirtualMachineAdmissionReport {
        admissionValidator.validate(request: request, existingRecords: records)
    }

    func bundleLocation(for record: VirtualMachineRecord) -> URL {
        bundleStore.layout(for: record.id).rootURL
    }

    func reload() {
        do {
            records = try bundleStore.listRecords()
        } catch {
            activeErrorMessage = "Failed to load VM bundles. \(error.localizedDescription)"
        }
    }

    func createVirtualMachine(from request: CreateVirtualMachineRequest) {
        do {
            _ = try createUseCase.execute(request: request, existingRecords: records)
            reload()
            isPresentingCreateWizard = false
        } catch {
            activeErrorMessage = error.localizedDescription
        }
    }
}