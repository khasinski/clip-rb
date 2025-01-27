require "mini_magick"
require "numo/narray"

module Clip
  class ImagePreprocessor
    # CLIP's expected image normalization parameters
    MEAN = Numo::DFloat[*[ 0.48145466, 0.4578275, 0.40821073 ]]
    STD = Numo::DFloat[*[ 0.26862954, 0.26130258, 0.27577711 ]]

    def initialize(target_size: 224)
      @target_size = target_size
    end

    # Preprocess the image and return a tensor with shape [batch_size, 3, 224, 224]
    def preprocess(image_path)
      image = load_and_resize(image_path)
      tensor = image_to_tensor(image)
      normalized = normalize(tensor)
      add_batch_dimension(normalized)
    end

    private

    # Load image, convert to RGB, and resize to target size
    def load_and_resize(image_path)
      image = MiniMagick::Image.open(image_path)
      image.format "png" # Ensure consistent format
      image = image.combine_options do |c|
        c.resize "#{@target_size}x#{@target_size}!"
        c.quality 100
        c.colorspace "RGB"
      end
      image
    end

    # Convert the image to a normalized NumPy array with shape [3, 224, 224]
    def image_to_tensor(image)
      pixels = image.get_pixels # Returns [[R, G, B], ...] for each row
      # Convert to Numo::NArray and reshape
      pixel_array = Numo::UInt8.asarray(pixels).cast_to(Numo::DFloat)
      # Reshape to [height, width, channels]
      pixel_array = pixel_array.reshape(@target_size, @target_size, 3)
      # Transpose to [channels, height, width]
      pixel_array = pixel_array.transpose(2, 0, 1)
      # Normalize to [0, 1]
      pixel_array / 255.0
    end

    # Apply CLIP normalization: (x - mean) / std
    def normalize(tensor)
      # Expand mean and std to match tensor shape
      mean = MEAN.reshape(3, 1, 1)
      std = STD.reshape(3, 1, 1)
      (tensor - mean) / std
    end

    # Add batch dimension: [1, 3, 224, 224]
    def add_batch_dimension(tensor)
      tensor.reshape(3, @target_size, @target_size)
    end
  end
end
