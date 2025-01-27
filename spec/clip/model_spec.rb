# frozen_string_literal: true

RSpec.describe Clip::Model do
  let(:model) { described_class.new }
  describe '#encode_text' do
    it 'encodes text' do
      text = 'a photo'
      expect(model.encode_text(text)).to be_a(Array)
    end
  end
end
