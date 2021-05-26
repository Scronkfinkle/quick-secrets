$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
Gem::Specification.new do |s|
  s.name = 'quick-secrets'

  s.version = "0.0.1"
  s.summary = 'Sublimely Simple Secure Self-Hosted Secret Sharing'
  s.description = ''
  s.authors = [
    "Jesse Roland"
  ]

  s.executables = ['quick-secrets']

  s.bindir = 'exe'
  s.email = 'j.roland277@gmail.com'
  s.license = 'MIT'

  # files
  s.files = Dir[ 'lib/**/*' ]

  # Gem dependencies
  s.add_runtime_dependency 'sinatra'
  s.add_runtime_dependency 'sqlite3'
  s.add_runtime_dependency 'sequel'
  s.add_runtime_dependency 'rdiscount'
  s.add_runtime_dependency 'docopt'
  s.add_runtime_dependency 'webrick'

  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-byebug'

end
