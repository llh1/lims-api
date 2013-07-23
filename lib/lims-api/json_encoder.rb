require 'json'
require 'lims-api/struct_stream'
require 'lims-api/json_stream'

module Lims::Api
  module JsonEncoder
    
    ContentType = 'application/json'
    def content_type
      ContentType
    end
    
    def call()
      stream = StructStream.new
      to_stream(stream)
      stream.struct.to_json
    end

    def stream(stream)
      json_stream = JsonStream.new(stream)
      to_stream(json_stream)
    end
  end
end
