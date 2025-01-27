# frozen_string_literal: true

require_relative "lib/clip/version"

Gem::Specification.new do |spec|
  spec.name = "clip-rb"
  spec.version = Clip::VERSION
  spec.authors = ["Krzysztof Hasiński"]
  spec.email = ["krzysztof.hasinski@gmail.com"]

  spec.summary = "OpenAI CLIP embeddings, uses ONNX models"
  spec.description = "OpenAI CLIP embeddings, uses ONNX models. Allows to create embeddings for images and text"
  spec.homepage = "https://github.com/khasinski/clip-rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/khasinski/clip-rb"
  spec.metadata["changelog_uri"] = "https://github.com/khasinski/clip-rb/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "onnxruntime", "~> 0.9.3"
  spec.add_dependency "net-http", "~> 0.6.0"
  spec.add_dependency "zlib", "~> 3.2"
  spec.add_dependency "logger", "~> 1.6"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
