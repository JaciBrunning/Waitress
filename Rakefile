require 'rake/extensiontask'
require 'rake/testtask'

spec = Gem::Specification.load('waitress-core.gemspec')
Rake::ExtensionTask.new('waitress_http11', spec)

task default: %w[test]

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/unit.rb']
  t.verbose = true
end
