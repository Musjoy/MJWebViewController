#
# Be sure to run `pod lib lint MJWebViewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "MJWebViewController"
  s.version          = "0.1.5"
  s.summary          = "This is a custom WebViewController."

  s.homepage         = "https://github.com/Musjoy/MJWebViewController"
  s.license          = 'MIT'
  s.author           = { "Raymond" => "Ray.musjoy@gmail.com" }
  s.source           = { :git => "https://github.com/Musjoy/MJWebViewController.git", :tag => "v-#{s.version}" }

  s.ios.deployment_target = '7.0'

  s.source_files = 'MJWebViewController/Classes/**/*'
  
  s.user_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => 'MODULE_WEB_CONTROLLER'
  }

  s.dependency 'MJUtils'
  s.dependency 'MJControllerManager'
  s.dependency 'ActionProtocol'
  s.dependency 'DBModel'
  s.dependency 'ModuleCapability'
  s.prefix_header_contents = '#import "ModuleCapability.h"'
end
