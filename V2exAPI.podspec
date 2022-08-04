Pod::Spec.new do |spec|

  spec.name         = "V2exAPI"
  spec.version      = "0.0.1"
  spec.summary      = "V2ex API 的 Swift 封装，支持 iOS/macOS"

  spec.description  = <<-DESC
                      V2ex API 的 Swift 封装，支持 iOS/macOS，支持 V1/V2 API。
                      DESC

  spec.homepage     = "https://github.com/isaced/V2exAPI"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "isaced" => "isaced@163.com" }

  spec.ios.deployment_target = "15.0"
  spec.osx.deployment_target = "12.0"
  spec.watchos.deployment_target = "6.0"
  spec.tvos.deployment_target = "15.0"

  spec.source       = { :git => "https://github.com/isaced/V2exAPI.git", :tag => "#{spec.version}" }

  spec.source_files  = ["Sources/**/*.swift"]
end