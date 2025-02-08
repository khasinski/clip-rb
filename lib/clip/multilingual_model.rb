require "onnxruntime"
require "tokenizers"

module Clip
  class MultilingualModel
    def initialize(
      textual_model_path: ".clip_models/multilingual/textual.onnx",
      visual_model_path: ".clip_models/multilingual/visual.onnx",
      tokenizer: Tokenizers.from_pretrained("M-CLIP/XLM-Roberta-Large-Vit-B-32"),
      image_preprocessor: Clip::ImagePreprocessor.new,
      download_models: true,
      download_dir: ".clip_models/multilingual"
    )
      @textual_model_path = textual_model_path
      @visual_model_path = visual_model_path
      Clip.download_models(download_dir, Clip::MULTILINGUAL_MODELS) if download_models && !Clip.models_exist?(textual_model_path: textual_model_path, visual_model_path: visual_model_path)
      @tokenizer = tokenizer
      @image_preprocessor = image_preprocessor
    end

    def encode_text(text)
      encoding  = tokenizer.encode(text)
      input_ids      = [encoding.ids]
      attention_mask = [Array.new(encoding.ids.size, 1)]

      text_model.predict({ "input_ids" => input_ids, "attention_mask" => attention_mask })['output'].first
    end

    def encode_image(image)
      image = image_preprocessor.preprocess(image).to_a
      image_model.predict({ pixel_values: [ image ] })["output"].first
    end

    def text_model
      @text_model ||= OnnxRuntime::Model.new(textual_model_path)
    end

    def image_model
      @image_model ||= OnnxRuntime::Model.new(visual_model_path)
    end

    private

    attr_reader :textual_model_path, :visual_model_path, :tokenizer, :image_preprocessor
  end
end
