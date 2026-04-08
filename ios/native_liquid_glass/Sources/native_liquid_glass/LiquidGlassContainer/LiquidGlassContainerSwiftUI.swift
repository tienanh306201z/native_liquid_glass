import SwiftUI
import UIKit

// MARK: - SwiftUI Glass Container (iOS 26+)

@available(iOS 26.0, *)
struct LiquidGlassContainerSwiftUIView: View {
  let effect: String
  let shape: String
  let cornerRadius: CGFloat?
  let tint: UIColor?
  let interactive: Bool
  let glassEffectUnionId: String?
  let glassEffectId: String?
  @Namespace private var namespace

  var body: some View {
    GeometryReader { geometry in
      resolvedShape()
        .fill(Color.clear)
        .allowsHitTesting(false)
        .glassEffect(resolvedGlassEffect(), in: resolvedShape())
        .applyLiquidGlassContainerModifiers(
          unionId: glassEffectUnionId,
          id: glassEffectId,
          namespace: namespace
        )
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
  }

  private func resolvedGlassEffect() -> Glass {
    var glass: Glass = effect == "clear" ? Glass.clear : Glass.regular

    if let tintColor = tint {
      glass = glass.tint(Color(tintColor))
    }

    if interactive {
      glass = glass.interactive()
    }

    return glass
  }

  private func resolvedShape() -> AnyShape {
    switch shape {
    case "circle":
      return AnyShape(Circle())
    case "capsule":
      return AnyShape(Capsule())
    case "rect":
      let radius = cornerRadius ?? 16.0
      return AnyShape(RoundedRectangle(cornerRadius: radius))
    default:
      let radius = cornerRadius ?? 16.0
      return AnyShape(RoundedRectangle(cornerRadius: radius))
    }
  }
}

@available(iOS 26.0, *)
extension View {
  @ViewBuilder
  func applyLiquidGlassContainerModifiers(
    unionId: String?,
    id: String?,
    namespace: Namespace.ID
  ) -> some View {
    if let unionId = unionId {
      if let id = id {
        self
          .glassEffectUnion(id: unionId, namespace: namespace)
          .glassEffectID(id, in: namespace)
      } else {
        self
          .glassEffectUnion(id: unionId, namespace: namespace)
      }
    } else if let id = id {
      self
        .glassEffectID(id, in: namespace)
    } else {
      self
    }
  }
}
