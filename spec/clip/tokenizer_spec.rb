# frozen_string_literal: true

RSpec.describe Clip::Tokenizer do
  let(:tokenizer) { described_class.new }

  describe '#bytes_to_unicode' do
    it 'returns a hash mapping bytes to Unicode strings' do
      expect(tokenizer.bytes_to_unicode).to be_a(Hash)
    end
  end

  describe '#basic_clean' do
    it 'returns the input text' do
      expect(tokenizer.basic_clean("hello")).to eq("hello")
    end
  end

  describe '#whitespace_clean' do
    it 'returns the input text with whitespace cleaned' do
      expect(tokenizer.whitespace_clean("hello  world")).to eq("hello world")
    end
  end

  describe '#bpe' do
    it 'returns the input token after applying byte pair encoding' do
      expect(tokenizer.bpe("hello")).to eq("hello</w>")
    end
  end

  describe '#encode' do
    let(:input_vector_size) { Clip::Tokenizer::INPUT_VECTOR_SIZE }
    let(:padding) { Array.new(input_vector_size - tokenized.size, 0) }


    context 'when the input text is "hello"' do
      let(:tokenized) do
        # begin token, hello, end token
        [ 49406, 3306, 49407 ]
      end

      it 'returns a list of token ids', aggregate_failures: true do
        expect(tokenizer.encode("hello")).to eq(tokenized + padding)
      end
    end

    context 'when the input text is "你好"' do
      let(:tokenized) do
        # start token, 你好, end token
        [ 49406, 47466, 254, 29290, 377, 49407 ]
      end

      it 'correctly encodes non-ASCII characters' do
        expect(tokenizer.encode("你好")).to eq(tokenized + padding)
      end
    end
  end
end
