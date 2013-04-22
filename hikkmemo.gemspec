Gem::Specification.new do |s|
  s.name        = 'hikkmemo'
  s.version     = '1.0.0'
  s.license     = 'MIT'
  s.author      = 'Ulthar Sothoth'
  s.email       = 'ulthar.ix@gmail.com'
  s.homepage    = 'http://github.com/ulthar/hikkmemo'
  s.summary     = 'Imageboard memoizer.'
  s.description = 'Extensible/customizable/programmable thread/post/image memoizer for imageboards.'

  s.add_runtime_dependency 'nokogiri',      '~> 1.5'
  s.add_runtime_dependency 'sqlite3',       '~> 1.3'
  s.add_runtime_dependency 'sequel',        '~> 3.46'
  s.add_runtime_dependency 'rainbow',       '~> 1.1'
  s.add_runtime_dependency 'unicode_utils', '~> 1.4'

  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'
end
