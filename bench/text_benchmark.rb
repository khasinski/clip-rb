# Text-side benchmark: BPE tokenizer + ONNX textual model.
#
#   ruby  -Ilib bench/text_benchmark.rb
#   spinel -Ilib -I <onnxruntime gem>/lib bench/text_benchmark.rb -o bench_bin && ./bench_bin
#
# The image side (mini_magick + numo-narray) is left out: numo is a C
# extension, which an AOT compiler such as Spinel cannot load.
require_relative "../lib/clip/tokenizer"
require "onnxruntime"

MODEL = ENV["CLIP_TEXT_MODEL"] || ".clip_models/textual.onnx"
ROUNDS = (ENV["ROUNDS"] || "20").to_i

SENTENCES = [
  "a photo of a cat",
  "a photo of a dog playing in the snow",
  "an astronaut riding a horse on the moon",
  "a bowl of ramen with a soft boiled egg",
  "the quick brown fox jumps over the lazy dog",
  "a watercolor painting of a lighthouse at dusk",
  "two people shaking hands in a modern office",
  "a red sports car parked next to a palm tree"
]

def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

def ms(t) = (t * 1000).round(1)

def us(t) = (t * 1_000_000).round(1)

t0 = now
tokenizer = Clip::Tokenizer.new
t_init = now - t0

# tokenizer throughput: fresh tokenizer caches are the slow path, so the
# first round is timed apart from the (cached) rest
t0 = now
first = SENTENCES.map { |s| tokenizer.encode(s) }
t_tok_cold = now - t0
t0 = now
ROUNDS.times { SENTENCES.each { |s| tokenizer.encode(s) } }
t_tok_warm = now - t0

# BPE on words the cache has never seen: the pure-Ruby, CPU-bound part
seed = 12345
letters = "abcdefghijklmnopqrstuvwxyz"
words = Array.new(3000) do
  len = 4 + (seed % 7)
  w = +""
  len.times do
    seed = (seed * 1103515245 + 12345) % 2147483648
    w << letters[seed % 26]
  end
  w
end
t0 = now
bpe_ids = 0
words.each_slice(10) { |ws| bpe_ids += tokenizer.encode(ws.join(" ")).sum }
t_bpe = now - t0

t0 = now
model = OnnxRuntime::Model.new(MODEL)
t_load = now - t0

t0 = now
embeddings = []
ROUNDS.times do
  SENTENCES.each_with_index do |s, i|
    embeddings[i] = model.predict({ input: [tokenizer.encode(s)] })["output"].first
  end
end
t_encode = now - t0

n = ROUNDS * SENTENCES.size
puts "tokens[0]:        #{first[0].first(8).inspect}"
puts "embedding dims:   #{embeddings[0].size}"
puts "embedding[0][0..2]: #{embeddings[0].first(3).map { |x| x.round(5) }.inspect}"
puts "checksum:         #{embeddings.sum { |e| e.sum }.round(4)}"
puts "bpe id checksum:  #{bpe_ids}"
puts
puts "tokenizer init:   #{ms(t_init)} ms"
puts "tokenize (cold):  #{us(t_tok_cold / SENTENCES.size)} us/sentence"
puts "tokenize (warm):  #{us(t_tok_warm / n)} us/sentence"
puts "bpe (new words):  #{ms(t_bpe)} ms for #{words.size} words"
puts "model load:       #{ms(t_load)} ms"
puts "encode_text:      #{ms(t_encode / n)} ms/sentence (#{n} runs)"
