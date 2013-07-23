module Lims::Api
  class Stream

    def initialize(stream = nil)
      @stack = []
    end

    def with_hash
      start_hash
      yield
      end_hash
      self
    end

    def with_array
      start_array
      yield
      end_array
      self
    end

    def start_hash
      raise NotImplementedError, "#{self.class.name}#start_hash not implemented"
    end

    def end_hash
      raise NotImplementedError, "#{self.class.name}#end_hash not implemented"
    end

    def start_array
      raise NotImplementedError, "#{self.class.name}#start_array not implemented"
    end

    def end_array
      raise NotImplementedError, "#{self.class.name}#end_array not implemented"
    end

    private

    def push(struct)
      @stack << struct
    end

    def current
      @stack.last
    end

    def pop
      @stack.pop
    end
  end
end
