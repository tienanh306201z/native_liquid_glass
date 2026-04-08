import Flutter
import UIKit

/// Platform-view bridge for native UIDatePicker with Liquid Glass effects.
final class LiquidGlassDatePickerPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let datePicker: UIDatePicker
  private let methodChannel: FlutterMethodChannel

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear

    datePicker = UIDatePicker()
    datePicker.translatesAutoresizingMaskIntoConstraints = false

    methodChannel = FlutterMethodChannel(
      name: "liquid-glass-date-picker-view/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()

    configurePicker(args: args)
    setupMethodChannelHandler()
  }

  func view() -> UIView {
    containerView
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

  private func configurePicker(args: [String: Any]?) {
    // Mode: 0=date, 1=time, 2=dateAndTime
    let modeIndex = (args?["mode"] as? NSNumber)?.intValue ?? 2
    switch modeIndex {
    case 0: datePicker.datePickerMode = .date
    case 1: datePicker.datePickerMode = .time
    default: datePicker.datePickerMode = .dateAndTime
    }

    // Style: 0=compact, 1=inline, 2=wheels
    let styleIndex = (args?["style"] as? NSNumber)?.intValue ?? 0
    if #available(iOS 13.4, *) {
      if #available(iOS 14.0, *), styleIndex == 1 {
        datePicker.preferredDatePickerStyle = .inline
      } else if styleIndex == 2 {
        datePicker.preferredDatePickerStyle = .wheels
      } else {
        datePicker.preferredDatePickerStyle = .compact
      }
    }

    // Initial date
    if let millis = (args?["initialDate"] as? NSNumber)?.doubleValue {
      datePicker.date = Date(timeIntervalSince1970: millis / 1000.0)
    }

    // Min/max
    if let minMillis = (args?["minimumDate"] as? NSNumber)?.doubleValue {
      datePicker.minimumDate = Date(timeIntervalSince1970: minMillis / 1000.0)
    }
    if let maxMillis = (args?["maximumDate"] as? NSNumber)?.doubleValue {
      datePicker.maximumDate = Date(timeIntervalSince1970: maxMillis / 1000.0)
    }

    // Minute interval
    if let interval = (args?["minuteInterval"] as? NSNumber)?.intValue {
      datePicker.minuteInterval = interval
    }

    // Tint color
    if let color = Self.decodeColor(from: args?["color"]) {
      datePicker.tintColor = color
    }

    datePicker.addTarget(self, action: #selector(handleDateChanged), for: .valueChanged)

    containerView.addSubview(datePicker)
    NSLayoutConstraint.activate([
      datePicker.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      datePicker.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      datePicker.topAnchor.constraint(equalTo: containerView.topAnchor),
      datePicker.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])
  }

  @objc
  private func handleDateChanged() {
    let millis = Int(datePicker.date.timeIntervalSince1970 * 1000)
    methodChannel.invokeMethod("dateChanged", arguments: millis)
  }

  private func setupMethodChannelHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "setDate":
        if let args = call.arguments as? [String: Any],
          let millis = (args["date"] as? NSNumber)?.doubleValue
        {
          let animated = (args["animated"] as? Bool) ?? false
          self.datePicker.setDate(
            Date(timeIntervalSince1970: millis / 1000.0),
            animated: animated
          )
        }
        result(nil)

      case "setMinimumDate":
        if let args = call.arguments as? [String: Any],
          let millis = (args["date"] as? NSNumber)?.doubleValue
        {
          self.datePicker.minimumDate = Date(timeIntervalSince1970: millis / 1000.0)
        }
        result(nil)

      case "setMaximumDate":
        if let args = call.arguments as? [String: Any],
          let millis = (args["date"] as? NSNumber)?.doubleValue
        {
          self.datePicker.maximumDate = Date(timeIntervalSince1970: millis / 1000.0)
        }
        result(nil)

      case "setColor":
        if let args = call.arguments as? [String: Any],
          let color = Self.decodeColor(from: args["color"])
        {
          self.datePicker.tintColor = color
        }
        result(nil)

      case "updateConfig":
        let args = call.arguments as? [String: Any]
        let modeIndex = (args?["mode"] as? NSNumber)?.intValue ?? 2
        switch modeIndex {
        case 0: self.datePicker.datePickerMode = .date
        case 1: self.datePicker.datePickerMode = .time
        default: self.datePicker.datePickerMode = .dateAndTime
        }
        let styleIndex = (args?["style"] as? NSNumber)?.intValue ?? 0
        if #available(iOS 13.4, *) {
          if #available(iOS 14.0, *), styleIndex == 1 {
            self.datePicker.preferredDatePickerStyle = .inline
          } else if styleIndex == 2 {
            self.datePicker.preferredDatePickerStyle = .wheels
          } else {
            self.datePicker.preferredDatePickerStyle = .compact
          }
        }
        if let interval = (args?["minuteInterval"] as? NSNumber)?.intValue {
          self.datePicker.minuteInterval = interval
        }
        if let minMillis = (args?["minimumDate"] as? NSNumber)?.doubleValue {
          self.datePicker.minimumDate = Date(timeIntervalSince1970: minMillis / 1000.0)
        }
        if let maxMillis = (args?["maximumDate"] as? NSNumber)?.doubleValue {
          self.datePicker.maximumDate = Date(timeIntervalSince1970: maxMillis / 1000.0)
        }
        if let color = Self.decodeColor(from: args?["color"]) {
          self.datePicker.tintColor = color
        }
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
