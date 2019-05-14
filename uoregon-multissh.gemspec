Gem::Specification.new do |spec|
  spec.name        = 'uoregon-multissh'
  spec.version     = '0.3.5'
  spec.date        = '2019-05-14'
  spec.summary     = "Do all the things everywhere at the same time"
  spec.description = "Quickly run multiple commands on many boxes at the same time"
  spec.authors     = ["Lucas Crownover"]
  spec.email       = 'lcrownover127@gmail.com'
  spec.homepage    = 'https://www.savethemanatee.org/manatees/facts/'
  spec.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|build|dev)/}) }
  spec.executables = ["multissh"]
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency "colorize", [">= 0.8.1"]
  spec.add_runtime_dependency "net-ssh", [">= 5.1.0"]
  spec.add_runtime_dependency "parallel", [">= 1.12.1"]
  spec.license     = 'MIT'
end
