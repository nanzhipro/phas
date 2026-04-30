import AppKit
import SwiftUI

struct VirtualMachineRuntimeWindowView: View {
  @ObservedObject var library: VirtualMachineLibrary

  var body: some View {
    Group {
      if let session = library.runtimeSession, let record = library.currentRecord {
        HSplitView {
          machinePane(session: session, record: record)
          inspectorPane(record: record)
        }
      } else {
        ContentUnavailableView(
          "Runtime Window Unavailable",
          systemImage: "display",
          description: Text(
            "Create a VM first, then open the runtime window from the home surface.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
      }
    }
    .onAppear {
      library.noteRuntimeWindowOpened()
    }
    .onDisappear {
      library.noteRuntimeWindowClosed()
    }
  }

  private func machinePane(session: VirtualMachineSession, record: VirtualMachineRecord)
    -> some View
  {
    VStack(spacing: 0) {
      runtimeHeader(record: record)

      Divider()

      VirtualMachineViewContainer(machine: session.machine)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    .frame(minWidth: 860, maxWidth: .infinity, maxHeight: .infinity)
  }

  private func inspectorPane(record: VirtualMachineRecord) -> some View {
    let snapshot = library.runtimeDetailSnapshot(for: record)

    return ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Text(snapshot.title)
          .font(.title2.weight(.semibold))

        detailCard(
          title: "Runtime Details",
          icon: "list.bullet.rectangle",
          lines: snapshot.detailLines
        )

        detailCard(
          title: "Current Boundary",
          icon: "scope",
          lines: [
            "Single VM only.",
            "No relaunch recovery yet.",
            "No diagnostics export yet.",
            "Phase-5 owns recovery and diagnostics.",
          ]
        )

        if let report = library.recoveryReport {
          recoveryCard(report)
        }

        HStack(spacing: 10) {
          Button("Open VM Storage") {
            NSWorkspace.shared.open(library.bundleLocation(for: record))
          }
          .buttonStyle(.bordered)

          Button("Open Logs") {
            let logURL = library.logFileURL(for: record)
            let destination =
              FileManager.default.fileExists(atPath: logURL.path)
              ? logURL : logURL.deletingLastPathComponent()
            NSWorkspace.shared.open(destination)
          }
          .buttonStyle(.bordered)
        }
      }
      .padding(24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(minWidth: 320, idealWidth: 360, maxWidth: 420, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
  }

  private func runtimeHeader(record: VirtualMachineRecord) -> some View {
    let availability = library.runtimeControlAvailability

    return VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .center, spacing: 16) {
        VStack(alignment: .leading, spacing: 4) {
          Text(record.name)
            .font(.title2.weight(.semibold))
          Text(record.stateDisplayName)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer()

        HStack(spacing: 10) {
          Button("Start") {
            Task {
              await library.startCurrentVirtualMachine()
            }
          }
          .buttonStyle(.borderedProminent)
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
      }

      if let latestSummary = library.latestRuntimeSummary {
        Text(latestSummary)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .padding(22)
    .background(Color(nsColor: .controlBackgroundColor))
  }

  private func detailCard(title: String, icon: String, lines: [String]) -> some View {
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
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
    )
  }

  private func recoveryCard(_ report: VirtualMachineRecoveryReport) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      Label(report.headline, systemImage: recoveryIcon(for: report.severity))
        .font(.headline)

      Text(report.summary)
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
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
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
