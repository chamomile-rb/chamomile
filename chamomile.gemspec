# frozen_string_literal: true

require_relative "lib/chamomile/version"

Gem::Specification.new do |spec|
  spec.name          = "chamomile"
  spec.version       = Chamomile::VERSION
  spec.authors       = ["Chamomile Contributors"]
  spec.summary       = "The complete Ruby TUI framework — core, styling, and components"
  spec.description   = "Build beautiful terminal applications with an event-driven architecture, " \
                       "terminal styling (borders, colors, layout), and reusable components " \
                       "(text inputs, tables, lists, spinners, and more)"
  spec.license       = "MIT"
  spec.require_paths = ["lib"]
  spec.files         = Dir["lib/**/*.rb"]
  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "concurrent-ruby", "~> 1.3"

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.homepage = "https://github.com/chamomile-rb/chamomile"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"]          = spec.homepage
  spec.metadata["source_code_uri"]       = "https://github.com/chamomile-rb/chamomile"
  spec.metadata["changelog_uri"]         = "https://github.com/chamomile-rb/chamomile/blob/master/CHANGELOG.md"
end
