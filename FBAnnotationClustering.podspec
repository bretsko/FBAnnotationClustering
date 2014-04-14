#
# Be sure to run `pod lib lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = "FBAnnotationClustering"
  s.version          = "0.1.0"
  s.summary          = "A short description of FBAnnotationClustering."
  s.description      = <<-DESC
                       An optional longer description of FBAnnotationClustering

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = ""
  s.screenshots      = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Filip Beć" => "filip.bec@gmail.com" }
  s.source           = { :git => "http://EXAMPLE/NAME.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/FilipBec'

  s.platform     = :ios, '6.0'
  s.ios.deployment_target = '6.0'
  s.requires_arc = true

  s.source_files = 'FBAnnotationClustering'
  s.public_header_files = 'FBAnnotationClustering/*.h'
  s.frameworks = 'CoreLocation', 'MapKit'
end