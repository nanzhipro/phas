import AppKit
import SwiftUI

struct HomeRootView: View {
  @Environment(\.openWindow) private var openWindow

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
            vmOverviewSection(record)
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
    .alert(
      "Unable to Continue",
      isPresented: Binding(
        get: { library.activeErrorMessage != nil },
        set: { newValue in
          if !newValue {
            library.clearError()
          }
        }
      )
    ) {
      Button("OK", role: .cancel) {
        library.clearError()
      }
    } message: {
      Text(library.activeErrorMessage ?? "")
    }
    .task(id: library.pendingRuntimeWindowRestoration) {
      restoreRuntimeWindowIfNeeded()
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
        if library.currentRecord == nil {
          Button(model.primaryActionTitle) {
            library.presentCreateWizard()
          }
          .buttonStyle(.borderedProminent)
          .disabled(!library.canCreateVirtualMachine)
        } else {
          Button("Open Runtime Window") {
            openRuntimeWindow()
          }
          .buttonStyle(.borderedProminent)
          .disabled(!library.runtimeControlAvailability.canOpenWindow)
        }

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
              Color(nsColor: .windowBackgroundColor),
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

  private func vmOverviewSection(_ record: VirtualMachineRecord) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack(alignment: .top, spacing: 20) {
        let snapshot = library.runtimeDetailSnapshot(for: record)
        summaryCard(
          title: "Current VM",
          icon: "shippingbox.circle",
          lines: snapshot.detailLines
        )

        runtimeControlCard(record)
      }

      if let report = library.recoveryReport {
        recoveryDiagnosticsCard(report)
      }
    }
    .frame(maxWidth: .infinity)
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

    return
      "A single VM already exists. The MVP stays intentionally single-VM, so creation remains blocked while runtime inspection, start/stop control, and error handling now move into the main product surface."
  }

  private var hostSummaryLines: [String] {
    let snapshot = library.hostSnapshot
    return [
      "Host architecture: \(snapshot.architecture.displayString).",
      "Host system: \(snapshot.operatingSystemVersion.displayString).",
      "Host memory: \(snapshot.totalMemoryGiB) GiB total, \(snapshot.maximumSafeMemoryMiB / 1024) GiB safe ceiling for the VM.",
      "Host CPU: \(snapshot.activeCPUCount) active cores, up to \(snapshot.maximumSafeCPUCount) vCPU safe for the VM.",
      "Recommended preset: \(snapshot.recommendedPreset.subtitle).",
    ]
  }

  private func openVMStorageFolder() {
    NSWorkspace.shared.open(library.bundleRootURL)
  }

  private func openRuntimeWindow() {
    guard library.prepareRuntimeWindow() else {
      return
    }

    openWindow(id: phasApp.runtimeWindowID)
  }

  private func restoreRuntimeWindowIfNeeded() {
    guard library.consumePendingRuntimeWindowRestoration() else {
      return
    }

    guard library.prepareRuntimeWindow() else {
      return
    }

    openWindow(id: phasApp.runtimeWindowID)
  }

  private func openRuntimeLogs(for record: VirtualMachineRecord) {
    let logURL = library.logFileURL(for: record)
    let destination =
      FileManager.default.fileExists(atPath: logURL.path)
      ? logURL : logURL.deletingLastPathComponent()
    NSWorkspace.shared.open(destination)
  }

  private func runtimeControlCard(_ record: VirtualMachineRecord) -> some View {
    let availability = library.runtimeControlAvailability

    return VStack(alignment: .leading, spacing: 16) {
      Label("Lifecycle", systemImage: "playpause.circle")
        .font(.headline)

      Text(
        "Phase-4 keeps the UI bound to product-level state and the phase-3 session service. The window, controls, and detail surface stay on the single-VM MVP path."
      )
      .font(.subheadline)
      .foregroundStyle(.secondary)

      Button("Open Runtime Window") {
        openRuntimeWindow()
      }
      .buttonStyle(.borderedProminent)
      .disabled(!availability.canOpenWindow)

      HStack(spacing: 10) {
        Button("Start") {
          Task {
            await library.startCurrentVirtualMachine()
          }
        }
        .buttonStyle(.bordered)
        .disabled(!availability.canStart)

        Button("Request Stop") {
          library.requestCurrentVirtualMachineStop()
        }
        .buttonStyle(.bordered)
        .disabled(!availability.canRequestStop)

        Button("Force Stop") {
          Task {
            await library.forceStopCurrentVirtualMachine()
          }
        }
        .buttonStyle(.bordered)
        .disabled(!availability.canForceStop)
      }

      HStack(spacing: 10) {
        Button("Open VM Storage") {
          openVMStorageFolder()
        }
        .buttonStyle(.bordered)

        Button("Open Logs") {
          openRuntimeLogs(for: record)
        }
        .buttonStyle(.bordered)
      }

      if let latestSummary = library.latestRuntimeSummary {
        Text(latestSummary)
          .font(.footnote)
          .foregroundStyle(.secondary)
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

  private func recoveryDiagnosticsCard(_ report: VirtualMachineRecoveryReport) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Label(report.headline, systemImage: recoveryIcon(for: report.severity))
        .font(.headline)

      Text(report.summary)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      HStack(spacing: 10) {
        if report.actions.canRetryStart {
          Button("Retry Start") {
            Task {
              await library.startCurrentVirtualMachine()
            }
          }
          .buttonStyle(.borderedProminent)
        }

        if report.actions.canRecoverToStopped {
          Button("Recover to Stopped") {
            library.recoverCurrentVirtualMachineToStopped()
          }
          .buttonStyle(.bordered)
        }

        if report.actions.canReloadFromDisk {
          Button("Reload State") {
            library.reload()
          }
          .buttonStyle(.bordered)
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
        .strokeBorder(recoveryColor(for: report.severity).opacity(0.24), lineWidth: 1)
    )
  }

  private func recoveryIcon(for severity: VirtualMachineRecoverySeverity) -> String {
    switch severity {
    case .healthy:
      return "checkmark.shield"
    case .warning:
      return "exclamationmark.triangle"
    case .error:
      return "bolt.horizontal.circle"
    }
  }

  private func recoveryColor(for severity: VirtualMachineRecoverySeverity) -> Color {
    switch severity {
    case .healthy:
      return .green
    case .warning:
      return .orange
    case .error:
      return .red
    }
  }
}

#Preview {
  HomeRootView(model: .default, library: VirtualMachineLibrary())
    .frame(width: 1200, height: 800)
}
