require "onnxruntime"

module Clip
  class Model
    def initialize(
      textual_model_path: ".clip_models/textual.onnx",
      visual_model_path: ".clip_models/visual.onnx",
      tokenizer: Clip::Tokenizer.new,
      image_preprocessor: Clip::ImagePreprocessor.new,
      download_models: true,
      download_dir: ".clip_models"
    )
      @textual_model_path = textual_model_path
      @visual_model_path = visual_model_path
      Clip.download_models(download_dir) if download_models && !Clip.models_exist?(textual_model_path: textual_model_path, visual_model_path: visual_model_path)
      @tokenizer = tokenizer
      @image_preprocessor = image_preprocessor
    end

    def encode_text(text)
      tokens = tokenizer.encode(text)
      text_model.predict({ input: [ tokens ] })["output"].first
    end

    def encode_image(image)
      image = image_preprocessor.preprocess(image).to_a
      image_model.predict({ input: [ image ] })["output"].first
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
