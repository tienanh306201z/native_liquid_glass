import SwiftUI
import UIKit

// MARK: - Observable ViewModel

@available(iOS 26.0, *)
final class LiquidGlassContainerViewModel: ObservableObject {
  @Published var effect: String = "regular"
  @Published var shape: String = "rect"
  @Published var cornerRadius: CGFloat? = nil
  @Published var tint: UIColor? = nil
  @Published var interactive: Bool = false
  @Published var glassEffectUnionId: String? = nil
  @Published var glassEffectId: String? = nil
  @Published var customPathOps: [[Any]]? = nil
  @Published var customPathWidth: CGFloat? = nil
  @Published var customPathHeight: CGFloat? = nil

  /// Normalised + padded path data for animatable custom shapes.
  @Published var normalizedPathData: [CGFloat] = []

  var isCustom: Bool {
    shape == "custom"
      && customPathOps != nil
      && (customPathWidth ?? 0) > 0
      && (customPathHeight ?? 0) > 0
  }

  func update(from args: [String: Any]?, animated: Bool) {
    let apply = {
      self.effect = (args?["effect"] as? String) ?? "regular"
      self.shape = (args?["shape"] as? String) ?? "rect"
      self.cornerRadius = (args?["cornerRadius"] as? NSNumber).map { CGFloat($0.doubleValue) }
      self.interactive = (args?["interactive"] as? Bool) ?? false
      self.tint = Self.decodeColor(from: args?["tint"])
      self.glassEffectUnionId = {
        let v = args?["glassEffectUnionId"] as? String
        return (v?.isEmpty == false) ? v : nil
      }()
      self.glassEffectId = {
        let v = args?["glassEffectId"] as? String
        return (v?.isEmpty == false) ? v : nil
      }()
      self.customPathOps = args?["customPath"] as? [[Any]]
      self.customPathWidth = (args?["customPathWidth"] as? NSNumber).map { CGFloat($0.doubleValue) }
      self.customPathHeight = (args?["customPathHeight"] as? NSNumber).map { CGFloat($0.doubleValue) }

      // Normalise custom path ops into a fixed-length float array for animation.
      if let ops = self.customPathOps,
         let w = self.customPathWidth, w > 0,
         let h = self.customPathHeight, h > 0 {
        self.normalizedPathData = Self.normalizeOps(ops, sourceWidth: w, sourceHeight: h)
      }
    }

    if animated {
      withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
        apply()
      }
    } else {
      apply()
    }
  }

  // MARK: - Path normalisation

  /// Max cubic segments the animatable path supports. Paths with fewer
  /// segments are padded with degenerate cubics at the last point.
  private static let maxSegments = 32

  /// Converts raw path ops into a fixed-length `[CGFloat]` normalised to [0,1].
  /// All ops are converted to cubic beziers so the array always has the
  /// same structure, enabling smooth interpolation between any two paths.
  static func normalizeOps(_ ops: [[Any]], sourceWidth: CGFloat, sourceHeight: CGFloat) -> [CGFloat] {
    var coords: [CGFloat] = []
    var prevX: CGFloat = 0
    var prevY: CGFloat = 0
    var firstX: CGFloat = 0
    var firstY: CGFloat = 0
    var segCount = 0

    for op in ops {
      guard let verb = op.first as? String else { continue }
      if segCount >= maxSegments { break }

      switch verb {
      case "moveTo":
        guard op.count >= 3 else { continue }
        let x = cgFloat(op[1]) / sourceWidth
        let y = cgFloat(op[2]) / sourceHeight
        if coords.isEmpty {
          coords.append(contentsOf: [x, y])
          firstX = x; firstY = y
        }
        prevX = x; prevY = y

      case "lineTo":
        guard op.count >= 3 else { continue }
        let x = cgFloat(op[1]) / sourceWidth
        let y = cgFloat(op[2]) / sourceHeight
        coords.append(contentsOf: [prevX, prevY, x, y, x, y])
        prevX = x; prevY = y
        segCount += 1

      case "cubicTo":
        guard op.count >= 7 else { continue }
        let c1x = cgFloat(op[1]) / sourceWidth
        let c1y = cgFloat(op[2]) / sourceHeight
        let c2x = cgFloat(op[3]) / sourceWidth
        let c2y = cgFloat(op[4]) / sourceHeight
        let x   = cgFloat(op[5]) / sourceWidth
        let y   = cgFloat(op[6]) / sourceHeight
        coords.append(contentsOf: [c1x, c1y, c2x, c2y, x, y])
        prevX = x; prevY = y
        segCount += 1

      case "quadTo":
        guard op.count >= 5 else { continue }
        let cx = cgFloat(op[1]) / sourceWidth
        let cy = cgFloat(op[2]) / sourceHeight
        let x  = cgFloat(op[3]) / sourceWidth
        let y  = cgFloat(op[4]) / sourceHeight
        let c1x = prevX + 2.0 / 3.0 * (cx - prevX)
        let c1y = prevY + 2.0 / 3.0 * (cy - prevY)
        let c2x = x + 2.0 / 3.0 * (cx - x)
        let c2y = y + 2.0 / 3.0 * (cy - y)
        coords.append(contentsOf: [c1x, c1y, c2x, c2y, x, y])
        prevX = x; prevY = y
        segCount += 1

      case "close":
        if prevX != firstX || prevY != firstY {
          coords.append(contentsOf: [prevX, prevY, firstX, firstY, firstX, firstY])
          prevX = firstX; prevY = firstY
          segCount += 1
        }

      default:
        break
      }
    }

    // Ensure we have at least the moveTo.
    if coords.count < 2 { coords = [0, 0] }

    // Pad remaining segments with degenerate cubics at the last point.
    let lastX = coords[coords.count - 2]
    let lastY = coords[coords.count - 1]
    while segCount < maxSegments {
      coords.append(contentsOf: [lastX, lastY, lastX, lastY, lastX, lastY])
      segCount += 1
    }

    return coords
  }

  private static func cgFloat(_ value: Any) -> CGFloat {
    if let d = value as? Double { return CGFloat(d) }
    if let n = value as? NSNumber { return CGFloat(n.doubleValue) }
    return 0
  }

  private static func decodeColor(from value: Any?) -> UIColor? {
    guard let numericValue = value as? NSNumber else { return nil }
    let argb = UInt32(bitPattern: Int32(truncatingIfNeeded: numericValue.intValue))
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red   = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >> 8) & 0xFF) / 255.0
    let blue  = CGFloat(argb & 0xFF) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }
}

