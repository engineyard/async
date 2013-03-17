# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "async"
  s.version = "0.0.1"
  s.author = "Jacob"
  s.email = "jacob@engineyard.com"
  s.homepage = "https://github.com/jacobo/async"
  s.summary = "abstraction over background job systems"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ['lib']

end
