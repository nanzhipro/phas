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
          Section(L10n.text("home.sidebar.virtualMachine", fallback: "Virtual Machine")) {
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
        } else {
          Section(L10n.text("home.sidebar.library", fallback: "Library")) {
            VStack(alignment: .leading, spacing: 6) {
              Text(L10n.text("home.sidebar.noVM", fallback: "No virtual machine yet"))
                .font(.headline)
              Text(model.emptyStateMessage)
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
                title: L10n.text("home.card.gettingStarted", fallback: "Before You Begin"),
                icon: "checkmark.seal",
                lines: model.gettingStartedHighlights
              )
              summaryCard(
                title: L10n.text("home.card.compatibility", fallback: "Compatibility"),
                icon: "cpu",
                lines: model.compatibilityHighlights
              )
            }
            .frame(maxWidth: .infinity)
          }

          summaryCard(
            title: L10n.text("home.card.hostSummary", fallback: "Host Summary"),
            icon: "desktopcomputer",
            lines: hostSummaryLines
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
      L10n.text("home.alert.unableContinue", fallback: "Unable to Continue"),
      isPresented: Binding(
        get: { library.activeErrorMessage != nil },
        set: { newValue in
          if !newValue {
            library.clearError()
          }
        }
      )
    ) {
      Button(L10n.text("action.ok", fallback: "OK"), role: .cancel) {
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
          Button(L10n.text("action.openRuntimeWindow", fallback: "Open Window")) {
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
          title: L10n.text("home.card.currentVM", fallback: "Current VM"),
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

    return L10n.text(
      "home.existingVMMessage",
      fallback:
        "This version supports one virtual machine per Mac. Use the existing VM to continue."
    )
  }

  private var hostSummaryLines: [String] {
    let snapshot = library.hostSnapshot
    return [
      L10n.format(
        "home.host.architecture",
        fallback: "Architecture: %@",
        snapshot.architecture.displayString
      ),
      L10n.format(
        "home.host.system",
        fallback: "System: %@",
        snapshot.operatingSystemVersion.displayString
      ),
      L10n.format(
        "home.host.memory",
        fallback: "Memory: %d GiB total, up to %d GiB recommended for the VM",
        snapshot.totalMemoryGiB,
        snapshot.maximumSafeMemoryMiB / 1024
      ),
      L10n.format(
        "home.host.cpu",
        fallback: "CPU: %d active cores, up to %d vCPU recommended",
        snapshot.activeCPUCount,
        snapshot.maximumSafeCPUCount
      ),
      L10n.format(
        "home.host.preset",
        fallback: "Recommended preset: %@",
        snapshot.recommendedPreset.subtitle
      ),
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
      Label(L10n.text("home.controlSection", fallback: "Controls"), systemImage: "playpause.circle")
        .font(.headline)

      Button(L10n.text("action.openRuntimeWindow", fallback: "Open Window")) {
        openRuntimeWindow()
      }
      .buttonStyle(.borderedProminent)
      .disabled(!availability.canOpenWindow)

      HStack(spacing: 10) {
        Button(L10n.text("action.start", fallback: "Start")) {
          Task {
            await library.startCurrentVirtualMachine()
          }
        }
        .buttonStyle(.bordered)
        .disabled(!availability.canStart)

        Button(L10n.text("action.stop", fallback: "Shut Down")) {
          library.requestCurrentVirtualMachineStop()
        }
        .buttonStyle(.bordered)
        .disabled(!availability.canRequestStop)

        Button(L10n.text("action.forceStop", fallback: "Force Stop")) {
          Task {
            await library.forceStopCurrentVirtualMachine()
          }
        }
        .buttonStyle(.bordered)
        .disabled(!availability.canForceStop)
      }

      HStack(spacing: 10) {
        Button(L10n.text("action.openStorage", fallback: "Open Storage")) {
          openVMStorageFolder()
        }
        .buttonStyle(.bordered)

        Button(L10n.text("action.openLogs", fallback: "Open Logs")) {
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
          Button(L10n.text("action.retryStart", fallback: "Retry Start")) {
            Task {
              await library.startCurrentVirtualMachine()
            }
          }
          .buttonStyle(.borderedProminent)
        }

        if report.actions.canRecoverToStopped {
          Button(L10n.text("action.markStopped", fallback: "Mark as Stopped")) {
            library.recoverCurrentVirtualMachineToStopped()
          }
          .buttonStyle(.bordered)
        }

        if report.actions.canReloadFromDisk {
          Button(L10n.text("action.reload", fallback: "Reload")) {
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
