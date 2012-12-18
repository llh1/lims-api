require 'json'
require 'lims-api/struct_stream'

module Lims
  module Api
    module Hook

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def define_hook(method_name, &block)
          method_alias = "__#{method_name}__hook__"

          unless private_instance_methods.include?(method_alias)
            alias_method method_alias, method_name
            private method_alias

            define_method(method_name) do |*args|
              result = __send__(method_alias, *args)

              # If the result is a lambda, we embed everything in 
              # a new lambda to respond to the call method
              if result.lambda? 
                lambda do
                    result_after_call = result.call
                    block.call(self, {:method => method_name,
                                      :attributes => args,
                                      :result => result_after_call})
                    result_after_call
                end
              # Otherwise we just call the block and give back the 
              # original method result
              else
                block.call(self, {:method => method_name,
                                  :attributes => args,
                                  :result => result})
                result
              end
            end
          end
        end
        private :define_hook
      end


      module Actions
        def self.publish_message(action, content)
          # Use AMQP implementation in the Core to publish a message
          s = StructStream.new
          content.encoder_for(["application/json"]).to_stream(s)
          s.struct["on_action"] = action
         
          s.struct.to_json
        end
      end

    end
  end
end
