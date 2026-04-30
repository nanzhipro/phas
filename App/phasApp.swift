import SwiftUI

@main
struct phasApp: App {
    var body: some Scene {
        WindowGroup {
            HomeRootView(model: .default)
                .frame(minWidth: 980, minHeight: 680)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Create Virtual Machine") {
                }
                .keyboardShortcut("n")
            }
        }
    }
}
