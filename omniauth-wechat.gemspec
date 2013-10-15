# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth/wechat/version'

Gem::Specification.new do |spec|
  spec.name          = "omniauth-wechat"
  spec.version       = Omniauth::Wechat::VERSION
  spec.authors       = ["victor"]
  spec.email         = ["gyyshuai@gmail.com"]
  spec.description   = %q{omniauth strategy for wechat}
  spec.summary       = %q{omniauth strategy for wechat}
  spec.homepage      = "https://github.com/victorgong/omniauth-wechat"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'omniauth', '~> 1.0'
  spec.add_dependency 'omniauth-oauth2', '~> 1.0'
  spec.add_dependency 'multi_json'
end
