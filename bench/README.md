# Text benchmark: CRuby vs Spinel

`text_benchmark.rb` times the text side of clip-rb: the BPE tokenizer
(pure Ruby) and `encode_text` through the ONNX textual model (onnxruntime
gem, over FFI). The image side needs numo-narray, a C extension, and is left
out.

## Running

```bash
# the textual model (~250 MB)
curl -L -o .clip_models/textual.onnx \
  "https://huggingface.co/khasinski/clip-ViT-B-32-onnx/resolve/main/textual.onnx?download=true"

# CRuby
ruby -Ilib bench/text_benchmark.rb

# Spinel (AOT compiler, https://github.com/matz/spinel) -- needs its FFI support
spinel -Ilib -I $(gem contents onnxruntime | grep 'lib/onnxruntime.rb$' | xargs dirname) \
  bench/text_benchmark.rb -o text_benchmark && ./text_benchmark
```

Both print the same token ids, embeddings and checksums.

## Results

Apple M5 Max, macOS 27.0, onnxruntime 0.11.7. CRuby 4.0.7; Spinel at the
`ffi-gem-support` branch (590ef085). Median of 3 runs.

| step                          | CRuby 4.0.7 | CRuby 4.0.7 --yjit | Spinel      | Spinel vs CRuby |
|-------------------------------|------------:|-------------------:|------------:|----------------:|
| tokenizer init (vocab + BPE)  |     54.0 ms |            54.3 ms |     45.4 ms |           1.2x  |
| tokenize, cold cache          |  70.8 µs/s  |         ~400 µs/s  |  35.4 µs/s  |           2.0x  |
| tokenize, warm cache          |  20.3 µs/s  |          21.5 µs/s |   7.7 µs/s  |           2.6x  |
| BPE on 3000 unseen words      |     44.4 ms |            40.2 ms |     16.9 ms |           2.6x  |
| model load                    |    115.1 ms |           119.6 ms |    116.2 ms |           1.0x  |
| `encode_text`                 |  5.9 ms/s   |          5.9 ms/s  |   5.9 ms/s  |           1.0x  |

(`µs/s`, `ms/s`: per sentence.)

The tokenizer, which is plain Ruby, runs 2-2.6x faster compiled; YJIT does
not get to warm up on a run this short. `encode_text` is the ONNX runtime's
own C++ doing the work in both, so it does not move -- Ruby's share of a
text embedding is the ~8-70 µs of tokenization next to ~5.9 ms of inference.
