# frozen_string_literal: true

RSpec.describe Clip::MultilingualModel do
  let(:model) { described_class.new }
  describe '#encode_text' do
    it 'encodes text', aggregate_failures: true do
      text = 'a photo'
      result = model.encode_text(text)
      expect(result).to be_a(Array)
      expect(result.size).to eq(512)
      expect(result.all? { |x| x.is_a?(Float) }).to be_truthy
    end
  end

  describe '#encode_image' do
    it 'encodes an image' do
      image = File.open('spec/fixtures/test.jpg')
      result = model.encode_image(image)
      expect(result).to be_a(Array)
      expect(result.size).to eq(512)
      expect(result.all? { |x| x.is_a?(Float) }).to be_truthy
    end
  end
end
