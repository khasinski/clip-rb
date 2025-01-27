# clip-rb

[![Gem Version](https://badge.fury.io/rb/clip-rb.svg)](https://badge.fury.io/rb/clip-rb)
[![Test](https://github.com/khasinski/clip-rb/workflows/clip-rb/badge.svg)](https://github.com/khasinski/clip-rb/actions/workflows/main.yml)

Clip replacement that uses ONNX models. No Python required! 

## Requirements

- Ruby 3.0.0 or later
- ONNX models for CLIP (downloaded automatically on first use)

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add clip-rb
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install clip-rb
```

## Usage

```ruby
require 'clip'

clip = Clip::Model.new

clip.encode_text("a photo of a cat") # => [0.15546110272407532, 0.07329428941011429, ...]

clip.encode_image("test/fixtures/test.jpg") # => [0.22115306556224823,, 0.19343754649162292, ...]
```

## CLI

Additionally you can fetch embeddings by calling:

```bash
$ clip-embed-text "a photo of a cat"
$ clip-embed-image test/fixtures/test.jpg
```

Use KNN vector search to find similar images, remember to use cosine distance!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/khasinski/clip-rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/clip-rb/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the clip-rb project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/clip-rb/blob/main/CODE_OF_CONDUCT.md).
