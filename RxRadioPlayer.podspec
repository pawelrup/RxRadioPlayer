#
# Be sure to run `pod lib lint RxRadioPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RxRadioPlayer'
  s.version          = '0.1.3'
  s.summary          = 'RxRadioPlayer is a small framework to play radio streaming.'

  s.description      = <<-DESC
  RxRadioPlayer is a small framework for iOS and tvOS to play radio streaming, using RxSwift.
  Requires Xcode 10.2 with Swift 5.0.
                       DESC

  s.homepage         = 'https://github.com/pawelrup/RxRadioPlayer'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Paweł Rup' => 'pawelrup@lobocode.pl' }
  s.source           = { :git => 'https://github.com/pawelrup/RxRadioPlayer.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'

  s.swift_version = '5.0'
  s.pod_target_xcconfig =  {
    'SWIFT_VERSION' => '5.0',
  }

  s.source_files = 'RxRadioPlayer/Classes/**/*'

  s.frameworks = 'Foundation', 'UIKit', 'AVFoundation', 'AVKit'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
end
