# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

pod 'GoogleSignIn'
pod 'GoogleAPIClientForREST/Gmail'

plugin 'cocoapods-keys', {
  :project => "EmailClient",
  :target => "EmailClient",
  :keys => [
    "ClientID",
  ]
}

target 'EmailClient' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for EmailClient

  target 'EmailClientTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'EmailClientUITests' do
    # Pods for testing
  end

end
