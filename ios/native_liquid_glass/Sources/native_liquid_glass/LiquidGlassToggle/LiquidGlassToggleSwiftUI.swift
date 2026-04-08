import SwiftUI

// MARK: - ViewModel

@available(iOS 26.0, *)
class LiquidGlassToggleViewModel: ObservableObject {
  @Published var isOn: Bool = false
  @Published var enabled: Bool = true
  @Published var tintColor: Color? = nil

  var onChanged: ((Bool) -> Void)?
}

// MARK: - SwiftUI View

@available(iOS 26.0, *)
struct LiquidGlassToggleSwiftUIView: View {
  @ObservedObject var viewModel: LiquidGlassToggleViewModel

  var body: some View {
    Toggle("", isOn: Binding(
      get: { viewModel.isOn },
      set: { newValue in
        viewModel.isOn = newValue
        viewModel.onChanged?(newValue)
      }
    ))
    .labelsHidden()
    .tint(viewModel.tintColor)
    .disabled(!viewModel.enabled)
  }
}
