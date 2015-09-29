# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'waitress/version'

Gem::Specification.new do |spec|
  spec.name          = "waitress-core"
  spec.version       = Waitress::VERSION
  spec.authors       = ["Jaci Brunning"]
  spec.email         = ["jaci.brunning@gmail.com"]

  spec.summary       = %q{Waitress is a lightweight, fast Ruby Web Server with the ability to serve dynamic webpages, manage libraries and support for virtual hosts and much more}
  spec.homepage      = "http://github.com/JacisNonsense/Waitress"

  spec.bindir        = "bin"
  spec.files = Dir.glob("lib/**/*") + ['Rakefile', 'waitress-core.gemspec', 'Gemfile', 'LICENSE'] + Dir.glob("ext/**/*")
  spec.executables   = ["waitress"]
  spec.require_paths = ["lib"]
  spec.extensions << "ext/waitress_http11/extconf.rb"

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rake-compiler"
  spec.add_dependency "Go.rb", ">= 0.3.0"
  spec.add_dependency "scon"
  spec.add_dependency "configfile"
end
