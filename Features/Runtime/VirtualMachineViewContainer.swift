import SwiftUI
import Virtualization

struct VirtualMachineViewContainer: NSViewRepresentable {
  let machine: VZVirtualMachine

  func makeNSView(context: Context) -> VZVirtualMachineView {
    let view = VZVirtualMachineView()
    view.virtualMachine = machine
    return view
  }

  func updateNSView(_ nsView: VZVirtualMachineView, context: Context) {
    nsView.virtualMachine = machine
  }
}
