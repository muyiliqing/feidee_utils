$:.push File.expand_path("../lib", __FILE__)

require 'feidee_utils/version'

Gem::Specification.new do |s|
  s.name        = 'feidee_utils'
  s.version     = FeideeUtils::VERSION
  s.date        = '2015-05-01'
  s.summary     = "Utils to extract useful information from Feidee Mymoney backup."
  s.description = "Feidee Utils provides a set of ActiveReocrd-like classes to read Feidee private backups (.kbf files). It also provides a better abstraction to the general format of transaction-account style data."
  s.authors     = ["Liqing Muyi"]
  s.email       = 'muyiliqing@gmail.com'

  s.files       = Dir["lib/**/*", "Rakefile", "Gemfile", "MIT-LICENSE", "README.md"]

  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency 'rake', '~> 10.4', '>= 10.4.0'
  s.add_dependency 'rubyzip', '~> 1.1', '>= 1.1.6'
  s.add_dependency 'sqlite3', '~> 1.3', '>= 1.3.10'
  s.add_dependency 'tzinfo', '~> 1.2', '>= 1.2.2'

  s.add_development_dependency 'minitest', '~> 5.8', '>= 5.8.1'

  s.homepage    = 'http://github.com/muyiliqing/feidee_utils'
  s.license     = 'MIT'
end
