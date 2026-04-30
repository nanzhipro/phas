import SwiftUI

@main
struct phasApp: App {
  static let runtimeWindowID = "vm-runtime"

  @StateObject private var library = VirtualMachineLibrary()

  var body: some Scene {
    WindowGroup {
      HomeRootView(model: .default, library: library)
        .frame(minWidth: 980, minHeight: 680)
    }

    Window("Virtual Machine", id: Self.runtimeWindowID) {
      VirtualMachineRuntimeWindowView(library: library)
        .frame(minWidth: 1200, minHeight: 780)
    }
    .commands {
      CommandGroup(replacing: .newItem) {
        Button("Create Virtual Machine") {
          library.presentCreateWizard()
        }
        .disabled(!library.canCreateVirtualMachine)
        .keyboardShortcut("n")
      }
    }
  }
}
