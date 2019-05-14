Gem::Specification.new do |spec|
  spec.name        = 'multissh'
  spec.version     = '0.2.2'
  spec.date        = '2019-05-14'
  spec.summary     = "Do all the things everywhere at the same time"
  spec.description = "Quickly run multiple commands on many boxes at the same time"
  spec.authors     = ["Lucas Crownover"]
  spec.email       = 'lcrownover127@gmail.com'
  spec.homepage    = 'https://www.savethemanatee.org/manatees/facts/'
  spec.files       = `git ls-files`.split($\)
  spec.executables = ["multissh"]
  spec.require_paths = ["lib"]
  spec.license     = 'MIT'
end
