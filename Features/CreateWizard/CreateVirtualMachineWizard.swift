import AppKit
import SwiftUI

struct CreateVirtualMachineWizard: View {
  private enum PresetSelection: String, CaseIterable, Identifiable {
    case light
    case standard
    case custom

    var id: String {
      rawValue
    }

    var preset: VirtualMachineResourcePreset? {
      switch self {
      case .light:
        return .light
      case .standard:
        return .standard
      case .custom:
        return nil
      }
    }

    var title: String {
      switch self {
      case .light:
        return L10n.text("preset.light", fallback: "Light")
      case .standard:
        return L10n.text("preset.standard", fallback: "Standard")
      case .custom:
        return L10n.text("preset.custom", fallback: "Custom")
      }
    }
  }

  @ObservedObject var library: VirtualMachineLibrary

  @State private var name: String
  @State private var installImagePath: String
  @State private var cpuCount: Int
  @State private var memoryGiB: Int
  @State private var diskGiB: Int
  @State private var selectedPreset: PresetSelection

  init(library: VirtualMachineLibrary) {
    self.library = library

    let recommendedPreset = library.hostSnapshot.recommendedPreset
    let resources = recommendedPreset.resources

    _name = State(initialValue: "Ubuntu ARM64")
    _installImagePath = State(initialValue: "")
    _cpuCount = State(initialValue: resources.cpuCount)
    _memoryGiB = State(initialValue: resources.memoryMiB / 1024)
    _diskGiB = State(initialValue: resources.diskGiB)
    _selectedPreset = State(initialValue: recommendedPreset == .standard ? .standard : .light)
  }

