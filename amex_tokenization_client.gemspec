
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "amex_tokenization_client/version"

Gem::Specification.new do |spec|
  spec.name          = "amex_tokenization_client"
  spec.version       = AmexTokenizationClient::VERSION
  spec.authors       = ["Piers Chambers"]
  spec.email         = ["piers@varyonic.com"]

  spec.summary       = "Unofficial Ruby wrapper for the American Express Tokenization Service (AETS)."
  spec.homepage      = "https://github.com/varyonic/amex_enhanced_authorization"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "jwe", ">= 0.4.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