// MARK: - Animatable Path Vector (VectorArithmetic)

/// Fixed-length float array that SwiftUI can interpolate element-wise.
struct AnimatablePathVector: VectorArithmetic {
  var values: [CGFloat]

  /// 2 (moveTo) + 32 segments * 6 (cubicTo) = 194
  private static let fixedLength = 194

  static var zero: AnimatablePathVector {
    AnimatablePathVector(values: [CGFloat](repeating: 0, count: fixedLength))
  }

  static func + (lhs: AnimatablePathVector, rhs: AnimatablePathVector) -> AnimatablePathVector {
    let count = max(lhs.values.count, rhs.values.count)
    var r = [CGFloat](repeating: 0, count: count)
    for i in 0..<count {
      let l = i < lhs.values.count ? lhs.values[i] : 0
      let rv = i < rhs.values.count ? rhs.values[i] : 0
      r[i] = l + rv
    }
    return AnimatablePathVector(values: r)
  }

  static func - (lhs: AnimatablePathVector, rhs: AnimatablePathVector) -> AnimatablePathVector {
    let count = max(lhs.values.count, rhs.values.count)
    var r = [CGFloat](repeating: 0, count: count)
    for i in 0..<count {
      let l = i < lhs.values.count ? lhs.values[i] : 0
      let rv = i < rhs.values.count ? rhs.values[i] : 0
      r[i] = l - rv
    }
    return AnimatablePathVector(values: r)
  }

  mutating func scale(by rhs: Double) {
    for i in values.indices { values[i] *= CGFloat(rhs) }
  }

