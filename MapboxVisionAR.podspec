Pod::Spec.new do |s|

  s.name         = "MapboxVisionAR"
  s.version      = "0.0.1-alpha.2"
  s.summary      = "Easy to use AR Navigation"

  s.homepage     = 'https://www.mapbox.com/vision/'

  s.license      = { :type => "CUSTOM", :file => "LICENSE.md" }

  s.author            = { 'Mapbox' => 'mobile@mapbox.com' }
  s.social_media_url  = 'https://twitter.com/mapbox'
  s.documentation_url = 'https://www.mapbox.com/vision/'

  s.platform              = :ios
  s.ios.deployment_target = '11.2'

  s.source        = { :git => "https://github.com/mapbox/mapbox-vision-ar-ios.git", :tag => "v#{s.version}" }

  s.source_files  = "MapboxVisionAR/**/*.{swift,h,metal}"
  s.resource      = "MapboxVisionAR/Models/*"

  s.requires_arc = true

  s.swift_version = '4.1'

  s.dependency "MapboxVision", "~> 0.0.1-alpha.2"
  s.dependency "MapboxCoreNavigation", "~> 0.20.0"

end
