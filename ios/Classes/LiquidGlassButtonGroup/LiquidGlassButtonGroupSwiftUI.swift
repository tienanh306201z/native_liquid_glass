import Flutter
import SwiftUI
import UIKit

// MARK: - Data model

@available(iOS 26.0, *)
struct LiquidGlassButtonData: Identifiable {
  let id = UUID()
  let buttonConfig: LiquidGlassButtonConfig
  let onPressed: () -> Void
}

// MARK: - View model

@available(iOS 26.0, *)
class LiquidGlassButtonGroupViewModel: ObservableObject {
  @Published var buttons: [LiquidGlassButtonData] = []
  @Published var axis: Axis = .horizontal
  @Published var spacing: CGFloat = 8.0
  @Published var spacingForGlass: CGFloat = 40.0

  func updateButtons(_ newButtons: [LiquidGlassButtonData]) {
    buttons = newButtons
  }
}

// MARK: - SwiftUI group view

@available(iOS 26.0, *)
struct LiquidGlassButtonGroupSwiftUI: View {
  @ObservedObject var viewModel: LiquidGlassButtonGroupViewModel
  @Namespace private var namespace

  /// For horizontal groups with multiple buttons, use a higher effective spacing
  /// so the glass blend starts sooner and reduces gaps between icons.
  private var effectiveSpacingForGlass: CGFloat {
    if viewModel.axis == .horizontal, viewModel.buttons.count >= 2 {
      return max(viewModel.spacingForGlass, 80)
    }
    return viewModel.spacingForGlass
  }

  var body: some View {
    GlassEffectContainer(spacing: effectiveSpacingForGlass) {
      if viewModel.axis == .horizontal {
        HStack(alignment: .center, spacing: viewModel.spacing) {
          ForEach(Array(viewModel.buttons.enumerated()), id: \.offset) { _, button in
            LiquidGlassButtonGroupItemView(
              config: button.buttonConfig,
              onPressed: button.onPressed,
              namespace: namespace
            )
            .fixedSize(horizontal: true, vertical: false)
          }
        }
        .frame(minHeight: 0, maxHeight: .infinity, alignment: .center)
      } else {
        VStack(alignment: .center, spacing: viewModel.spacing) {
          ForEach(Array(viewModel.buttons.enumerated()), id: \.offset) { _, button in
            LiquidGlassButtonGroupItemView(
              config: button.buttonConfig,
              onPressed: button.onPressed,
              namespace: namespace
            )
            .fixedSize(horizontal: true, vertical: false)
          }
        }
        .frame(minHeight: 0, maxHeight: .infinity, alignment: .center)
      }
    }
    .frame(minHeight: 0, maxHeight: .infinity, alignment: .center)
    .ignoresSafeArea()
  }
}
