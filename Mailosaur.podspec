#
#  Be sure to run `pod spec lint Mailosaur.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name                  = 'Mailosaur'
  s.version               = '0.0.1'
  s.summary               = 'Mailosaur lets you automate email and SMS tests as part of software development and QA..'
  s.homepage              = 'https://mailosaur.com/'
  s.license               = { type: 'MIT', file: 'LICENSE' }
  s.authors               = { 'Mailosaur Ltd' => 'code@mailosaur.com' }
  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'
  s.swift_version         = '5.5'
  s.source                = { git: 'https://github.com/mailosaur/mailosaur-swift.git', tag: "#{s.version}" }
  s.source_files          = 'Sources/**/*.swift'
end
