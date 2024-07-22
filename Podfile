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
pod 'Firebase/Crashlytics'
pod 'SSZipArchive'

target 'IRCCloud' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IRCCloud
  pod 'youtube-ios-player-helper'
  pod 'Firebase/Messaging'

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

end

target 'IRCCloud FLEX' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IRCCloud FLEX
  pod 'youtube-ios-player-helper'
  pod 'Firebase/Messaging'

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
  installer.aggregate_targets.each do |target|
    target.xcconfigs.each do |variant, xcconfig|
      xcconfig_path = target.client_root + target.xcconfig_relative_path(variant)
      IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
    end
  end
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.base_configuration_reference.is_a? Xcodeproj::Project::Object::PBXFileReference
        xcconfig_path = config.base_configuration_reference.real_path
        IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
      end
    end
  end
end
