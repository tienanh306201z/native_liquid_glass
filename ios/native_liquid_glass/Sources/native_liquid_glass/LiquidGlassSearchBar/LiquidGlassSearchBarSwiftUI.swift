import SwiftUI
import UIKit

// MARK: - SwiftUI Search Bar (iOS 26+)

@available(iOS 26.0, *)
class LiquidGlassSearchBarViewModel: ObservableObject {
  @Published var placeholder: String = "Search"
  @Published var expandable: Bool = true
  @Published var showCancelButton: Bool = true
  @Published var cancelText: String = "Cancel"
  @Published var expandedHeight: CGFloat = 44.0
  @Published var tint: Color? = nil
  @Published var textColor: Color? = nil
  @Published var placeholderColor: Color? = nil
  @Published var cancelButtonColor: Color? = nil
  @Published var iconColor: Color? = nil
  @Published var interactive: Bool = true
  @Published var textFont: Font? = nil
  @Published var textLetterSpacing: CGFloat? = nil
  var glassEffectUnionId: String? = nil
  var glassEffectId: String? = nil
  var borderRadius: CGFloat? = nil

  var onTextChanged: ((String) -> Void)?
  var onSubmitted: ((String) -> Void)?
  var onExpandStateChanged: ((Bool) -> Void)?
  var onCancelTapped: (() -> Void)?
}

@available(iOS 26.0, *)
struct LiquidGlassSearchBarSwiftUI: View {
  @ObservedObject var viewModel: LiquidGlassSearchBarViewModel
  @State private var isExpanded: Bool
  @State private var searchText: String = ""
  @FocusState private var isFocused: Bool
  @Namespace private var animation
  @Namespace private var glassNamespace

  init(viewModel: LiquidGlassSearchBarViewModel, initiallyExpanded: Bool) {
    self.viewModel = viewModel
    self._isExpanded = State(initialValue: initiallyExpanded || !viewModel.expandable)
  }

  private var resolvedShape: AnyShape {
    if let r = viewModel.borderRadius {
      return AnyShape(RoundedRectangle(cornerRadius: r))
    }
    return AnyShape(Capsule())
  }

  var body: some View {
    HStack(spacing: 8) {
      // Search bar container
      HStack(spacing: 8) {
        // Search icon
        Image(systemName: "magnifyingglass")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(viewModel.iconColor ?? viewModel.tint ?? .secondary)
          .matchedGeometryEffect(id: "searchIcon", in: animation)

        if isExpanded {
          // Text field
          TextField(viewModel.placeholder, text: $searchText)
            .foregroundColor(viewModel.textColor ?? .primary)
            .font(viewModel.textFont)
            .focused($isFocused)
            .submitLabel(.search)
            .onSubmit {
              viewModel.onSubmitted?(searchText)
            }
            .onChange(of: searchText) { _, newValue in
              viewModel.onTextChanged?(newValue)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))

          // Clear button
          if !searchText.isEmpty {
            Button(action: {
              searchText = ""
              viewModel.onTextChanged?("")
            }) {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(viewModel.placeholderColor ?? .secondary)
            }
            .transition(.opacity.combined(with: .scale))
          }
        }
      }
      .padding(.horizontal, 12)
      .frame(height: viewModel.expandedHeight)
      .frame(maxWidth: isExpanded ? .infinity : 44)
      .glassEffect(
        viewModel.interactive ? Glass.regular.interactive() : Glass.regular, in: resolvedShape
      )
      .applySearchBarGlassModifiers(
        unionId: viewModel.glassEffectUnionId, effectId: viewModel.glassEffectId,
        namespace: glassNamespace
      )
      .contentShape(resolvedShape)
      .onTapGesture {
        if !isExpanded && viewModel.expandable {
          withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isExpanded = true
            viewModel.onExpandStateChanged?(true)
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isFocused = true
          }
        }
      }

      // Cancel button
      if viewModel.showCancelButton && isExpanded {
        Button(action: {
          withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isExpanded = false
            searchText = ""
            isFocused = false
            viewModel.onExpandStateChanged?(false)
            viewModel.onCancelTapped?()
          }
        }) {
          Text(viewModel.cancelText)
            .foregroundColor(viewModel.cancelButtonColor ?? viewModel.tint ?? .accentColor)
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
      }
    }
    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
  }
}

@available(iOS 26.0, *)
extension View {
  @ViewBuilder
  fileprivate func applySearchBarGlassModifiers(
    unionId: String?, effectId: String?, namespace: Namespace.ID
  ) -> some View {
    if let uid = unionId {
      if let eid = effectId {
        self.glassEffectUnion(id: uid, namespace: namespace)
          .glassEffectID(eid, in: namespace)
      } else {
        self.glassEffectUnion(id: uid, namespace: namespace)
      }
    } else if let eid = effectId {
      self.glassEffectID(eid, in: namespace)
    } else {
      self
    }
  }
}
