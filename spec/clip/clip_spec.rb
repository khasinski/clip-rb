# frozen_string_literal: true

RSpec.describe Clip do
  it "has a version number" do
    expect(Clip::VERSION).not_to be nil
  end
end
