#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint chottu_link.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'chottu_link'
  s.version          = '1.1.1'
  s.summary          = 'Flutter plugin for ChottuLink URL Shortener and Deep Linking service'
  s.description      = <<-DESC
Flutter plugin for ChottuLink URL Shortener and Deep Linking service.
                       DESC
  s.homepage         = 'https://docs.chottulink.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ChottuLink' => 'sdk.support@chottulink.com' }
  s.source           = { :path => '.' }

  s.source_files = 'chottu_link/Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  s.vendored_frameworks = 'chottu_link/Framework/ChottuLinkSDK.xcframework'

  pod_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }

  s.pod_target_xcconfig = pod_xcconfig
  s.swift_version = '6.0'
  s.static_framework = true
end
