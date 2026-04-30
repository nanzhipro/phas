import AppKit
import SwiftUI

struct HomeRootView: View {
    let model: HomeScreenModel
    @ObservedObject var library: VirtualMachineLibrary

    var body: some View {
        NavigationSplitView {
            List {
                if let record = library.currentRecord {
                    Section("Virtual Machine") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(record.name)
                                .font(.headline)
                            Text(record.stateDisplayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(record.resourceSummary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Project") {
                    ForEach(model.sidebarSections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title)
                                .font(.headline)
                            Text(section.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("phas")
            .frame(minWidth: 280)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    heroCard
                    if let record = library.currentRecord {
                        vmSummaryCard(record)
                    } else {
                        HStack(alignment: .top, spacing: 20) {
                            summaryCard(
                                title: "Acceptance Target",
                                icon: "checkmark.seal",
                                lines: model.acceptanceTargets
                            )
                            summaryCard(
                                title: "Support Matrix",
                                icon: "cpu",
                                lines: model.supportMatrix
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }

                    summaryCard(
                        title: "Host Summary",
                        icon: "desktopcomputer",
                        lines: hostSummaryLines
                    )

                    summaryCard(
                        title: "Implementation Trail",
                        icon: "shippingbox",
                        lines: model.phaseZeroDeliverables
                    )
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .sheet(isPresented: $library.isPresentingCreateWizard) {
            CreateVirtualMachineWizard(library: library)
        }
        .alert("Unable to Continue", isPresented: Binding(
            get: { library.activeErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    library.clearError()
                }
            }
        )) {
            Button("OK", role: .cancel) {
                library.clearError()
            }
        } message: {
            Text(library.activeErrorMessage ?? "")
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(model.subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
            Divider()
            Text(heroMessage)
                .font(.body)
                .foregroundStyle(.primary)
            HStack(spacing: 12) {
                Button(model.primaryActionTitle) {
                    library.presentCreateWizard()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!library.canCreateVirtualMachine)

                Button(model.secondaryActionTitle) {
                    openVMStorageFolder()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(nsColor: .controlAccentColor).opacity(0.18),
                            Color(nsColor: .windowBackgroundColor)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func vmSummaryCard(_ record: VirtualMachineRecord) -> some View {
        summaryCard(
            title: "Current VM",
            icon: "shippingbox.circle",
            lines: [
                "State: \(record.stateDisplayName)",
                "Resources: \(record.resourceSummary)",
                "Install image: \(record.installImagePath ?? "Not set")",
                "Bundle: \(library.bundleLocation(for: record).path)"
            ]
        )
    }

    private func summaryCard(title: String, icon: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.headline)
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .padding(.top, 7)
                        .foregroundStyle(.secondary)
                    Text(line)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var heroMessage: String {
        if library.currentRecord == nil {
            return model.emptyStateMessage
        }

        return "A single draft VM already exists. The MVP stays intentionally single-VM, so creation is now blocked until delete support lands in a later phase."
    }

    private var hostSummaryLines: [String] {
        let snapshot = library.hostSnapshot
        return [
            "Host architecture: \(snapshot.architecture.displayString).",
            "Host system: \(snapshot.operatingSystemVersion.displayString).",
            "Host memory: \(snapshot.totalMemoryGiB) GiB total, \(snapshot.maximumSafeMemoryMiB / 1024) GiB safe ceiling for the VM.",
            "Host CPU: \(snapshot.activeCPUCount) active cores, up to \(snapshot.maximumSafeCPUCount) vCPU safe for the VM.",
            "Recommended preset: \(snapshot.recommendedPreset.subtitle)."
        ]
    }

    private func openVMStorageFolder() {
        NSWorkspace.shared.open(library.bundleRootURL)
    }
}

#Preview {
    HomeRootView(model: .default, library: VirtualMachineLibrary())
        .frame(width: 1200, height: 800)
}
