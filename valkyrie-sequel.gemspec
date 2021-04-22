# frozen_string_literal: true
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "valkyrie/sequel/version"

Gem::Specification.new do |spec|
  spec.name          = "valkyrie-sequel"
  spec.version       = Valkyrie::Sequel::VERSION
  spec.authors       = ["Trey Pendragon"]
  spec.email         = ["tpendragon@princeton.edu"]

  spec.summary       = 'Valkyrie::MetadataAdapter for Postgres using Sequel.'
  spec.description   = 'Valkyrie::MetadataAdapter for Postgres using Sequel.'
  spec.homepage      = "https://github.com/samvera-labs/valkyrie-sequel"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sequel", "~> 5.0"
  spec.add_dependency "sequel_pg", "~> 1.0"
  spec.add_dependency "valkyrie", '~> 2.1.0'
  spec.add_dependency "oj", "~> 3.0"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "bixby"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "simplecov"
end
