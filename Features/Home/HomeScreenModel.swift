import Foundation

struct HomeScreenModel: Equatable {
  struct SidebarSection: Equatable {
    let title: String
    let detail: String
  }

  let title: String
  let subtitle: String
  let emptyStateMessage: String
  let primaryActionTitle: String
  let secondaryActionTitle: String
  let sidebarSections: [SidebarSection]
  let acceptanceTargets: [String]
  let supportMatrix: [String]
  let phaseZeroDeliverables: [String]
}

extension HomeScreenModel {
  static let `default` = HomeScreenModel(
    title: "Local Linux VM, kept intentionally narrow.",
    subtitle: "A single-VM Apple Virtualization MVP for Apple silicon Macs.",
    emptyStateMessage:
      "No virtual machines exist yet. This phase establishes the native app shell, build pipeline, entitlement wiring, and the placeholder surface where VM creation, lifecycle control, and diagnostics will land in later phases.",
    primaryActionTitle: "Create Virtual Machine",
    secondaryActionTitle: "Open VM Storage",
    sidebarSections: [
      SidebarSection(
        title: "Current Focus",
        detail: "Phase-0 locks the app entry point, entitlement, and shell layout."
      ),
      SidebarSection(
        title: "Runtime Promise",
        detail: "Single VM, GUI install flow, persistent disk, NAT networking."
      ),
      SidebarSection(
        title: "Out of Scope",
        detail: "Snapshots, bridged networking, shared folders, clipboard sync, Intel support."
      ),
    ],
    acceptanceTargets: [
      "Create, install, restart, and delete one Linux VM from a native macOS app.",
      "Preserve VM bundle data under ~/Library/Application Support/phas/VMs/.",
      "Keep every failure path attached to an explicit recovery action instead of silent mutation.",
    ],
    supportMatrix: [
      "Host: Apple silicon + macOS 14 or newer.",
      "Primary validation image: Ubuntu Desktop ARM64 LTS.",
      "Secondary compatibility pass: Fedora Workstation ARM64.",
    ],
    phaseZeroDeliverables: [
      "SwiftUI app entry point and stable empty-state home screen.",
      "Virtualization entitlement wired into the target.",
      "Documented xcodegen + xcodebuild workflow that succeeds on the current toolchain.",
    ]
  )
}
