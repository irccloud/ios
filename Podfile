# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'
use_modular_headers!

pod 'GoogleUtilities/AppDelegateSwizzler'
pod 'GoogleUtilities/Environment'
pod 'GoogleUtilities/ISASwizzler'
pod 'GoogleUtilities/Logger'
pod 'GoogleUtilities/MethodSwizzler'
pod 'GoogleUtilities/NSData+zlib'
pod 'GoogleUtilities/Network'
pod 'GoogleUtilities/Reachability'
pod 'GoogleUtilities/UserDefaults'
pod 'Firebase/Crashlytics', '10.5.0'
pod 'SSZipArchive'

target 'IRCCloud' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IRCCloud
  pod 'youtube-ios-player-helper'
  pod 'Firebase/Messaging'
  pod 'Firebase/Performance'

  target 'IRCCloudUnitTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'IRCCloud Enterprise' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IRCCloud Enterprise
  pod 'youtube-ios-player-helper'
  pod 'Firebase/Messaging'
  pod 'Firebase/Performance'

end

target 'IRCCloud FLEX' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IRCCloud FLEX
  pod 'youtube-ios-player-helper'
  pod 'Firebase/Messaging'
  pod 'Firebase/Performance'

end

target 'NotificationService' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for NotificationService

end

target 'NotificationService Enterprise' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for NotificationService Enterprise

end

target 'ShareExtension' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ShareExtension

end

target 'ShareExtension Enterprise' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ShareExtension Enterprise

end

post_install do |installer|
  installer.pods_project.targets.each do |t|
      t.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
  end

end
