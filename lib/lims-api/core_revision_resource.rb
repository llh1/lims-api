unless defined?(Lims::Core::NO_AUTOLOAD)
  require 'lims-core/persistence/sequel/user_session_sequel_persistor'
  require 'lims-core/persistence/revision_persistor'
  require 'lims-core/persistence/resource_state'
  require 'lims-core/persistence/sequel/revision/persistor'
  require 'lims-core/persistence/sequel/revision/session'
end

module Lims::Api
  module CoreRevisionResource

    def session_id=(session_id)
      @session_id = session_id.to_i
    end

    def actions
      %w{read}
    end

    def object(session=nil)
      @object ||= begin
                    raise RuntimeError, "Can't load object without a session" unless session
                    load_versioned_object(session).tap do |found|
                      raise RuntimeError, "No object found for #{@uuid_resource.uuid}" unless found
                    end
                  end
    end

    private

    def load_versioned_object(session)
      Lims::Core::Persistence::Sequel::Revision::Session.new(session.store, @session_id).with_session do |session_revision|
        session_revision[@uuid_resource]
      end
    end
  end
end
