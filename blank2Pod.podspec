#
# Be sure to run `pod lib lint blank2Pod.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'blank2Pod'
  s.version          = '0.1.0'
  s.summary          = '项目名称： 智行智能旅游规划系统'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  项目名称： 智行智能旅游规划系统

  一、项目背景与目标
  
  随着人们生活水平的提高和互联网的普及，旅游已经成为许多人休闲和放松的首选方式。然而，传统的旅游规划方式往往效率低下，信息获取不全，导致游客在旅游过程中可能遇到各种不便。为了解决这一问题，我们提出开发一款名为“智行”的智能旅游规划系统。
  
  项目目标：
  
  提供全面、准确的旅游信息，帮助用户轻松规划旅游行程。
  利用人工智能和大数据分析技术，为用户推荐最符合其兴趣和需求的旅游目的地和景点。
  实现线上线下无缝对接，提供一站式旅游服务，如酒店预订、机票购买、景点门票购买等。
  打造用户社区，让游客可以分享自己的旅游经验，获取他人的旅游建议。
  二、项目内容
  
  1. 旅游信息数据库建设
  
  收集全球各地的旅游景点、酒店、餐厅、交通等信息，并实时更新。
  对旅游信息进行分类整理，方便用户查询。
  DESC

  s.homepage         = 'https://github.com/thomaswu001'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'x001' => 'thomaswu001' }
  s.source           = { :git => 'https://github.com/thomaswu001/prj2.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'
  s.swift_versions = '5.0'
  s.source_files = 'blank2Pod/Classes/**/*'
  
  # s.resource_bundles = {
  #   'blank2Pod' => ['blank2Pod/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  # s.vendored_frameworks="blank2Pod.framework"
  s.pod_target_xcconfig = { 'VALID_ARCHS' => 'x86_64 armv7 arm64' }

end
