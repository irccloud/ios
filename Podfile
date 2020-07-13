# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

pod 'Firebase/Crashlytics'
pod 'Firebase/Analytics'
pod 'Firebase/Performance'

target 'IRCCloud' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IRCCloud

  target 'IRCCloudUnitTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'IRCCloud Enterprise' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IRCCloud Enterprise

end

target 'IRCCloud FLEX' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IRCCloud FLEX

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

post_install do |pi|
    pi.pods_project.targets.each do |t|
        t.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
        end
    end
end
