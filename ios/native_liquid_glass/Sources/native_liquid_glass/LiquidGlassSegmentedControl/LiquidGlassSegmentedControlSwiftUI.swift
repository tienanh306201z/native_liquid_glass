import SwiftUI

// MARK: - ViewModel

@available(iOS 26.0, *)
class LiquidGlassSegmentedControlViewModel: ObservableObject {
  @Published var selection: Int = 0
  @Published var labels: [String] = []
  @Published var enabled: Bool = true
  @Published var tintColor: Color? = nil

  var onChanged: ((Int) -> Void)?
}

// MARK: - SwiftUI View

@available(iOS 26.0, *)
struct LiquidGlassSegmentedControlSwiftUIView: View {
  @ObservedObject var viewModel: LiquidGlassSegmentedControlViewModel

  var body: some View {
    Picker("", selection: selectionBinding) {
      ForEach(0..<viewModel.labels.count, id: \.self) { index in
        Text(viewModel.labels[index]).tag(index)
      }
    }
    .pickerStyle(.segmented)
    .tint(viewModel.tintColor)
    .disabled(!viewModel.enabled)
    .padding(.horizontal, 16)
  }

  private var selectionBinding: Binding<Int> {
    Binding(
      get: { viewModel.selection },
      set: { newValue in
        viewModel.selection = newValue
        viewModel.onChanged?(newValue)
      }
    )
  }
}
