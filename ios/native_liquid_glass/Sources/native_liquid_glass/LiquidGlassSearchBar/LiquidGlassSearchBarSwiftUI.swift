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

  // MARK: - Command state (driven by the host via the method channel)
  //
  // The SwiftUI view binds its text/expansion/focus to these published
  // properties, so mutating them here drives `expand/collapse/clear/setText/
  // focus/unfocus` on the iOS 26+ SwiftUI path (which has no UIKit searchBar).
  @Published var searchText: String = ""
  @Published var isExpanded: Bool = false
  @Published var isFocused: Bool = false

  var onTextChanged: ((String) -> Void)?
  var onSubmitted: ((String) -> Void)?
  var onExpandStateChanged: ((Bool) -> Void)?
  var onCancelTapped: (() -> Void)?

  // MARK: - Host-driven commands

  func setText(_ text: String) {
    searchText = text
  }

  func clearText() {
    searchText = ""
  }

  func expand() {
    if !isExpanded {
      isExpanded = true
      onExpandStateChanged?(true)
    }
  }

  func collapse() {
    if isExpanded {
      isExpanded = false
      searchText = ""
      isFocused = false
      onExpandStateChanged?(false)
    }
  }

  func requestFocus() {
    if expandable {
      isExpanded = true
    }
    isFocused = true
  }

  func resignFocus() {
    isFocused = false
  }
}

@available(iOS 26.0, *)
struct LiquidGlassSearchBarSwiftUI: View {
  @ObservedObject var viewModel: LiquidGlassSearchBarViewModel
  @FocusState private var isFocused: Bool
  @Namespace private var animation
  @Namespace private var glassNamespace

  // Expansion and text are owned by the view model so the host can drive
  // `expand/collapse/clear/setText/focus/unfocus` over the method channel.
  private var isExpanded: Bool { viewModel.isExpanded }
  private var searchText: Binding<String> {
    Binding(get: { viewModel.searchText }, set: { viewModel.searchText = $0 })
  }

  init(viewModel: LiquidGlassSearchBarViewModel, initiallyExpanded: Bool) {
    self.viewModel = viewModel
    viewModel.isExpanded = initiallyExpanded || !viewModel.expandable
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
          TextField(viewModel.placeholder, text: searchText)
            .foregroundColor(viewModel.textColor ?? .primary)
            .font(viewModel.textFont)
            .focused($isFocused)
            .submitLabel(.search)
            .onSubmit {
              viewModel.onSubmitted?(viewModel.searchText)
            }
            .onChange(of: viewModel.searchText) { _, newValue in
              viewModel.onTextChanged?(newValue)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))

          // Clear button
          if !viewModel.searchText.isEmpty {
            Button(action: {
              viewModel.searchText = ""
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
            viewModel.isExpanded = true
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
            viewModel.isExpanded = false
            viewModel.searchText = ""
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
    .animation(.easeInOut(duration: 0.2), value: viewModel.searchText.isEmpty)
    // Sync focus driven by the host (focus/unfocus commands) into the field.
    .onChange(of: viewModel.isFocused) { _, newValue in
      if isFocused != newValue {
        isFocused = newValue
      }
    }
    // Reflect user-driven focus changes back onto the view model.
    .onChange(of: isFocused) { _, newValue in
      if viewModel.isFocused != newValue {
        viewModel.isFocused = newValue
      }
    }
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
