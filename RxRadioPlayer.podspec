#
# Be sure to run `pod lib lint RxRadioPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RxRadioPlayer'
  s.version          = '0.0.2'
  s.summary          = 'RxRadioPlayer is a small framework to play radio streaming.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  RxRadioPlayer is a small framework for iOS and tvOS to play radio streaming, using RxSwift.
  Requires Xcode 10.0 with Swift 4.2.
                       DESC

  s.homepage         = 'https://github.com/pawelrup/RxRadioPlayer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Paweł Rup' => 'pawelrup@lobocode.pl' }
  s.source           = { :git => 'https://github.com/pawelrup/RxRadioPlayer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'

  s.swift_version = '4.2'

  s.source_files = 'RxRadioPlayer/Classes/**/*'
  s.pod_target_xcconfig =  {
	  'SWIFT_VERSION' => '4.2',
  }

  # s.resource_bundles = {
  #   'RxRadioPlayer' => ['RxRadioPlayer/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'Foundation', 'UIKit', 'AVFoundation', 'MediaPlayer'
  s.dependency 'RxSwift', '~> 4.3.1'
  s.dependency 'RxCocoa', '~> 4.3.1'
  s.dependency 'RxSwiftExt', '~> 3.3.0'
  s.dependency 'Action', '~> 3.8.0'
end
