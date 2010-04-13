require 'rubygems'
require 'rake/gempackagetask'

PKG_VERSION = File.read("VERSION").strip

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "A HTML form generator on steroids."
  s.name = 'rformation'
  s.version = PKG_VERSION
  s.require_path = 'lib'
  s.files = Dir["lib/rformation/*.rb"] + %w[README VERSION lib/rformation.rb]
  s.add_dependency("treetop")
  s.description = <<-EOF
    A DSL to generate dynamic HTML forms with client and server side validations.
  EOF
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

desc "Rebuild the grammar"
task :rebuild_grammar do
  system "tt lib/rformation/condition_parser.treetop"
  data = File.read("lib/rformation/condition_parser.rb")
  data.gsub!(/\bCondition\b/, "RFormation::Condition")
  data.gsub!(/\bConditionParser\b/, "RFormation::ConditionParser")
  File.open("lib/rformation/condition_parser.rb", "w") { |f| f << data }
end
