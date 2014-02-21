require 'lims-api/core_resource'
require 'lims-core/persistence/user_session'
require 'lims-core/helpers'

module Lims::Core
  module Persistence
    class UserSession
      class UserSessionResource < Lims::Api::CoreResource

        def content_to_stream(s, mime_type)
          attributes = object.attributes.mash do |k,v|
            case k.to_sym
            when :id then [:session_id, v]
            when :parameters then [k, (v && v != "null") ? Lims::Core::Helpers::load_json(v) : v] 
            else [k,v]
            end
          end

          attributes.each do |k,v|
            s.add_key k
            s.add_value v
          end
        end

        module Encoder
          include Lims::Api::CoreResource::Encoder

          def to_hash_stream_base(h)
            nil
          end
        end

        Encoders = [
          class JsonEncoder
            include Encoder
            include Lims::Api::JsonEncoder
          end
        ]

        def self.encoder_class_map 
          Encoders.mash { |k| [k::ContentType, k] }
        end
      end
    end
  end
end
