require "net/http"
require "fileutils"
require_relative "clip/model"
require_relative "clip/tokenizer"
require_relative "clip/image_preprocessor"
require "logger"

module Clip
  attr_accessor :logger

  BASE_URL = "https://huggingface.co/khasinski/"
  MODELS = {
    textual: "clip-ViT-B-32-onnx/resolve/main/textual.onnx?download=true",
    visual: "clip-ViT-B-32-onnx/resolve/main/visual.onnx?download=true"
  }

  def self.download_models(download_dir)
    logger ||= Logger.new(STDOUT)
    FileUtils.mkdir_p(download_dir)

    MODELS.each do |type, path|
      uri = URI.join(BASE_URL, path)
      logger.info("Downloading #{type} model from #{uri}")

      while true
        response = Net::HTTP.get_response(uri)

        if response.is_a?(Net::HTTPRedirection)
          logger.info("Redirected to #{response['location']}")
          uri = URI.parse(response['location']) # Update URI to the redirect location
          next
        elsif response.is_a?(Net::HTTPSuccess)
          file_path = File.join(download_dir, "#{type}.onnx")
          File.open(file_path, 'wb') do |file|
            file.write(response.body) # Write the body directly for simplicity
          end
          logger.info("Successfully downloaded #{type} model")
          break
        else
          logger.error("Failed to download #{type} model from #{uri}: #{response.code} #{response.message}")
          raise "Failed to download #{type} model from #{uri}"
        end
      end
    end
  end

  def self.models_exist?(textual_model_path:, visual_model_path:)
    File.exist?(textual_model_path) && File.exist?(visual_model_path)
  end
end
