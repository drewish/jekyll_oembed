# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "jekyll-oembed"
  gem.version       = '0.1.0'
  gem.authors       = ["stereobooster"]
  gem.email         = ["stereobooster@gmail.com"]
  gem.description   = %q{A Jekyll plugin that provides an oembed liquid tag for embedding content from various providers like YouTube, Vimeo, etc.}
  gem.summary       = %q{Provides an oembed liquid tag for Jekyll}
  gem.homepage      = "https://github.com/stereobooster/jekyll_oembed"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 2.7.0', '< 4.0'

  gem.add_dependency "jekyll", "~> 4.0"
  gem.add_dependency "ruby-oembed", "~> 0.13"

  gem.add_development_dependency "rake", "~> 13.0"
  gem.add_development_dependency "minitest", "~> 5.0"

end
