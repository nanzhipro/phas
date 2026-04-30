import Foundation

struct HomeScreenModel: Equatable {
  let title: String
  let subtitle: String
  let emptyStateMessage: String
  let primaryActionTitle: String
  let secondaryActionTitle: String
  let gettingStartedHighlights: [String]
  let compatibilityHighlights: [String]
}

extension HomeScreenModel {
  static let `default` = HomeScreenModel(
    title: L10n.text("home.title", fallback: "Linux virtual machine for your Mac."),
    subtitle: L10n.text(
      "home.subtitle", fallback: "Create, run, and manage one local Linux VM."),
    emptyStateMessage: L10n.text(
      "home.emptyStateMessage",
      fallback: "Create a virtual machine to install Linux and keep it on this Mac."),
    primaryActionTitle: L10n.text("action.createVM", fallback: "Create VM"),
    secondaryActionTitle: L10n.text("action.openStorage", fallback: "Open Storage"),
    gettingStartedHighlights: [
      L10n.text("home.gettingStarted.1", fallback: "Prepare a Linux ARM64 ISO image."),
      L10n.text(
        "home.gettingStarted.2",
        fallback: "Choose CPU, memory, and disk size for this Mac."),
      L10n.text(
        "home.gettingStarted.3",
        fallback: "Complete installation in the runtime window."),
    ],
    compatibilityHighlights: [
      L10n.text(
        "home.support.1", fallback: "Host Mac: Apple silicon, macOS 14 or later."),
      L10n.text(
        "home.support.2", fallback: "Recommended image: Ubuntu Desktop ARM64 LTS."),
      L10n.text(
        "home.support.3", fallback: "Also tested with Fedora Workstation ARM64."),
    ]
  )
}
