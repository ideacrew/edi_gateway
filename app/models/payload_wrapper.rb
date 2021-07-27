# frozen_string_literal: true

# Wrap a payload string into something CarrierWave likes.
class PayloadWrapper < StringIO
  attr_reader :original_filename

  def initialize(data, f_name)
    super(data)
    @original_filename = f_name
  end
end