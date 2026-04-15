#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint native_liquid_glass.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'native_liquid_glass'
  s.version          = '0.2.3'
  s.summary          = 'Liquid Glass iOS platform view for Flutter.'
  s.description      = <<-DESC
UIKit-native iOS platform views for rendering Liquid Glass style components in Flutter.
                       DESC
  s.homepage         = 'https://pub.dev/packages/native_liquid_glass'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'native_liquid_glass contributors' => 'opensource@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'native_liquid_glass/Sources/native_liquid_glass/**/*.swift'
  s.dependency 'Flutter'
  s.dependency 'SVGKit'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'native_liquid_glass_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
