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
pod 'Firebase/Analytics'
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

#    installer.pods_project.targets.each do |target|
#        
        # handle non catalyst libs
#        libs = ["FirebaseAnalytics", "FIRAnalyticsConnector", "FirebasePerformance", "GoogleAppMeasurement"]
        
#        target.build_configurations.each do |config|
#            xcconfig_path = config.base_configuration_reference.real_path
#            xcconfig = File.read(xcconfig_path)
#            values = ""
            
#            libs.each { |lib|
#                if xcconfig["-framework \"#{lib}\""]
#                    puts "Found '#{lib}' on target '#{target.name}'"
#                    xcconfig.sub!(" -framework \"#{lib}\"", '')
#                    values += " -framework \"#{lib}\""
#                end
#            }
            
#            if values.length > 0
#                puts "Preparing '#{target.name}' for Catalyst\n\n"
#                new_xcconfig = xcconfig + 'OTHER_LDFLAGS[sdk=iphone*] = $(inherited)' + values
#                File.open(xcconfig_path, "w") { |file| file << new_xcconfig }
#            end
#        end
#    end
end
