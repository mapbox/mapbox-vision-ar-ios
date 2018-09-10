Pod::Spec.new do |s|

  s.name         = "VisionAR"
  s.version      = "0.0.1-alpha.1"
  s.summary      = "Easy to use AR Navigation"

  s.homepage     = 'https://www.mapbox.com/vision/'

  s.license      = { :type => "CUSTOM", :file => "LICENSE.md" }

  s.author            = { 'Mapbox' => 'mobile@mapbox.com' }
  s.social_media_url  = 'https://twitter.com/mapbox'
  s.documentation_url = 'https://www.mapbox.com/vision/'

  s.platform              = :ios
  s.ios.deployment_target = '11.2'

  s.source        = { :git => "git@github.com:mapbox/VisionAR.git", :branch => "alpha-1" }

  s.source_files  = "VisionAR/**/*.{swift,h,metal}"
  s.resource      = "VisionAR/Models/*"

  s.requires_arc = true

  s.swift_version = '4.1'

  s.dependency "VisionSDK", "~> 0.0.1-alpha.1"
  s.dependency "MapboxCoreNavigation", "~> 0.20.0"

end
