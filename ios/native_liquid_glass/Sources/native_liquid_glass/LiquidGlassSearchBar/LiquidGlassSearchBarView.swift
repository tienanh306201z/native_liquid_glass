import Flutter
import SwiftUI
import UIKit

// MARK: - Platform view bridge

/// Platform-view bridge for Liquid Glass search bar.
final class LiquidGlassSearchBarPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let methodChannel: FlutterMethodChannel

  // iOS 26+ SwiftUI path
  private var searchBarViewModel: Any?  // LiquidGlassSearchBarViewModel
  private var hostingController: UIViewController?

  // Pre-iOS 26 UIKit path
  private var searchBar: UISearchBar?
  private var suppressObserver: GlassSuppressObserver?

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear

    methodChannel = FlutterMethodChannel(
      name: "liquid-glass-search-bar-view/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()
    suppressObserver = GlassSuppressObserver(view: containerView)

    if #available(iOS 26.0, *) {
      configureSwiftUI(args: args)
    } else {
      configureLegacyUIKit(args: args)
    }

    setupMethodChannelHandler()
  }

  func view() -> UIView {
    containerView
  }

  // MARK: - Color decoding

  private static func mapFontWeight(_ value: Int) -> Font.Weight {
    switch value {
    case ...100: return .ultraLight
    case ...200: return .thin
    case ...300: return .light
    case ...400: return .regular
    case ...500: return .medium
    case ...600: return .semibold
    case ...700: return .bold
    case ...800: return .heavy
    default: return .black
    }
  }

  private static func decodeColor(from value: Any?) -> UIColor? {
    guard let numericValue = value as? NSNumber else { return nil }
    let argb = UInt32(bitPattern: Int32(truncatingIfNeeded: numericValue.intValue))
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >> 8) & 0xFF) / 255.0
    let blue = CGFloat(argb & 0xFF) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  // MARK: - SwiftUI path (iOS 26+)

  @available(iOS 26.0, *)
  private func configureSwiftUI(args: [String: Any]?) {
    let vm = LiquidGlassSearchBarViewModel()
    self.searchBarViewModel = vm

    let placeholder = (args?["placeholder"] as? String) ?? "Search"
    let expandable = (args?["expandable"] as? Bool) ?? true
    let initiallyExpanded = (args?["initiallyExpanded"] as? Bool) ?? false
    let expandedHeight =
      (args?["expandedHeight"] as? NSNumber).map { CGFloat(truncating: $0) } ?? 44.0
    let showCancelButton = (args?["showCancelButton"] as? Bool) ?? true
    let cancelText = (args?["cancelText"] as? String) ?? "Cancel"
    let tint = Self.decodeColor(from: args?["tint"])
    let textColor = Self.decodeColor(from: args?["textColor"])
    let placeholderColor = Self.decodeColor(from: args?["placeholderColor"])

    vm.placeholder = placeholder
    vm.expandable = expandable
    vm.showCancelButton = showCancelButton
    vm.cancelText = cancelText
    vm.expandedHeight = expandedHeight
    vm.tint = tint.map { Color(uiColor: $0) }
    vm.textColor = textColor.map { Color(uiColor: $0) }
    vm.placeholderColor = placeholderColor.map { Color(uiColor: $0) }
    vm.cancelButtonColor = Self.decodeColor(from: args?["cancelButtonColor"]).map {
      Color(uiColor: $0)
    }
    vm.iconColor = Self.decodeColor(from: args?["iconColor"]).map { Color(uiColor: $0) }
    if let br = (args?["borderRadius"] as? NSNumber)?.doubleValue, br > 0 {
      vm.borderRadius = CGFloat(br)
    }
    vm.interactive = (args?["interactive"] as? Bool) ?? true
    vm.glassEffectUnionId = args?["glassEffectUnionId"] as? String
    vm.glassEffectId = args?["glassEffectId"] as? String

    // Resolve text style into SwiftUI Font
    if let textStyleArgs = args?["textStyle"] as? [String: Any] {
      let fontSize = (textStyleArgs["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
      let fontWeight = (textStyleArgs["fontWeight"] as? NSNumber)?.intValue
      let fontFamily = (textStyleArgs["fontFamily"] as? String)?.trimmingCharacters(
        in: .whitespacesAndNewlines)
      let letterSpacing = (textStyleArgs["letterSpacing"] as? NSNumber).map {
        CGFloat(truncating: $0)
      }

      let size = fontSize ?? 16.0
      if let fontFamily, !fontFamily.isEmpty {
        vm.textFont = .custom(fontFamily, size: size)
      } else if let fontWeight {
        vm.textFont = .system(size: size, weight: Self.mapFontWeight(fontWeight))
      } else if fontSize != nil {
        vm.textFont = .system(size: size)
      }
      vm.textLetterSpacing = letterSpacing
    }

    let channelRef = methodChannel
    vm.onTextChanged = { text in
      channelRef.invokeMethod("onChanged", arguments: text)
    }
    vm.onSubmitted = { text in
      channelRef.invokeMethod("onSubmitted", arguments: text)
    }
    vm.onExpandStateChanged = { expanded in
      channelRef.invokeMethod("onExpandStateChanged", arguments: expanded)
    }
    vm.onCancelTapped = {
      channelRef.invokeMethod("onCancel", arguments: nil)
    }

    let swiftUIView = LiquidGlassSearchBarSwiftUI(
      viewModel: vm,
      initiallyExpanded: initiallyExpanded
    )

    let hc = UIHostingController(rootView: swiftUIView)
    hc.view.backgroundColor = .clear
    hc.view.translatesAutoresizingMaskIntoConstraints = false

    containerView.addSubview(hc.view)
    NSLayoutConstraint.activate([
      hc.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      hc.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      hc.view.topAnchor.constraint(equalTo: containerView.topAnchor),
      hc.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    self.hostingController = hc
  }

  // MARK: - Legacy UIKit path (pre-iOS 26)

  private func configureLegacyUIKit(args: [String: Any]?) {
    let placeholder = (args?["placeholder"] as? String) ?? "Search"
    let showCancelButton = (args?["showCancelButton"] as? Bool) ?? true
    let tint = Self.decodeColor(from: args?["tint"])
    let textColor = Self.decodeColor(from: args?["textColor"])
    let placeholderColor = Self.decodeColor(from: args?["placeholderColor"])
    let textStyleArgs = args?["textStyle"] as? [String: Any]
    let textFont: UIFont? = {
      guard let args = textStyleArgs else { return nil }
      let fontSize = (args["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
      let fontFamily = (args["fontFamily"] as? String)?.trimmingCharacters(
        in: .whitespacesAndNewlines)
      let pointSize = fontSize ?? 16.0
      if let fontFamily, !fontFamily.isEmpty,
        let customFont = UIFont(name: fontFamily, size: pointSize)
      {
        return customFont
      }
      if let fontSize { return UIFont.systemFont(ofSize: fontSize) }
      return nil
    }()

    let sb = UISearchBar()
    sb.searchBarStyle = .minimal
    sb.translatesAutoresizingMaskIntoConstraints = false
    sb.placeholder = placeholder
    sb.showsCancelButton = showCancelButton
    sb.delegate = self

    if let tint { sb.tintColor = tint }

    if let textField = sb.searchTextField as? UITextField {
      if let textColor { textField.textColor = textColor }
      if let textFont { textField.font = textFont }
      if let placeholderColor {
        textField.attributedPlaceholder = NSAttributedString(
          string: placeholder,
          attributes: [.foregroundColor: placeholderColor]
        )
      }
    }

    containerView.addSubview(sb)
    NSLayoutConstraint.activate([
      sb.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      sb.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      sb.topAnchor.constraint(equalTo: containerView.topAnchor),
      sb.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    self.searchBar = sb
  }

  // MARK: - Method channel handler

  private func setupMethodChannelHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      switch call.method {
      case "expand":
        if let sb = self.searchBar {
          sb.becomeFirstResponder()
        }
        // SwiftUI handles expand via its own state
        result(nil)
      case "collapse":
        if let sb = self.searchBar {
          sb.resignFirstResponder()
          sb.text = ""
        }
        result(nil)
      case "clear":
        if let sb = self.searchBar {
          sb.text = ""
        }
        result(nil)
      case "setText":
        if let args = call.arguments as? [String: Any], let text = args["text"] as? String {
          if let sb = self.searchBar {
            sb.text = text
          }
        }
        result(nil)
      case "focus":
        if let sb = self.searchBar {
          sb.becomeFirstResponder()
        }
        result(nil)
      case "unfocus":
        if let sb = self.searchBar {
          sb.resignFirstResponder()
        }
        result(nil)
      case "setPlaceholder":
        if let args = call.arguments as? [String: Any],
          let placeholder = args["placeholder"] as? String
        {
          if let sb = self.searchBar {
            sb.placeholder = placeholder
          }
          if #available(iOS 26.0, *),
            let vm = self.searchBarViewModel as? LiquidGlassSearchBarViewModel
          {
            vm.placeholder = placeholder
          }
        }
        result(nil)
      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          // UIKit path
          if let sb = self.searchBar {
            if let tint = Self.decodeColor(from: args["tint"]) {
              sb.tintColor = tint
            }
            if let textField = sb.searchTextField as? UITextField {
              if let textColor = Self.decodeColor(from: args["textColor"]) {
                textField.textColor = textColor
              }
              if let placeholderColor = Self.decodeColor(from: args["placeholderColor"]) {
                textField.attributedPlaceholder = NSAttributedString(
                  string: sb.placeholder ?? "Search",
                  attributes: [.foregroundColor: placeholderColor]
                )
              }
            }
          }
          // SwiftUI path
          if #available(iOS 26.0, *),
            let vm = self.searchBarViewModel as? LiquidGlassSearchBarViewModel
          {
            if let tint = Self.decodeColor(from: args["tint"]) {
              vm.tint = Color(uiColor: tint)
            }
            if let textColor = Self.decodeColor(from: args["textColor"]) {
              vm.textColor = Color(uiColor: textColor)
            }
            if let placeholderColor = Self.decodeColor(from: args["placeholderColor"]) {
              vm.placeholderColor = Color(uiColor: placeholderColor)
            }
            if let cancelButtonColor = Self.decodeColor(from: args["cancelButtonColor"]) {
              vm.cancelButtonColor = Color(uiColor: cancelButtonColor)
            }
            if let iconColor = Self.decodeColor(from: args["iconColor"]) {
              vm.iconColor = Color(uiColor: iconColor)
            }
          }
        }
        result(nil)
      case "setSuppressed":
        let suppressed = (call.arguments as? [String: Any])?["suppressed"] as? Bool ?? false
        self.suppressObserver?.setRouteSuppressed(suppressed)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

// MARK: - UISearchBarDelegate (legacy UIKit path)

extension LiquidGlassSearchBarPlatformView: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    methodChannel.invokeMethod("onChanged", arguments: searchText)
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    methodChannel.invokeMethod("onSubmitted", arguments: searchBar.text ?? "")
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = ""
    searchBar.resignFirstResponder()
    methodChannel.invokeMethod("onCancel", arguments: nil)
  }
}
