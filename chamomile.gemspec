require_relative "lib/chamomile/version"

Gem::Specification.new do |spec|
  spec.name          = "chamomile"
  spec.version       = Chamomile::VERSION
  spec.authors       = ["Chamomile Contributors"]
  spec.summary       = "A Ruby TUI framework based on The Elm Architecture"
  spec.description   = "Build rich terminal UIs in Ruby using the Model/Update/View pattern"
  spec.license       = "MIT"
  spec.require_paths = ["lib"]
  spec.files         = Dir["lib/**/*.rb"]
  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "tty-reader", "~> 0.9"

  spec.add_development_dependency "rspec", "~> 3.12"
end
