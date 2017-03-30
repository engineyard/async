# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "async/version"

Gem::Specification.new do |s|
  s.name = "async-jobs"
  s.version = Async::VERSION
  s.author = "Jacob"
  s.email = "jacob@engineyard.com"
  s.homepage = "https://github.com/engineyard/async"
  s.summary = "abstraction over background job systems"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ['lib']

end
