spec = Gem::Specification.new do |spec|
  spec.name = "magic_door"
  spec.version = "0.1.0b"
  spec.summary = "MagicDoor generator"
  spec.description = <<-EOF
Generates custom button images with RMagick using the famous sliding doors css tehnique.
EOF

  spec.authors << "Daniel Mircea"
  spec.email = "daniel@viseztrance.com"
  spec.homepage = "http://github.com/viseztrance/magic_door"

  spec.files = Dir["{bin,lib,docs}/**/*"] + ["README.rdoc", "LICENSE", "Rakefile", "magic_door.gemspec"]
  spec.executables = "magic-door"

  spec.has_rdoc = true
  spec.rdoc_options << "--main" << "README.rdoc" << "--title" <<  "MagicDoor generator" << "--line-numbers"
                       "--webcvs" << "http://github.com/viseztrance/magic_door"
  spec.extra_rdoc_files = ["README.rdoc", "LICENSE"]
end