  var magnitudeSquared: Double {
    values.reduce(0.0) { $0 + Double($1 * $1) }
  }
}

// MARK: - Animatable Custom Path Shape

/// A `Shape` whose control points are interpolated by SwiftUI's animation
/// system. All coordinates are normalised to [0,1] and scaled to the target
/// rect in `path(in:)`.
struct AnimatableCustomPathShape: Shape, Animatable {
  var pathData: AnimatablePathVector

  var animatableData: AnimatablePathVector {
    get { pathData }
    set { pathData = newValue }
  }

  func path(in rect: CGRect) -> SwiftUI.Path {
    let v = pathData.values
    guard v.count >= 2 else { return SwiftUI.Path() }

    var path = SwiftUI.Path()

    // First 2 values = moveTo (normalised).
    path.move(to: pt(v[0], v[1], in: rect))

    // Remaining values = cubic segments, 6 floats each.
    var i = 2
    while i + 5 < v.count {
      let c1  = pt(v[i],   v[i+1], in: rect)
      let c2  = pt(v[i+2], v[i+3], in: rect)
      let end = pt(v[i+4], v[i+5], in: rect)
      path.addCurve(to: end, control1: c1, control2: c2)
      i += 6
    }

    path.closeSubpath()
    return path
  }

  private func pt(_ nx: CGFloat, _ ny: CGFloat, in rect: CGRect) -> CGPoint {
    CGPoint(x: nx * rect.width + rect.minX,
            y: ny * rect.height + rect.minY)
  }
}

// MARK: - Built-in Animatable Shape (rect / capsule / circle)

struct BuiltInGlassShape: Shape, Animatable {
  var cornerRadius: CGFloat

  var animatableData: CGFloat {
    get { cornerRadius }
    set { cornerRadius = newValue }
  }

  func path(in rect: CGRect) -> SwiftUI.Path {
    let maxR = min(rect.width, rect.height) / 2
    let r = min(cornerRadius, maxR)
    return Path(roundedRect: rect, cornerRadius: r, style: .continuous)
  }
}

// MARK: - SwiftUI Glass Container (iOS 26+)

@available(iOS 26.0, *)
struct LiquidGlassContainerSwiftUIView: View {
  @ObservedObject var viewModel: LiquidGlassContainerViewModel
  @Namespace private var namespace

  var body: some View {
    GeometryReader { geometry in
      Group {
        if viewModel.isCustom {
          customGlassView(in: geometry.size)
            .transition(.opacity)
        } else {
          builtInGlassView(in: geometry.size)
            .transition(.opacity)
        }
      }
      .applyLiquidGlassContainerModifiers(
        unionId: viewModel.glassEffectUnionId,
        id: viewModel.glassEffectId,
        namespace: namespace
      )
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
  }

  // MARK: Built-in

  @ViewBuilder
  private func builtInGlassView(in size: CGSize) -> some View {
    let radius: CGFloat = {
      switch viewModel.shape {
      case "circle", "capsule":
        return min(size.width, size.height) / 2
      default:
        return viewModel.cornerRadius ?? 16
      }
    }()
    let shape = BuiltInGlassShape(cornerRadius: radius)
    shape
      .fill(Color.clear)
      .allowsHitTesting(false)
      .glassEffect(resolvedGlassEffect(), in: shape)
  }

  // MARK: Custom (animatable path morphing)

  @ViewBuilder
  private func customGlassView(in size: CGSize) -> some View {
    let shape = AnimatableCustomPathShape(
      pathData: AnimatablePathVector(values: viewModel.normalizedPathData)
    )
    shape
      .fill(Color.clear)
      .allowsHitTesting(false)
      .glassEffect(resolvedGlassEffect(), in: shape)
  }

  // MARK: Glass effect

  private func resolvedGlassEffect() -> Glass {
    var glass: Glass = viewModel.effect == "clear" ? Glass.clear : Glass.regular
    if let tintColor = viewModel.tint {
      glass = glass.tint(Color(tintColor))
    }
    if viewModel.interactive {
      glass = glass.interactive()
    }
    return glass
  }
}

// MARK: - Modifier Helpers

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
