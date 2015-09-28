Gem::Specification.new do |s|
  s.name        = 'feidee_utils'
  s.version     = '0.0.0'
  s.date        = '2015-05-01'
  s.summary     = "Utils to extract useful information from Feidee mymoney backup."
  s.description = "Utils to extract useful information from Feidee mymoeny backup."
  s.authors     = ["Liqing Muyi"]
  s.email       = 'feideeutils@ditsing.com'

  s.files       = Dir["lib/**/*", "Rakefile", "Gemfile", "MIT-LICENSE", "README.md"]

  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency 'rubyzip', '~> 1.1', '>= 1.1.6'
  s.add_dependency 'sqlite3', '~> 1.3', '>= 1.3.10'

  s.add_development_dependency 'minitest', '~> 5.8', '>= 5.8.1'

  s.homepage    = 'http://github.com/muyiliqing/feidee-utils'
  s.license     = 'MIT'
end
