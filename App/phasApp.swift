import SwiftUI

@main
struct phasApp: App {
    @StateObject private var library = VirtualMachineLibrary()

    var body: some Scene {
        WindowGroup {
            HomeRootView(model: .default, library: library)
                .frame(minWidth: 980, minHeight: 680)
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
