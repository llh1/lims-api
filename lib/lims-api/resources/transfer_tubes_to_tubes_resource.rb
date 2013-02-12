require 'lims-api/core_action_resource'
require 'lims-api/struct_stream'

module Lims::Api
  module Resources
    class TransferTubesToTubesResource < CoreActionResource

      # We have to change the parameters name for the transfers attribute.
      # source should be renamed into source_uuid
      # and target should be renamed into target_uuid
      # If we make the change directly into the "attributes" object,
      # it doesn't work. We can add new parameters but not remove
      # the key/value source and target. It might be because it references 
      # the same objet in "result". Below, we just build a new hash of attributes
      # adding source_uuid and target_uuid but not source and target.
      def filtered_attributes
        new_attributes = {}
        super.tap do |attributes|
          attributes.each do |k,v|
            if k.to_s == "transfers"
              new_attributes[k] ||= []
              attributes[k].each do |transfer|
                h = {}
                transfer.each do |tk, te|
                  h[tk] = te unless ["source", "target"].include?(tk.to_s)
                end
                h["source_uuid"] = @context.uuid_for(transfer["source"])
                h["target_uuid"] = @context.uuid_for(transfer["target"])
                new_attributes[k] << h
              end
            else
              new_attributes[k] = v
            end
          end
        end
        new_attributes
      end

      def content_to_stream(s, mime_type)
        filtered_attributes.each do |k,v|
          case v
          when Hash
            {:sources => :sources, :results => :targets, :targets => :targets}.each do |json_key, attribute|
              s.add_key json_key
              s.with_hash do
                s.add_key "tubes"
                s.with_array do
                  v[attribute].each do |r|
                    resource = @context.resource_for(r,@context.find_model_name(r.class))
                    resource.encoder_for([mime_type]).to_stream(s)
                  end
                end
              end
            end
          else
            s.add_key k
            s.add_value v
          end
        end
      end
    end
  end
end

