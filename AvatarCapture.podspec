Pod::Spec.new do |s|
  s.name	= 'AvatarCapture'
  s.version	= '1.0.5'
  s.summary	= 'A Swift based drop in solution for taking avatar/profile pictures using the iOS Camera'

  s.description	= <<-DESC
Writing a ground-up solution for taking profile pictures in iOS can be a pain and time consuming. AvatarCapture is a Swift based library whose purpose is to make it easy as possible to start your camera, allow you to snap a photo or choose a photo from your Photos library.
		 DESC

  s.homepage	= 'https://github.com/gatewayapps/avatar-capture-ios'
  s.license	= { :type => 'MIT', :file => 'LICENSE' }
  s.author	= { 'John Murphy' => 'john@gatewayapps.com' }
  s.source	= { :git => 'https://github.com/gatewayapps/avatar-capture-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.swift_version = '4.0'
  s.resource_bundles = {
    'AvatarCapture' => ['AvatarCapture/*/Assets.xcassets']
  }
  s.dependency 'FontAwesome.swift', '~> 1.3.0'
  s.source_files = 'AvatarCapture/AvatarCapture/AvatarCaptureController.swift' 

end
