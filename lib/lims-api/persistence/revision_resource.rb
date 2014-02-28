require 'lims-api/core_resource'

module Lims::Core
  module Persistence
    class Revision
      class RevisionResource < Lims::Api::CoreResource

        def content_to_stream(s, mime_type)
          s.add_key "revisions"
          s.with_array do
            user_sessions.each do |user_session|
              user_session_to_stream(s, mime_type, user_session)
            end
          end
        end
        
        private

        def user_sessions
          [].tap do |sessions|
            @context.with_session do |session|
              state_list = session.user_session.for_resources(@object)
              state_list.each do |user_session|
                sessions << user_session
              end
            end
          end
        end

        def user_session_to_stream(s, mime_type, user_session)
          s.with_hash do
            user_session_resource_class = @context.resource_class_for(user_session)
            model_name = @context.find_model_name(user_session.class)
            user_session_resource = user_session_resource_class.new(@context, nil, model_name, user_session)

            revision_action_to_stream(s, user_session.id)
            user_session_resource.content_to_stream(s, mime_type)
          end
        end

        def revision_action_to_stream(s, session_id)
          path = "#{uuid}/revisions/#{session_id}"
          s.add_key "actions"
          s.with_hash do
            s.add_key "read"
            s.add_value @context.url_for(path)
          end
        end
      end
    end
  end
end
