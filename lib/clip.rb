require_relative "clip/model"
require_relative "clip/multilingual_model"
require_relative "clip/tokenizer"
require_relative "clip/image_preprocessor"
require "net/http"
require "uri"
require "fileutils"
require "logger"

module Clip
  attr_accessor :logger

  BASE_URL = "https://huggingface.co/khasinski/"
  MODELS = {
    "textual.onnx" => "clip-ViT-B-32-onnx/resolve/main/textual.onnx?download=true",
    "visual.onnx" => "clip-ViT-B-32-onnx/resolve/main/visual.onnx?download=true"
  }

  MULTILINGUAL_MODELS = {
    "textual.onnx" => "XLM-Roberta-Large-Vit-B-32-onnx/resolve/main/textual.onnx?download=true",
    "data.bin" => "XLM-Roberta-Large-Vit-B-32-onnx/resolve/main/data.bin?download=true",
    "visual.onnx" => "XLM-Roberta-Large-Vit-B-32-onnx/resolve/main/visual.onnx?download=true"
  }

  def self.download_models(download_dir, models = MODELS)
    logger ||= Logger.new(STDOUT)
    FileUtils.mkdir_p(download_dir)

    models.each do |filename, path|
      uri = URI.join(BASE_URL, path)
      logger.info("Downloading #{filename} model from #{uri}")

      self.download_file(uri.to_s, File.join(download_dir, filename))
    end
  end

  def self.download_file(url, destination, limit = 10)
    raise "Too many HTTP redirects" if limit == 0

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Get.new(uri.request_uri)

    http.request(request) do |response|
      case response
      when Net::HTTPRedirection
        new_url = response['location']
        self.download_file(new_url, destination, limit - 1)
      when Net::HTTPSuccess
        File.open(destination, 'wb') do |file|
          response.read_body do |chunk|
            file.write(chunk)
          end
        end
      else
        raise "Failed to download file: #{response.code} #{response.message}"
      end
    end
  end

  def self.models_exist?(textual_model_path:, visual_model_path:)
    File.exist?(textual_model_path) && File.exist?(visual_model_path)
  end
end
