require 'lims-api/core_resource'
require 'lims-core/persistence/revision'

module Lims::Core
  module Persistence
    class Revision
      class RevisionResource < Lims::Api::CoreResource

        def content_to_stream(s, mime_type)
          s.add_key "revisions"
          s.with_array do
            revisions.each do |revision|
              revision_to_stream(s, mime_type, revision)
            end
          end
        end
        
        private

        def revision_to_stream(s, mime_type, revision)
          s.with_hash do
            s.add_key "revision_number"
            s.add_value revision.number
            s.add_key "action"
            s.add_value revision.action
            s.add_key "user_session"
            user_session_to_stream(s, mime_type, revision.session_id)
            s.add_key "resource"
            revision_resource_to_stream(s, revision)
          end
        end

        def user_session_to_stream(s, mime_type, session_id)
          s.with_hash do
            @context.with_session do |session|
              user_session = session.user_session[{:id => session_id}]
              user_session_resource_class = @context.resource_class_for(user_session)
              model_name = @context.find_model_name(user_session.class)
              user_session_resource = user_session_resource_class.new(@context, nil, model_name, user_session)
              user_session_resource.content_to_stream(s, mime_type)
            end
          end
        end

        def revision_resource_to_stream(s, revision)
          path = "#{uuid}/revisions/#{revision.session_id}"
          s.with_hash do
            s.add_key "actions"
            s.with_hash do
              s.add_key "read"
              s.add_value @context.url_for(path)
            end
          end
        end

        def revisions
          [].tap do |revisions|
            @context.with_session do |session|
              sessions = session.user_session.for_resources(@object)
              session_ids = sessions.inject([]) { |m,e| m << e.id }
              resource_id = session.id_for(object)

              session_ids.each do |session_id|
                Lims::Core::Persistence::Sequel::Revision::Session.new(session.store, session_id).with_session do |revision_session|
                  revision_persistor = revision_session.send(model_name)
                  revision_persistor[resource_id]
                  revisions << revision_persistor.revision_for(resource_id)
                end
              end
            end
          end
        end
      end
    end
  end
end