  var body: some View {
    let report = library.admissionReport(for: draftRequest)
    let snapshot = report.hostSnapshot

    VStack(alignment: .leading, spacing: 18) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 6) {
          Text(L10n.text("wizard.title", fallback: "Create Virtual Machine"))
            .font(.system(size: 28, weight: .bold, design: .rounded))
          Text(
            L10n.text("wizard.subtitle", fallback: "Set up one Linux virtual machine for this Mac.")
          )
          .foregroundStyle(.secondary)
        }
        Spacer()
        Button(L10n.text("action.cancel", fallback: "Cancel")) {
          library.dismissCreateWizard()
        }
        .keyboardShortcut(.cancelAction)
      }

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          card(
            title: L10n.text("home.card.hostSummary", fallback: "Host Summary"),
            systemImage: "desktopcomputer"
          ) {
            infoLine(
              label: L10n.text("wizard.field.architecture", fallback: "Architecture"),
              value: snapshot.architecture.displayString)
            infoLine(
              label: L10n.text("wizard.field.system", fallback: "System"),
              value: snapshot.operatingSystemVersion.displayString)
            infoLine(
              label: L10n.text("wizard.field.memory", fallback: "Memory"),
              value: L10n.format(
                "wizard.value.memory", fallback: "%d GiB total", snapshot.totalMemoryGiB))
            infoLine(
              label: L10n.text("wizard.field.cpu", fallback: "CPU"),
              value: L10n.format(
                "wizard.value.cpu", fallback: "%d active cores", snapshot.activeCPUCount))
            infoLine(
              label: L10n.text("wizard.field.recommendedPreset", fallback: "Recommended Preset"),
              value: snapshot.recommendedPreset.subtitle)
          }

          card(
            title: L10n.text("wizard.card.basics", fallback: "Setup"),
            systemImage: "square.and.pencil"
          ) {
            VStack(alignment: .leading, spacing: 12) {
              TextField(
                L10n.text("wizard.field.namePlaceholder", fallback: "Virtual machine name"),
                text: $name
              )
              .textFieldStyle(.roundedBorder)

              HStack(spacing: 12) {
                TextField(
                  L10n.text(
                    "wizard.field.installImagePlaceholder", fallback: "/path/to/linux-arm64.iso"),
                  text: $installImagePath
                )
                .textFieldStyle(.roundedBorder)
                Button(L10n.text("wizard.button.browse", fallback: "Browse…")) {
                  browseForInstallImage()
                }
              }
            }
          }

          card(
            title: L10n.text("wizard.card.resources", fallback: "Resources"),
            systemImage: "slider.horizontal.3"
          ) {
            VStack(alignment: .leading, spacing: 14) {
              Picker(
                L10n.text("wizard.field.preset", fallback: "Preset"), selection: $selectedPreset
              ) {
                ForEach(PresetSelection.allCases) { selection in
                  Text(selection.title).tag(selection)
                }
              }
              .pickerStyle(.segmented)

              HStack(spacing: 18) {
                Stepper(value: $cpuCount, in: 1...max(snapshot.activeCPUCount, 8)) {
                  Text(L10n.format("wizard.stepper.cpu", fallback: "CPU: %d vCPU", cpuCount))
                }
                Stepper(value: $memoryGiB, in: 1...max(snapshot.totalMemoryGiB, 8)) {
                  Text(L10n.format("wizard.stepper.memory", fallback: "Memory: %d GiB", memoryGiB))
                }
                Stepper(value: $diskGiB, in: 8...256) {
                  Text(L10n.format("wizard.stepper.disk", fallback: "Disk: %d GiB", diskGiB))
                }
              }

              Text(L10n.text("wizard.resourcesHint", fallback: "Light: 2/4/32. Standard: 4/8/64."))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }

          card(
            title: L10n.text("wizard.card.review", fallback: "Checks"),
            systemImage: "exclamationmark.bubble"
          ) {
            if report.issues.isEmpty {
              Text(L10n.text("wizard.ready", fallback: "This setup is ready."))
                .foregroundStyle(.secondary)
            } else {
              VStack(alignment: .leading, spacing: 10) {
                ForEach(report.issues) { issue in
                  HStack(alignment: .top, spacing: 10) {
                    Image(
                      systemName: issue.severity == .blocking
                        ? "xmark.octagon.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(issue.severity == .blocking ? .red : .orange)
                    .padding(.top, 2)
                    Text(issue.message)
                  }
                }
              }
            }
          }
        }
        .padding(.vertical, 4)
      }

      Divider()

      HStack {
        if !report.warnings.isEmpty {
          Text(L10n.text("wizard.warningsHint", fallback: "Warnings won't block creation."))
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Button(L10n.text("wizard.create", fallback: "Create VM")) {
          library.createVirtualMachine(from: draftRequest)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!report.canCreate)
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(24)
    .frame(minWidth: 760, minHeight: 620)
    .onChange(of: selectedPreset) { _, newSelection in
      guard let preset = newSelection.preset else {
        return
      }

      cpuCount = preset.resources.cpuCount
      memoryGiB = preset.resources.memoryMiB / 1024
      diskGiB = preset.resources.diskGiB
    }
    .onChange(of: cpuCount) { _, _ in syncPresetSelection() }
    .onChange(of: memoryGiB) { _, _ in syncPresetSelection() }
    .onChange(of: diskGiB) { _, _ in syncPresetSelection() }
  }

  private var draftRequest: CreateVirtualMachineRequest {
    CreateVirtualMachineRequest(
      name: name,
      installImagePath: installImagePath,
      resources: VirtualMachineResources(
        cpuCount: cpuCount,
        memoryMiB: memoryGiB * 1024,
        diskGiB: diskGiB
      )
    )
  }

  private func syncPresetSelection() {
    let resources = draftRequest.resources
    if resources == VirtualMachineResourcePreset.light.resources {
      selectedPreset = .light
    } else if resources == VirtualMachineResourcePreset.standard.resources {
      selectedPreset = .standard
    } else {
      selectedPreset = .custom
    }
  }

  private func browseForInstallImage() {
    let panel = NSOpenPanel()
    panel.allowedFileTypes = ["iso", "img"]
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowsMultipleSelection = false
    panel.prompt = L10n.text("wizard.prompt.chooseInstallImage", fallback: "Choose Install Image")

    if panel.runModal() == .OK {
      installImagePath = panel.url?.path ?? ""
    }
  }

  private func infoLine(label: String, value: String) -> some View {
    HStack {
      Text(label)
        .foregroundStyle(.secondary)
      Spacer()
      Text(value)
    }
  }

  private func card<Content: View>(
    title: String, systemImage: String, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      Label(title, systemImage: systemImage)
        .font(.headline)
      content()
    }
    .padding(20)
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
}
