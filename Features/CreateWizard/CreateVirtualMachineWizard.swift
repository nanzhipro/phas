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
        return "Light"
      case .standard:
        return "Standard"
      case .custom:
        return "Custom"
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
          Text("Create Virtual Machine")
            .font(.system(size: 28, weight: .bold, design: .rounded))
          Text("Collect the minimum inputs for a single Apple Virtualization Linux install.")
            .foregroundStyle(.secondary)
        }
        Spacer()
        Button("Cancel") {
          library.dismissCreateWizard()
        }
        .keyboardShortcut(.cancelAction)
      }

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          card(title: "Host Summary", systemImage: "desktopcomputer") {
            infoLine(label: "Architecture", value: snapshot.architecture.displayString)
            infoLine(label: "System", value: snapshot.operatingSystemVersion.displayString)
            infoLine(label: "Memory", value: "\(snapshot.totalMemoryGiB) GiB total")
            infoLine(label: "CPU", value: "\(snapshot.activeCPUCount) active cores")
            infoLine(label: "Recommended Preset", value: snapshot.recommendedPreset.subtitle)
          }

          card(title: "Basics", systemImage: "square.and.pencil") {
            VStack(alignment: .leading, spacing: 12) {
              TextField("VM name", text: $name)
                .textFieldStyle(.roundedBorder)

              HStack(spacing: 12) {
                TextField("/path/to/ubuntu-arm64.iso", text: $installImagePath)
                  .textFieldStyle(.roundedBorder)
                Button("Browse…") {
                  browseForInstallImage()
                }
              }
            }
          }

          card(title: "Resources", systemImage: "slider.horizontal.3") {
            VStack(alignment: .leading, spacing: 14) {
              Picker("Preset", selection: $selectedPreset) {
                ForEach(PresetSelection.allCases) { selection in
                  Text(selection.title).tag(selection)
                }
              }
              .pickerStyle(.segmented)

              HStack(spacing: 18) {
                Stepper(value: $cpuCount, in: 1...max(snapshot.activeCPUCount, 8)) {
                  Text("CPU: \(cpuCount) vCPU")
                }
                Stepper(value: $memoryGiB, in: 1...max(snapshot.totalMemoryGiB, 8)) {
                  Text("Memory: \(memoryGiB) GiB")
                }
                Stepper(value: $diskGiB, in: 8...256) {
                  Text("Disk: \(diskGiB) GiB")
                }
              }

              Text(
                "Light: 2/4/32. Standard: 4/8/64. Custom remains bounded by admission rules so the VM can still boot on the current host."
              )
              .font(.footnote)
              .foregroundStyle(.secondary)
            }
          }

          card(title: "Admission Report", systemImage: "exclamationmark.bubble") {
            if report.issues.isEmpty {
              Text(
                "No blocking issues or warnings. This configuration can be created as a draft VM."
              )
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
          Text("Warnings are visible, but only blocking issues disable creation.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Button("Create Draft VM") {
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
    panel.prompt = "Choose Install Image"

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
