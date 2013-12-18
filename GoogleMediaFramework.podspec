#
# Be sure to run `pod spec lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about the attributes see http://docs.cocoapods.org/specification.html
#
Pod::Spec.new do |s|
  s.name         = "GoogleMediaFramework"
  s.version      = "0.1.0"
  s.summary      = "A video player framework for playing videos. Integrates easily with the Google IMA SDK for including advertising on your videos."
  s.homepage     = "https://github.com/googleads/Google-Media-Framework-iOS"
  s.screenshots  = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author       = "Google"
  s.source       = { :git => "https://github.com/googleads/Google-Media-Framework-iOS.git", :tag => s.version.to_s }

  s.platform     = :ios, '5.0'
  s.requires_arc = true

  s.source_files = 'GoogleMediaFramework'
  s.resources = 'Resources/*'

  #s.public_header_files = 'GoogleMediaFramework/GoogleMediaFramework.h'

  # s.frameworks = 'SomeFramework', 'AnotherFramework'
end
