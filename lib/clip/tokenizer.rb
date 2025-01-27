require "zlib"
require "set"

module Clip
  class Tokenizer
    INPUT_VECTOR_SIZE = 77

    def initialize(bpe_path = __dir__ + "/../bpe_simple_vocab_16e6.txt.gz")
      @byte_encoder = bytes_to_unicode
      @byte_decoder = @byte_encoder.invert
      merges = Zlib::GzipReader.open(bpe_path).read.split("\n")[1..(49152 - 256 - 2)]
      merges = merges.map { |merge| merge.split(" ") }
      vocab = @byte_encoder.values
      vocab += vocab.map { |v| "#{v}</w>" }
      merges.each { |merge| vocab << merge.join }
      vocab += [ "<|startoftext|>", "<|endoftext|>" ]
      @encoder = Hash[vocab.zip(0...vocab.size)]
      @decoder = @encoder.invert
      @bpe_ranks = Hash[merges.zip(0...merges.size)]
      @cache = { "<|startoftext|>" => "<|startoftext|>", "<|endoftext|>" => "<|endoftext|>" }
      @pattern = Regexp.new("<\\|startoftext\\|>|<\\|endoftext\\|>|'s|'t|'re|'ve|'m|'ll|'d|\\p{L}+|\\p{N}|[^\\s\\p{L}\\p{N}]+", Regexp::IGNORECASE)
    end

    def bytes_to_unicode
      # Define base ranges for printable ASCII and extended Unicode
      bs = (33..126).to_a + (161..172).to_a + (174..255).to_a # Printable characters
      cs = bs.dup # Start with the same set of characters for mapping

      # Map remaining bytes (0–255) to unique Unicode codepoints starting from 256
      n = 0
      (0...256).each do |b|
        unless bs.include?(b)
          bs << b                   # Add the byte to the mapping
          cs << (256 + n)           # Assign a unique Unicode codepoint
          n += 1                    # Increment the counter for unmapped bytes
        end
      end

      # Convert codepoints to UTF-8 strings
      cs = cs.map { |n| n.chr(Encoding::UTF_8) }

      # Create a hash mapping bytes (0–255) to Unicode strings
      Hash[bs.zip(cs)]
    end

    def get_pairs(word)
      pairs = Set.new
      prev_char = word[0]
      word[1..-1].each do |char|
        pairs.add([ prev_char, char ])
        prev_char = char
      end
      pairs
    end

    def basic_clean(text)
      text
    end

    def whitespace_clean(text)
      text.gsub(/\s+/, " ").strip
    end

    def bpe(token)
      return @cache[token] if @cache.key?(token)

      word = token.chars[0..-2] + [ "#{token[-1]}</w>" ]
      pairs = get_pairs(word)

      until pairs.empty?
        bigram = pairs.min_by { |pair| @bpe_ranks.fetch(pair, Float::INFINITY) }
        break unless @bpe_ranks.key?(bigram)

        first, second = bigram
        new_word = []
        i = 0
        while i < word.size
          j = word[i..-1]&.index(first)
          j = j.nil? ? nil : j + i

          if j.nil?
            new_word.concat(word[i..-1])
            break
          else
            new_word.concat(word[i...j])
            if word[j] == first && word[j + 1] == second
              new_word << "#{first}#{second}"
              i = j + 2
            else
              new_word << word[j]
              i = j + 1
            end
          end
        end

        word = new_word
        break if word.size == 1

        pairs = get_pairs(word)
      end

      result = word.join(" ")
      @cache[token] = result
      result
    end

    def encode(text)
      bpe_tokens = []
      cleaned_text = whitespace_clean(basic_clean(text)).downcase
      cleaned_text = "<|startoftext|>#{cleaned_text}<|endoftext|>"
      cleaned_text.scan(@pattern) do |token|
        utf8_bytes = token.encode("utf-8").bytes

        mapped_chars = utf8_bytes.map do |b|
          @byte_encoder[b]
        end
        encoded = mapped_chars.join

        bpe_subtokens = bpe(encoded).split(" ")

        bpe_subtokens.each do |subtok|
          bpe_tokens << @encoder[subtok]
        end
      end
      pad_array(bpe_tokens)
    end

    def decode(tokens)
      text = tokens.map { |token| @decoder[token] }.join
      text = text.gsub("</w>", " ")

      decoded_bytes = text.each_char.map do |c|
        @byte_decoder[c]
      end

      decoded_bytes.compact.pack("C*").force_encoding("utf-8")
    end

    def pad_array(array)
      array.fill(0, array.length...INPUT_VECTOR_SIZE).first(INPUT_VECTOR_SIZE)
    end
  end
end
