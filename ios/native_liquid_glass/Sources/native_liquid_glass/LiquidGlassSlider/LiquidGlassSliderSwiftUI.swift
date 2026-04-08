import SwiftUI

// MARK: - ViewModel

@available(iOS 26.0, *)
class LiquidGlassSliderViewModel: ObservableObject {
  @Published var value: Double = 0
  @Published var minValue: Double = 0
  @Published var maxValue: Double = 1
  @Published var step: Double? = nil
  @Published var enabled: Bool = true
  @Published var tintColor: Color? = nil

  var onChanged: ((Double) -> Void)?
}

// MARK: - SwiftUI View

@available(iOS 26.0, *)
struct LiquidGlassSliderSwiftUIView: View {
  @ObservedObject var viewModel: LiquidGlassSliderViewModel

  var body: some View {
    Group {
      if let step = viewModel.step, step > 0 {
        Slider(
          value: valueBinding,
          in: viewModel.minValue...viewModel.maxValue,
          step: step
        )
      } else {
        Slider(
          value: valueBinding,
          in: viewModel.minValue...viewModel.maxValue
        )
      }
    }
    .tint(viewModel.tintColor)
    .disabled(!viewModel.enabled)
    .padding(.horizontal, 16)
  }

  private var valueBinding: Binding<Double> {
    Binding(
      get: { viewModel.value },
      set: { newValue in
        viewModel.value = newValue
        viewModel.onChanged?(newValue)
      }
    )
  }
}
